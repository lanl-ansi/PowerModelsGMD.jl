using PowerModelsGMD

import InfrastructureModels
import JuMP
import JSON
import MathOptInterface
import Memento
import PowerModels

import Cbc
import Ipopt
import Juniper

# Suppress warnings during testing:
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

using Test

# Default setup for optimizers:
ipopt_optimizer = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_optimizer = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=ipopt_optimizer, mip_solver=cbc_optimizer, log_levels=[])

setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

@testset "PowerModelsGMD" begin

    include("gmd_ls.jl")
    include("gmd_matrix.jl")
    include("gmd_opf_decoupled.jl")
    include("gmd_opf_ts_decoupled.jl")
    include("gmd_opf.jl")
    include("gmd_ots.jl")
    include("gmd.jl")

end


