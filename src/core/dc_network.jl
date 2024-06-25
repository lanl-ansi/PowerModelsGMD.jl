function gen_dc_data(gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    output = Dict{String, Any}()

    dc_bus_map = _gen_gmd_bus!(output, gic_data, raw_data)
    _gen_gmd_branch!(output, gic_data, raw_data, dc_bus_map)

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
    branches = Dict{Int, Any}()

    offset = 0
    for (branch_id, branch) in raw_data["branch"]
        branch_id = parse(Int, branch_id)
        if !branch["transformer"]
            branch_data = Dict{String, Any}(
                "f_bus" => dc_bus_map[branch["f_bus"]],
                "t_bus" => dc_bus_map[branch["t_bus"]],
                "br_r" => branch["br_r"] * (raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] ^ 2) / (3 * raw_data["baseMVA"]),
                "name" => string("dc_br", branch_id + offset),
                "br_status" => 1,
                "parent_index" => branch_id + offset,
                "parent_type" => "branch",
                "source_id" => branch["source_id"],
                "br_v" => 0, # TODO
                "len_km" => 0, # TODO
            )

            branches[branch_id + offset] = branch_data
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
                    "br_r" => transformer["WRI"]/3, # TODO: Always I?
                    "name" => string("dc_x", branch_id + offset, "_hi"),
                    "br_status" => 1,
                    "parent_index" => branch_id + offset,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0, # TODO
                    "len_km" => 0, # TODO
                )

                offset += 1
                branches[branch_id + offset] = branch_data
            end

            if (secondary_winding)
                branch_data = Dict{String, Any}(
                    "f_bus" => dc_bus_map[branch["f_bus"]],
                    "t_bus" => substation,
                    "br_r" => transformer["WRJ"]/3, # TODO: Always I?
                    "name" => string("dc_x", branch_id, "_lo"),
                    "br_status" => 1,
                    "parent_index" => branch_id + offset,
                    "parent_type" => "branch",
                    "source_id" => branch["source_id"],
                    "br_v" => 0, # TODO
                    "len_km" => 0, # TODO
                )

                offset += 1
                branches[branch_id + offset] = branch_data
            end
        end
    end

    output["gmd_branch"] = branches
end

function _gen_branch_gmd!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    
end