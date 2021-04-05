export run_msse_qloss, run_ac_msse_qloss
export run_ac_gmd_msse_decoupled

# This model minimizes distance from a specified set point.

"FUNCTION: run GMD with the nonlinear AC equations"
function run_ac_msse_qloss(data, optimizer; kwargs...)
    return run_msse_qloss(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: run the ordinary GMD model"
function run_msse_qloss(data::String, model_type::Type, optimizer; kwargs...)
    return PMs.run_generic_model(data, model_type, optimizer, post_gmd_min_error; ref_extensions=[ref_add_core!], solution_builder = solution_gmd!, kwargs...)
end


"FUNCTION: GMD Model"
function post_msse_qloss(pm::PMs.AbstractPowerModel; kwargs...)

    PMs.variable_bus_voltage(pm)

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_gen_power(pm)
    PMs.variable_active_branch_flow(pm)
    PMs.variable_reactive_branch_flow(pm)

    variable_dc_line_flow(pm)
    variable_demand_factor(pm)

    objective_gmd_min_error(pm)

    PMs.constraint_voltage(pm)

    for i in PMs.ids(pm, :bus)
         # TODO: check that this constraint is correct 
         constraint_power_balance_shunt_gmd_mls(pm, i)
    end

    for i in Pms.ids(pm, :branch)

        if vnom 
            constraint_vnom_qloss(pm, i)
        else
            constraint_qloss(pm, i)
        end


        constraint_dc_current_mag(pm, i)
        constraint_qloss_constant_v(pm, i)

        PMs.constraint_ohms_yt_from(pm, i)
        PMs.constraint_ohms_yt_to(pm, i)


        PMs.constraint_thermal_limit_from(pm, i)
        PMs.constraint_thermal_limit_to(pm, i)
        PMs.constraint_voltage_angle_difference(pm, i)

    end

end


