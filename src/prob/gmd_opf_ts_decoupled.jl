export run_ac_gmd_opf_ts_decoupled


"FUNCTION: update the vs values"
function modify_gmd_case!(net, mods, time_index)

    if mods !== nothing && mods["waveforms"] !== nothing

        for (k,wf) in mods["waveforms"]
            otype = wf["parent_type"]
            field  = wf["parent_field"]
            net[otype][k][field] = wf["values"][time_index]
        end

    end
    return net

end


"FUNCTION: decoupled time-extended GMD+OPF specification"
function run_ac_gmd_opf_ts_decoupled(net, optimizer, mods, settings; kwargs...)

    timesteps = mods["time"]
    n = length(timesteps)
    t = timesteps

    # Input values for temperature calculations
    base_mva = net["baseMVA"]
    delta_t = t[2]-t[1]

    results = []
    Ie_prev = Dict()
    
    for (k,br) in net["branch"]
        Ie_prev[k] = nothing
    end

    # println("Start running each time periods\n")
    # for i in 1:n
    for i in 21:23

        # println("")
        # println("########## Time: $(t[i]) ##########")

        modify_gmd_case!(net, mods, i)

        # println("Run AC-OPF using calculated quasi-dc currents")
        data = run_ac_gmd_opf_decoupled(net, optimizer; setting=settings)
        
        data["time_index"] = i
        data["time"] = t[i]
        trf_temp = Dict("Ieff"=>0.0, "delta_topoilrise_ss"=>0.0, "delta_hotspotrise_ss"=>0.0, "actual_hotspot"=>0.0)

        if i > 1
            delta_t = t[i] - t[i-1]
        end

        for (k,br) in data["ac"]["case"]["branch"]

            if !(br["type"] == "transformer" || br["type"] == "xf")
                continue
            end

            result = data["ac"]["result"]
           
            if false  
                delta_topoilrise(br, result, base_mva, delta_t) 
                # delta_topoilrise_ss(br, result, base_mva) #included in delta_topoilrise
                update_topoilrise(br, net)
                
                # delta_hotspotrise(br, result, Ie_prev[k], delta_t) #decided to only calculate stead-state value
                delta_hotspotrise_ss(br, result)
                update_hotspotrise(br, net)
                
                # Store calculated transformer temperature related results:
                trf_temp["Ieff"] = br["ieff"]
                #trf_temp["delta_topoilrise"] = br["delta_topoilrise"] #decided not to store value
                trf_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
                #trf_temp["delta_hotspotrise"] =  br["delta_hotspotrise"] #decided not to store value
                trf_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
                trf_temp["actual_hotspot"] = (br["temperature_ambient"]+br["delta_topoilrise_ss"]+br["delta_hotspotrise_ss"])
            end
                
            merge!(result["solution"]["branch"][k], trf_temp)


        end
        
        push!(results, data)
        
    end
    # println("Finished running\n")

    return results
end


