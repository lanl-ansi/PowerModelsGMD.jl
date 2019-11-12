# Formulations of GMD Problems
export run_msse_qloss, run_ac_msse_qloss
# TODO: Implement this
export run_ac_gmd_msse_decoupled

"Run GMD with the nonlinear AC equations - This model minimizes distance from a specified set point"
function run_ac_msse_qloss(file, solver; kwargs...)
    return run_msse_qloss(file, ACPPowerModel, solver; kwargs...)
end

"Run the ordinary GMD model - This model minimizes distance from a specified set point"

function run_msse_qloss(file::String, model_constructor, solver; kwargs...)
    return PMs.run_generic_model(file, model_constructor, solver, post_gmd_min_error; solution_builder = get_gmd_solution, kwargs...)
end

"GMD Model - This model minimizes distance from a specified set point"
function post_msse_qloss(pm::PMs.AbstractPowerModel; kwargs...)
    PMs.variable_voltage(pm)

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_generation(pm)
    PMs.variable_active_branch_flow(pm)
    PMs.variable_reactive_branch_flow(pm)

    variable_dc_line_flow(pm)
    variable_demand_factor(pm)

    objective_gmd_min_error(pm)

    PMs.constraint_voltage(pm)

    for i in PMs.ids(pm, :bus)
         # TODO: check that this constraint is correct 
         constraint_kcl_shunt_gmd_ls(pm, i)
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






