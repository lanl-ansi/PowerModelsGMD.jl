"REF: add gmd blockers to ref dict structures"
function ref_add_gmd_blockers!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})

    for (nw, nw_ref) in ref[:it][pm_it_sym][:nw]
        nw_ref[:blocker_buses] = Dict(i=>gmd_bus for (i,gmd_bus) in nw_ref[:gmd_bus] if get(gmd_bus, "blocker", 0.0) != 0.0)
    end

end
