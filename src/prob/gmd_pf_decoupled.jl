export run_pf_qloss, run_pf_qloss_vnom
export run_ac_pf_qloss, run_ac_pf_qloss_vnom
export run_ac_gmd_pf_decoupled


"FUNCTION: basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_pf_qloss(pm::PMs.AbstractPowerModel; kwargs...)
    vnom = false
    post_pf_qloss(pm::PMs.AbstractPowerModel, vnom; kwargs...)
end


"FUNCTION: basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_pf_qloss_vnom(pm::PMs.AbstractPowerModel; kwargs...)
    vnom = true
    post_pf_qloss(pm::PMs.AbstractPowerModel, vnom; kwargs...)
end


"FUNCTION: basic AC + GMD Model - Minimize Generator Dispatch with Ieff Calculated"
function post_pf_qloss(pm::PMs.AbstractPowerModel, vnom; kwargs...)
# this should be almost the same that power world does

    # -- Variables -- #

    PMs.variable_bus_voltage(pm, bounded = false)
    variable_qloss(pm)

    PMs.variable_gen_power(pm, bounded = false)
    PMs.variable_branch_power(pm, bounded = false)

    # TODO: add dc line flow
    # PMs.variable_dcline_flow(pm, bounded = false):w

    # -- Constraints -- #

    PMs.constraint_model_voltage(pm)

    for (k,bus) in PMs.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        PMs.constraint_theta_ref(pm, k)
        PMs.constraint_voltage_magnitude_setpoint(pm, k)
    end

    for (k,bus) in PMs.ref(pm, :bus)
        constraint_power_balance_gmd(pm, k)

        # PV Bus Constraints
        if length(PMs.ref(pm, :bus_gens, k)) > 0 && !(k in PMs.ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            PMs.constraint_voltage_magnitude_setpoint(pm, k)
            for j in PMs.ref(pm, :bus_gens, k)
                PMs.constraint_active_gen_setpoint(pm, j)
            end
        end
    end

    for k in PMs.ids(pm, :branch)
        if vnom 
            constraint_qloss_decoupled_vnom(pm, k)
        else
            constraint_qloss_decoupled(pm, k)
        end

        PMs.constraint_ohms_yt_from(pm, k) 
        PMs.constraint_ohms_yt_to(pm, k) 
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


"FUNCTION: run basic GMD with the nonlinear AC equations"
function run_ac_pf_qloss(data, optimizer; kwargs...)
    return run_pf_qloss(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: run basic GMD with the nonlinear AC equations"
function run_ac_pf_qloss_vnom(data, optimizer; kwargs...)
    return run_pf_qloss_vnom(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: run the basic GMD model"
function run_pf_qloss(data, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_pf_qloss; ref_extensions=[ref_add_core!], solution_builder = solution_gmd_qloss!, kwargs...)
end


"FUNCTION: run the basic GMD model"
function run_pf_qloss_vnom(data, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_pf_qloss; ref_extensions=[ref_add_core!], solution_builder = solution_gmd_qloss!, kwargs...)
end


"FUNCTION: run AC GMD PF Decoupled"
function run_ac_gmd_pf_decoupled(dc_case, optimizer; setting=Dict{String,Any}(), kwargs...)

    # add logic to read file if needed
    #dc_case = PMs.parse_file(file)
    dc_result = run_gmd(dc_case, optimizer; setting=setting)
    dc_solution = dc_result["solution"]
    make_gmd_mixed_units(dc_solution, 100.0)
    ac_case = deepcopy(dc_case)

    for (k,br) in ac_case["branch"]
        dc_current_mag(br, ac_case, dc_solution)
    end

    ac_result = run_ac_pf_qloss(ac_case, optimizer, setting=setting)
    ac_solution = ac_result["solution"]
    make_gmd_mixed_units(ac_solution, 100.0)

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)

    adjust_gmd_phasing(dc_result)
    return data

end


