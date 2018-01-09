
"default SOC constructor"
SOCWRPowerModel(data::Dict{String,Any}; kwargs...) = GenericGMDPowerModel(data, SOCWRForm; kwargs...)

"default QC constructor"
function QCWRPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, QCWRForm; kwargs...)
end

"default QC trilinear model constructor"
function QCWRTriPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, QCWRTriForm; kwargs...)
end