import PowerModelsGMD
import JSON
using SparseArrays
import CSV
using DataFrames
using Memento

const _LOGGER = Memento.getlogger(@__MODULE__)

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

    case = generate_dc_data(gic_data, raw_data, 1.0, 90.0, 1.0)

    PowerModelsGMD.add_gmd_3w_branch!(case)

    open("../temp_data/network_$name.json", "w") do f
        JSON.print(f, case)
    end

    output = PowerModelsGMD.solve_gmd(case; kwargs...)

    open("../temp_data/output_$name.json", "w") do f
        JSON.print(f, output)
    end
end

function save_solution(name)
    case = PowerModelsGMD.parse_file("../test/data/matpower/$name.m")
    PowerModelsGMD.add_gmd_3w_branch!(case)

    open("../temp_data/solution_$(name)_network.json", "w") do f
        JSON.print(f, case)
    end

    output = PowerModelsGMD.solve_gmd(case)
    open("../temp_data/solution_$(name).json", "w") do f
        JSON.print(f, output)
    end
end

if !isdir("../temp_data/")
    mkdir("../temp_data/")
end

solve_gmd("activsg10k")
# solve_gmd("b4gic3wyyd")
# save_solution("activsg10k")
# solve_gmd("activsg10k")

# name = "activsg10k"

# data = PowerModelsGMD.parse_files("../test/data/gic/$name.gic", "../test/data/pti/$name.raw")

# gic_data = data["nw"]["1"]
# raw_data = data["nw"]["2"]

# case_1 = gen_dc_data(gic_data, raw_data, "../test/data/lines/$name.csv")

# case_2 = PowerModelsGMD.parse_file("../test/data/matpower/$name.m")

# branch_map = Dict{Array, Dict}()
# for branch in values(case_2["branch"])
#     key = [branch["f_bus"], branch["t_bus"]]
#     branch_map[key] = branch
# end

# for branch in values(case_1["branch"])
#     branch2 = branch_map[[branch["f_bus"], branch["t_bus"] == 101 ? 1001 : branch["t_bus"]]]
#     for (key, value) in branch
#         if branch2[key] != branch[key] && key != "source_id"
#             print(branch[key], " ",  branch2[key], " ", key, "\n")
#         end
#     end
# end

# # g, i_inj = PowerModelsGMD.gen_g_i_matrix(case_1)
# # display(g)
# # display(i_inj)

# # g, i_inj = PowerModelsGMD.gen_g_i_matrix(case_2)
# # display(g)
# # display(i_inj)

# # name = "activsg200"

# # data = PowerModelsGMD.parse_files("../test/data/gic/$name.gic", "../test/data/pti/$name.raw")

# # gic_data = data["nw"]["1"]
# # raw_data = data["nw"]["2"]

# # open("../temp_data/gic_$name.json", "w") do f
# #     JSON.print(f, gic_data)
# # end

# # open("../temp_data/raw_$name.json", "w") do f
# #     JSON.print(f, raw_data)
# # end

# # case = gen_dc_data(gic_data, raw_data, "../test/data/lines/$name.csv")

# # open("../temp_data/network_$name.json", "w") do f
# #     JSON.print(f, case)
# # end

# # solution = PowerModelsGMD.solve_gmd("../test/data/matpower/activsg2000_mod.m")

# # open("../temp_data/solution_activsg2000.json", "w") do f
# #     JSON.print(f, solution)
# # end

# # solution = PowerModelsGMD.parse_file("../test/data/matpower/activsg2000_mod.m")

# # open("../temp_data/solution_activsg2000_network.json", "w") do f
# #     JSON.print(f, solution)
# # end

# # g, i_inj = gen_g_i_matrix(solution)

# # # println(g)

# # # branch_map = Dict{Array, Dict}()

# # # for (id, branch) in solution["branch"]
# # #     key = [branch["f_bus"], branch["t_bus"]]
# # #     branch_map[key] = branch
# # # end

# # # for (id, bus) in case["branch"]
# # #     println(id)
# # #     solution_branch = branch_map[[bus["f_bus"], bus["t_bus"]]]
# # #     for (key, value) in bus
# # #         if !(solution_branch[key] == value || (typeof(value) in [Int64, Float64] && solution_branch[key] - value < 0.2))
# # #             println(key, ": ", value, " ", solution_branch[key])
# # #         end
# # #     end
# # # end

# answers = CSV.read("../temp_data/answers_2000.csv", DataFrame; header=2)

# name = "b4gic3wydd"

# data = PowerModelsGMD.parse_files("../test/data/gic/$name.gic", "../test/data/pti/$name.raw")

# gic_data = data["nw"]["1"]
# raw_data = data["nw"]["2"]

# case1 = gen_dc_data(gic_data, raw_data, "../test/data/lines/$name.csv")

# PowerModelsGMD.add_gmd_3w_branch!(case1)

