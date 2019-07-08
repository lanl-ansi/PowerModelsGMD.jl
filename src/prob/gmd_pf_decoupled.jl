# Formulations of GMD Problems
export run_pf_qloss, run_pf_qloss_vnom
export run_ac_pf_qloss, run_ac_pf_qloss_vnom
export run_ac_gmd_pf_decoupled

"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_pf_qloss(pm::PMs.GenericPowerModel; kwargs...)
    vnom = false
    post_pf_qloss(pm::PMs.GenericPowerModel, vnom; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_pf_qloss_vnom(pm::PMs.GenericPowerModel; kwargs...)
    vnom = true
    post_pf_qloss(pm::PMs.GenericPowerModel, vnom; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_pf_qloss(pm::PMs.GenericPowerModel, vnom; kwargs...)
    # Todo: abbreviate PowerModels
    PowerModels.variable_voltage(pm, bounded = false)
    variable_qloss(pm)

    PowerModels.variable_generation(pm, bounded = false)
    PowerModels.variable_branch_flow(pm, bounded = false)
    # TODO: add dc line flow
    # Powermodels.variable_dcline_flow(pm, bounded = false):w

    # What exactly does this do?
    PowerModels.constraint_model_voltage(pm)

    for (k,bus) in PMs.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        PowerModels.constraint_theta_ref(pm, k)
        PowerModels.constraint_voltage_magnitude_setpoint(pm, k)
    end

    for k in PMs.ids(pm, :bus)
        constraint_kcl_gmd(pm, k)

        # PV Bus Constraints
        if length(PMs.ref(pm, :bus_gens, k)) > 0 && !(k in PMs.ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            PowerModels.constraint_voltage_magnitude_setpoint(pm, k)
            for j in PMs.ref(pm, :bus_gens, k)
                PowerModels.constraint_active_gen_setpoint(pm, j)
            end
        end
    end

    for k in PMs.ids(pm, :branch)
        if vnom 
            constraint_qloss_vnom(pm, k)
        else
            constraint_qloss(pm, k)
        end

        PowerModels.constraint_ohms_yt_from(pm, k) 
        PowerModels.constraint_ohms_yt_to(pm, k) 
    end

    # Todo: add dclines
    # for (i,dcline) in ref(pm, :dcline)
    #     #constraint_dcline(pm, i) not needed, active power flow fully defined by dc line setpoints
    #     constraint_active_dcline_setpoint(pm, i)

    #     f_bus = ref(pm, :bus)[dcline["f_bus"]]
    #     if f_bus["bus_type"] == 1
    #         constraint_voltage_magnitude_setpoint(pm, f_bus["index"])
    #     end

    #     t_bus = ref(pm, :bus)[dcline["t_bus"]]
    #     if t_bus["bus_type"] == 1
    #         constraint_voltage_magnitude_setpoint(pm, t_bus["index"])
    #     end
    # end

end

"Run basic GMD with the nonlinear AC equations"
function run_ac_pf_qloss(file, solver; kwargs...)
    return run_pf_qloss(file, ACPPowerModel, solver; kwargs...)
end

"Run basic GMD with the nonlinear AC equations"
function run_ac_pf_qloss_vnom(file, solver; kwargs...)
    return run_pf_qloss_vnom(file, ACPPowerModel, solver; kwargs...)
end

"Run the basic GMD model"
function run_pf_qloss(file, model_constructor, solver; kwargs...)
    return PMs.run_model(file, model_constructor, solver, post_pf_qloss; solution_builder = get_gmd_decoupled_solution, kwargs...)
end

"Run the basic GMD model"
function run_pf_qloss_vnom(file, model_constructor, solver; kwargs...)
    return PMs.run_model(file, model_constructor, solver, post_pf_qloss_vnom; solution_builder = get_gmd_decoupled_solution, kwargs...)
end

function run_ac_gmd_pf_decoupled(dc_case, solver; setting=Dict{String,Any}(), kwargs...)
    # add logic to read file if needed
    #dc_case = PowerModels.parse_file(file)
    dc_result = PowerModelsGMD.run_gmd(dc_case, solver; setting=setting)
    dc_solution = dc_result["solution"]
    make_gmd_mixed_units(dc_solution, 100.0)
    ac_case = deepcopy(dc_case)

    for (k,br) in ac_case["branch"]
        dc_current_mag(br, ac_case, dc_solution)
    end

    ac_result = run_ac_pf_qloss(ac_case, solver, setting=setting)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)

    adjust_gmd_phasing(dc_result)
    return data
end


     
