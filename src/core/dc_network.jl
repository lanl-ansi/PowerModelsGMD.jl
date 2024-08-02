impxfrm = Dict{Float64, Float64}(
    765.0 => 1.0892000157158984e-05,
    500.0 => 1.666666666676272e-05,
    345.0 => 2.4155598209192887e-05,
    230.0 => 3.623188405928273e-05,
    161.0 => 5.175983436949935e-05,
    138.0 => 6.038901527172248e-05,
    115.0 => 7.246376811370438e-05,
) # For the implicit transformer branch resistances

# TODO: generate dc networks without coupling info

function gen_dc_data(gic_file::String, raw_file::String, voltage_file::String)
    # This produces an annoying warning about the number of columns in the first row
    # TODO: How to get rid of it?
    gic_data = parse_gic(gic_file)
    raw_data = _PM.parse_file(raw_file)
    lines_info = CSV.read(voltage_file, DataFrame; header=2)
    return gen_dc_data(gic_data, raw_data, lines_info)
end

function gen_dc_data(gic_file::IOStream, raw_file::IOStream, voltage_file::IOStream)
    # This produces an annoying warning about the number of columns in the first row
    # TODO: How to get rid of it?
    gic_data = parse_gic(gic_file)
    raw_data = _PM.parse_file(raw_file)
    lines_info = CSV.read(voltage_file, DataFrame; header=2)
    return gen_dc_data(gic_data, raw_data, lines_info)
end

function gen_dc_data(gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, lines_info::DataFrames.DataFrame)
    output = Dict{String, Any}()

    output["source_type"] = "gic"
    output["name"] = raw_data["name"]
    output["source_version"] = "3"

    output["dcline"] = raw_data["dcline"]
    output["storage"] = raw_data["storage"]
    output["switch"] = raw_data["switch"]
    output["baseMVA"] = raw_data["baseMVA"]
    output["load"] = raw_data["load"]

    dc_bus_map = _gen_gmd_bus!(output, gic_data, raw_data)
    _gen_gmd_branch!(output, gic_data, raw_data, dc_bus_map)

    branch_map = Dict{Array, Int}()
    for branch in values(output["gmd_branch"])
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

    _gen_ac_data!(output, gic_data, raw_data)

    return output
end

function _gen_gmd_bus!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    gmd_bus = Dict{String, Any}()
    global_index = 1

    for substation_index in sort([x["SUBSTATION"] for x in values(gic_data["SUBSTATION"])])
        substation = gic_data["SUBSTATION"]["$substation_index"]
        substation_data = Dict{String, Any}(
            "name" => "dc_" * replace(lowercase(substation["NAME"]), " " => "_"),
            # TODO: check for cases where 0 is not just a placeholder
            "g_gnd" => substation["RG"] != 0 ? 1/substation["RG"] : 4.6216128431, # TODO Find the value for reals
            "index" => global_index,
            "status" => 1,
            "source_id" => ["substation", substation_index],
        )

        gmd_bus["$global_index"] = substation_data
        global_index += 1
    end

    bus_map = Dict{Int, Int}()
    for bus_index in sort([x["index"] for x in values(raw_data["bus"])])
        bus = gic_data["BUS"]["$bus_index"]
        bus_data = Dict{String, Any}(
            "name" => "dc_" * replace(lowercase(strip(raw_data["bus"]["$bus_index"]["name"])), " " => "_"),
            "g_gnd" => 0,
            "index" => global_index,
            "status" => 1,
            "sub" => bus["SUBSTATION"],
            "source_id" => ["bus", bus_index],
            "parent_index" => bus_index,
            "parent_type" => "bus"
        )

        bus_map[bus_index] = global_index
        gmd_bus["$global_index"] = bus_data
        global_index += 1
    end
    
    output["gmd_bus"] = gmd_bus

    return bus_map
end

