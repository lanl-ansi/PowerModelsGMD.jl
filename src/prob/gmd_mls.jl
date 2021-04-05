export run_gmd_mls, run_ac_gmd_mls, run_qc_gmd_mls


"FUNCTION: run GMD mitigation with nonlinear ac equations"
function run_ac_gmd_mls(file, optimizer; kwargs...)
    return run_gmd_mls(
        file,
        _PM.ACPPowerModel,
        optimizer;
        kwargs...,
    )
end


"FUNCTION: run GMD GMD mitigation with qc ac equations"
function run_qc_gmd_mls(file, optimizer; kwargs...)
    return run_gmd_mls(
        file,
        _PM.QCLSPowerModel,
        optimizer;
        kwargs...,
    )
end

function run_gmd_mls(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
        build_gmd_mls;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!,
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd_mls!
        ],
        kwargs...,
    )
end


"FUNCTION: build the ac minimum-load-shed coupled with a quasi-dc power flow problem
as a generator dispatch minimization and load shedding problem"
function build_gmd_mls(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   Mowen et al., "Optimal Transmission Line Switching under Geomagnetic Disturbances", 2018.
#   below built problem formulation corresponds to Model C4 of above paper

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_load(pm)
    variable_ac_current(pm)

    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)
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

        constraint_current(pm, i)
        constraint_qloss_vnom(pm, i)
        constraint_dc_current_mag(pm, i)
        constraint_thermal_protection(pm, i)

    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance_shunt(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_gmd_min_mls(pm)

end

