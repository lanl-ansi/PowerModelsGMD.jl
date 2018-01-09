
"default DC constructor"
DCPPowerModel(data::Dict{String,Any}; kwargs...) =
    GenericGMDPowerModel(data, StandardDCPForm; kwargs...)