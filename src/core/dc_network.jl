# For the implicit transformer branch resistances
impxfrm = Dict{Float64, Float64}(
    765.0 => 1.0892000157158984e-05,
    500.0 => 1.666666666676272e-05,
    345.0 => 2.4155598209192887e-05,
    230.0 => 3.623188405928273e-05,
    161.0 => 5.175983436949935e-05,
    138.0 => 6.038901527172248e-05,
    115.0 => 7.246376811370438e-05,
)

# Auto Transformer high side minimum kV
KVMIN = 50

# Resistance value for gmd_branches from each bus to substation
R_g_default = 25000.00

# Main Function for generating DC network
function generate_dc_data(gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, voltage_file::String)
    # Sets up output network dictionary
    output = Dict{String, Any}()
    output["source_type"] = "gic"
    output["name"] = raw_data["name"]
    output["source_version"] = "3"

    # Generates gmd_bus table
    dc_bus_map = _generate_gmd_bus!(output, gic_data, raw_data)

    # Creates a link between AC branches and gic transformers
    transformer_map = gen_transformer_map(gic_data)

    # Generates gmd_branch table
    _generate_gmd_branch!(output, raw_data, dc_bus_map, transformer_map)

    # Adds line voltages 
    _configure_line_info!(voltage_file, output)

    # Generates the rest of the AC Data
    _generate_ac_data!(output, gic_data, raw_data)

    # Copies over identical AC data
    output["dcline"] = raw_data["dcline"]
    output["storage"] = raw_data["storage"]
    output["switch"] = raw_data["switch"]
    output["baseMVA"] = raw_data["baseMVA"]
    output["load"] = raw_data["load"]

    return output
end

# Generates gmd_bus table
function _generate_gmd_bus!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    gmd_bus = Dict{String, Dict}()

    # Index for the values in the gmd_bus table
    gmd_bus_index = 1

    # Adds substations to the gmd_bus table
    gmd_bus_index, substation_map = _add_substation_table!(gmd_bus, gmd_bus_index, gic_data, raw_data)

    # Adds ac buses to the gmd_bus table
    bus_map = _add_bus_table!(gmd_bus, substation_map, gmd_bus_index, raw_data)
    
    output["gmd_bus"] = gmd_bus

    return bus_map
end

# Compiles arrays of gen and load buses
function _gen_load_buses(raw_data::Dict{String, Any})
    # Compile all generator buses to array
    gen_buses = []
    for generator in values(raw_data["gen"])
        push!(gen_buses, generator["gen_bus"])
    end

    # Compile all load buses to array
    load_buses = []
    for load in values(raw_data["load"])
        push!(load_buses, load["load_bus"])
    end

    return gen_buses, load_buses
end

function _get_branch_data(raw_data::Dict{String, Any}, dc_bus_map::Dict{Int64, Int64}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict})

end

