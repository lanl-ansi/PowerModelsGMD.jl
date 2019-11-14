""
SDPWRMPowerModel(data::Dict{String,<:Any}; kwargs...) =
    InitializeGMDPowerModel(PMs.SDPWRMForm, data; kwargs...)

