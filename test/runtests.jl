using PowerModelsGMD

import InfrastructureModels
import PowerModels

#using Gurobi
#using CPLEX
import Ipopt
import Pavito
import Cbc
import Juniper

import JuMP
import Memento


# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

using Test

cbc_solver = Cbc.CbcSolver()

# default setup for solvers
ipopt_solver = Ipopt.IpoptSolver(tol=1e-6, print_level=0)
#ipopt_solver = IpoptSolver(tol=1e-6)

#juniper_solver = JuniperSolver(ipopt_solver, mip_solver=cbc_solver)
juniper_solver = Juniper.JuniperSolver(ipopt_solver, mip_solver=cbc_solver, log_levels=[])

#gurobi_solver = GurobiSolver(OutputFlag=0) # change to Pajarito
#cplex_solver = CplexSolver()
pavito_solver = Pavito.PavitoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, mip_solver_drives=false, log_level=1)


setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))

@testset "PowerModelsGMD" begin

include("gmd.jl")
include("gmd_ls.jl")
include("gmd_gic.jl")
include("gmd_ots.jl")

end
