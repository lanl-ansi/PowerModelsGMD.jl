export solve_soc_gmd_mld_qloss_vnom, solve_soc_gmd_cascade_mld_qloss_vnom
export solve_gmd_mld_qloss_vnom, solve_gmd_cascade_mld_qloss_vnom
export solve_soc_gmd_mld_decoupled, solve_soc_gmd_cascade_mld_decoupled


"FUNCTION: run GMD MLD mitigation with second order cone relaxation"
function solve_soc_gmd_mld_qloss_vnom(file, solver; kwargs...)
    return solve_gmd_mld_qloss_vnom(file, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_gmd_mld_qloss_vnom(file, model_constructor, solver; kwargs...)
    return _PM.solve_model(
        file,
        model_constructor,
        solver,
        build_gmd_mld_qloss_vnom;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end


"FUNCTION: run GMD CASCADE MLD mitigation with second order cone relaxation"
function solve_soc_gmd_cascade_mld_qloss_vnom(file, solver; kwargs...)
    return solve_gmd_cascade_mld_qloss_vnom(file, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_gmd_cascade_mld_qloss_vnom(file, model_constructor, solver; kwargs...)
    return _PM.solve_model(
        file,
        model_constructor,
        solver,
        build_gmd_cascade_mld_qloss_vnom;
        ref_extensions = [
            ref_add_gmd! #,
            #ref_add_load_block!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end



"FUNCTION: build the sequential quasi-dc power flow and minimum loadshed problem
as a maximum loadability problem"
function build_gmd_mld_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built problem specification corresponds to the "MLD" maximum loadability specification of
#   PowerModelsRestoration.jl (https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl)

    variable_bus_voltage_indicator(pm, relax=true)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    # TODO: Should I use a single variable for both load and shunt shedding???
    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    # variable_reactive_loss(pm)

    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        _PM.constraint_power_balance_ls(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        # constraint_qloss_decoupled_vnom_mld(pm, i)  
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    objective_max_loadability(pm)

end


"FUNCTION: build the sequential quasi-dc power flow and minimum loadshed problem
as a cascading maximum loadability problem where line limits are disabled"
function build_gmd_cascade_mld_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)

    variable_bus_voltage_indicator(pm, relax=true)
    variable_bus_voltage_on_off(pm)

    # _PM.variable_gen_indicator(pm, relax=true)
    variable_block_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm, bounded=false)
    _PM.variable_dcline_power(pm)

    # _PM.variable_load_power_factor(pm, relax=true)
    # _PM.variable_shunt_admittance_factor(pm, relax=true)
    variable_block_shunt_admittance_factor(pm, relax=true)
    variable_block_demand_factor(pm, relax=true)

    variable_reactive_loss(pm)

    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd_shunt_ls(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        # println("Adding constraints for branch $i")

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        # constraint_qloss_decoupled_vnom_mld(pm, i)  
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    objective_max_loadability(pm)

end


"FUNCTION: run the quasi-dc power flow problem followed by the maximum loadability problem 
with second order cone relaxation"
function solve_soc_gmd_mld_decoupled(file::String, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_soc_gmd_mld_decoupled(data, solver; kwargs...)
end

function solve_soc_gmd_mld_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_mld_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_gmd_mld_decoupled(file::String, model_constructor, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_mld_decoupled(data, model_constructor, solver; kwargs...)
end


function solve_gmd_mld_decoupled(dc_case::Dict{String,Any}, model_constructor, solver; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = solve_gmd(dc_case, solver)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for branch in values(ac_case["branch"])
        dc_current_mag(branch, ac_case, dc_solution)
    end
    
    qloss_decoupled_vnom(ac_case)
    ac_result = solve_gmd_mld_qloss_vnom(ac_case, model_constructor, solver, setting=setting)
    ac_solution = ac_result["solution"]
    adjust_gmd_qloss(ac_case, ac_solution)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


"FUNCTION: run the quasi-dc power flow problem followed the cascading maximum loadability problem
with second order cone relaxation"
function solve_soc_gmd_cascade_mld_decoupled(file::String, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_soc_gmd_cascade_mld_decoupled(data, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_soc_gmd_cascade_mld_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_cascade_mld_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_gmd_cascade_mld_decoupled(file::String, model_constructor, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_cascade_mld_decoupled(data, model_constructor, solver; kwargs...)
end


function solve_gmd_cascade_mld_decoupled(dc_case::Dict{String,Any}, model_constructor, solver; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = solve_gmd(dc_case, solver)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for branch in values(ac_case["branch"])
        dc_current_mag(branch, ac_case, dc_solution)
    end
    
    qloss_decoupled_vnom(ac_case)
    ac_result = solve_gmd_cascade_mld_qloss_vnom(ac_case, model_constructor, solver, setting=setting)
    ac_solution = ac_result["solution"]
    adjust_gmd_qloss(ac_case, ac_solution)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end

