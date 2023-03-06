##############
# GIC AC-OTS #
##############


# ===   COUPLED AC-MLS-OTS   === #


"FUNCTION: solve GMD MLS OTS mitigation with nonlinear ac polar relaxation"
function solve_ac_gmd_mls_ots(file, optimizer; kwargs...)
    return solve_gmd_mls_ots( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION:  solve GMD MLS OTS mitigation with quadratic constrained least squares relaxation"
function solve_qc_gmd_mls_ots(file, optimizer; kwargs...)
    return solve_gmd_mls_ots( file, _PM.QCLSPowerModel, optimizer; kwargs...)
end


"FUNCTION:  solve GMD MLS OTS mitigation with second order cone relaxation"
function solve_soc_gmd_mls_ots(file, optimizer; kwargs...)
    return solve_gmd_mls_ots( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function solve_gmd_mls_ots(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_mls_ots;
        ref_extensions = [
            _PM.ref_add_on_off_va_bounds!,
            ref_add_gmd!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd!,
            solution_gmd_mls!,
        ],
        kwargs...,
    )
end


"FUNCTION: build coupled quasi-dc-pf and ac-ots with ac-mls problem
as a generator dispatch minimization and load shedding problem"
function build_gmd_mls_ots(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built minimum loadshedding problem specification corresponds to the "Model C4" of
#   Mowen et al., "Optimal Transmission Line Switching under Geomagnetic Disturbances", 2018.

    _PM.variable_bus_voltage_on_off(pm)
    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_indicator(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_ac_current_on_off(pm)
    variable_active_generation_sqr_cost(pm)
    variable_load(pm)

    variable_dc_voltage_on_off(pm)
    variable_dc_line_flow(pm, bounded=false)
    variable_reactive_loss(pm)
    variable_dc_current(pm)

    _PM.constraint_model_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd_shunt_ls(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
        constraint_gen_ots_on_off(pm, i)
        constraint_gen_perspective(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from_on_off(pm, i)
        _PM.constraint_ohms_yt_to_on_off(pm, i)

        _PM.constraint_voltage_angle_difference_on_off(pm, i)

        _PM.constraint_thermal_limit_from_on_off(pm, i)
        _PM.constraint_thermal_limit_to_on_off(pm, i)

        constraint_qloss(pm, i)
        constraint_current_on_off(pm, i)
        constraint_dc_current_mag(pm, i)
        constraint_dc_current_mag_on_off(pm, i)

        constraint_thermal_protection(pm, i)

    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms_on_off(pm, i)
    end

    objective_gmd_mls_on_off(pm)

end


# ===   COUPLED AC-MLS-OTS-TS   === #


"FUNCTION: solve the multi-time-series GMD model with nonlinear ac polar relaxation"
function solve_ac_gmd_mls_ots_ts(file, optimizer; kwargs...)
    return solve_gmd_mls_ots_ts( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: solve the multi-time-series GMD model with second order cone relaxation"
function solve_soc_gmd_mls_ots_ts(file, optimizer; kwargs...)
    return solve_gmd_mls_ots_ts( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function solve_gmd_mls_ots_ts(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_mls_ots_ts;
        multinetwork = true,
        ref_extensions = [
            ref_add_gmd!,
            _PM.ref_add_on_off_va_bounds!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd!,
            solution_gmd_mls!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the multi-time-series coupled quasi-dc-pf and ac-ots with ac-mls problem
as a generator dispatch minimization problem"
function build_gmd_mls_ots_ts(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built minimum loadshedding problem specification corresponds to the "Model C4" of
#   Mowen et al., "Optimal Transmission Line Switching under Geomagnetic Disturbances", 2018.



    for (n, network) in _PM.nws(pm)

        _PM.variable_bus_voltage_on_off(pm, nw=n)
        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        variable_load(pm, nw=n)

        variable_dc_voltage_on_off(pm, nw=n)
        variable_dc_line_flow(pm, nw=n, bounded=false)
        variable_dc_current(pm, nw=n)
        variable_dc_current_mag(pm, nw=n)
        variable_qloss(pm, nw=n)

        variable_delta_oil_ss(pm, nw=n, bounded=true)
        variable_delta_oil(pm, nw=n, bounded=true)
        variable_delta_hotspot_ss(pm, nw=n, bounded=true)
        variable_delta_hotspot(pm, nw=n, bounded=true)
        variable_hotspot(pm, nw=n, bounded=true)

        _PM.constraint_model_voltage_on_off(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_power_balance_gmd_shunt_ls(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            _PM.constraint_gen_power_on_off(pm, i, nw=n)
            constraint_gen_ots_on_off(pm, i, nw=n)
            constraint_gen_perspective(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)

            _PM.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            _PM.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            _PM.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            _PM.constraint_thermal_limit_to_on_off(pm, i, nw=n)

            constraint_qloss_vnom(pm, i, nw=n)
            constraint_dc_current_mag(pm, i, nw=n)
            constraint_dc_current_mag_on_off(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state(pm, i, nw=n)
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)

        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_bus, nw=n)
            constraint_dc_power_balance(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_branch, nw=n)
            constraint_dc_ohms_on_off(pm, i, nw=n)
        end

    end

    network_ids = sort(collect(nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PM.ids(pm, :branch, nw=n_1)
        constraint_temperature_state(pm, i, nw=n_1)
    end
    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_temperature_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    _PM.objective_min_fuel_and_flow_cost(pm)

end