function _gen_gmd_branch!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int, Int})
    branches = Dict{String, Any}()

    transformer_map = Dict{Tuple{Int64, Int64, String}, Dict}()
    for transformer in values(gic_data["TRANSFORMER"])
        key = (transformer["BUSI"], transformer["BUSJ"], transformer["CKT"]) # use tuple instead of array as tuples are immutable
        transformer_map[key] = transformer
    end

    offset = 0
    for branch_index in sort([x["index"] for x in values(raw_data["branch"])])
        branch = raw_data["branch"]["$branch_index"]

        branch["f_bus"] = branch["source_id"][2]
        branch["t_bus"] = branch["source_id"][3] # TODO Do not know why this is happening...

        hi_bus = raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] < raw_data["bus"]["$(branch["t_bus"])"]["base_kv"] ? branch["t_bus"] : branch["f_bus"]
        lo_bus = raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] < raw_data["bus"]["$(branch["t_bus"])"]["base_kv"] ? branch["f_bus"] : branch["t_bus"]

        branch["hi_bus"] = hi_bus
        branch["lo_bus"] = lo_bus

        gen_buses = []
        for generator in values(raw_data["gen"])
            push!(gen_buses, generator["gen_bus"])
        end

        if !branch["transformer"]
            branch_data = Dict{String, Any}(
                "f_bus" => dc_bus_map[branch["f_bus"]],
                "t_bus" => dc_bus_map[branch["t_bus"]],
                "br_r" => branch["br_r"] != 0 ? branch["br_r"] * (raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] ^ 2) / (3 * raw_data["baseMVA"]) : 0.0005, # TODO add 1e-4 ohms per km
                "name" => "dc_br$(branch_index + offset)",
                "br_status" => 1,
                "parent_index" => branch_index,
                "parent_type" => "branch",
                "source_id" => branch["source_id"],
                "br_v" => 0.0, # TODO
                "len_km" => 0.0, # TODO
            )

            gmd_branch_index = branch_index + offset
            branch_data["index"] = gmd_branch_index
            branches["$gmd_branch_index"] = branch_data
        else
            # It is a transformer
            transformer = transformer_map[(branch["f_bus"], branch["t_bus"], branch["source_id"][5])]
            if length(strip(transformer["VECGRP"])) == 0 || (endswith(transformer["VECGRP"], r"a.*") && !startswith(transformer["VECGRP"],"YNa"))
                if branch["f_bus"] in gen_buses
                    transformer["VECGRP"] = "D"
                else
                    transformer["VECGRP"] = "YN"
                end

                if branch["t_bus"] in gen_buses
                    transformer["VECGRP"] *= "d" # TODO: could end up with delta delta, is that ok?
                else
                    transformer["VECGRP"] *= "yn"
                end

                # Note: this seems a little dangerous to force gwye-gwye transformers as autos
                if transformer["VECGRP"] == "YNyn"
                    transformer["VECGRP"] = "YNa" # TODO: Unknown configs are assumed as not auto...
                end

                # TODO Warn that a transformer config has been assumed
            end

            turns_ratio = raw_data["bus"]["$(branch["hi_bus"])"]["base_kv"] / raw_data["bus"]["$(branch["lo_bus"])"]["base_kv"]

            if endswith(transformer["VECGRP"], r"a.*") # same as 'a' in transformer["VECGRP"]?
                # It is an auto transformer
                substation = output["gmd_bus"]["$(dc_bus_map[transformer["BUSJ"]])"]["sub"]

                Z_base = (raw_data["bus"]["$(branch["hi_bus"])"]["base_kv"] ^ 2) / raw_data["baseMVA"]
                R_s, R_c = _calc_transformer_resistances(branch["br_r"], turns_ratio, Z_base; is_auto=true)

                if (turns_ratio == 1)
                    R_c = R_s # TODO: Temporary solution
                end

                common_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[lo_bus],
                    "t_bus" => substation,
                    "br_r" => lo_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_common",
                    "br_status" => 1,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0.0,
                    "len_km" => 0.0, # TODO
                )

                if common_data["br_r"] == 0
                    common_data["br_r"] = R_c
                end

                gmd_branch_index = branch_index + offset
                common_data["index"] = gmd_branch_index
                branches["$gmd_branch_index"] = common_data

                series_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[hi_bus],
                    "t_bus" => dc_bus_map[lo_bus],
                    "br_r" => hi_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_series",
                    "br_status" => 1,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0.0,
                    "len_km" => 0.0, # TODO
                )

                if series_data["br_r"] == 0
                    series_data["br_r"] = R_s
                end

                offset += 1
                gmd_branch_index = branch_index + offset
                series_data["index"] = gmd_branch_index
                branches["$gmd_branch_index"] = series_data
                continue
            end

            primary_winding = false
            secondary_winding = false
            if (startswith(transformer["VECGRP"], "YN") && hi_bus == transformer["BUSI"]) || (endswith(transformer["VECGRP"], r"yn.*") && transformer["BUSJ"] == hi_bus)
                primary_winding = true
            end
            
            # TODO: same as "yn" in occursin("yn", transformer["VECGRP"])?
            if (endswith(transformer["VECGRP"], r"yn.*") && lo_bus == transformer["BUSJ"]) || (startswith(transformer["VECGRP"], "YN") && lo_bus == transformer["BUSI"])
                secondary_winding = true
            end

            if !(primary_winding || secondary_winding)
                continue
            end

            Z_base_high = (raw_data["bus"]["$(branch["hi_bus"])"]["base_kv"] ^ 2) / raw_data["baseMVA"]
            R_hi, R_lo = _calc_transformer_resistances(branch["br_r"], turns_ratio, Z_base_high; is_auto=true)

            offset -= 1

            substation = output["gmd_bus"]["$(dc_bus_map[transformer["BUSI"]])"]["sub"]

            if (primary_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["hi_bus"]],
                    "t_bus" => substation,
                    "br_r" => hi_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_hi",
                    "br_status" => 1,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0.0, # 
                    "len_km" => 0.0, # TODO
                )

                if branch_data["br_r"] == 0.0
                    branch_data["br_r"] = R_hi
                end

                offset += 1
                gmd_branch_index = branch_index + offset
                branch_data["index"] = gmd_branch_index
                branches["$gmd_branch_index"] = branch_data
            end

            if (secondary_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["lo_bus"]],
                    "t_bus" => substation,
                    "br_r" => lo_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_lo",
                    "br_status" => 1,
                    "parent_index" => branch_index,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0.0,
                    "len_km" => 0.0, # TODO
                )

                if branch_data["br_r"] == 0.0
                    branch_data["br_r"] = R_lo
                end

                offset += 1
                gmd_branch_index = branch_index + offset
                branch_data["index"] = gmd_branch_index
                branches["$gmd_branch_index"] = branch_data
            end
        end
    end

    index = length(branches)
    for id in sort([x["index"] for x in values(raw_data["bus"])])
        bus = raw_data["bus"]["$id"]
        index += 1
        substation = output["gmd_bus"]["$(dc_bus_map[id])"]["sub"]
        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[id],
            "t_bus" => substation,
            "br_r" => 25e3,
            "name" => "dc_bus$id",
            "br_status" => 1,
            "parent_index" => id,
            "index" => index,
            "parent_type" => "bus",
            "source_id" => ["gmd_branch", index],
            "br_v" => 0.0,
            "len_km" => 0.0, # TODO
        )

        branches["$index"] = branch_data
    end

    for id in sort([x["index"] for x in values(raw_data["gen"])])
        gen = raw_data["gen"]["$id"]
        gen_base_kv = raw_data["bus"]["$(gen["gen_bus"])"]["base_kv"]

        if gen_base_kv < 30.0 || gen["gen_status"] == 0
            continue
        end

        # TODO: Add bus-sub mapping into the bus table directly?
        substation = output["gmd_bus"]["$(dc_bus_map[gen["gen_bus"]])"]["sub"]
        z_base = (gen_base_kv ^ 2) / gen["mbase"]

        index += 1
        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[gen["gen_bus"]],
            "t_bus" => substation,
            "br_r" => impxfrm[gen_base_kv] * z_base,
            "name" => "dc_gen$id",
            "br_status" => 1,
            "parent_index" => id,
            "index" => index,
            "parent_type" => "gen",
            "source_id" => ["gen", id],
            "br_v" => 0,
            "len_km" => 0, # TODO
        )

        branches["$index"] = branch_data
    end

    output["gmd_branch"] = branches
