using Ipopt
using Gurobi
using PowerModels
using PowerModelsGMD
using Logging

# suppress warnings during testing
Logging.configure(level=ERROR)

using Base.Test

# default setup for solvers
#ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
ipopt_solver = IpoptSolver(tol=1e-6)
gurobi_solver = GurobiSolver() # change to Pajarito

setting = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("branch_flows" => true))

#include("gmd.jl")
include("gmd_ls.jl")