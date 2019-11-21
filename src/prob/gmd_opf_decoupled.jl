export run_opf_qloss, run_opf_qloss_vnom
export run_ac_opf_qloss, run_ac_opf_qloss_vnom
export run_ac_gmd_opf_decoupled


"FUNCTION: Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss(pm::PMs.AbstractACPModel; kwargs...)
    use_vnom = false
    post_opf_qloss(pm::PMs.AbstractACPModel, use_vnom; kwargs...)
end


"FUNCTION: Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_opf_qloss_vnom(pm::PMs.AbstractACPModel; kwargs...)
    use_vnom = true
    post_opf_qloss(pm::PMs.AbstractACPModel, use_vnom; kwargs...)
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


"FUNCTION: Run basic GMD with the nonlinear AC equations"
function run_ac_opf_qloss(data, optimizer; kwargs...)
    return run_opf_qloss(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: Run basic GMD with the nonlinear AC equations"
function run_ac_opf_qloss_vnom(data, optimizer; kwargs...)
    return run_opf_qloss_vnom(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: Run the basic GMD model"
function run_opf_qloss(data, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_opf_qloss; ref_extensions=[ref_add_core!], solution_builder = solution_gmd_decoupled!, kwargs...)
end


"FUNCTION: Run the basic GMD model"
function run_opf_qloss_vnom(data, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_opf_qloss_vnom; ref_extensions=[ref_add_core!], solution_builder = solution_gmd_decoupled!, kwargs...)
end


"FUNCTION: Run GIC followed by AC OPF with Qloss constraints"
function run_ac_gmd_opf_decoupled(data::String, optimizer; setting=Dict(), kwargs...)
    file = PMs.parse_file(data)
    return run_ac_gmd_opf_decoupled(file, optimizer; kwargs...)
end


"FUNCTION: Run GIC followed by AC OPF with Qloss constraints"
function run_ac_gmd_opf_decoupled(dc_case::Dict{String,Any}, optimizer; setting=Dict{String,Any}(), kwargs...)
    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = run_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]
    make_gmd_mixed_units(dc_solution, 100.0)
    ac_case = deepcopy(dc_case)

    for (k,br) in ac_case["branch"]
        dc_current_mag(br, ac_case, dc_solution)
    end

    #println("Running ac opf with voltage-dependent qloss")
    #ac_result = run_ac_opf_qloss(ac_case, optimizer, setting=setting)

    println("Running ac opf with voltage-independent qloss")
    ac_result = run_ac_opf_qloss_vnom(ac_case, optimizer, setting=setting)
    ac_solution = ac_result["solution"]

    make_gmd_mixed_units(ac_solution, 100.0)
    adjust_gmd_qloss(ac_case, ac_solution)
  

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)

    adjust_gmd_phasing(dc_result)
    return data

end


