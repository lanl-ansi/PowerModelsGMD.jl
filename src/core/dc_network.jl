function gen_dc_data(gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, voltage_file::String)
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

    # This produces an annoying warning about the number of columns in the first row
    # How to get rid of it?
    lines_info = CSV.read(voltage_file, DataFrame; header=2)

    branch_map = Dict{Array, Int}()
    for (_, branch) in output["gmd_branch"]
        source_id = branch["source_id"]
        if source_id[1] == "transformer"
            continue
        end
        source_id[4]  = strip(source_id[4])
        branch_map[source_id] = branch["index"]
    end

    # double-spaces in the field name exists in the input file
    dc_voltages = lines_info[!, "GIC DC  Volt Input"]
    froms = lines_info[!, "From Number"]
    tos = lines_info[!, "To Number"]
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

    for substation_id in sort(collect(keys(gic_data["SUBSTATION"])))
        substation = gic_data["SUBSTATION"][substation_id]
        local_id = parse(Int, substation_id)
        substation_data = Dict{String, Any}(
            "name" => "dc_sub_" * substation["NAME"],
            "g_gnd" => 1/substation["RG"],
            "index" => global_index,
            "status" => 1,
            "source_id" => ["gmd_bus", local_id],
            "parent_index" => local_id,
            "parent_type" => "sub"
        )

        gmd_bus["$global_index"] = substation_data
        global_index += 1
    end

    bus_map = Dict{Int, Int}()
    for bus_id in sort(collect(keys(gic_data["BUS"])))
        bus = gic_data["BUS"][bus_id]
        local_id = parse(Int, bus_id)
        bus_data = Dict{String, Any}(
            "name" => "dc_bus_" * strip(raw_data["bus"][bus_id]["name"]),
            "g_gnd" => 0,
            "index" => global_index,
            "status" => 1,
            "sub" => bus["SUBSTATION"],
            "source_id" => ["gmd_bus", local_id],
            "parent_index" => local_id,
            "parent_type" => "bus"
        )

        bus_map[parse(Int, bus_id)] = global_index
        gmd_bus["$global_index"] = bus_data
        global_index += 1
    end
    
    output["gmd_bus"] = gmd_bus

    return bus_map
end

function _gen_gmd_branch!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int, Int})
    branches = Dict{String, Any}()

    offset = 0
    # for (branch_id, branch) in raw_data["branch"]
    for branch_id in sort(collect(keys(raw_data["branch"])))
        branch = raw_data["branch"][branch_id]
        branch_index = branch["index"]
        if !branch["transformer"]
            branch_data = Dict{String, Any}(
                "f_bus" => dc_bus_map[branch["f_bus"]],
                "t_bus" => dc_bus_map[branch["t_bus"]],
                "br_r" => branch["br_r"] * (raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] ^ 2) / (3 * raw_data["baseMVA"]),
                "name" => "dc_br$(branch_index + offset)",
                "br_status" => 1,
                "parent_index" => branch_index + offset,
                "parent_type" => "branch",
                "source_id" => branch["source_id"],
                "br_v" => 0, # TODO
                "len_km" => 0, # TODO
            )

            gmd_branch_index = branch_index + offset
            branch_data["index"] = gmd_branch_index
            branches["$gmd_branch_index"] = branch_data            
        else
            # It is a transformer
            transformer = gic_data["TRANSFORMER"]["$(branch["source_id"][2])"]

            primary_winding = false
            secondary_winding = false
            if startswith(transformer["VECGRP"], "YN")
                primary_winding = true
            end
            
            if endswith(transformer["VECGRP"], r"yn.*")
                secondary_winding = true
            end

            if !(primary_winding || secondary_winding)
                continue
            end

            offset -= 1

            substation = output["gmd_bus"]["$(dc_bus_map[transformer["BUSI"]])"]["sub"]

            if (primary_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["f_bus"]],
                    "t_bus" => substation,
                    "br_r" => transformer["WRI"]/3,
                    "name" => "dc_x$(branch_index + offset)_hi",
                    "br_status" => 1,
                    "parent_index" => branch_index + offset,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0,
                    "len_km" => 0, # TODO
                )

                offset += 1
                gmd_branch_index = branch_index + offset
                branch_data["index"] = gmd_branch_index
                branches["$gmd_branch_index"] = branch_data
            end

            if (secondary_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["f_bus"]],
                    "t_bus" => substation,
                    "br_r" => transformer["WRJ"]/3,
                    "name" => "dc_x$(branch_index)_lo",
                    "br_status" => 1,
                    "parent_index" => branch_index + offset,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0,
                    "len_km" => 0, # TODO
                )

                offset += 1
                gmd_branch_index = branch_i + offset
                branch_data["index"] = gmd_branch_index
                branches["$gmd_branch_index"] = branch_data
            end
        end
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

    transformer_map = Dict{Array, Dict}()
    for transformer in values(gic_data["TRANSFORMER"])
        key = [transformer["BUSI"], transformer["BUSJ"], transformer["CKT"]]
        transformer_map[key] = transformer
    end

    gmd_branch_map = Dict{Array, Int}()
    for (_, gmd_branch) in output["gmd_branch"]
        if gmd_branch["source_id"][1] == "transformer"
            key = [gmd_branch["source_id"], last(gmd_branch["name"], 2)]
            gmd_branch_map[key] = gmd_branch["index"]
        end
    end

    output["branch"] = Dict{String, Any}()
    for (branch_id, branch) in raw_data["branch"]
        branch_data = deepcopy(branch)
        branch_data["gmd_br_series"] = -1 # TODO autotransformers
        branch_data["gmd_br_common"] = -1 # TODO
        # TODO hotspot coeff, gmd_k
        branch_data["lo_bus"] = branch["t_bus"] # TODO
        branch["transformer"] ? branch_data["xfmr"] = 1 : branch_data["xfmr"] = 0
        # TODO pt, topoil_init, hotspot_instant_limit, topoil_rated
        branch_data["source_id"] = ["branch", branch_id]
        gmd_branch_hi = haskey(gmd_branch_map, [branch["source_id"], "hi"]) ? gmd_branch_map[[branch["source_id"], "hi"]] : nothing
        gmd_branch_lo = haskey(gmd_branch_map, [branch["source_id"], "lo"]) ? gmd_branch_map[[branch["source_id"], "lo"]] : nothing
        if branch["transformer"]
            key = [branch["f_bus"], branch["t_bus"], branch["source_id"][5]]
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
        end
        branch_data["baseMVA"] = raw_data["baseMVA"]
        # TODO topoil_initialized
        branch_data["hi_bus"] = branch["f_bus"] # TODO
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
                "d" => "-delta"
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
        branch["transformer"] ? branch_data["type"] = "xfmr" : branch_data["type"] = "line"
        # TODO: pf
        branch_data["source_id"] = ["branch", parse(Int, branch_id)]
        output["branch"][branch_id] = branch_data
    end
end