# Generate gmd_branch table
function _generate_gmd_branch!(output::Dict{String, Any}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int64, Int64}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict})
    branches = Dict{String, Any}()
    gmd_3w_branch = Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Int64}}()

    three_winding_resistances = _generate_3w_resistances(raw_data)

    gen_buses, load_buses = _gen_load_buses(raw_data)

    gmd_branch_index = 1
    sorted_branch_indices = sort([x["index"] for x in values(raw_data["branch"])])

    for branch_index in sorted_branch_indices
        branch = raw_data["branch"]["$branch_index"]

        # TODO: If not three winding, corrects raw parser error of f_bus and t_bus being flipped sometimes
        if branch["source_id"][4] == 0
            branch["f_bus"] = branch["source_id"][2]
            branch["t_bus"] = branch["source_id"][3]
        end

        # Determines the high and low buses of a branch
        hi_bus = raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] < raw_data["bus"]["$(branch["t_bus"])"]["base_kv"] ? branch["t_bus"] : branch["f_bus"]
        lo_bus = raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] < raw_data["bus"]["$(branch["t_bus"])"]["base_kv"] ? branch["f_bus"] : branch["t_bus"]
        branch["hi_bus"] = hi_bus
        branch["lo_bus"] = lo_bus

        if !branch["transformer"]
            # Branch is a line
            branch_data = Dict{String, Any}(
                "f_bus" => dc_bus_map[branch["f_bus"]],
                "t_bus" => dc_bus_map[branch["t_bus"]],
                "br_r" => branch["br_r"] != 0 ? branch["br_r"] * (raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] ^ 2) / (3 * raw_data["baseMVA"]) : 0.0005, # TODO add 1e-4 ohms per km
                "name" => "dc_br$(gmd_branch_index)",
                "br_status" => 1,
                "index" => gmd_branch_index,
                "parent_index" => branch_index,
                "parent_type" => "branch",
                "source_id" => branch["source_id"],
                "br_v" => 0,
                "len_km" => 0,
            )

            branches["$gmd_branch_index"] = branch_data
            gmd_branch_index += 1
        else
            # Branch is a transformer
            transformer = deepcopy(transformer_map[Tuple(branch["source_id"][2:5])])

            # Three winding if tertiary winding in source id is not 0
            three_winding = branch["source_id"][4] != 0

            # Determines the high and low bus out of the primary and secondary sides of the transformers
            hi_side_bus = raw_data["bus"]["$(branch["source_id"][2])"]["base_kv"] >= raw_data["bus"]["$(branch["source_id"][3])"]["base_kv"] ? branch["source_id"][2] : branch["source_id"][3]
            lo_side_bus = raw_data["bus"]["$(branch["source_id"][2])"]["base_kv"] >= raw_data["bus"]["$(branch["source_id"][3])"]["base_kv"] ? branch["source_id"][3] : branch["source_id"][2]

            # Fetches the nominal voltages of the high side and low side buses 
            hi_side_bus_kv = raw_data["bus"]["$hi_side_bus"]["base_kv"]
            lo_side_bus_kv = raw_data["bus"]["$lo_side_bus"]["base_kv"]

            # Adds to gmd_3w_branch table
            if three_winding
                if !haskey(gmd_3w_branch, Tuple(branch["source_id"][2:5]))
                    gmd_3w_branch[Tuple(branch["source_id"][2:5])] = Dict{String, Int64}()
                end

                # Determines prefix for the gmd_3w_branch table
                if lo_side_bus == branch["f_bus"]
                    prefix = "lo"
                elseif hi_side_bus == branch["f_bus"]
                    prefix = "hi"
                else
                    prefix = "tr"
                end

                gmd_3w_branch[Tuple(branch["source_id"][2:5])]["$(prefix)_3w_branch"] = branch_index
            end

            turns_ratio = hi_side_bus_kv / lo_side_bus_kv

            # If no transformer configuration given or non gwye-gwye auto transformer
            if length(strip(transformer["VECGRP"])) == 0 || (endswith(transformer["VECGRP"], r"a.*") && !startswith(transformer["VECGRP"],"YNa"))
                # Determines assumed configurations according to PowerWorld rules
                if hi_side_bus_kv > KVMIN && (lo_side_bus_kv < KVMIN || lo_side_bus in load_buses)
                    if hi_side_bus == branch["f_bus"]
                        transformer["VECGRP"] = "Dyn"
                    else
                        transformer["VECGRP"] = "YNd"
                    end
                end

                if (hi_side_bus_kv > KVMIN && lo_side_bus in gen_buses) || (hi_side_bus_kv >= 300 && lo_side_bus_kv < KVMIN)
                    if hi_side_bus == branch["f_bus"]
                        transformer["VECGRP"] = "YNd"
                    else
                        transformer["VECGRP"] = "Dyn"
                    end
                end

                if (hi_side_bus_kv > KVMIN && lo_side_bus_kv > KVMIN) || (hi_side_bus_kv < KVMIN && lo_side_bus_kv < KVMIN)
                    transformer["VECGRP"] = "YNyn"
                end

                # Assumes auto transformer
                if transformer["VECGRP"] == "YNyn" && turns_ratio <= 4 && turns_ratio != 1 && hi_side_bus_kv >= KVMIN
                    transformer["VECGRP"] = "YNa"
                end

                # Adds assumed delta tertiary if three winding
                if three_winding
                    transformer["VECGRP"] *= "0d0"
                end

                Memento.warn(_LOGGER, "Transformer configuration corresponding to index $branch_index in the raw branch table was assumed as $(transformer["VECGRP"])")
            end

            # Calculates/Fetches information for the transformer
            hi_base_z = (hi_side_bus_kv ^ 2) / raw_data["baseMVA"]
            xfmr_r = branch["br_r"]
            substation = raw_data["bus"]["$(branch["t_bus"])"]["sub"]

            if three_winding
                xfmr_r = three_winding_resistances[Tuple(branch["source_id"][2:5])]

                # Adjusts transformer configuration to match specific AC branch
                if branch["source_id"][3] == branch["f_bus"]
                    # Branch corresponds to secondary-starbus branch
                    # TODO: Should this be flipped?
                    transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[2]) * "yn"
                    if transformer["VECGRP"] == "Ayn"
                        transformer["VECGRP"] = "YNa"
                    end
                elseif branch["source_id"][4] == branch["f_bus"]
                    transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[3]) * "yn"
                    transformer["BUSI"] = transformer["BUSK"]
                else
                    if startswith(transformer["VECGRP"],"YNa")
                        transformer["VECGRP"] = "YNa"
                    else
                        transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[1]) * "yn" 
                    end
                end
            end


            if endswith(transformer["VECGRP"], r"a.*")
                # Auto transformer case
                R_s, R_c = calcTransformerResistances(xfmr_r, turns_ratio, hi_base_z, true)

                # In this case R_c is calculated as Inf, but should be defaulted to = R_s
                if (turns_ratio == 1)
                    R_c = R_s
                end

                # Models the two transformers (primary-star and secondary-star) to behave like a singular transformer
                if three_winding && hi_side_bus == branch["f_bus"]
                    R_c = 1e6
                end

                if three_winding && lo_side_bus == branch["f_bus"]
                    R_s = 1e-6
                end

                # Creates gmd_branch for common side of the auto transformer
                common_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[lo_bus],
                    "t_bus" => substation,
                    "br_r" => lo_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_common",
                    "br_status" => 1,
                    "index" => gmd_branch_index,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0,
                    "len_km" => 0,
                )

                # Sets default resistance if needed
                if common_data["br_r"] == 0
                    common_data["br_r"] = R_c
                end

                branches["$gmd_branch_index"] = common_data
                gmd_branch_index += 1

                # Creates gmd_branch for series side of the auto transformer
                series_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[hi_bus],
                    "t_bus" => dc_bus_map[lo_bus],
                    "br_r" => hi_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_series",
                    "br_status" => 1,
                    "index" => gmd_branch_index,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0,
                    "len_km" => 0,
                )

                # Sets default resistance if needed
                if series_data["br_r"] == 0
                    series_data["br_r"] = R_s
                end

                branches["$gmd_branch_index"] = series_data
                gmd_branch_index += 1
                continue
            end

            hi_side_winding = false
            lo_side_winding = false

            # High side winding exists if high side is a grounded wye winding
            if (startswith(transformer["VECGRP"], "YN") && hi_bus == branch["f_bus"]) || (endswith(transformer["VECGRP"], r"yn.*") && branch["t_bus"] == hi_bus)
                hi_side_winding = !raw_data["bus"]["$hi_bus"]["starbus"] # Not modeled if to starbus
            end
            
            # Low side winding exists if low side is a grounded wye winding
            if (endswith(transformer["VECGRP"], r"yn.*") && lo_bus == branch["t_bus"]) || (startswith(transformer["VECGRP"], "YN") && lo_bus == branch["f_bus"])
                lo_side_winding = !raw_data["bus"]["$lo_bus"]["starbus"] # Not modeled if to starbus
            end

            R_hi, R_lo = calcTransformerResistances(xfmr_r, turns_ratio, hi_base_z, true)

            if (hi_side_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["hi_bus"]],
                    "t_bus" => substation,
                    "br_r" => hi_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_hi",
                    "br_status" => 1,
                    "index" => gmd_branch_index,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0,
                    "len_km" => 0,
                )

                # Sets default resistance if needed
                if branch_data["br_r"] == 0
                    branch_data["br_r"] = R_hi
                end

                branches["$gmd_branch_index"] = branch_data
                gmd_branch_index += 1
            end

            if (lo_side_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["lo_bus"]],
                    "t_bus" => substation,
                    "br_r" => lo_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_lo",
                    "br_status" => 1,
                    "index" => gmd_branch_index,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0,
                    "len_km" => 0,
                )

                # Sets default resistance if needed
                if branch_data["br_r"] == 0
                    branch_data["br_r"] = R_lo
                end

                branches["$gmd_branch_index"] = branch_data
                gmd_branch_index += 1
            end
        end
    end

    # Makes a unique branch for each bus to its substation
    for (bus_id, bus) in raw_data["bus"]
        bus_id = parse(Int64, bus_id)
        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[bus_id],
            "t_bus" => bus["sub"],
            "br_r" => R_g_default,
            "name" => "dc_bus$bus_id",
            "br_status" => 1,
            "parent_index" => bus_id,
            "index" => gmd_branch_index,
            "parent_type" => "bus",
            "source_id" => ["gmd_branch", gmd_branch_index],
            "br_v" => 0,
            "len_km" => 0,
        )

        branches["$gmd_branch_index"] = branch_data
        gmd_branch_index += 1
    end

    # Adds GSU transformer at each active generator above 30kV
    for (gen_id, gen) in raw_data["gen"]
        gen_bus = gen["gen_bus"]
        gen_base_kv = raw_data["bus"]["$gen_bus"]["base_kv"]
        if gen_base_kv < 30.0 || gen["gen_status"] == 0
            continue
        end

        gen_id = parse(Int64, gen_id)

        # Impedance base for the generator helps determine the assumed resistance of the transformer
        z_base = (gen_base_kv ^ 2) / gen["mbase"]

        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[gen["gen_bus"]],
            "t_bus" => raw_data["bus"]["$gen_bus"]["sub"],
            "br_r" => impxfrm[gen_base_kv] * z_base,
            "name" => "dc_gen$gen_id",
            "br_status" => 1,
            "parent_index" => gen_id,
            "index" => gmd_branch_index,
            "parent_type" => "gen",
            "source_id" => ["gen", gen_id],
            "br_v" => 0,
            "len_km" => 0,
        )

        branches["$gmd_branch_index"] = branch_data
        gmd_branch_index += 1
    end

    # Copies data to final output dictionary
    output["gmd_branch"] = branches

    # Compiles all the three winding transformers to gmd_3w_branch table
    gmd_3w_branch_index = 1
    output["gmd_3w_branch"] = Dict{String, Dict{String, Int64}}()
    for branch in values(gmd_3w_branch)
        branch["index"] = gmd_3w_branch_index
        output["gmd_3w_branch"]["$gmd_3w_branch_index"] = branch
        gmd_3w_branch_index += 1
    end
