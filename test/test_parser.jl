import PowerModelsGMD
const _PMGMD = PowerModelsGMD

println(_PMGMD.parse_file("data/gic/Bus4.gic"), "\n")
println(_PMGMD.parse_file("data/gic/EPRI.gic"), "\n")
println(_PMGMD.parse_files("data/matpower/autotransformer.m", "data/gic/EPRI.gic", "data/gic/Bus4.gic"), "\n")