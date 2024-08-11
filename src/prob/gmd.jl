##########
# GIC DC #
##########


# ===   WITH OPTIMIZER   === #


"FUNCTION: solve GIC current model"
function solve_gmd(file, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd;
        ref_extensions = [
            ref_add_gmd!,
        ],
        solution_processors = [
            solution_gmd!
        ],
        kwargs...,
    )
end


"FUNCTION: build the quasi-dc-pf problem
as a linear constraint satisfaction problem"
function build_gmd(pm::_PM.AbstractPowerModel; kwargs...)

    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_kcl(pm, i) # constraint_gic_current_balance(
        
    end

    for i in _PM.ids(pm, :branch)
        constraint_qloss_gmd(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end
end


# ===   WITH MATRIX SOLVE   === #
function solve_gmd(raw_file::IO, gic_file::IO, csv_file::IO; kwargs...)
    raw_data = _PM.parse_psse(raw_file)
    gic_data = parse_gic(gic_file)
    case = generate_dc_data(gic_data, raw_data)
    add_coupled_voltages!(csv_file, case)
    return solve_gmd(case; kwargs)
end

"FUNCTION: solve GIC matrix solve"
function solve_gmd(raw_file::String, gic_file::String, field_mag::Float64=1.0, field_dir::Float64=90.0, min_line_length::Float64=1.0; kwargs...)
    # TODO: pass coupling arguments
    case = generate__dc_data_raw(raw_file, gic_file)
    return solve_gmd(case; kwargs)
end

function solve_gmd(file::String; kwargs...)
    data = parse_file(file)
    return solve_gmd(data; kwargs...)
end

function solve_gmd(case::Dict{String,Any}; kwargs...)
    g, i_inj = generate_g_i_matrix(case)

    v = g\i_inj
    
    return solution_gmd(v, case)
end


"FUNCTION: solve the multi-time-series quasi-dc-pf problem"
function solve_gmd_ts_decoupled(case, optimizer, waveform; setting=Dict{String,Any}(), thermal=false, kwargs...)
    # TODO: consider deepcopy case to avoid errors

    wf_time = waveform["time"]
    wf_waveforms = waveform["waveforms"]

    if thermal
        base_mva = case["baseMVA"]
        delta_t = wf_time[2] - wf_time[1]

        Ie_prev = Dict()
        for (i, br) in case["branch"]
            Ie_prev[i] = nothing
        end
    end

    # TODO: add optional parameter of ac solve for transformer loading, or add sequential ac solve
    solution = []
    for i in eachindex(wf_time)
        if (waveform !== nothing && waveform["waveforms"] !== nothing)
            for (k, wf) in waveform["waveforms"]

                otype = wf["parent_type"]
                field  = wf["parent_field"]

                case[otype][k][field] = wf["values"][i]

            end
        end

        result = Dict()

        if optimizer !== nothing
            result = solve_gmd(case, optimizer; setting=setting,
            solution_processors = [
                solution_gmd!,
            ])
        else
            result = solve_gmd(case)            
        end

        result["time_index"] = i
        result["time"] = wf_time[i]

        if thermal
            xfmr_temp = Dict("Ieff" => 0.0, "delta_topoilrise_ss" => 0.0, "delta_hotspotrise_ss" => 0.0, "actual_hotspot" => 0.0)

            if i > 1
                delta_t = wf_time[i] - wf_time[i-1]
            end

            result["solution"]["branch"] = Dict()

            #for (k, br) in result["ac"]["case"]["branch"]
            for (k, br) in case["branch"]

                if !(br["type"] == "xfmr" || br["type"] == "xf" || br["type"] == "transformer")
                    continue
                else
                    br["delta_topoilrise_ss"] = calc_delta_topoilrise_ss(br, result, base_mva)
                    br["delta_topoilrise"] = calc_delta_topoilrise(br, result, base_mva, delta_t)
                    update_topoilrise!(br, case)

                    br["delta_hotspotrise_ss"] = calc_delta_hotspotrise_ss(br, k, result)
                    br["delta_hotspotrise"] = calc_delta_hotspotrise(br, result, k, Ie_prev[k], delta_t)
                    update_hotspotrise!(br, case)

                    xfmr_temp["Ieff"] = result["solution"]["ieff"][k]
                    # xfmr_temp["delta_topoilrise"] = br["delta_topoilrise"]
                    xfmr_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
                    # xfmr_temp["delta_hotspotrise"] =  br["delta_hotspotrise"]
                    xfmr_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
                    xfmr_temp["actual_hotspot"] = (get(br, "temperature_ambient", 25.0) + br["delta_topoilrise_ss"] + br["delta_hotspotrise_ss"])
                end

                result["solution"]["branch"]["$k"] = xfmr_temp
            end
        end


        push!(solution, result)
    end
    return solution

end
