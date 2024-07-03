import PowerModelsGMD
import JSON
import SparseArrays
import CSV
using DataFrames

include("../src/core/dc_network.jl")
include("../src/core/utilities.jl")

function solve_gmd(name; kwargs...)
    data = PowerModelsGMD.parse_files("../test/data/gic/$name.gic", "../test/data/pti/$name.raw")

    gic_data = data["nw"]["1"]
    raw_data = data["nw"]["2"]

    open("../temp_data/gic_$name.json", "w") do f
        JSON.print(f, gic_data)
    end

    open("../temp_data/raw_$name.json", "w") do f
        JSON.print(f, raw_data)
    end

    case = gen_dc_data(gic_data, raw_data, "../test/data/lines/$name.csv")

    open("../temp_data/network_$name.json", "w") do f
        JSON.print(f, case)
    end

    g, i_inj = gen_g_i_matrix(case)

    println(g)

    output = PowerModelsGMD.solve_gmd(case; kwargs...)

    open("../temp_data/output_$name.json", "w") do f
        JSON.print(f, output)
    end
end
# gic_data = PowerModelsGMD.parse_file("../test/data/gic/Bus4.gic")
# raw_data = PowerModelsGMD.parse_file("../test/data/pti/B4GIC.RAW"; import_all=true)

if !isdir("../temp_data/")
    mkdir("../temp_data/")
end

# open("../temp_data/gicBus4.json", "w") do f
#     JSON.print(f, gic_data)
# end

# open("../temp_data/rawBus4.json", "w") do f
#     JSON.print(f, raw_data)
# end

# include("../src/core/dc_network.jl")

# network_data = gen_dc_data(gic_data, raw_data, "../test/data/lines/Bus4.csv")

# open("../temp_data/networkBus4.json", "w") do f
#     JSON.print(f, network_data)
# end

# include("../src/core/utilities.jl")

# solve_gic = PowerModelsGMD.solve_gmd(network_data)

# open("../temp_data/output_solve_gic.json", "w") do f
#     JSON.print(f, solve_gic)
# end

solve_gmd("epri")

# solve_m = PowerModelsGMD.solve_gmd("../test/data/matpower/b4gic_default.m")

# open("../temp_data/output_solve_m.json", "w") do f
#     JSON.print(f, solve_m)
# end

# name = "activsg200"

# data = PowerModelsGMD.parse_files("../test/data/gic/$name.gic", "../test/data/pti/$name.raw")

# gic_data = data["nw"]["1"]
# raw_data = data["nw"]["2"]

# case_1 = gen_dc_data(gic_data, raw_data, "../test/data/lines/$name.csv")

# case_2 = PowerModelsGMD.parse_file("../test/data/matpower/activsg200.m")

# branch_map = Dict{Array, Dict}()
# for branch in values(case_2["branch"])
#     key = [branch["f_bus"], branch["t_bus"]]
#     branch_map[key] = branch
# end

# for branch in values(case_1["branch"])
#     branch2 = branch_map[[branch["f_bus"], branch["t_bus"]]]
#     for (key, value) in branch
#         if branch2[key] != branch[key] && key != "source_id"
#             print(branch[key], " ",  branch2[key], " ", key, "\n")
#         end
#     end
# end

# g, i_inj = PowerModelsGMD.gen_g_i_matrix(case_1)
# display(g)
# display(i_inj)

# g, i_inj = PowerModelsGMD.gen_g_i_matrix(case_2)
# display(g)
# display(i_inj)

name = "epri"

data = PowerModelsGMD.parse_files("../test/data/gic/$name.gic", "../test/data/pti/$name.raw")

gic_data = data["nw"]["1"]
raw_data = data["nw"]["2"]

open("../temp_data/gic_$name.json", "w") do f
    JSON.print(f, gic_data)
end

open("../temp_data/raw_$name.json", "w") do f
    JSON.print(f, raw_data)
end

case = gen_dc_data(gic_data, raw_data, "../test/data/lines/$name.csv")

solution = PowerModelsGMD.parse_file("../test/data/matpower/epricase_new.m")

g, i_inj = gen_g_i_matrix(solution)

println(g)

branch_map = Dict{Array, Dict}()

for (id, branch) in solution["branch"]
    key = [branch["f_bus"], branch["t_bus"]]
    branch_map[key] = branch
end

for (id, bus) in case["branch"]
    println(id)
    solution_branch = branch_map[[bus["f_bus"], bus["t_bus"]]]
    for (key, value) in bus
        if !(solution_branch[key] == value || (typeof(value) in [Int64, Float64] && solution_branch[key] - value < 0.2))
            println(key, ": ", value, " ", solution_branch[key])
        end
    end
end