# Formulations of GMD Problems
export run_decoupled_gmd_pf, run_ac_pf_decoupled_gmd, run_decoupled_gmd_pf_nominal_voltage, run_ac_pf_decoupled_gmd_nominal_voltage, run_decoupled_gmd_ac_pf


"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_decoupled_gmd_pf(pm::GenericPowerModel; kwargs...)
    use_nominal_voltage = false
    post_decoupled_gmd(pm::GenericPowerModel, use_nominal_voltage; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_decoupled_gmd_pf_nominal_voltage(pm::GenericPowerModel; kwargs...)
    use_nominal_voltage = true
    post_decoupled_gmd(pm::GenericPowerModel, use_nominal_voltage; kwargs...)
end
 
"Basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_decoupled_gmd_pf(pm::GenericPowerModel, nominal_voltage; kwargs...)
    # Todo: abbreviate PowerModels
    PowerModels.variable_voltage(pm, bounded = false)
    variable_qloss(pm)

    PowerModels.variable_generation(pm, bounded = false)
    PowerModels.variable_branch_flow(pm, bounded = false)
    # TODO: add dc line flow
    # Powermodels.variable_dcline_flow(pm, bounded = false):w

    # What exactly does this do?
    PowerModels.constraint_voltage(pm)

    for k in ids(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        PowerModels.constraint_theta_ref(pm, k)
        PowerModels.constraint_voltage_magnitude_setpoint(pm, k)
    end

    for k in ids(pm, :bus)
        constraint_kcl_gmd(pm, k)

        # PV Bus Constraints
        if length(ref(pm, :bus_gens, k)) > 0 && !(k in ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            PowerModels.constraint_voltage_magnitude_setpoint(pm, k)
            for j in ref(pm, :bus_gens, k)
                PowerModels.constraint_active_gen_setpoint(pm, j)
            end
        end
    end

    for k in ids(pm, :branch)
        if nominal_voltage 
            constraint_nominal_voltage_qloss(pm, k)
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
function run_ac_decoupled_gmd_pf(file, solver; kwargs...)
    return run_decoupled_gmd_pf(file, ACPPowerModel, solver; kwargs...)
end

"Run basic GMD with the nonlinear AC equations"
function run_ac_decoupled_gmd_pf_nominal_voltage(file, solver; kwargs...)
    return run_decoupled_gmd_pf_nominal_voltage(file, ACPPowerModel, solver; kwargs...)
end

"Run the basic GMD model"
function run_decoupled_gmd_pf(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_decoupled_gmd_pf; solution_builder = get_decoupled_gmd_solution, kwargs...)
end

"Run the basic GMD model"
function run_decoupled_gmd_pf_nominal_voltage(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_decoupled_gmd_pf_nominal_voltage; solution_builder = get_decoupled_gmd_solution, kwargs...)
end

# change this to run_decoupled_gmd and rename others to run_decoupled_gmd_gic
function run_decoupled_gmd_ac(dc_case, solver, settings; kwargs...)
    # add logic to read file if needed
    #dc_case = PowerModels.parse_file(file)
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


     
