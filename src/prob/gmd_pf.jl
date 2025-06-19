#############
# GIC AC-PF #
#############

"Solve coupled GMD PF problem"
function solve_gmd_pf(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_pf;
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

"Build the coupled GMD PF problem"
function build_gmd_pf(pm::_PM.AbstractPowerModel; kwargs...)
    bound_voltage = get(pm.setting,"bound_voltage",false)

    variable_bus_voltage(pm, bounded=bound_voltage)
    _PM.variable_gen_power(pm, bounded=false)
    _PM.variable_dcline_power(pm, bounded=false)
    _PM.variable_branch_power(pm, bounded=false)

    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    constraint_model_voltage(pm)

    for (i,bus) in _PM.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i)
        _PM.constraint_voltage_magnitude_setpoint(pm, i)

        # if multiple generators, fix power generation degeneracies
        if length(_PM.ref(pm, :bus_gens, i)) > 1
            for j in collect(_PM.ref(pm, :bus_gens, i))[2:end]
                _PM.constraint_gen_setpoint_active(pm, j)
                _PM.constraint_gen_setpoint_reactive(pm, j)
            end
        end
    end


    for (i,bus) in _PM.ref(pm, :bus)
        constraint_power_balance_gmd(pm, i)

        # PV Bus Constraints
        if length(_PM.ref(pm, :bus_gens, i)) > 0 && !(i in _PM.ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            _PM.constraint_voltage_magnitude_setpoint(pm, i)
            for j in _PM.ref(pm, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm, j)
            end
        end
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        constraint_qloss_pu(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for (i,dcline) in _PM.ref(pm, :dcline)
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

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_kcl(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end


"Solve sequential GMD PF problem with nonlinear ac equations"
function solve_ac_gmd_pf_uncoupled(file, optimizer; kwargs...)
    return solve_gmd_pf_uncoupled(file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"Solve sequential GMD PF problem with second order cone relaxation"
function solve_soc_gmd_pf_uncoupled(file, optimizer; kwargs...)
    return solve_gmd_pf_uncoupled(file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


"Solve sequential GMD PF problem with nonlinear ac equations"
function solve_qc_gmd_pf_uncoupled(file, optimizer; kwargs...)
    return solve_gmd_pf_uncoupled(file, _PM.QCRMPowerModel , optimizer; kwargs...)
end


# TODO: use solve_gmd_uncoupled in algo.jl for this
"Solve sequential GMD PF problem with arbitrary formulation"
function solve_gmd_pf_uncoupled(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_pf_uncoupled;
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

# Note: assumes that ieff is provided for each branch in the input case
"Build the sequential GMD PF problem"
function build_gmd_pf_uncoupled(pm::_PM.AbstractPowerModel; kwargs...)
    bound_voltage = get(pm.setting,"bound_voltage",false)

    variable_bus_voltage(pm, bounded=bound_voltage)
    _PM.variable_gen_power(pm, bounded=false)
    _PM.variable_dcline_power(pm, bounded=false)
    _PM.variable_branch_power(pm, bounded=false)

    variable_qloss(pm)

    constraint_model_voltage(pm)

    for (i,bus) in _PM.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i)
        _PM.constraint_voltage_magnitude_setpoint(pm, i)

        # if multiple generators, fix power generation degeneracies
        if length(_PM.ref(pm, :bus_gens, i)) > 1
            for j in collect(_PM.ref(pm, :bus_gens, i))[2:end]
                _PM.constraint_gen_setpoint_active(pm, j)
                _PM.constraint_gen_setpoint_reactive(pm, j)
            end
        end
    end


    for (i,bus) in _PM.ref(pm, :bus)
        constraint_power_balance_gmd(pm, i)

        # PV Bus Constraints
        if length(_PM.ref(pm, :bus_gens, i)) > 0 && !(i in _PM.ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            _PM.constraint_voltage_magnitude_setpoint(pm, i)
            for j in _PM.ref(pm, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm, j)
            end
        end
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        constraint_qloss_constant_ieff(pm, i)
    end

    for (i,dcline) in _PM.ref(pm, :dcline)
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
