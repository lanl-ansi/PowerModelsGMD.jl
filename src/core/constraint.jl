##########################
# Constraint Definitions #
##########################

# Commonly used constraints are defined here.


# ===   VOLTAGE CONSTRAINTS   === #

"CONSTRAINT: voltage magnitude on/off constraint"
function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)

    vm = _PM.var(pm, n, :vm, i)
    z_voltage = _PM.var(pm, n, :z_voltage, i)

    JuMP.@constraint(pm.model,
        vm
        <=
        vmax * z_voltage
    )
    JuMP.@constraint(pm.model,
        vm
        >=
        vmin * z_voltage
    )

end


"CONSTRAINT: squared voltage magnitude on/off constraint"
function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)

    w = _PM.var(pm, n, :w, i)
    z_voltage = _PM.var(pm, n, :z_voltage, i)

    JuMP.@constraint(pm.model,
        w
        <=
        vmax^2 * z_voltage
    )
    JuMP.@constraint(pm.model,
        w
        >=
        vmin^2 * z_voltage
    )

end


# ===   CURRENT CONSTRAINTS   === #


"CONSTRAINT: dc current on normal lines"
function constraint_dc_current_mag_line(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)

    JuMP.@constraint(pm.model,
        ieff[k]
        ==
        0.0
    )

end
constraint_dc_current_mag_line(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag_line(pm, nw, k)


"CONSTRAINT: dc current on grounded transformers"
function constraint_dc_current_mag_grounded_xf(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)

    JuMP.@constraint(pm.model,
        ieff[k]
        >=
        0.0
    )

end
constraint_dc_current_mag_grounded_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag_grounded_xf(pm, nw, k)


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        ihi
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        -ihi
    )

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a * ihi + ilo) / a
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - (a * ihi + ilo) / a
    )

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractPowerModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a * is + ic) / (a + 1.0)
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - ( a * is + ic) / (a + 1.0)
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        0.0
    )

end


"CONSTRAINT: computing the dc current magnitude"
function constraint_dc_current_mag(pm::_PM.AbstractPowerModel, n::Int, k)

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

    elseif branch["config"] == "three-winding"
        # TODO: need to support 3W transformers in optimization problems

        ieff = _PM.var(pm, n, :i_dc_mag)
        JuMP.@constraint(pm.model,
            ieff[k]
            ==
            0.0
        )

    end

end
constraint_dc_current_mag(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag(pm, nw, k)


"CONSTRAINT: on/off dc current on the ac lines"
function constraint_dc_current_mag_on_off(pm::_PM.AbstractPowerModel, n::Int, k, dc_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    z = _PM.var(pm, n, :z_branch)[k]

    JuMP.@constraint(pm.model,
        ieff
        <=
        z * dc_max
    )

end


# ===   GENERATOR CONSTRAINTS   === #


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::_PM.AbstractPowerModel, n::Int, i, cost)

    z = _PM.var(pm, n, :z_gen)[i]
    pg_sqr = _PM.var(pm, n, :pg_sqr)[i]
    pg = _PM.var(pm, n, :pg)[i]

    JuMP.@constraint(pm.model,
        z * pg_sqr
        >=
        cost[1] * pg^2
    )

end


"CONSTRAINT: tie OTS variables to gen variables"
function constraint_gen_ots_on_off(pm::_PM.AbstractPowerModel, n::Int, i, bus_arcs)

    z = _PM.var(pm, n, :z_gen)[i]
    zb = _PM.var(pm, n, :z_branch)

    JuMP.@constraint(pm.model,
        z
        <=
        sum(zb[a[1]] for a in bus_arcs)
    )

end


# ===   POWER BALANCE CONSTRAINTS   === #


"CONSTRAINT: nodal power balance with gmd"
function constraint_power_balance_gmd(pm::_PM.AbstractWModels, n::Int, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd)

    w = _PM.var(pm, n, :w, i)
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

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] + qloss[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for qd in values(bus_qd))
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"CONSTRAINT: nodal power balance with gmd and shunts"
function constraint_power_balance_gmd_shunt(pm::_PM.AbstractWModels, n::Int, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    w = _PM.var(pm, n, :w, i)
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

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs)) * w
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] + qloss[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for qd in values(bus_qd))
        + sum(bs for bs in values(bus_bs)) * w
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractWConvexModels, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    w = _PM.var(pm, n, :w, i)
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
    wz_shunt = get(_PM.var(pm, n), :wz_shunt, Dict()); _PM._check_var_keys(wz_shunt, keys(bus_gs), "voltage square power factor", "shunt")

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd * z_demand[i] for (i,pd) in bus_pd)
        - sum(gs * wz_shunt[i] for (i,gs) in bus_gs)
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] + qloss[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd * z_demand[i] for (i,qd) in bus_qd)
        + sum(bs * wz_shunt[i] for (i,bs) in bus_bs)
    )

    for s in keys(bus_gs)
        _IM.relaxation_product(pm.model, w, z_shunt[s], wz_shunt[s])
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"CONSTRAINT: nodal power balance for dc circuits"
function constraint_dc_power_balance(pm::_PM.AbstractPowerModel, n::Int, i, dc_expr, gmd_bus_arcs, gs, blocker_status)

    v_dc = _PM.var(pm, n, :v_dc)[i]

    if length(gmd_bus_arcs) > 0

        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
            println()
        end

        if blocker_status != 0.0
            JuMP.@constraint(pm.model,
                sum(dc_expr[a] for a in gmd_bus_arcs)
                ==
                0.0
            )
        else
            con = JuMP.@constraint(pm.model,
                sum(dc_expr[a] for a in gmd_bus_arcs)
                ==
                (gs * v_dc)
            )

        end

    end

