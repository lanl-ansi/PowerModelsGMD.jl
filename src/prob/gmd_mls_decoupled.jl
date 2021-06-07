export run_ac_gmd_mls_qloss_vnom, run_soc_gmd_mld_qloss_vnom
export run_gmd_mls_qloss_vnom, run_gmd_mld_qloss_vnom
export run_ac_gmd_mls_decoupled, run_soc_gmd_mld_decoupled


"FUNCTION: run GMD mitigation with nonlinear ac equations"
function run_ac_gmd_mls_qloss_vnom(file, optimizer; kwargs...)
    return run_gmd_mls_qloss_vnom(
        file,
        _PM.ACPPowerModel,
        optimizer;
        kwargs...,
    )
end

function run_gmd_mls_qloss_vnom(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
        build_gmd_mls_qloss_vnom;
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


"FUNCTION: run GMD mitigation with second order cone relaxation"
function run_soc_gmd_mld_qloss_vnom(file, optimizer; kwargs...)
    return run_gmd_mld_qloss_vnom(
        file,
        _PM.SOCWRPowerModel,
        optimizer;
        kwargs...,
    )
end

function run_gmd_mld_qloss_vnom(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
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


"FUNCTION: build the sequential quasi-dc power flow and minimum-load-shed problem
as a generator dispatch minimization and load shedding problem"
function build_gmd_mls_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built problem specification corresponds to the "Model C4" of
#   Mowen et al., "Optimal Transmission Line Switching under Geomagnetic Disturbances", 2018.

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_load(pm)

    variable_reactive_loss(pm)
    variable_dc_current(pm)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shunt_gmd_mls(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss_decoupled_vnom(pm, i)

    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    objective_gmd_min_mls(pm)

end


"FUNCTION: build the sequential quasi-dc power flow and maximum loadability problem
with second order cone relaxation"
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

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    variable_reactive_loss(pm)
    variable_dc_current(pm)

    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss_decoupled_vnom(pm, i)  

    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    objective_max_loadability(pm)

end


"FUNCTION: run the quasi-dc power flow problem followed by the minimum-load-shed problem
with nonlinear ac equations"
function run_ac_gmd_mls_decoupled(file::String, optimizer; setting=Dict(), kwargs...)

    data = _PM.parse_file(file)
    return run_ac_gmd_mls_decoupled(data, _PM.ACPPowerModel, optimizer; kwargs...)

end

function run_ac_gmd_mls_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return run_gmd_mls_decoupled(
        case,
        _PM.ACPPowerModel,
        optimizer;
        kwargs...
    )
end

function run_gmd_mls_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    
    data = _PM.parse_file(file)
    return run_gmd_mls_decoupled(data, model_type, optimizer; kwargs...)

end

function run_gmd_mls_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = run_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        dc_current_mag(branch, ac_case, dc_solution)
    end
    
    ac_result = run_gmd_mls_qloss_vnom(ac_case, model_type, optimizer, setting=setting)
    ac_solution = ac_result["solution"]
    adjust_gmd_qloss(ac_case, ac_solution)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


"FUNCTION: run the quasi-dc power flow problem followed by the maximum loadability problem 
with second order cone relaxation"
function run_soc_gmd_mld_decoupled(file::String, optimizer; setting=Dict(), kwargs...)

    data = _PM.parse_file(file)
    return run_soc_gmd_mld_decoupled(data, _PM.ACPPowerModel, optimizer; kwargs...)

end

function run_soc_gmd_mld_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return run_gmd_mld_decoupled(
        case,
        _PM.SOCWRPowerModel,
        optimizer;
        kwargs...
    )
end

function run_gmd_mld_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    
    data = _PM.parse_file(file)
    return run_gmd_mld_decoupled(data, model_type, optimizer; kwargs...)

end

function run_gmd_mld_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = run_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        dc_current_mag(branch, ac_case, dc_solution)
    end
    
    ac_result = run_gmd_mld_qloss_vnom(ac_case, model_type, optimizer, setting=setting)
    ac_solution = ac_result["solution"]
    adjust_gmd_qloss(ac_case, ac_solution)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end

