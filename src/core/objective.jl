#########################
# Objective Definitions #
#########################


# ===   GMD OBJECTIVES   === #

"OBJECTIVE: minimize cost of installing GIC blocker"
function objective_blocker_placement_cost(pm::_PM.AbstractPowerModel)

    return JuMP.@objective(pm.model, Min,
        sum(
            sum( blocker["construction_cost"]*_PM.var(pm, n, :z_blocker, i) for (i,blocker) in nw_ref[:gmd_ne_blocker] )
        for (n, nw_ref) in _PM.nws(pm))
    )

end
