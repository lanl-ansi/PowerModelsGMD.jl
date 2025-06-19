##########
# GIC DC #
##########


# ===   WITH OPTIMIZER   === #
"Solve GIC current model with an optimizer given input file
in extended MatPower format"
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


"Build the quasi-dc-pf problem
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


# ===   WITH MATRIX SOLVER   === #
"Solve GIC current model with Lehtinen–Pirjola (LP)
matrix solver given RAW/GIC/CSV file path inputs"
function solve_gmd(ac_file::String, gic_file::String, csv_file::String; kwargs...)
    ac_data = _PM.parse_file(ac_file)
    gic_data = parse_gic(gic_file)
    case = generate_dc_data(gic_data, ac_data)
    add_coupled_voltages!(csv_file, case)
    add_gmd_3w_branch!(case)
    return solve_gmd(case; kwargs)
end


"Solve GIC current model with Lehtinen–Pirjola (LP)
matrix solver given RAW/GIC/CSV file handle inputs"
function solve_gmd(raw_file::IO, gic_file::IO, csv_file::IO; kwargs...)
    raw_data = _PM.parse_psse(raw_file)
    gic_data = parse_gic(gic_file)
    case = generate_dc_data(gic_data, raw_data)
    add_coupled_voltages!(csv_file, case)
    add_gmd_3w_branch!(case)
    return solve_gmd(case; kwargs)
end


"Solve GIC current model with Lehtinen–Pirjola (LP)
matrix solver given with RAW/GICfile paths and specified field
magnitude/direction for a uniform electric field"
function solve_gmd(raw_file::String, gic_file::String, field_mag::Float64=1.0, field_dir::Float64=90.0, min_line_length::Float64=1.0; kwargs...)
    # TODO: pass coupling arguments
    case = generate_dc_data_raw(raw_file, gic_file)
    add_gmd_3w_branch!(case)
    return solve_gmd(case; kwargs)
end


"Solve GIC current model with Lehtinen–Pirjola (LP)
matrix solver given extended MatPower file path"
function solve_gmd(file::String; kwargs...)
    data = parse_file(file)
    return solve_gmd(data; kwargs...)
end


"Solve GIC current model with Lehtinen–Pirjola (LP)
matrix solver given dictionary input"
function solve_gmd(case::Dict{String,Any}; kwargs...)
    g, i_inj = generate_g_i_matrix(case)
    v = g\i_inj
    println(g, i_inj, v)
    return solution_gmd(v, case)
end


"Solve the multi-time-series quasi-dc-pf problem"
function solve_gmd_ts_decoupled(base_case, optimizer, waveform; setting=Dict{String,Any}(), thermal=false, kwargs...)
    # TODO: consider deepcopy case to avoid errors
    case = deepcopy(base_case)

    wf_time = waveform["time"]
    wf_waveforms = waveform["waveforms"]

    if thermal
        base_mva = case["baseMVA"]
        δ_t = wf_time[2] - wf_time[1]
    end

    # TODO: add optional parameter of ac solve for transformer loading, or add sequential ac solve
    results = []

    for i in eachindex(wf_time)
        if (waveform !== nothing && waveform["waveforms"] !== nothing)
            for (k, wf) in waveform["waveforms"]
                otype = wf["parent_type"]
                field  = wf["parent_field"]

                case[otype][k][field] = wf["values"][i]
            end
        end

        result = Dict()

        if isnothing(optimizer)
            result = solve_gmd(case)
        else
            result = solve_gmd(case, optimizer; setting=setting,
            solution_processors = [
                solution_gmd!,
            ])
        end

        result["time_index"] = i
        result["time"] = wf_time[i]

        if thermal

            if i > 1
                δ_t = wf_time[i] - wf_time[i-1]
            end

            result["solution"]["branch"] = Dict()

            for (k, br) in case["branch"]
                if br["type"] ∉ Set(("xfmr", "xf", "transformer"))
                    continue
                end

                calc_transformer_temps!(br, result, base_mva, δ_t)

                xfmr_temp = Dict{String,Any}()
                xfmr_temp["Ieff"] = br["ieff"]
                xfmr_temp["delta_topoilrise"] = br["delta_topoilrise"]
                xfmr_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
                xfmr_temp["delta_hotspotrise"] =  br["delta_hotspotrise"]
                xfmr_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
                xfmr_temp["actual_hotspot"] = br["actual_hotspot"]

                result["solution"]["branch"][k] = xfmr_temp
            end
        end

        push!(results, result)
    end

    return results
end
