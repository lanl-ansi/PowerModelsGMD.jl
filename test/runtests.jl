using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import PowerModels
const _PM = PowerModels
import InfrastructureModels
const _IM = InfrastructureModels

import JSON
import JuMP
#import MathOptInterface
import Memento

# Suppress warning messages:
Memento.setlevel!(Memento.getlogger(_IM), "error")
Memento.setlevel!(Memento.getlogger(_PM), "error")
Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
_PMGMD.logger_config!("error")

const TESTLOG = Memento.getlogger(_PMGMD)
Memento.setlevel!(TESTLOG, "error")


import Cbc
import Ipopt
import Juniper
import SCS

# Default setup for optimizers:
cbc_solver = JuMP.optimizer_with_attributes(Cbc.Optimizer, "logLevel"=>0)
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>PowerModels.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])
scs_solver = JuMP.optimizer_with_attributes(SCS.Optimizer, "max_iters"=>100000, "eps"=>1e-5, "verbose"=>0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))


using Test

# Parse test cases:
case_b4gic = _PMs.parse_file("../test/data/b4gic.m")


# Perform the tests of implemented formulations:
@testset "PowerModelsGMD" begin

    # GIC DC
    include("gmd.jl")


    #include("gmd_ls.jl")
    #include("gmd_matrix.jl")
    #include("gmd_opf_decoupled.jl")
    #include("gmd_opf_ts_decoupled.jl")
    #include("gmd_opf.jl")
    #include("gmd_ots.jl")

end
