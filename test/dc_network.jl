import PowerModelsGMD
import JSON
import SparseArrays

gic_data = PowerModelsGMD.parse_file("../test/data/gic/Bus4.gic")
raw_data = PowerModelsGMD.parse_file("../test/data/pti/B4GIC.RAW")

if !isdir("../temp_data/")
    mkdir("../temp_data/")
end

open("../temp_data/gicBus4.json", "w") do f
    JSON.print(f, gic_data)
end

open("../temp_data/rawBus4.json", "w") do f
    JSON.print(f, raw_data)
end

include("../src/core/dc_network.jl")

network_data = gen_dc_data(gic_data, raw_data)

open("../temp_data/networkBus4.json", "w") do f
    JSON.print(f, network_data)
end

include("../src/core/utilities.jl")

matrices = gen_g_i_matrix(network_data)

display(matrices[1])
display(matrices[2])

# gic_data = PowerModelsGMD.parse_file("../test/data/gic/activsg200.gic")
# raw_data = PowerModelsGMD.parse_file("../test/data/pti/ACTIVSg200.RAW")

# network_data = gen_dc_data(gic_data, raw_data)

# open("../networkActivsg200.json", "w") do f
#     JSON.print(f, network_data)
# end
