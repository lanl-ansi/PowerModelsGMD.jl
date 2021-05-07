export run_ac_pf_qloss, run_ac_pf_qloss_vnom
export run_pf_qloss, run_pf_qloss_vnom
export run_ac_gmd_pf_decoupled


"FUNCTION: run basic GMD model with nonlinear ac equations"
function run_ac_pf_qloss(file, optimizer; kwargs...)
    return run_pf_qloss(
        file,
        _PM.ACPPowerModel,
        optimizer;
        kwargs...,
    )
end

function run_ac_pf_qloss_vnom(file, optimizer; kwargs...)
    return run_pf_qloss_vnom(
        file,
        _PM.ACPPowerModel,
        optimizer;
        kwargs...,
    )
end

function run_pf_qloss(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
        build_pf_qloss;
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

function run_pf_qloss_vnom(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
        build_pf_qloss_vnom;
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


"FUNCTION: build the sequential quasi-dc power flow and ac power flow problem
as a generator dispatch minimization problem with calculated ieff"
function build_pf_qloss(pm::_PM.AbstractPowerModel; kwargs...)

    use_vnom = false
    build_pf_qloss(pm::_PM.AbstractACPModel, use_vnom; kwargs...)

end

function build_pf_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)

    use_vnom = true
    build_pf_qloss(pm::_PM.AbstractACPModel, use_vnom; kwargs...)

end

function build_pf_qloss(pm::_PM.AbstractACPModel, vnom; kwargs...)

    _PM.variable_bus_voltage(pm, bounded=false) # ok
    _PM.variable_gen_power(pm, bounded=false) # ok
    _PM.variable_branch_power(pm, bounded=false) # ok
    _PM.variable_dcline_power(pm, bounded=false)

    variable_qloss(pm) # ok

    _PM.constraint_model_voltage(pm) # ok

    for (i, bus) in _PM.ref(pm, :ref_buses)

        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i) # ok
        _PM.constraint_voltage_magnitude_setpoint(pm, i) # ok

    end

    for (i, bus) in _PM.ref(pm, :bus)

        constraint_power_balance_gmd(pm, i) # ok

        if length(_PM.ref(pm, :bus_gens, i)) > 0 && !(i in _PM.ids(pm,:ref_buses))

            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm, i)
            for j in _PM.ref(pm, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm, j)
            end

        end

    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i) # ok
        _PM.constraint_ohms_yt_to(pm, i) # ok

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        if vnom
            constraint_qloss_decoupled_vnom(pm, i) # ok
        else
            constraint_qloss_decoupled(pm, i) # ok
        end

    end

    for (i, dcline) in _PM.ref(pm, :dcline)

        _PM.constraint_dcline_setpoint_active(pm, i)

        f_bus = _PM.ref(pm, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm, f_bus["index"])
        end

        t_bus = _PM.ref(pm, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm, t_bus["index"])
        end

    end

end


"FUNCTION: run the quasi-dc power flow problem followed by the ac-pf problem with qloss constraints"
function run_ac_gmd_pf_decoupled(file::String, optimizer; setting=Dict(), kwargs...)

    data = _PM.parse_file(file)
    return run_ac_gmd_pf_decoupled(data, _PM.ACPPowerModel, optimizer; kwargs...)

end

function run_ac_gmd_pf_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return run_gmd_pf_decoupled(
        case,
        _PM.ACPPowerModel,
        optimizer;
        kwargs...
    )
end

function run_gmd_pf_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    
    data = _PM.parse_file(file)
    return run_gmd_pf_decoupled(data, model_type, optimizer; kwargs...)

end

function run_gmd_pf_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = run_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        dc_current_mag(branch, ac_case, dc_solution)
    end

    ac_result = run_pf_qloss_vnom(ac_case, model_type, optimizer, setting=setting)
    ac_solution = ac_result["solution"]
    adjust_gmd_qloss(ac_case, ac_solution)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end

