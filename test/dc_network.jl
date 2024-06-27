import PowerModelsGMD
import JSON
import SparseArrays
import CSV
using DataFrames

# gic_data = PowerModelsGMD.parse_file("../test/data/gic/Bus4.gic")
# raw_data = PowerModelsGMD.parse_file("../test/data/pti/B4GIC.RAW"; import_all=true)

# if !isdir("../temp_data/")
#     mkdir("../temp_data/")
# end

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

solve_gic = PowerModelsGMD.solve_gmd("../test/data/pti/B4GIC.RAW", "../test/data/gic/Bus4.gic", "../test/data/lines/Bus4.csv")

open("../temp_data/output_solve_gic.json", "w") do f
    JSON.print(f, solve_gic)
end


# solve_m = PowerModelsGMD.solve_gmd("../test/data/matpower/b4gic_default.m")

# open("../temp_data/output_solve_m.json", "w") do f
#     JSON.print(f, solve_m)
# end