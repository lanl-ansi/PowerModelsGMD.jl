#########################
# Objective Definitions #
#########################


# ===   GMD OBJECTIVES   === #


"OBJECTIVE: minimize fuel"
function objective_gmd_min_fuel(pm::_PM.AbstractPowerModel)

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            get(gen["cost"], 1, 0.0) * sum( _PM.var(pm, n, :pg, i) for c in _PM.conductor_ids(pm, n) )^2 +
            get(gen["cost"], 2, 0.0) * sum( _PM.var(pm, n, :pg, i) for c in _PM.conductor_ids(pm, n) ) +
            get(gen["cost"], 3, 0.0) for (i,gen) in nw_ref[:gen]
        ) + sum(
            sum(
                _PM.var(pm, n, :i_dc_mag, i)^2 for c in _PM.conductor_ids(pm, n)
            ) for (i, branch) in nw_ref[:branch]
            ) for (n, nw_ref) in _PM.nws(pm)
    ))

end


"OBJECTIVE: minimize generator error"
function objective_gmd_min_error(pm::_PM.AbstractPowerModel)
    # Keep generators as close as possible to original setpoints.

    @assert all(!_PM.ismulticonductor(pm) for n in _PM.nws(pm))

    M_p = Dict(n => max([gen["pmax"] for (i, gen) in nw_ref[:gen]]) for (n, nw_ref) in _PM.nws(pm))

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            (gen["pg"] - _PM.var(pm, :pg, i, nw=n))^2 +
            (gen["qg"] - _PM.var(pm, :qg, i, nw=n))^2 for (i, gen) in _PM.ref(pm, n, :gen)
        ) + sum(
            _PM.var(pm, :i_dc_mag, i, nw=n)^2 for (i, branch) in _PM.ref(pm, n, :branch)
            ) + sum(
                -100.0 * M_p^2 * _PM.var(pm, :z_demand, i, nw=n) for (i, load) in _PM.ref(pm, n, :load)
                ) for (n, nw_ref) in _PM.nws(pm)
    ))

end


# ===   LOAD SHEDDING AND LOADABILITY OBJECTIVES   === #


"OBJECTIVE: minimize load shedding and fuel cost"
function objective_gmd_mls_on_off(pm::_PM.AbstractPowerModel)

    @assert all(!_PM.ismulticonductor(pm) for n in _PM.nws(pm))

    shed_cost = calc_load_shed_cost(pm)

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            get(gen["cost"], 1, 0.0) * _PM.var(pm, :pg_sqr, i, nw=n) +
            get(gen["cost"], 2, 0.0) * _PM.var(pm, :pg, i, nw=n) +
            get(gen["cost"], 3, 0.0) * _PM.var(pm, :z_gen, i, nw=n) for (i, gen) in nw_ref[:gen]
        ) + sum(
            shed_cost * (
                _PM.var(pm, :pd, i, nw=n) +
                _PM.var(pm, :qd, i, nw=n)
                ) for (i, load) in nw_ref[:load]
            ) for (n, nw_ref) in _PM.nws(pm)
    ))

end


"OBJECTIVE: minimize load shedding and fuel cost"
function objective_gmd_min_mls(pm::_PM.AbstractPowerModel)

    @assert all(!_PM.ismulticonductor(pm) for n in _PM.nws(pm))

    shed_cost = calc_load_shed_cost(pm)

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            get(gen["cost"], 1, 0.0) * _PM.var(pm, :pg, i, nw=n)^2 +
            get(gen["cost"], 2, 0.0) * _PM.var(pm, :pg, i, nw=n) +
            get(gen["cost"], 3, 0.0) for (i, gen) in nw_ref[:gen]
        ) + sum(
            shed_cost * (
                abs(load["pd"])*(1.0-_PM.var(pm, :z_demand, i, nw=n)) +
                abs(load["qd"])*(1.0-_PM.var(pm, :z_demand, i, nw=n))
                ) for (i, load) in nw_ref[:load]
            ) for (n, nw_ref) in _PM.nws(pm)
    ))

end


# ===   THERMAL OBJECTIVES   === #


"OBJECTIVE: minimize transfomer heating caused by GIC"
function objective_gmd_min_transformer_heating(pm::_PM.AbstractPowerModel)

    # TODO: add i_dc_mag minimization

    return JuMP.@objective(pm.model, Min,
        sum(
            sum(
                sum( _PM.var(pm, n, :hsa, i) for c in _PM.conductor_ids(pm, n)
                ) for (i, branch) in nw_ref[:branch]
            ) for (n, nw_ref) in _PM.nws(pm)
        ))

end


# ===   GIC BLOCKER OBJECTIVES   === #


"OBJECTIVE: minimize cost of installing GIC blocker"
function objective_blocker_placement_cost(pm::_PM.AbstractPowerModel)

    # TODO: extend to multinetwork
    # nws = _PM.nw_ids(pm)

    nw = nw_id_default
    return JuMP.@objective(pm.model, Min,
        sum(
            get(_PM.ref(pm, nw, :blocker_buses, i), "blocker_cost", 1.0) *
            _PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :blocker_buses)
        ))

end


"OBJECTIVE: minimize weighted sum of GIC and placement cost"
function objective_minimize_idc_sum(pm::_PM.AbstractPowerModel)

    # TODO: extend to multinetwork
    # nws = _PM.nw_ids(pm)

    nw = nw_id_default
    return JuMP.@objective(pm.model, Min,
        sum(
            _PM.var(pm, nw, :dc).^2
        ) + 1000 * sum(
                        get(_PM.ref(pm, nw, :blocker_buses, i), "blocker_cost", 1.0) *
                        _PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :blocker_buses)
                    )
        )

end

