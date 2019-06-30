# Formulations of GMD Problems
export run_ac_gic_opf_ts_decoupled


function modify_gic_case(gic_case, mods, time_index) 
    gic_branches = Dict()

    for gb in values(gic_case["gic_branch"])
        k = gb["parent_index"]
        gic_branches[k] gb
    end

    for omod in values(mods["object_modifiers"])
        k = omod["parent_index"]
        gic_branches[k]["Vdc"] = omod["values"][time_index]
    end

    return gic_case
end
        

function run_ac_gic_opf_ts_decoupled(dc_case, solver, mods, settings; kwargs...)
    ac_case = deepcopy(dc_case)

    # get the number of time steps
    t = mods["times"]
    N = length(t)
    ts_data = []
    Delta_t = t[2] - t[1]

    for n in 1:N
        modify_gic_case(dc_case, mods, n)
        dc_result = PowerModelsGMD.run_gic(dc_case, solver; setting=settings)
        dc_solution = dc_result["solution"]
        make_gmd_mixed_units(dc_solution, 100.0)

        for (k,br) in ac_case["branch"]
            dc_current_mag(br, ac_case, dc_solution)
        end

        ac_result = run_ac_opf_qloss(ac_case, solver, setting=settings)
        adjust_gmd_phasing(dc_result)

        # the data requirements here could be prohibitive
        data = Dict()
        data["time"] = mods["times"][n]
        data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
        data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)


        if n == 1
            Delta_t = t[2] - t[1]
        else
            Delta_t = t[n] - t[n-1]
        end

        if "output" in settings && "transformer_temperatures" in settings["output"] && settings["output"] == true
            top_oil_rise(br, result; Delta_t = Delta_t, base_mva = net["baseMVA"]))
            update_top_oil_rise(br, net)

            ss_hotspot_rise(br, result)
            update_hotspot_rise(br, net)
        end


        push!(ts_data, data) 
    end

    return ts_data
end


     
