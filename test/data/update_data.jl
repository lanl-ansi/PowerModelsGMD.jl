#!/usr/bin/env julia

using JSON
using PowerModels

function update_json!(gmd_data::Dict{String,Any})
    #=
    loads = Dict{String,Any}()
    shunts = Dict{String,Any}()

    load_index = 1
    shunt_index = 1

    for (i, bus) in gmd_data["bus"]
        if bus["pd"] != 0.0 || bus["qd"] != 0.0
            loads["$(load_index)"] = Dict{String,Any}(
                "pd" => bus["pd"],
                "qd" => bus["qd"],
                "load_bus" => bus["bus_i"],
                "status" => convert(Int8, bus["bus_type"] != 4),
                "index" => load_index
            )
            load_index += 1
        end

        if bus["gs"] != 0.0 || bus["bs"] != 0.0
            shunts["$(shunt_index)"] = Dict{String,Any}(
                "gs" => bus["gs"],
                "bs" => bus["bs"],
                "shunt_bus" => bus["bus_i"],
                "status" => convert(Int8, bus["bus_type"] != 4),
                "index" => shunt_index
            )
            shunt_index += 1
        end

        delete!(bus, "pd")
        delete!(bus, "qd")
        delete!(bus, "pd")
        delete!(bus, "qd")
    end

    gmd_data["load"] = loads
    gmd_data["shunt"] = shunts
    =#

    for (i, branch) in gmd_data["branch"]
        branch["g_fr"] = 0
        branch["g_to"] = 0
        branch["b_fr"] = branch["br_b"]/2.0
        branch["b_to"] = branch["br_b"]/2.0
        delete!(branch, "br_b")
    end

    #PowerModels.check_network_data(gmd_data)
end


for (root, dirs, files) in walkdir(".")
    for file in files
        if endswith(file, ".json")
            file_path = joinpath(root, file)
            println(file_path) # path to files

            data_string = readstring(open(file_path))
            data = JSON.parse(data_string)
            update_json!(data)

            open(file_path, "w") do f
                JSON.print(f, data)
            end
        end
    end
end
