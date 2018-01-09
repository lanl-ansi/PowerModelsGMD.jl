

""
const ACPPowerModel = GenericPowerModel{PowerModels.StandardACPForm}

"default AC constructor for GMD type problems"
ACPPowerModel(data::Dict{String,Any}; kwargs...) =
    GenericGMDPowerModel(data, PowerModels.StandardACPForm; kwargs...)
