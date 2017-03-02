function add_gmd_ref(pm::GenericPowerModel)
    ref = pm.ref
    data = pm.data

    # filter turned off stuff
    # TODO does this need to be filtered when AC buses are turned off?
    # ref[:gmd_bus] = filter((i, gmd_bus) -> ..., ref[:gmd_bus])
    # TODO does this need to be filtered?
    # ref[:gmd_branch] = filter((i, branch) -> ..., ref[:gmd_branch])

    ref[:gmd_arcs_from] = [(i,branch["f_bus"],branch["t_bus"]) for (i,branch) in ref[:gmd_branch]]
    ref[:gmd_arcs_to]   = [(i,branch["t_bus"],branch["f_bus"]) for (i,branch) in ref[:gmd_branch]]
    ref[:gmd_arcs] = [ref[:gmd_arcs_from]; ref[:gmd_arcs_to]]

    gmd_bus_arcs = Dict([(i, []) for (i,bus) in ref[:gmd_bus]])
    for (l,i,j) in ref[:gmd_arcs]
        push!(gmd_bus_arcs[i], (l,i,j))
    end
    ref[:gmd_bus_arcs] = gmd_bus_arcs
end