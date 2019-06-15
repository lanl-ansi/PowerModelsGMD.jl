using PowerModelsGMD

import InfrastructureModels
import PowerModels

#using Gurobi
#using CPLEX
import Ipopt
import Cbc
import Juniper

import JuMP
import Memento

# for checking status codes
import MathOptInterface
const MOI = MathOptInterface

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

using Test

# default setup for solvers
ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=ipopt_solver, mip_solver=cbc_solver, log_levels=[])
#gurobi_solver = GurobiSolver(OutputFlag=0) # change to Pajarito
#cplex_solver = CplexSolver()

setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

@testset "PowerModelsGMD" begin

#include("gmd.jl")
#include("gmd_matrix.jl")
##include("gic_pf_decoupled.jl")
#include("gmd_opf_decoupled.jl")
include("gmd_opf.jl")
#include("gmd_ml.jl")
##include("gic_ots.jl")

end
