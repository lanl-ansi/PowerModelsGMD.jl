module PowerModelsGMD
    using JuMP
    using InfrastructureModels
    using PowerModels
    using Memento

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

    include("prob/gic.jl")
    include("prob/gic_matrix.jl")
    include("prob/gic_opf.jl")
    include("prob/gic_opf_decoupled.jl")
    #include("prob/gic_pf_decoupled.jl")
    #include("prob/gic_opf_ts.jl")
    #include("prob/gic_opf_ts_decoupled.jl")
    #include("prob/gic_msse_decoupled.jl")
    include("prob/gic_ml.jl")
    #include("prob/gic_ots.jl")    
    #include("prob/gic_ots_ts.jl")
end
