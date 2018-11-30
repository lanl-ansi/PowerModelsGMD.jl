# Formulations of GMD Problems
export run_gmd_min_error, run_ac_gmd_min_error

"Run GMD with the nonlinear AC equations - This model minimizes distance from a specified set point"
function run_ac_gmd_min_error(file, solver; kwargs...)
    return run_gmd_min_error(file, ACPPowerModel, solver; kwargs...)
end

"Run the ordinary GMD model - This model minimizes distance from a specified set point"
function run_gmd_min_error(file::AbstractString, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gmd_min_error; solution_builder = get_gmd_solution, kwargs...)
end

"GMD Model - This model minimizes distance from a specified set point"
function post_gmd_min_error{T}(pm::GenericPowerModel{T}; kwargs...)
    PMs.variable_voltage(pm)

    variable_dc_voltage(pm)

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_generation(pm) 
    PMs.variable_active_branch_flow(pm)
    PMs.variable_reactive_branch_flow(pm)
   
    variable_dc_line_flow(pm)
    variable_demand_factor(pm)
   
    objective_gmd_min_error(pm)

    PMs.constraint_voltage(pm)

    for i in ids(pm, :bus)
         constraint_kcl_shunt_gmd_ls(pm, i)
    end

    for i in ids(pm, :branch)
        @printf "Adding constraints for branch %d\n" i
        constraint_dc_current_mag(pm, i)
        constraint_qloss_constant_v(pm, i)

        PMs.constraint_ohms_yt_from(pm, i)
        PMs.constraint_ohms_yt_to(pm, i)


        PMs.constraint_thermal_limit_from(pm, i)
        PMs.constraint_thermal_limit_to(pm, i)
        PMs.constraint_voltage_angle_difference(pm, i)
    end

    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
        constraint_dc_kcl_shunt(pm, i)
    end

    for i in ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end






