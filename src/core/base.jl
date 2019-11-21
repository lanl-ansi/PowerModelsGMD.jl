
"FUNCTION: add data structures that are specific for GMD modeling"
function ref_add_core!(pm::PMs.AbstractPowerModel)
    nw_refs = pm.ref[:nw]

    for (nw, ref) in nw_refs

        # add something like pm_component_status_inactive["bus"] here instead of hardcoding
        ref[:gmd_bus] = Dict(x for x in ref[:gmd_bus] if x.second["status"] != 0)
        ref[:gmd_branch] = Dict(x for x in ref[:gmd_branch] if x.second["br_status"] != 0)

        ref[:gmd_arcs_from] = [(i,branch["f_bus"],branch["t_bus"]) for (i,branch) in ref[:gmd_branch]]
        ref[:gmd_arcs_to]   = [(i,branch["t_bus"],branch["f_bus"]) for (i,branch) in ref[:gmd_branch]]
        ref[:gmd_arcs] = [ref[:gmd_arcs_from]; ref[:gmd_arcs_to]]

        gmd_bus_arcs = Dict([(i, []) for (i,bus) in ref[:gmd_bus]])
        for (l,i,j) in ref[:gmd_arcs]
           push!(gmd_bus_arcs[i], (l,i,j))
        end
        ref[:gmd_bus_arcs] = gmd_bus_arcs

    end
end


"FUNCTION: check GMD branch parent status"
function check_gmd_branch_parent_status(ref, i, gmd_branch)

    parent_id = gmd_branch["parent_index"]
    status = false

    if parent_id in keys(ref[:branch])
        parent_branch = ref[:branch][parent_id]
        status = parent_branch["br_status"] == 1 && gmd_branch["f_bus"] in keys(ref[:gmd_bus]) && gmd_branch["t_bus"] in keys(ref[:gmd_bus])
    end

    return status

end