end

function _gen_branch_gmd!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    
end

function _gen_ac_data!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    output["bus"] = Dict{String, Any}()
    for (bus_id, bus) in raw_data["bus"]
        bus_data = deepcopy(bus)
        bus_data["source_id"] = Array{Any}(bus_data["source_id"])
        bus_data["source_id"][2] = parse(Int64, bus["source_id"][2])
        sub_id = gic_data["BUS"][bus_id]["SUBSTATION"]
        bus_data["substation"] = sub_id
        bus_data["lat"] = gic_data["SUBSTATION"]["$sub_id"]["LAT"]
        bus_data["lon"] = gic_data["SUBSTATION"]["$sub_id"]["LONG"]
        output["bus"][bus_id] = bus_data
    end

    # Add a substation table
    # This isn't needed for analysis so not sure if it's smart
    # to add it
    output["substation"] = Dict{String, Any}()
    for (sub_id, sub) in gic_data["SUBSTATION"]
        sub_data = Dict{String,Any}()
        sub_data["index"] = sub["SUBSTATION"]
        sub_data["g"] = sub["RG"]
        sub_data["lat"] = sub["LAT"]
        sub_data["lon"] = sub["LONG"]
        output["substation"][sub_id] = sub_data
    end

    # TODO: this looks like it is messing up the gen ID
    # do we really need to do this?
    output["gen"] = Dict{String, Any}()
    for (gen_id, gen) in raw_data["gen"]
        gen_data = deepcopy(gen)
        # TODO qc1max, qc2max, ramp_agc, ramp_10, pc2, cost, qc1min, qc2min, pc1, ramp_q, ramp_30, apf
        gen_data["source_id"] = ["gen", parse(Int, gen_id)]
        output["gen"][gen_id] = gen_data
    end

    transformer_map = Dict{Vector, Dict}()
    for transformer in values(gic_data["TRANSFORMER"])
        key = [transformer["BUSI"], transformer["BUSJ"], transformer["CKT"]]
        transformer_map[key] = transformer
    end

    gmd_branch_map = Dict{Vector, Int}()
    for gmd_branch in values(output["gmd_branch"])
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
        branch_data["source_id"] = ["branch", branch_id]
        gmd_branch_hi = get(gmd_branch_map, (branch["source_id"], "hi"), nothing)
        gmd_branch_lo = get(gmd_branch_map, (branch["source_id"], "lo"), nothing) 
        gmd_branch_series = get(gmd_branch_map, (branch["source_id"], "es"), nothing)
        gmd_branch_common = get(gmd_branch_map, (branch["source_id"], "on"), nothing)

        if branch["transformer"]
            key = [branch["f_bus"], branch["t_bus"], branch["source_id"][5]]
            transformer = transformer_map[key]
            null2magic = x -> isnothing(x) ? -1 : x

            branch_data["gmd_br_hi"] = null2magic(gmd_branch_hi)
            branch_data["gmd_br_lo"] = null2magic(gmd_branch_lo)
            branch_data["gmd_br_series"] = null2magic(gmd_branch_series)
            branch_data["gmd_br_common"] = null2magic(gmd_branch_common)
        end

        branch_data["baseMVA"] = raw_data["baseMVA"]
        # TODO topoil_initialized
        branch_data["config"] = "none"

        if branch["transformer"]
            key = [branch["f_bus"], branch["t_bus"], branch["source_id"][5]]
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
      
        if branch_data["transformer"]
            branch_data["type"] = "xfmr"
        elseif branch_data["br_r"] == 0
            branch_data["type"] = "series_cap"
        else
            branch_data["type"] = "line"
        end
        
        # TODO: pf
        # branch_data["source_id"] = ["branch", parse(Int, branch_id)]
        output["branch"][branch_id] = branch_data
    end
end

function _calc_transformer_resistances(positive_sequence_r::Float64, turns_ratio::Float64, Z_base_high::Float64; is_auto::Bool=false)
    R_high = (Z_base_high * positive_sequence_r) / 2
    if is_auto
        R_low = R_high / ((turns_ratio - 1) ^ 2)
   else
        R_low = R_high / (turns_ratio ^ 2)
    end
    
    return R_high / 3, R_low / 3
end
