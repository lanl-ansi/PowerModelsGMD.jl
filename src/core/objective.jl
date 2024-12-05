#########################
# Objective Definitions #
#########################


# ===   GMD OBJECTIVES   === #

"OBJECTIVE: minimize cost of installing GIC blocker"
function objective_blocker_placement_cost(pm::_PM.AbstractPowerModel)
    # don't need to sum across all scenarios - objective will be somewhat confusing
    return JuMP.@objective(pm.model, Min,
        sum(
            sum( get(blocker, "multiplier", 1.0) * get(blocker, "construction_cost", 1.0) *_PM.var(pm, n, :z_blocker, i) for (i,blocker) in nw_ref[:gmd_ne_blocker] )
        for (n, nw_ref) in _PM.nws(pm))
    )

end


"OBJECTIVE: maximize the qloss of the ac model"
function objective_max_qloss(pm::_PM.AbstractPowerModel, nw::Int=nw_id_default)
    k = get(pm.setting,"qloss_branch",false)
    branch = _PM.ref(pm, nw, :branch)[k]
    i = branch["hi_bus"]
    j = branch["lo_bus"]
    return JuMP.@objective(pm.model, Max,
        sum(_PM.var(pm, n, :qloss)[(k,i,j)]
        for (n, nw_ref) in _PM.nws(pm))
    )
end


"OBJECTIVE: max/min the dc voltage at the sub station"
function objective_bound_gmd_bus_v(pm::_PM.AbstractPowerModel, nw::Int=nw_id_default)

    bus = get(pm.setting,"gmd_bus",false)

    if get(pm.setting,"max",false)
        return JuMP.@objective(pm.model, Max,
            sum(_PM.var(pm, n, :v_dc)[bus]
            for (n, nw_ref) in _PM.nws(pm))
        )
    else
        return JuMP.@objective(pm.model, Min,
            sum(_PM.var(pm, n, :v_dc)[bus]
            for (n, nw_ref) in _PM.nws(pm))
        )
    end
end