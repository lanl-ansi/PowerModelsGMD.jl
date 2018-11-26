# Formulations of GMD Problems
export run_decoupled_gmd, run_ac_decoupled_gmd, run_decoupled_gmd_nominal_voltage, run_ac_decoupled_gmd_nominal_voltage


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

# change this to run_decoupled_gmd and rename others to run_decoupled_gmd_gic
function run_decoupled_gmd_ac(file, solver; kwargs...)
    dc_case = PowerModels.parse_file(file)
    dc_result = PowerModelsGMD.run_gmd_gic(dc_case, solver; setting=settings)
    dc_solution = dc_result["solution"]
    make_gmd_mixed_units(dc_solution, 100.0)
    ac_case = deepcopy(dc_case)

    for (k,br) in ac_case["branch"]
        dc_current_mag(br, ac_case, dc_solution)
    end

    ac_result = run_ac_decoupled_gmd(ac_case, solver, setting=settings)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)

    adjust_gmd_phasing(dc_result)
    return data
end


     
