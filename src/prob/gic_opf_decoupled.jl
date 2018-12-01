# Formulations of GMD Problems
export run_opf_qloss, run_opf_qloss_vnom
export run_ac_opf_qloss, run_ac_opf_qloss_vnom
export run_ac_gic_opf_decoupled


"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss(pm::GenericPowerModel; kwargs...)
    use_vnom = false
    post_opf_qloss(pm::GenericPowerModel, use_vnom; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss_vnom(pm::GenericPowerModel; kwargs...)
    use_vnom = true
    post_opf_qloss(pm::GenericPowerModel, use_vnom; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss(pm::GenericPowerModel, vnom; kwargs...)
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
        # TODO: check that this constraint is correct to use
        PowerModelsGMD.constraint_kcl_gmd(pm, k)
    end

    for k in ids(pm, :branch)
        if vnom 
            constraint_vnom_qloss(pm, k)
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
function run_ac_opf_qloss(file, solver; kwargs...)
    return run_opf_qloss(file, ACPPowerModel, solver; kwargs...)
end

"Run basic GMD with the nonlinear AC equations"
function run_ac_opf_qloss_vnom(file, solver; kwargs...)
    return run_opf_qloss_vnom(file, ACPPowerModel, solver; kwargs...)
end

"Run the basic GMD model"
function run_opf_qloss(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_opf_qloss; solution_builder = get_gmd_decoupled_solution, kwargs...)
end

"Run the basic GMD model"
function run_opf_qloss_vnom(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_opf_qloss; solution_builder = get_gmd_decoupled_solution, kwargs...)
end

function run_ac_gic_opf_decoupled(dc_case, solver, settings; kwargs...)
    # add logic to read file if needed
    #dc_case = PowerModels.parse_file(file)
    dc_result = PowerModelsGMD.run_gic(dc_case, solver; setting=settings)
    dc_solution = dc_result["solution"]
    make_gmd_mixed_units(dc_solution, 100.0)
    ac_case = deepcopy(dc_case)

    for (k,br) in ac_case["branch"]
        dc_current_mag(br, ac_case, dc_solution)
    end

    ac_result = run_ac_opf_qloss(ac_case, solver, setting=settings)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)

    adjust_gmd_phasing(dc_result)
    return data
end


     