# g, i_inj = gen_g_i_matrix(case1)

# output1 = PowerModelsGMD.solve_gmd(case1)["solution"]

# case2 = PowerModelsGMD.parse_file("../test/data/matpower/$name.m")
# PowerModelsGMD.add_gmd_3w_branch!(case2)
# g2, i_inj2 = gen_g_i_matrix(case2)

# output2 = PowerModelsGMD.solve_gmd(case2)["solution"]

# bus_map = Dict{Any, Any}()

# for (bus_id, bus) in case2["gmd_bus"]
#     bus_map[bus["parent_index"]] = parse(Int, bus_id)
# end

# transformer_map_3w = Dict{Any, Any}()
# for transformer in values(case2["gmd_3w_branch"])
#     key = [case2["branch"]["$(transformer["hi_3w_branch"])"]["f_bus"], case2["branch"]["$(transformer["lo_3w_branch"])"]["f_bus"], case2["branch"]["$(transformer["tr_3w_branch"])"]["f_bus"]]
#     transformer_map_3w[key] = case2["branch"]["$(transformer["hi_3w_branch"])"]["t_bus"]
# end

# # transformer_map = Dict{Tuple{Int64, Int64, Int64, String}, Dict}()
# # for transformer in values(gic_data["TRANSFORMER"])
# #     key = (transformer["BUSI"], transformer["BUSJ"], transformer["BUSK"], transformer["CKT"])
# #     transformer_map[key] = transformer
# # end

# for (x, y, z) in zip(findnz(g)...)
#     if case1["gmd_bus"]["$x"]["parent_type"] != "sub" 
#         bus_id = case1["gmd_bus"]["$x"]["parent_index"]
#         if !haskey(case2["bus"], "$bus_id")
#             key = [case1["bus"]["$bus_id"]["source_id"][4], case1["bus"]["$bus_id"]["source_id"][5], case1["bus"]["$bus_id"]["source_id"][6]]
#             bus_id = transformer_map_3w[key]
#         end
#         x2 = bus_map[bus_id]
#     else
#         x2 = x
#     end

#     if case1["gmd_bus"]["$y"]["parent_type"] != "sub" 
#         bus_id = case1["gmd_bus"]["$y"]["parent_index"]
#         if !haskey(case2["bus"], "$bus_id")
#             key = [case1["bus"]["$bus_id"]["source_id"][4], case1["bus"]["$bus_id"]["source_id"][5], case1["bus"]["$bus_id"]["source_id"][6]]
#             bus_id = transformer_map_3w[key]
#         end
#         y2 = bus_map[bus_id]
#     else
#         y2 = y
#     end
    
#     raw_x = case1["gmd_bus"]["$x"]["parent_index"]
#     raw_y = case1["gmd_bus"]["$y"]["parent_index"]

#     if !isapprox(g2[x2, y2], z, rtol=0.1)
#         println(x, " ", y, " ", z, " ", x2, " ", y2, " ", g2[x2,y2])
#     end
# end

# branch_map_case2 = Dict{Array, Any}()
# for (branch_index, branch) in case2["branch"]
#     key = [branch["f_bus"], branch["t_bus"]]
#     branch_map_case2[key] = branch
# end

# branches = []

# for branch in values(case1["branch"])
#     if branch["source_id"][1] != "transformer"
#         continue
#     end

#     if branch["source_id"][4] == 0
#         branch_case2 = branch_map_case2[[branch["f_bus"], branch["t_bus"]]]
#     else
#         branch_case2 = branch_map_case2[[branch["f_bus"], branch["source_id"][4] + 1]]
#     end

#     if branch["gmd_br_hi"] != -1
#         if !isapprox(case1["gmd_branch"]["$(branch["gmd_br_hi"])"]["br_r"], case2["gmd_branch"]["$(branch_case2["gmd_br_hi"])"]["br_r"], rtol=0.1)
#             # println("hi", " ", branch["gmd_br_hi"], " ", branch_case2["gmd_br_hi"], branch)
#             # println(case1["gmd_branch"]["$(branch["gmd_br_hi"])"]["br_r"])
#             # println(case2["gmd_branch"]["$(branch_case2["gmd_br_hi"])"]["br_r"])
#             push!(branches, branch)
#         end
#     end

#     if branch["gmd_br_lo"] != -1
#         if !isapprox(case1["gmd_branch"]["$(branch["gmd_br_lo"])"]["br_r"], case2["gmd_branch"]["$(branch_case2["gmd_br_lo"])"]["br_r"], rtol=0.1)
#             # println("lo", " ", branch["gmd_br_lo"], " ", branch_case2["gmd_br_lo"])
#             # println(case1["gmd_branch"]["$(branch["gmd_br_lo"])"]["br_r"])
#             # println(case2["gmd_branch"]["$(branch_case2["gmd_br_lo"])"]["br_r"])
#             push!(branches, branch)
#         end
#     end

