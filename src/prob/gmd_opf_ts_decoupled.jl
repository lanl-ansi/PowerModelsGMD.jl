export run_ac_gmd_opf_ts_decoupled


"FUNCTION: run the multi-time-series sequential quasi-dc power flow and ac optimal power flow problem"
function run_ac_gmd_opf_ts_decoupled(case, optimizer, waveform; setting=Dict{String,Any}(), disable_thermal=true, kwargs...)

    wf_time = waveform["time"]
    wf_waveforms = waveform["waveforms"]

    if disable_thermal == false

        base_mva = case["baseMVA"]
        delta_t = wf_time[2]-wf_time[1]
    
        Ie_prev = Dict()
        for (i, br) in case["branch"]
            Ie_prev[i] = nothing
        end

    end


    # Run each timestep:

    solution = []
    for i in 1:length(wf_time)

        update_gmd_case!(case, waveform, i)

        result = run_ac_gmd_opf_decoupled(case, optimizer; setting=setting)
        result["time_index"] = i
        result["time"] = wf_time[i]

        if disable_thermal == false

            xfmr_temp = Dict("Ieff" => 0.0, "delta_topoilrise_ss" => 0.0, "delta_hotspotrise_ss" => 0.0, "actual_hotspot" => 0.0)

            if i > 1
                delta_t = wf_time[i] - wf_time[i-1]
            end

            for (k, br) in result["ac"]["case"]["branch"]

                ac_result = result["ac"]["result"]

                if !(br["type"] == "xfmr" || br["type"] == "xf" || br["type"] == "transformer")
                    continue

                else

                    delta_topoilrise_ss(br, ac_result, base_mva)
                    delta_topoilrise(br, ac_result, base_mva, delta_t)
                    update_topoilrise(br, case)

                    delta_hotspotrise_ss(br, ac_result)
                    delta_hotspotrise(br, ac_result, Ie_prev[k], delta_t)
                    update_hotspotrise(br, case)

                    xfmr_temp["Ieff"] = br["ieff"]
                    # xfmr_temp["delta_topoilrise"] = br["delta_topoilrise"]
                    xfmr_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
                    # xfmr_temp["delta_hotspotrise"] =  br["delta_hotspotrise"]
                    xfmr_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
                    xfmr_temp["actual_hotspot"] = (br["temperature_ambient"] + br["delta_topoilrise_ss"] + br["delta_hotspotrise_ss"])

                end

                merge!(ac_result["solution"]["branch"]["$k"], xfmr_temp)

            end

        end

        push!(solution, result)

    end

    return solution

end


"FUNCTION: update values in the case"
function update_gmd_case!(case, waveform, time_index)

    if (waveform !== nothing && waveform["waveforms"] !== nothing)
        for (k, wf) in waveform["waveforms"]

            otype = wf["parent_type"]
            field  = wf["parent_field"]
            case[otype][k][field] = wf["values"][time_index]

        end
    end

    return case

end

