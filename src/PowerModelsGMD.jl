isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsGMD
    using PowerModels
    using JuMP

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

    include("prob/gmd.jl")
    include("prob/gmd_min_error.jl")
end
