#############################################
# Polar Form of the Non-Convex AC Equations #
#############################################


# ===   VOLTAGE VARIABLES   === #


"VARIABLE: bus voltage on/off"
function variable_bus_voltage_on_off(pm::_PM.AbstractACPModel; kwargs...)

    _PM.variable_bus_voltage_angle(pm; kwargs...)

    variable_bus_voltage_magnitude_on_off(pm; kwargs...)

end


# ===   CURRENT VARIABLES   === #


"VARIABLE: ac current"
function variable_ac_current(pm::_PM.AbstractACPModel; kwargs...)

    variable_ac_current_mag(pm; kwargs...)

end


"VARIABLE: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractACPModel; kwargs...)

    variable_ac_current_mag(pm; bounded=false, kwargs...)

end


"VARIABLE: dc current"
function variable_dc_current(pm::_PM.AbstractACPModel; kwargs...)

    variable_dc_current_mag(pm; kwargs...)

end


"VARIABLE: reactive loss"
function variable_reactive_loss(pm::_PM.AbstractACPModel; kwargs...)

    variable_qloss(pm; kwargs...)

end


# ===   VOLTAGE CONSTRAINTS   === #

"CONSTRAINT: bus voltage on/off"
function constraint_bus_voltage_on_off(pm::_PM.AbstractACPModel; nw::Int=nw_id_default, kwargs...)

    for (i,bus) in _PM.ref(pm, nw, :bus)

        constraint_voltage_magnitude_on_off(pm, i; nw=nw)

    end

end


# ===   POWER BALANCE CONSTRAINTS   === #


"CONSTRAINT: nodal power balance with gmd"
function constraint_power_balance_gmd(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd)

    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    qloss = get(_PM.var(pm, n), :qloss, Dict()); _PM._check_var_keys(qloss, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

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

    if !nl_form
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
        )
    else
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"CONSTRAINT: nodal power balance with gmd and shunts"
function constraint_power_balance_gmd_shunt(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    qloss = get(_PM.var(pm, n), :qloss, Dict()); _PM._check_var_keys(qloss, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

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

    if !nl_form
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs) * vm^2
        )
    else
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs) * vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    qloss = get(_PM.var(pm, n), :qloss, Dict()); _PM._check_var_keys(qloss, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

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
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * z_shunt[i] for (i,bs) in bus_bs) * vm^2
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
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * z_shunt[i] for (i,bs) in bus_bs) * vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


# ===   QLOSS CONSTRAINTS   === #


"CONSTRAINT: zero qloss"
function constraint_zero_qloss(pm::_PM.AbstractACPModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        0.0
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: qloss assuming constant dc voltage"
function constraint_qloss_vnom(pm::_PM.AbstractACPModel, n::Int, k, i, j, branchMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    vm = _PM.var(pm, n, :vm)[i]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        Memento.warn(_LOGGER, "DC voltage magnitude cannot take a 0 value. In OTS applications, this may result in incorrect results.")
    end

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * vm * i_dc_mag) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


# ===   THERMAL CONSTRAINTS   === #

##########






"FUNCTION: relating current to power flow on/off"
function constraint_current_on_off(pm::_PM.AbstractACPModel, n::Int, i::Int, ac_max)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    z = _PM.var(pm, n, :z_branch)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        z * ac_max
    )
    JuMP.@constraint(pm.model,
        i_ac_mag
        >=
        0
    )

end


"FUNCTION: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractACPModel, n::Int, i::Int, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2] * ieff / ibase + coeff[3] * ieff^2 / ibase^2
    )

end



"CONSTRAINT: computing the dc current magnitude"
function constraint_dc_current_mag(pm::_PM.AbstractACPModel, n::Int, k)

    # correct equation is ieff = |a*ihi + ilo|/a
    # just use ihi for now
    branch = _PM.ref(pm, n, :branch, k)

    if !(branch["type"] == "xfmr" || branch["type"] == "xf" || branch["type"] == "transformer")
        constraint_dc_current_mag_line(pm, k, nw=n)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        Memento.debug(_LOGGER, "UNGROUNDED CONFIGURATION. Ieff is constrained to ZERO.")
        constraint_dc_current_mag_grounded_xf(pm, k, nw=n)
    elseif branch["config"] in ["delta-gwye", "gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm, k, nw=n)
    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm, k, nw=n)
    elseif branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm, k, nw=n)
    # TODO: need to support 3W transformers in optimization problems
    elseif branch["config"] == "three-winding"
        ieff = _PM.var(pm, n, :i_dc_mag)
        JuMP.@constraint(pm.model, ieff[k] >= 0.0)
    end

end


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractACPModel, n::Int, k, kh, ih, jh)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    JuMP.@NLconstraint(pm.model, ieff == abs(ihi))

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractACPModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]
    JuMP.@NLconstraint(pm.model, ieff == abs(a*ihi + ilo)/a)

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractACPModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]
    JuMP.@NLconstraint(pm.model, ieff == abs(a*is + ic)/(a + 1.0))

end

