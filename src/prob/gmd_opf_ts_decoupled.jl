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


"FUNCTION: decoupled time-extended GMD+OPF formulation"
function run_ac_gmd_opf_ts_decoupled(net, solver, mods, settings; kwargs...)

    timesteps = mods["time"]
    n = length(timesteps)
    t = timesteps

    # Define input values for temperature calculations
        #these need to be changed...
    base_mva = net["baseMVA"]
    tau_oil = 4260 #which is 71 mins in seconds
    delta_t = t[2]-t[1]
    delta_oil_rated = 75 #oil temp rise at rated power
    tau_hs = 150
    Re = 0.63 #from Randy Horton's report, transformer model E on p. 52
    temp_ambient = 25 #ambient temperature

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

        #println("Run AC-OPF using calculated quasi-dc currents")
        data = PowerModelsGMD.run_ac_gmd_opf_decoupled(net, solver; setting=settings)
        
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
            
            PowerModelsGMD.delta_topoilrise(br, result, base_mva, tau_oil, delta_t, delta_oil_rated) 
            # PowerModelsGMD.delta_topoilrise_ss(br, result, base_mva, delta_oil_rated) #included in delta_topoilrise
            PowerModelsGMD.update_topoilrise(br, net)
            
            # PowerModelsGMD.delta_hotspotrise(br, result, Ie_prev[k], tau_hs, delta_t, Re) #decided to only calculate stead-state value
            PowerModelsGMD.delta_hotspotrise_ss(br, result, Re)
            PowerModelsGMD.update_hotspotrise(br, net)
            
            # Store calculated transformer temperature related results:
            trf_temp["Ieff"] = br["ieff"]
            #trf_temp["delta_topoilrise"] = br["delta_topoilrise"] #decided not to store value
            trf_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
            #trf_temp["delta_hotspotrise"] =  br["delta_hotspotrise"] #decided not to store value
            trf_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
            trf_temp["actual_hotspot"] = (temp_ambient+br["delta_topoilrise_ss"]+br["delta_hotspotrise_ss"])
            
            merge!(result["solution"]["branch"][k], trf_temp)

        end
        
        push!(results, data)
        
    end
    println("Finished running\n")

    return results
end


