using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import InfrastructureModels
const _IM = InfrastructureModels
import PowerModels
const _PM = PowerModels

import JSON
import JuMP
import Memento

# Suppressing warning messages:
Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
Memento.setlevel!(Memento.getlogger(_IM), "error")
Memento.setlevel!(Memento.getlogger(_PM), "error")

_PMGMD.logger_config!("error")
const TESTLOG = Memento.getlogger(_PMGMD)
Memento.setlevel!(TESTLOG, "error")


import Ipopt
import Juniper

# Setup default optimizers:
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-3, "print_level" => 0, "sb" => "yes")
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => _PM.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-3, "print_level" => 0, "sb" => "yes"), "log_levels" => [])
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))


import LinearAlgebra
import SparseArrays
using Test

# Parse test cases:
data_b4gic = "../test/data/matpower/b4gic.m"
data_b4gic3w = "../test/data/pti/b4gic3w.raw"
data_b6gic_nerc = "../test/data/matpower/b6gic_nerc.m"
data_epri21 = "../test/data/matpower/epri21.m"
data_ieee_rts_0 = "../test/data/matpower/ieee_rts_0.m"
data_otstest = "../test/data/matpower/ots_test.m"
data_b4gic_ne_blocker = "../test/data/matpower/b4gic_ne_blocker.m"
data_epri21_ne_blocker = "../test/data/matpower/epri21_ne_blocker.m"

# Perform automated testing of PMsGMD problem specifications:
@testset "PowerModelsGMD" begin
    include("ac_data.jl")
    include("gmd.jl")
    include("gmd_opf.jl")
    include("gmd_mld.jl")
    include("gmd_ots.jl")
    include("gmd_blocker.jl")
end
