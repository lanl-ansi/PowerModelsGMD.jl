using Ipopt
using Gurobi
using PowerModels
using PowerModelsGMD
using Pajarito
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

#bonmin_solver = AmplNLSolver(CoinOptServices.bonmin)
juniper_solver = JuniperSolver(ipopt_solver, mip_solver=cbc_solver)

gurobi_solver = GurobiSolver() # change to Pajarito
pajarito_solver = PajaritoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, log_level=1)


setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("branch_flows" => true))

@testset "PowerModelsGMD" begin

include("gmd_ls.jl")
include("gmd.jl")
include("gmd_gic.jl")
include("gmd_ots.jl")

end