end

function _generate_ac_data!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    transformer_map = Dict{Tuple{Int64, Int64, String}, Dict}()
    for transformer in values(gic_data["TRANSFORMER"])
        key = (transformer["BUSI"], transformer["BUSJ"], transformer["CKT"]) # use tuple instead of array as tuples are immutable
        transformer_map[key] = transformer
    end
    output["bus"] = Dict{String, Any}()
    for (bus_id, bus) in raw_data["bus"]
        bus_data = deepcopy(bus)
        bus_data["source_id"] = Array{Any}(bus_data["source_id"])
        bus_data["source_id"][2] = parse(Int64, "$(bus["source_id"][2])")
        if haskey(gic_data["BUS"], bus_id)
            sub_id = gic_data["BUS"][bus_id]["SUBSTATION"]
        else
            sub_id = gic_data["BUS"]["$(bus["source_id"][4])"]["SUBSTATION"]
        end
        bus_data["lat"] = gic_data["SUBSTATION"]["$sub_id"]["LAT"]
        bus_data["lon"] = gic_data["SUBSTATION"]["$sub_id"]["LONG"]
        output["bus"][bus_id] = bus_data
    end

    output["gen"] = Dict{String, Any}()
    for (gen_id, gen) in raw_data["gen"]
        gen_data = deepcopy(gen)
        # TODO qc1max, qc2max, ramp_agc, ramp_10, pc2, cost, qc1min, qc2min, pc1, ramp_q, ramp_30, apf
        gen_data["source_id"] = ["gen", parse(Int, gen_id)]
        output["gen"][gen_id] = gen_data
    end

    gmd_branch_map = Dict{Array, Int64}()
    for (_, gmd_branch) in output["gmd_branch"]
        if gmd_branch["source_id"][1] == "transformer"
            key = [gmd_branch["source_id"], last(gmd_branch["name"], 2)]
            gmd_branch_map[key] = gmd_branch["index"]
        end
    end

    output["branch"] = Dict{String, Any}()
    for (branch_id, branch) in raw_data["branch"]
        branch_data = deepcopy(branch)
        # TODO hotspot coeff, gmd_k
        branch["transformer"] ? branch_data["xfmr"] = 1 : branch_data["xfmr"] = 0
        # TODO pt, topoil_init, hotspot_instant_limit, topoil_rated
        gmd_branch_hi = haskey(gmd_branch_map, [branch["source_id"], "hi"]) ? gmd_branch_map[[branch["source_id"], "hi"]] : nothing
        gmd_branch_lo = haskey(gmd_branch_map, [branch["source_id"], "lo"]) ? gmd_branch_map[[branch["source_id"], "lo"]] : nothing
        gmd_branch_series = haskey(gmd_branch_map, [branch["source_id"], "es"]) ? gmd_branch_map[[branch["source_id"], "es"]] : nothing
        gmd_branch_common = haskey(gmd_branch_map, [branch["source_id"], "on"]) ? gmd_branch_map[[branch["source_id"], "on"]] : nothing
        if branch["transformer"]
            key = (branch["source_id"][2], branch["source_id"][3], branch["source_id"][5])
            transformer = transformer_map[key]
            if !isnothing(gmd_branch_hi)
                branch_data["gmd_br_hi"] = gmd_branch_hi
            else
                branch_data["gmd_br_hi"] = -1
            end
            if !isnothing(gmd_branch_lo)
                branch_data["gmd_br_lo"] = gmd_branch_lo
            else
                branch_data["gmd_br_lo"] = -1
            end
            if !isnothing(gmd_branch_series)
                branch_data["gmd_br_series"] = gmd_branch_series
            else
                branch_data["gmd_br_series"] = -1
            end
            if !isnothing(gmd_branch_common)
                branch_data["gmd_br_common"] = gmd_branch_common
            else
                branch_data["gmd_br_common"] = -1
            end
        end
        branch_data["baseMVA"] = raw_data["baseMVA"]
        # TODO topoil_initialized
        branch_data["config"] = "none"
        if branch["transformer"]
            key = (branch["source_id"][2], branch["source_id"][3], branch["source_id"][5])
            transformer = transformer_map[key]
            config = ""
            config_map = Dict{String, String}(
                "Y" => "wye",
                "YN" => "gwye",
                "D" => "delta",
                "yn" => "-gwye",
                "y" => "-wye",
                "d" => "-delta",
                "a" => "-gwye-auto" # TODO can change if we expect non gwye-gwye autos
            )
            if startswith(transformer["VECGRP"], r"(YN|Y|D)(a|d|yn|y).*[dy]")
                # Three winding
                transformer = deepcopy(transformer)
                if branch["source_id"][3] == branch["f_bus"]
                    transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[2]) * "yn"
                    if transformer["VECGRP"] == "Ayn"
                        transformer["VECGRP"] = "YNa"
                    end
                elseif branch["source_id"][4] == branch["f_bus"]
                    transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[3]) * "yn"
                else
                    if startswith(transformer["VECGRP"],"YNa")
                        transformer["VECGRP"] = "YNa"
                    else
                        transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[1]) * "yn" 
                    end
                end
            end
            for key in keys(config_map)
                if startswith(transformer["VECGRP"], key * r"[a-z]+")
                    config = config_map[key] * config
                end
                if endswith(transformer["VECGRP"], r"[A-Z]+" * key * r"[^a-z]*")
                    config *= config_map[key]
                end
            end

            branch_data["config"] = config
            branch_data["gmd_k"] = transformer["KFACTOR"] * 2 * sqrt(2/3)
        end
        # TODO topoil_time_const
        # TODO: qf, temperature_ambient, qt, hotspot_avg_limit, hotspot_rated
        branch["transformer"] ? branch_data["type"] = "xfmr" : (branch_data["br_r"] == 0 ? branch_data["type"] = "series_cap" : branch_data["type"] = "line")
        # TODO: pf
        # branch_data["source_id"] = ["branch", parse(Int, branch_id)]
        output["branch"][branch_id] = branch_data
    end
