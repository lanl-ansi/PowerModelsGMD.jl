using Ipopt
#using Gurobi
using PowerModels
#using CPLEX
using PowerModelsGMD
using Pavito
using Cbc
using Juniper
using Memento

# Suppress warnings during testing.
setlevel!(getlogger(InfrastructureModels), "error")
setlevel!(getlogger(PowerModels), "error")

using Base.Test

cbc_solver = CbcSolver()

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
#ipopt_solver = IpoptSolver(tol=1e-6)

#juniper_solver = JuniperSolver(ipopt_solver, mip_solver=cbc_solver)
juniper_solver = JuniperSolver(ipopt_solver, mip_solver=cbc_solver, log_levels=[])

#gurobi_solver = GurobiSolver(OutputFlag=0) # change to Pajarito
#cplex_solver = CplexSolver()
pavito_solver = PavitoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, mip_solver_drives=false, log_level=1)


setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("branch_flows" => true))

@testset "PowerModelsGMD" begin

include("gic.jl")
#include("gic_pf_decoupled.jl")
include("gic_opf_decoupled.jl")
include("gic_opf.jl")
include("gic_ml.jl")
#include("gic_ots.jl")

end
