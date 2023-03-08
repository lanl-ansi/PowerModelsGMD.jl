##############
# GIC AC-MLD #
##############


# ===   DECOUPLED GMD MLD   === #


"FUNCTION: solve GMD MLD mitigation with second order cone relaxation"
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
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end


"FUNCTION: build the sequential quasi-dc-pf and maximum loadability problem
as a maximum loadability problem"
function build_gmd_mld_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built problem specification corresponds to the "MLD" maximum loadability specification of PowerModelsRestoration.jl
#   (https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl)

    _PMR.variable_bus_voltage_indicator(pm, relax=true)
    _PMR.variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    variable_qloss(pm)

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

    _PMR.objective_max_loadability(pm)

end


"FUNCTION: solve the quasi-dc-pf problem followed by the maximum loadability problem
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

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


# ===   DECOUPLED GMD CASCADE MLD   === #


"FUNCTION: solve GMD CASCADE MLD mitigation with second order cone relaxation"
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
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end


"FUNCTION: build the sequential quasi-dc-pf and cascade maximum loadability
problem as a maximum loadability problem where line limits are disabled"
function build_gmd_cascade_mld_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)

    _PMR.variable_bus_voltage_indicator(pm, relax=true)
    _PMR.variable_bus_voltage_on_off(pm)

    # _PM.variable_gen_indicator(pm, relax=true)
    variable_block_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm, bounded=false)
    _PM.variable_dcline_power(pm)

    # _PM.variable_load_power_factor(pm, relax=true)
    # _PM.variable_shunt_admittance_factor(pm, relax=true)
    variable_block_shunt_admittance_factor(pm, relax=true)
    variable_block_demand_factor(pm, relax=true)

    variable_qloss(pm)

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

    _PMR.objective_max_loadability(pm)

end


"FUNCTION: solve the quasi-dc-pf problem followed the cascading maximum loadability problem
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
    ac_result = solve_gmd_cascade_mld_qloss_vnom(ac_case, model_constructor, solver, setting=setting;
    solution_processors = [
        solution_gmd_qloss_decoupled!
    ])
    ac_solution = ac_result["solution"]

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


# ===   COUPLED MLD   === #


"FUNCTION: solve GMD MLD mitigation with nonlinear ac equations"
function solve_ac_gmd_mld(file, optimizer; kwargs...)
    return solve_gmd_mld(file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: solve GMD MLD mitigation with second order cone relaxation"
function solve_soc_gmd_mld(file, optimizer; kwargs...)
    return solve_gmd_mld(file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function solve_gmd_mld(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_mld;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the ac minimum loadshedding coupled with quasi-dc-pf problem
as a maximum loadability problem with relaxed generator and bus participation"
function build_gmd_mld(pm::_PM.AbstractPowerModel; kwargs...)

# Reference:
#   built problem specification corresponds to the "MLD" specification of  PowerModelsRestoration.jl
#   (https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl)

    _PMR.variable_bus_voltage_indicator(pm, relax=true)
    _PMR.variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    variable_dc_voltage(pm)
    variable_dc_current_mag(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    _PMR.constraint_bus_voltage_on_off(pm)

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
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss_vnom(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    _PMR.objective_max_loadability(pm)
end
