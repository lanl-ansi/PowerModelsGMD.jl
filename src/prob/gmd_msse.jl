export run_ac_gmd_msse
export run_msse_qloss


"FUNCTION: run basic GMD model with nonlinear ac equations"
function run_ac_gmd_msse(file, optimizer; kwargs...)
    return run_msse_qloss(file, _PM.ACPPowerModel, optimizer; kwargs...)
end

function run_msse_qloss(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_msse_qloss;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!,
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd_mls!,
            solution_gmd_demand!
        ],
        kwargs...,
    )
end


"FUNCTION: build the distance minimization from a specified setpoint problem
as a generator dispatch minimization problem"
function build_msse_qloss(pm::_PM.AbstractPowerModel; kwargs...)

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power_real(pm)
    _PM.variable_branch_power_imaginary(pm)

    variable_dc_current_mag(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)
    variable_demand_factor(pm)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shunt_gmd_mls(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        if vnom
            constraint_qloss_vnom(pm, i)
        else
            constraint_qloss(pm, i)
        end

        constraint_qloss_constant_v(pm, i)
        constraint_dc_current_mag(pm, i)

    end

    objective_gmd_min_error(pm)

end