#     if branch["gmd_br_series"] != -1
#         if !isapprox(case1["gmd_branch"]["$(branch["gmd_br_series"])"]["br_r"], case2["gmd_branch"]["$(branch_case2["gmd_br_series"])"]["br_r"], rtol=0.1)
#             # println("series", " ", branch["gmd_br_series"], " ", branch_case2["gmd_br_series"])
#             # println(case1["gmd_branch"]["$(branch["gmd_br_series"])"]["br_r"])
#             # println(case2["gmd_branch"]["$(branch_case2["gmd_br_series"])"]["br_r"])
#             push!(branches, branch)
#         end
#     end

#     if branch["gmd_br_common"] != -1
#         if !isapprox(case1["gmd_branch"]["$(branch["gmd_br_common"])"]["br_r"], case2["gmd_branch"]["$(branch_case2["gmd_br_common"])"]["br_r"], rtol=0.1)
#             # println("common", " ", branch["gmd_br_common"], " ", branch_case2["gmd_br_common"], " ", branch_case2)
#             # println(case1["gmd_branch"]["$(branch["gmd_br_common"])"]["br_r"])
#             # println(case2["gmd_branch"]["$(branch_case2["gmd_br_common"])"]["br_r"])
#             push!(branches, branch)
#         end
#     end
# end

# branches = Set(branches)

# println("f_bus", ", ", "t_bus", ", ", "tr_bus", ", ", "ckt", ", ", "config", ", ", "hi_side_bus_kv", ", ", "lo_side_bus_kv", ", ", "turns_ratio")

# for branch in branches
#     transformer = transformer_map[Tuple(branch["source_id"][2:5])]
#     # Determines the high and low bus out of the primary and secondary sides of the transformers
#     hi_side_bus = raw_data["bus"]["$(branch["source_id"][2])"]["base_kv"] >= raw_data["bus"]["$(branch["source_id"][3])"]["base_kv"] ? branch["source_id"][2] : branch["source_id"][3]
#     lo_side_bus = raw_data["bus"]["$(branch["source_id"][2])"]["base_kv"] >= raw_data["bus"]["$(branch["source_id"][3])"]["base_kv"] ? branch["source_id"][3] : branch["source_id"][2]

#     # Fetches the nominal voltages of the high side and low side buses 
#     hi_side_bus_kv = raw_data["bus"]["$hi_side_bus"]["base_kv"]
#     lo_side_bus_kv = raw_data["bus"]["$lo_side_bus"]["base_kv"]

#     turns_ratio = hi_side_bus_kv / lo_side_bus_kv

#     println(transformer["BUSI"], ", ", transformer["BUSJ"], ", ", transformer["BUSK"], ", ", transformer["CKT"], ", ", transformer["VECGRP"], ", ", hi_side_bus_kv, ", ", lo_side_bus_kv, ", ", turns_ratio, ", ", branch["br_r"])
# end

# for x in keys(output1["gmd_bus"])
#     if case1["gmd_bus"]["$x"]["parent_type"] != "sub" 
#         bus_id = case1["gmd_bus"]["$x"]["parent_index"]
#         if !haskey(case2["bus"], "$bus_id")
#             key = [case1["bus"]["$bus_id"]["source_id"][4], case1["bus"]["$bus_id"]["source_id"][5], case1["bus"]["$bus_id"]["source_id"][6]]
#             bus_id = transformer_map_3w[key]
#         end
#         x2 = bus_map[bus_id]
#     else
#         x2 = x
#     end
    
#     if !isapprox(output2["gmd_bus"]["$x2"]["gmd_vdc"], output1["gmd_bus"]["$x"]["gmd_vdc"], rtol=0.2)
#         println(x, " ", output1["gmd_bus"]["$x"]["gmd_vdc"], " ", x2, " ", output2["gmd_bus"]["$x2"]["gmd_vdc"])
#     end
# end

# for (idx, val) in enumerate(i_inj2)
#     if !isapprox(val, i_inj[idx], rtol=0.1)
        # println(idx, " ", val, " ", i_inj[idx])
#     end
# end

# # # println(g)

# # output = PowerModelsGMD.solve_gmd("../test/data/matpower/activsg2000_mod.m")

# branch_map = Dict{Array, Any}()

# for (branch_id, branch) in case["branch"]
#     if branch["type"] != "xfmr"
#         continue
#     end
#     key = [branch["hi_bus"], branch["lo_bus"]]
#     branch_map[key] = branch_id
# end

# for row in eachrow(answers)
#     key = [row["BusNum3W"], row["BusNum3W:1"]]
#     branch_id = branch_map[key]
#     if !isapprox(output["solution"]["qloss"][branch_id], row["GICQLosses"], rtol=0.15)
#         println(branch_id, " ", key, " ", output["solution"]["qloss"][branch_id], " ", row["GICQLosses"])
#     end
# end