end


"CONSTRAINT: nodal power balance for dc circuits with GIC blockers"
function constraint_dc_power_balance_blocker(pm::_PM.AbstractPowerModel, n::Int, i, dc_expr, gmd_bus_arcs, gs)

    v_dc = _PM.var(pm, n, :v_dc)[i]
    z = _PM.var(pm, n, :z_blocker)[i]

    println("Adding blocking dc power balance constraint for gmd bus $i with admittance $gs")

    if length(gmd_bus_arcs) > 0

        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
            println()
        end

        JuMP.@NLconstraint(pm.model,
            sum(dc_expr[a] for a in gmd_bus_arcs)
            ==
            (gs * v_dc)*(1 - z)
        )

    end

end


# ===   OHM'S LAW CONSTRAINTS   === #


"CONSTRAINT: ohms constraint for dc circuits"
function constraint_dc_ohms(pm::_PM.AbstractPowerModel, n::Int, i, f_bus, t_bus, f_idx, t_idx, vs, gs)

    Memento.debug(_LOGGER, "branch $i: ($f_bus,$t_bus), $vs, $gs \n")

    dc = _PM.var(pm, n, :dc)[(i, f_bus, t_bus)]
    vfr = _PM.var(pm, n, :v_dc)[f_bus]
    vto = _PM.var(pm, n, :v_dc)[t_bus]

    JuMP.@constraint(pm.model,
        dc
        ==
        gs * (vfr + vs - vto)
    )

end


"CONSTRAINT: ohms on/off constraint for dc circuits"
function constraint_dc_ohms_on_off(pm::_PM.AbstractPowerModel, n::Int, i, f_bus, t_bus, f_idx, t_idx, ac_branch, vs, gs)

    Memento.debug(_LOGGER, "branch $i: ($f_bus,$t_bus), $vs, $gs \n")

    v_dc_diff = _PM.var(pm, n, :v_dc_diff)[i]
    vfr = _PM.var(pm, n, :v_dc)[f_bus]
    vto = _PM.var(pm, n, :v_dc)[t_bus]

    dc = _PM.var(pm, n, :dc)[(i,f_bus,t_bus)]
    vz = _PM.var(pm, n, :vz)[i]
    z = _PM.var(pm, n, :z_branch)[ac_branch]

    JuMP.@constraint(pm.model,
        v_dc_diff
        ==
        vfr - vto
    )

    JuMP.@constraint(pm.model,
        dc
        ==
        gs * (vz + z * vs)
    )

    _IM.relaxation_product(pm.model, z, v_dc_diff, vz)

end


# ===   QLOSS CONSTRAINTS   === #


"CONSTRAINT: zero qloss"
function constraint_zero_qloss(pm::_PM.AbstractPowerModel, n::Int, k, i, j)

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


"CONSTRAINT: qloss assuming constant ac voltage"
function constraint_qloss(pm::_PM.AbstractPowerModel, n::Int, k, i, j, branchMVA, K, V)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * V * i_dc_mag) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: qloss assuming constant 1.0 dc voltage"
function constraint_qloss_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, branchMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * i_dc_mag) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: decoupled qloss assuming constant ac voltage"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, branchMVA, ieff)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * ieff) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, n::Int, k, i, j, branchMVA, K, ieff, ih)

    qloss = _PM.var(pm, n, :qloss)
    v = _PM.var(pm, n, :vm)[ih]
        # ih is the index of the high-side bus

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * v * ieff) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: decoupled qloss assuming constant ac voltage for MLD"
function constraint_qloss_decoupled_vnom_mld(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, branchMVA, ieff)

    qloss = _PM.var(pm, n, :qloss)
    z_voltage = _PM.var(pm, n, :z_voltage)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * ieff * z_voltage[i]) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


# ===   THERMAL CONSTRAINTS   === #


