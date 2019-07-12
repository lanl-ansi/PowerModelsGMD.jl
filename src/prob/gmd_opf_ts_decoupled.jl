# FORMULATIONS OF GMD PROBLEMS
export run_ac_gmd_opf_ts_decoupled


# FUNCTION: update the vs values
function modify_gmd_case!(net, mods, time_index) 
    for (k,wf) in mods["waveforms"]
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        net[otype][k][field] = wf["values"][time_index]
    end
    return net
end


# FUNCTION: decoupled time-extended GMD+OPF formulation
function run_ac_gmd_opf_ts_decoupled(net, solver, mods, settings; kwargs...)
    timesteps = mods["time"]
    n = length(timesteps)
    t = timesteps
    Delta_t = t[2]-t[1]
    
    base_mva = net["baseMVA"]
    println("")

    results = []
    Ie_prev = Dict()
    
    for (k,br) in net["branch"]
        Ie_prev[k] = nothing
    end

    println("Start running each time periods\n")
    for i in 1:n
        println("")
        println("########## Time: $(t[i]) ##########")
        modify_gmd_case!(net, mods, i)
        data = PowerModelsGMD.run_ac_gmd_opf_decoupled(net, solver; setting=settings)
        
        data["time_index"] = i
        data["time"] = t[i]
        data["temperatures"] = Dict("branch"=>[], "Ieff"=>[], "delta_topoilrise_ss"=>[], "delta_hotspotrise_ss"=>[], "actual_hotspot"=>[])
        
        if i > 1
            Delta_t = t[i] - t[i-1]
        end

        for (k,br) in data["ac"]["case"]["branch"]
            if !(br["type"] == "transformer" || br["type"] == "xf")
                continue
            end

            result = data["ac"]["result"]
            
            top_oil_rise(br, result, base_mva; Delta_t = Delta_t)
            update_top_oil_rise(br, net)

            ss_hotspot_rise(br, result)
            # hotspot_rise(branch, result, Ie_prev) #decided to only use the stead-state value
            update_hotspot_rise(br, net)
            
            
            # Store transformer temperature related results:
            temp_ambient = 25
            push!(data["temperatures"]["branch"], k)
            push!(data["temperatures"]["Ieff"], br["ieff"])
            # push!(data["temperatures"]["delta_oilrise"], br["delta_oil"]) #decided not to store value
            push!(data["temperatures"]["delta_topoilrise_ss"], br["delta_oil_ss"])
            push!(data["temperatures"]["delta_hotspotrise_ss"], br["delta_hs"])            
            push!(data["temperatures"]["actual_hotspot"], (temp_ambient+br["delta_oil_ss"]+br["delta_hs"]))

        end
        
        push!(results, data)
        
    end
    println("Finished running\n")

    return results
end
