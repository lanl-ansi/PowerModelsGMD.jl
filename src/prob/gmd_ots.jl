export run_ac_gmd_mls_ots, run_qc_gmd_mls_ots, run_soc_gmd_mls_ots
export run_gmd_mls_ots


"FUNCTION: run GMD mitigation with nonlinear ac equations"
function run_ac_gmd_mls_ots(file, optimizer; kwargs...)
    return run_gmd_mls_ots( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: run GMD mitigation with qc ac equations"
function run_qc_gmd_mls_ots(file, optimizer; kwargs...)
    return run_gmd_mls_ots( file, _PM.QCLSPowerModel, optimizer; kwargs...)
end


"FUNCTION: run GMD mitigation with second order cone relaxation"
function run_soc_gmd_mls_ots(file, optimizer; kwargs...)
    return run_gmd_mls_ots( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function run_gmd_mls_ots(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
        build_gmd_mls_ots;
        ref_extensions = [
            _PM.ref_add_on_off_va_bounds!,
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!,
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd_mls!,
            solution_gmd_xfmr_temp!
        ],        
        kwargs...,
    )
end


"FUNCTION: build the ac optimal transmission switching with minimum loadshed coupled with a quasi-dc power flow problem
as a generator dispatch minimization and load shedding problem"
function build_gmd_mls_ots(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built minimum loadshed problem specification corresponds to the "Model C4" of
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
        constraint_power_balance_shunt_gmd_mls(pm, i)
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
        constraint_dc_power_balance_shunt(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms_on_off(pm, i)
    end

    objective_gmd_mls_on_off(pm)

end

