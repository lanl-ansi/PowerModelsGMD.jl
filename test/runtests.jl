using PowerModelsGMD

import InfrastructureModels
import JuMP
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
juniper_optimizer = JuMP.with_optimizer(Juniper.Optimizer, nl_optimizer=ipopt_optimizer, mip_optimizer=cbc_optimizer, log_levels=[])

setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

@testset "PowerModelsGMD" begin

    include("gmd.jl")
    include("gmd_matrix.jl")
    # include("gic_pf_decoupled.jl") #TODO: write tests for gic_pf_decoupled.jl
    include("gmd_opf_decoupled.jl")
    include("gmd_opf.jl")
    include("gmd_ls.jl")
    # include("gmd_ots.jl") #TODO: EPRI21 test system need to be checked => 'branch_z' error

end


