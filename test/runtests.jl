using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import InfrastructureModels
const _IM = InfrastructureModels
import PowerModels
const _PM = PowerModels

import JSON
import JuMP
import Memento
import StatsBase
import FFTW

calc_mean = x -> StatsBase.Statistics.mean(x)
calc_std = x -> StatsBase.Statistics.std(x, corrected=true)

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
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes")
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => _PM.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes"), "log_levels" => [])
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

import LinearAlgebra
import SparseArrays
import CSV
using Test

include("test_cases.jl")
# Perform automated testing of PMsGMD problem specifications:
@testset "PowerModelsGMD" begin
    # include("ac_data.jl")
    include("gmd.jl") 
    # include("gmd_pf.jl")
    # include("gmd_opf.jl")
    include("gmd_mld.jl")
    # include("gmd_ots.jl")
    include("parse.jl") # GIC parser
    include("coupling.jl")
    include("gic.jl") # RAW/GIC network builder
    include("gmd_blocker.jl")
end
