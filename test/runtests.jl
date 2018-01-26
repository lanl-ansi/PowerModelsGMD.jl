using Ipopt
using Gurobi
using PowerModels
using PowerModelsGMD
using Logging
using Pajarito
using Cbc
using AmplNLWriter
using CoinOptServices


# suppress warnings during testing
Logging.configure(level=ERROR)

using Base.Test

# default setup for solvers
#ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
ipopt_solver = IpoptSolver(tol=1e-6)
#bonmin_solver = BonminNLSolver()

gurobi_solver = GurobiSolver() # change to Pajarito
cbc_solver = CbcSolver()
pajarito_solver = PajaritoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, log_level=1)


setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("branch_flows" => true))

include("gmd_ls.jl")
include("gmd.jl")
include("gmd_gic.jl")
#include("gmd_ots.jl")
