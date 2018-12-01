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
    N = length(mods["times"])
    ts_data = []

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

        push!(ts_data, data) 
    end

    return ts_data
end


     
