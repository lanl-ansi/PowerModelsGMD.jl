module PowerModelsGMD
    using JuMP
    using InfrastructureModels
    using PowerModels
    using Memento

    if VERSION > v"0.7.0-"
        using Printf
    end

    const LOGGER = getlogger(PowerModels)

    const PMs = PowerModels

    include("core/base.jl")
    include("core/data.jl")
    include("core/variable.jl")
    include("core/constraint.jl")
    include("core/constraint_template.jl")
    include("core/relaxation_scheme.jl")
    include("core/objective.jl")
    include("core/solution.jl")

    include("form/acp.jl")
    include("form/dcp.jl")
    include("form/wr.jl")
    include("form/wrm.jl")

    include("prob/gmd_gic.jl")
    include("prob/gmd.jl")
    include("prob/gmd_min_error.jl")
    include("prob/gmd_ls.jl")
    include("prob/gmd_ots.jl")    
end
