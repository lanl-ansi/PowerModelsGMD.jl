using PowerModels
using Logging
# suppress warnings during testing
Logging.configure(level=ERROR)

using Ipopt

if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)

# used by OTS and Loadshed TS models
function check_br_status(sol)
    for (idx,val) in sol["branch"]
        @test val["br_status"] == 0.0 || val["br_status"] == 1.0
    end
end

include("gmd.jl")
