export run_opf_qloss, run_opf_qloss_vnom
export run_ac_opf_qloss, run_ac_opf_qloss_vnom
export run_ac_gmd_opf_decoupled

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
    return PMs.run_model(file, model_constructor, solver, post_opf_qloss; solution_builder = get_gmd_decoupled_solution, kwargs...)
end

"Run the basic GMD model"
function run_opf_qloss_vnom(file, model_constructor, solver; kwargs...)
    return PMs.run_model(file, model_constructor, solver, post_opf_qloss_vnom; solution_builder = get_gmd_decoupled_solution, kwargs...)
end


"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss(pm::PMs.AbstractPowerModel; kwargs...)
    use_vnom = false
    post_opf_qloss(pm::PMs.AbstractACPModel, use_vnom; kwargs...)
end
 

"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss_vnom(pm::PMs.AbstractPowerModel; kwargs...)
    use_vnom = true
    post_opf_qloss(pm::PMs.AbstractACPModel, use_vnom; kwargs...)
end


"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss(pm::PMs.AbstractPowerModel, vnom; kwargs...)
    PowerModels.variable_voltage(pm)
    PowerModelsGMD.variable_qloss(pm)
end


"FUNCTION: Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss(pm::PMs.AbstractACPModel, vnom; kwargs...)
    PMs.variable_voltage(pm)
    variable_qloss(pm)

    PMs.variable_generation(pm)
    PMs.variable_branch_flow(pm)

    PMs.objective_min_fuel_cost(pm)

    PMs.constraint_model_voltage(pm)

    for k in PMs.ids(pm, :ref_buses)
        PMs.constraint_theta_ref(pm, k)
    end

    for k in PMs.ids(pm, :bus)
        constraint_kcl_gmd(pm, k)
    end

    for k in PMs.ids(pm, :branch)
        if vnom 
            constraint_qloss_decoupled_vnom(pm, k)
        else
            constraint_qloss_decoupled(pm, k)
        end

        PMs.constraint_ohms_yt_from(pm, k) 
        PMs.constraint_ohms_yt_to(pm, k) 

        PMs.constraint_thermal_limit_from(pm, k)
        PMs.constraint_thermal_limit_to(pm, k)
        PMs.constraint_voltage_angle_difference(pm, k)
    end
end


"""
    run_ac_gic_opf_decoupled(file)
Run GIC followed by AC OPF with Qloss constraints
"""
function run_ac_gmd_opf_decoupled(file::String, solver;  setting=Dict(), kwargs...)
    data = PowerModels.parse_file(file)
    return run_ac_gmd_opf_decoupled(data, PMs.ACPPowerModel, solver; kwargs...)
end

"""
    run_ac_gic_opf_decoupled(file)
Run GIC followed by AC OPF with Qloss constraints
"""
function run_gmd_opf_decoupled(file::String, model_form, solver;  setting=Dict(), kwargs...)
    data = PowerModels.parse_file(file)
    return run_gmd_opf_decoupled(data, model_form, solver; kwargs...)
end

"Run GIC followed by AC OPF with Qloss constraints"
function run_gmd_opf_decoupled(dc_case::Dict{String,Any}, model_form, solver; setting=Dict{String,Any}(), kwargs...)
    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = run_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]
    make_gmd_mixed_units(dc_solution, 100.0)
    ac_case = deepcopy(dc_case)

    for (k,br) in ac_case["branch"]
        dc_current_mag(br, ac_case, dc_solution)
    end

    # println("Running ac opf with voltage-dependent qloss")
    #ac_result = run_ac_opf_qloss(ac_case, optimizer, setting=setting)

    println("Running ac opf with voltage-independent qloss")
    ac_result = run_opf_qloss_vnom(ac_case, model_form, solver, setting=setting)
    ac_solution = ac_result["solution"]

    make_gmd_mixed_units(ac_solution, 100.0)
    adjust_gmd_qloss(ac_case, ac_solution)
  

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)

    adjust_gmd_phasing(dc_result)
    return data

end


