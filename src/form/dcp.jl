###########################################
# Simple Active Power Only Approximations #
###########################################


# ===   VOLTAGE VARIABLES   === #


# ===   CURRENT CONSTRAINTS   === #


"CONSTRAINT: relating current to power flow on/off"
function constraint_current_on_off(pm::_PM.AbstractDCPModel, n::Int, i::Int, ac_max)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    z  = _PM.var(pm, n, :z_branch)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        z * ac_max
    )
    JuMP.@constraint(pm.model,
        i_ac_mag
        >=
        z * 0
    )

end


# ===   POWER BALANCE CONSTRAINTS   === #


"CONSTRAINT: nodal power balance with gmd"
function constraint_power_balance_gmd(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd)

    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")


    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end

end


"CONSTRAINT: nodal power balance with gmd and shunts"
function constraint_power_balance_gmd_shunt(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_gs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs) * vm^2
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs) * vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end

end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_gs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor", "shunt")

    # this is required for improved performance in NLP models
    if length(z_shunt) <= 0
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * vm^2
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end

end


# ===   THERMAL CONSTRAINTS   === #


"CONSTRAINT: steady-state temperature state"
function constraint_temperature_steady_state(pm::_PM.AbstractDCPModel, n::Int, i::Int, f_idx, rate_a, delta_oil_rated)

    p_fr = _PM.var(pm, n, :p, f_idx)
    delta_oil_ss = _PM.var(pm, n, :ross, i)

    JuMP.@constraint(pm.model,
        sqrt(rate_a) * delta_oil_ss / sqrt(delta_oil_rated)
        >=
        p_fr
    )

end


"CONSTRAINT: thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractDCPModel, n::Int, i::Int, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2] * ieff / ibase + coeff[3] * ieff^2 / ibase^2
    )

end
