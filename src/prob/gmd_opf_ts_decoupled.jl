# FORMULATIONS OF GMD PROBLEMS
export run_ac_gmd_opf_ts_decoupled


"FUNCTION: update the vs values"
function modify_gmd_case!(net, mods, time_index) 
    for (k,wf) in mods["waveforms"]
        otype = wf["parent_type"]
        field  = wf["parent_field"]
        net[otype][k][field] = wf["values"][time_index]
    end
    return net
end


"FUNCTION: decoupled time-extended GMD+OPF formulation"
function run_ac_gmd_opf_ts_decoupled(net, solver, mods, settings; kwargs...)
    timesteps = mods["time"]
    n = length(timesteps)
    t = timesteps

    # Define input values for temperature calculations
    base_mva = net["baseMVA"]
    tau_oil = 4260 #which is 71 mins in seconds
    Delta_t = t[2]-t[1]
    delta_oil_rated = 75
    tau_hs = 150
    Re = 0.63 #'Re': from Randy Horton's report, transformer model E on p. 52
    
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

            delta_topoilrise(br, result, base_mva, tau_oil, Delta_t, delta_oil_rated) #decided not to calculate value separately
            delta_topoilrise_ss(br, result, base_mva, delta_oil_rated) 
            update_topoilrise(br, net)

            #delta_hotspotrise(br, result, Ie_prev, tau_hs, Delta_t, Re)  #decieded to only use stead-state value
            delta_hotspotrise_ss(br, result, Re)
            update_hotspotrise(br, net)
            
            # Store transformer temperature related results:
            temp_ambient = 25
            push!(data["temperatures"]["branch"], k)
            push!(data["temperatures"]["Ieff"], br["ieff"])
            #push!(data["temperatures"]["delta_topoilrise"], br["delta_topoilrise"]) #decided not to store value
            push!(data["temperatures"]["delta_topoilrise_ss"], br["delta_topoilrise_ss"])
            #push!(data["temperatures"]["delta_hotspotrise"], br["delta_hotspotrise"]) #decided not to store value
            push!(data["temperatures"]["delta_hotspotrise_ss"], br["delta_hotspotrise_ss"])            
            push!(data["temperatures"]["actual_hotspot"], (temp_ambient+br["delta_topoilrise_ss"]+br["delta_hotspotrise_ss"]))

        end
        
        push!(results, data)
        
    end
    println("Finished running\n")

    return results
end

