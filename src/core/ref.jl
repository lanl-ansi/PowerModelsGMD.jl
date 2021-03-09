function ref_add_core!(refs::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    refs_gmd = refs[:it][pm_it_sym]
    _ref_add_core!(refs_gmd[:nw])
end


function _ref_add_core!(nw_refs::Dict{Int,<:Any})
    for (nw, ref) in nw_refs
        ref[:gmd_bus] = Dict(x for x in ref[:gmd_bus] if x.second["status"] != 0)
        ref[:gmd_branch] = Dict(x for x in ref[:gmd_branch] if x.second["br_status"] != 0)

        ref[:gmd_arcs_from] = [(i,branch["f_bus"],branch["t_bus"]) for (i,branch) in ref[:gmd_branch]]
        ref[:gmd_arcs_to] = [(i,branch["t_bus"],branch["f_bus"]) for (i,branch) in ref[:gmd_branch]]
        ref[:gmd_arcs] = [ref[:gmd_arcs_from]; ref[:gmd_arcs_to]]

        gmd_bus_arcs = Dict([(i, []) for (i,bus) in ref[:gmd_bus]])
        for (l,i,j) in ref[:gmd_arcs]
           push!(gmd_bus_arcs[i], (l,i,j))
        end
        ref[:gmd_bus_arcs] = gmd_bus_arcs
    end
end