end

function calcTransformerResistances(positiveSequenceR::Float64, turnsRatio::Float64, baseHighR::Float64, isAuto::Bool)
    R_high = (baseHighR * positiveSequenceR) / 2
    if isAuto
        R_low = R_high / ((turnsRatio - 1) ^ 2)
    else
        R_low = R_high / (turnsRatio ^ 2)
    end

    R_high = R_high == 0 ? 0.25 : R_high
    R_low = R_low == 0 ? 0.25 : R_low

    return R_high / 3, R_low / 3
end

# Configures the line voltages and distances
function _configure_line_info!(voltage_file::String, output::Dict{String, Any})
    lines_info = CSV.read(voltage_file, DataFrame; header=2)

    branch_map = Dict{Array, Int64}()
    for (_, branch) in output["gmd_branch"]
        source_id = branch["source_id"]
        if source_id[1] != "branch"
            continue
        end
        source_id[4]  = strip(source_id[4])
        branch_map[source_id] = branch["index"]
    end

    dc_voltages = lines_info[!, "GICInducedDCVolt"]

    froms = lines_info[!, "BusNumFrom"]
    tos = lines_info[!, "BusNumTo"]
    ckts = lines_info[!, "Circuit"]

    for (from, to, ckt, dc_voltage) in zip(froms, tos, ckts, dc_voltages)
        source_id = ["branch", from, to, "$ckt"]
        branch_id = branch_map[source_id]
        output["gmd_branch"]["$branch_id"]["br_v"] = dc_voltage
    end

    # TODO: Adds line distances
