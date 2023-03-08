"FUNCTION: solve the quasi-dc-pf problem followed by the ac-opf problem with qloss constraints"
function solve_ac_gmd_opf_decoupled(file::String, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_ac_gmd_opf_decoupled(data, optimizer; kwargs...)
end

function solve_ac_gmd_opf_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_opf_decoupled(data, model_type, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = solve_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        branch["ieff"] = calc_dc_current_mag(branch, ac_case, dc_solution)
    end

    qloss_decoupled_vnom(ac_case)
    ac_result = _PM.solve_opf(ac_case, model_type, optimizer, setting=setting;
        solution_processors = [
            solution_gmd_qloss_decoupled!
        ])
    ac_solution = ac_result["solution"]

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end

"FUNCTION: solve the multi-time-series quasi-dc-pf problem followed by the ac-opf problem with qloss constraints"
function solve_ac_gmd_opf_ts_decoupled(case, optimizer, waveform; setting=Dict{String,Any}(), disable_thermal=true, kwargs...)

    wf_time = waveform["time"]
    wf_waveforms = waveform["waveforms"]

    if disable_thermal == false

        base_mva = case["baseMVA"]
        delta_t = wf_time[2] - wf_time[1]

        Ie_prev = Dict()
        for (i, br) in case["branch"]
            Ie_prev[i] = nothing
        end

    end

    solution = []
    for i in 1:length(wf_time)
        if (waveform !== nothing && waveform["waveforms"] !== nothing)
            for (k, wf) in waveform["waveforms"]

                otype = wf["parent_type"]
                field  = wf["parent_field"]

                case[otype][k][field] = wf["values"][i]

            end
        end

        result = solve_ac_gmd_opf_decoupled(case, optimizer; setting=setting,
        solution_processors = [
            solution_gmd!,
            solution_gmd_qloss_decoupled!
        ])

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
