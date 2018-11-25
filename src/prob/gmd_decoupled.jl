# Formulations of GMD Problems
export run_gmd, run_ac_gmd


"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_decoupled_gmd(pm::GenericPowerModel; kwargs...)
    use_nominal_voltage = false
    post_decoupled_gmd(pm::GenericPowerModel, use_nominal_voltage; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_decoupled_gmd_nominal_voltage(pm::GenericPowerModel; kwargs...)
    use_nominal_voltage = true
    post_decoupled_gmd(pm::GenericPowerModel, use_nominal_voltage; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_decoupled_gmd(pm::GenericPowerModel, nominal_voltage; kwargs...)
    PowerModels.variable_voltage(pm)
    PowerModelsGMD.variable_qloss(pm)

    PowerModels.variable_generation(pm)
    PowerModels.variable_branch_flow(pm)

    # TODO: Why does this use a different objective function than regular acopf?
    PowerModels.objective_min_fuel_cost(pm)

    PowerModels.constraint_voltage(pm)

    for k in ids(pm, :ref_buses)
        PowerModels.constraint_theta_ref(pm, k)
    end

    for k in ids(pm, :bus)
        PowerModelsGMD.constraint_kcl_gmd(pm, k)
    end

    for k in ids(pm, :branch)
        println(@sprintf "Adding constraints for branch %d" k)
        dc_current_mag!(ac_case["branch"]["$k"], ac_case, dc_solution)

        if nominal_voltage 
            constraint_nominal_voltage_qloss(pm, k)
        else
            constraint_qloss(pm, k)
        end

        PowerModels.constraint_ohms_yt_from(pm, k) 
        PowerModels.constraint_ohms_yt_to(pm, k) 

        PowerModels.constraint_thermal_limit_from(pm, k)
        PowerModels.constraint_thermal_limit_to(pm, k)
        PowerModels.constraint_voltage_angle_difference(pm, k)
    end
end

"Run basic GMD with the nonlinear AC equations"
function run_ac_decoupled_gmd(file, solver; kwargs...)
    return run_decoupled_gmd(file, ACPPowerModel, solver; kwargs...)
end

"Run basic GMD with the nonlinear AC equations"
function run_ac_decoupled_gmd_nominal_voltage(file, solver; kwargs...)
    return run_decoupled_gmd_nominal_voltage(file, ACPPowerModel, solver; kwargs...)
end

"Run the basic GMD model"
function run_decoupled_gmd(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_decoupled_gmd; solution_builder = get_decoupled_gmd_solution, kwargs...)
end

"Run the basic GMD model"
function run_decoupled_gmd_nominal_voltage(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_decoupled_gmd_nominal_voltage; solution_builder = get_decoupled_gmd_solution, kwargs...)
end



