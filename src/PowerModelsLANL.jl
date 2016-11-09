isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsLANL
    using PowerModels

    include("prob/ml.jl")
end