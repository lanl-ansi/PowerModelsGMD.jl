# Formulations of GMD Problems
export run_ac_gmd_opf_ts_decoupled


function modify_gmd_case!(net, mods, time_index) 
    for (k,wf) in mods["waveforms"]
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        net[otype][k][field] = wf["values"][time_index]
    end


    return net
end
        

function run_ac_gmd_opf_ts_decoupled(net, solver, mods, settings; kwargs...)
    # get the number of time steps
    t = mods["time"]
    N = length(t)
    results = []

    for n in 1:N
        modify_gmd_case!(net, mods, n)
        data = PowerModelsGMD.run_ac_gmd_opf_decoupled(net, solver; setting=settings)
        data["time_index"] = n
        data["time"] = t[n]
        push!(results, data)

        Delta_t = t[2] - t[1]

        if n > 1
            Delta_t = t[n] - t[n-1]
        end

        for (k,br) in data["ac"]["case"]["branch"]
            if !(br["type"] == "transformer" || br["type"] == "xf")
                continue
            end

            result = data["ac"]["result"]
            top_oil_rise(br, result; base_mva=net["baseMVA"], Delta_t = Delta_t)
            update_top_oil_rise(br, net)
            ss_hotspot_rise(br, result)
            update_hotspot_rise(br, net)
        end
    end

    return results
end


     