"CONSTRAINT: steady-state temperature state"
function constraint_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, rate_a, delta_oil_rated)

    p_fr = _PM.var(pm, n, :p, f_idx)
    q_fr = _PM.var(pm, n, :q, f_idx)
    delta_oil_ss = _PM.var(pm, n, :ross, i)

    JuMP.@constraint(pm.model,
        rate_a^2 * delta_oil_ss / delta_oil_rated
        >=
        p_fr^2 + q_fr^2
    )

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)

    delta_oil_ss = _PM.var(pm, n, :ross, i)
    delta_oil = _PM.var(pm, n, :ro, i)

    JuMP.@constraint(pm.model,
        delta_oil
        ==
        delta_oil_ss
    )

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, delta_oil_init)

    delta_oil = _PM.var(pm, n, :ro, i)

    JuMP.@constraint(pm.model,
        delta_oil
        ==
        delta_oil_init
    )

end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i, tau)

    delta_oil_ss_prev = _PM.var(pm, n_1, :ross, i)
    delta_oil_ss = _PM.var(pm, n_2, :ross, i)
    delta_oil_prev = _PM.var(pm, n_1, :ro, i)
    delta_oil = _PM.var(pm, n_2, :ro, i)

    JuMP.@constraint(pm.model,
        (1 + tau) * delta_oil
        ==
        delta_oil_ss + delta_oil_ss_prev - (1 - tau) * delta_oil_prev
    )

end


"CONSTRAINT: steady-state hot-spot temperature state"
function constraint_hotspot_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, rate_a, Re)

    delta_hotspot_ss = _PM.var(pm, n, :hsss, i)
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model,
        delta_hotspot_ss
        ==
        Re * ieff
    )

end


"CONSTRAINT: hot-spot temperature state"
function constraint_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)

    delta_hotspot_ss = _PM.var(pm, n, :hsss, i)
    delta_hotspot = _PM.var(pm, n, :hs, i)
    oil_temp = _PM.var(pm, n, :ro, i)

    JuMP.@constraint(pm.model,
        delta_hotspot
        ==
        delta_hotspot_ss
    )

end


"CONSTRAINT: absolute hot-spot temperature state"
function constraint_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, temp_ambient)

    hotspot = _PM.var(pm, n, :hsa, i)
    delta_hotspot = _PM.var(pm, n, :hs, i)
    oil_temp = _PM.var(pm, n, :ro, i)

    JuMP.@constraint(pm.model,
        hotspot
        ==
        delta_hotspot + oil_temp + temp_ambient
    )

end


"CONSTRAINT: average absolute hot-spot temperature state"
function constraint_avg_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, i, f_idx, max_temp)

    N = length(_PM.nws(pm))

    JuMP.@constraint(pm.model,
        sum(_PM.var(pm, n, :hsa, i) for (n, nw_ref) in _PM.nws(pm))
        <=
        N * max_temp
    )

end


"CONSTRAINT: thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractPowerModel, n::Int, i, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2] * ieff / ibase + coeff[3] * ieff^2 / ibase^2
    )

end


# ===   GIC BLOCKER CONSTRAINTS   === #


"CONSTRAINT: maximum cost of installing gic blockers"
function constraint_blocker_placement_cost(pm::_PM.AbstractPowerModel, max_cost)

    nw = nw_id_default
        # TODO: extend to multinetwork

    JuMP.@constraint(pm.model,
        sum(get(_PM.ref(pm, nw, :blocker_buses, i), "blocker_cost", 1.0) * _PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :blocker_buses))
        <=
        max_cost
    )

end


"CONSTRAINT: cost of installing gic blockers"
function constraint_blocker_count(pm::_PM.AbstractPowerModel, blocker_count)

    nws = _PM.nw_ids(pm)

    for n in nws

        JuMP.@constraint(pm.model,
            sum(get(_PM.ref(pm, nw, :blocker_buses, i), "blocker_cost", 1.0) * _PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :blocker_buses))
            ==
            blocker_count
        )

    end

end


"CONSTRAINT: more than a specified percentage of load is served"
function constraint_load_served(pm::_PM.AbstractPowerModel, min_ratio_load_served)

    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    total_load = 0
    for n in nws
        for (i,load) in _PM.ref(pm, n, :load)
            total_load += abs(load["pd"])
        end
    end

    min_load_served = total_load * min_ratio_load_served
    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)

    JuMP.@constraint(pm.model,
        sum(sum(abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load)) for n in nws)
        >=
        min_load_served
    )

end


"CONSTRAINT: weighted load shed is below a specified ratio"
function constraint_load_shed(pm::_PM.AbstractPowerModel, max_load_shed)

    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    # z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    # z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    # z_voltage = Dict(n => _PM.var(pm, n, :z_voltage) for n in nws)

    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)
    load_weight = Dict(n => Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load)) for n in nws)
    for n in nws
        scaled_weight = [load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]
        if isempty(scaled_weight)
            scaled_weight = [1.0]
        end
    end

    JuMP.@constraint(pm.model,
        sum((time_elapsed[n]*(sum(load_weight[n][i]*abs(load["pd"])*(1 - z_demand[n][i]) for (i,load) in _PM.ref(pm, n, :load)))) for n in nws)
        <=
        max_load_shed
    )

end