end

# Defines a link between ac branch and gic transformer table
function gen_transformer_map(gic_data::Dict{String, Any})
    transformer_map = Dict{Tuple{Int64, Int64, Int64, String}, Dict}()
    for transformer in values(gic_data["TRANSFORMER"])
        key = (transformer["BUSI"], transformer["BUSJ"], transformer["BUSK"], transformer["CKT"])
        transformer_map[key] = transformer
    end

    return transformer_map
end

# Adds substations to the gmd_bus table
function _add_substation_table!(gmd_bus::Dict{String, Dict}, gmd_bus_index::Int64, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    # Generates bus_info for each substation; needed for R_g assumption for substations
    bus_info = Dict{Int64, Array{Float64}}()
    for (bus_index, bus) in raw_data["bus"]
        # Adds substation to the raw bus table to reduce calculations
        if haskey(gic_data["BUS"], "$bus_index")
            bus["sub"] = gic_data["BUS"]["$bus_index"]["SUBSTATION"]
            bus["starbus"] = false
        else
            bus["sub"] = gic_data["BUS"]["$(bus["source_id"][4])"]["SUBSTATION"]
            bus["starbus"] = true
        end

        # bus_info has two values per substation: [max_kV, num_buses]
        if !haskey(bus_info, bus["sub"])
            bus_info[bus["sub"]] = [0.0, 0.0]
        end
        bus_info[bus["sub"]][1] = max(bus["base_kv"], bus_info[bus["sub"]][1])
        bus_info[bus["sub"]][2] += 1
    end

    substation_map = Dict{Int64, Int64}()
    sorted_substation_indices = sort([x["SUBSTATION"] for x in values(gic_data["SUBSTATION"])])
    
    for substation_index in sorted_substation_indices
        substation = gic_data["SUBSTATION"]["$substation_index"]
        sub_name = "dc_" * replace(lowercase(substation["NAME"]), " " => "_")

        # Calculates conductance to ground value for substation
        # TODO: Make sure it works
        r_g = substation["RG"]
        if r_g == 0
            # Piecewise function for calculating assumed g value of a substation
            if bus_info[substation_index][1] <= 230
                g = 0.4778 * bus_info[substation_index][2] + 1.6841
            else
                g = 0.73 * bus_info[substation_index][2] + 4.2131
            end
            g = 10
        else
            g = 1/r_g
        end

        substation_data = Dict{String, Any}(
            "name" => sub_name,
            "g_gnd" => g,
            "index" => gmd_bus_index,
            "status" => 1,
            "source_id" => ["substation", substation_index],
            "parent_index" => substation_index,
            "parent_type" => "sub"
        )

        # Links the substation index to the gmd_bus index for future reference
        substation_map[substation_index] = gmd_bus_index

        gmd_bus["$gmd_bus_index"] = substation_data
        gmd_bus_index += 1
    end

    return gmd_bus_index, substation_map
end

# Adds ac buses to the gmd_bus table
function _add_bus_table!(gmd_bus::Dict{String, Dict}, substation_map::Dict{Int64, Int64}, gmd_bus_index::Int64, raw_data::Dict{String, Any})
    bus_map = Dict{Int64, Int64}()
    sorted_bus_indices = sort([x["index"] for x in values(raw_data["bus"])])

    for bus_index in sorted_bus_indices
        bus = raw_data["bus"]["$bus_index"]
        bus["sub"] = substation_map[bus["sub"]]

        bus_name = "dc_" * replace(lowercase(strip(bus["name"])), " " => "_")

        bus_data = Dict{String, Any}(
            "name" => bus_name,
            "g_gnd" => 0, # Not tied to ground directly
            "index" => gmd_bus_index,
            "status" => 1,
            "sub" => bus["sub"], # Converts to new gmd_bus index for substation
            "source_id" => ["bus", bus_index],
            "parent_index" => bus_index,
            "parent_type" => "bus"
        )

        # Links bus indices from raw table to new gmd_bus table
        bus_map[bus_index] = gmd_bus_index

        gmd_bus["$gmd_bus_index"] = bus_data
        gmd_bus_index += 1
    end

    return bus_map
end

# Combines transformer resistances for primary-secondary positive sequence resistance of three winding transformers
function _generate_3w_resistances(raw_data::Dict{String, Any})
    # TODO calculate resistances for tertiary too by storing coil resistances instead of pu resistances in array
    three_winding_resistances = Dict{Tuple{Int64, Int64, Int64, String}, Float64}()
    for branch in values(raw_data["branch"])
        # If not a transformer, not three winding, or delta side of three winding
        if branch["source_id"][1] != "transformer" || branch["source_id"][4] == 0 || branch["f_bus"] == branch["source_id"][4]
            continue
        end

        if !haskey(three_winding_resistances, Tuple(branch["source_id"][2:5])) 
            three_winding_resistances[Tuple(branch["source_id"][2:5])] = 0
        end

        three_winding_resistances[Tuple(branch["source_id"][2:5])] += branch["br_r"]
    end

    return three_winding_resistances
end