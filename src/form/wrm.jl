""
SDPWRMPowerModel(data::Dict{String,<:Any}; kwargs...) =
    GenericGMDPowerModel(data, PMs.SDPWRMForm; kwargs...)

