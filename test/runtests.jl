using Ipopt
using PowerModels
using PowerModelsGMD
using Logging
# suppress warnings during testing
Logging.configure(level=ERROR)


if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)


include("gmd.jl")
