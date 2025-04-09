##########################
# Constraint Definitions #
##########################

# Commonly used constraints are defined here.


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
function constraint_dc_current_mag_ungrounded_xf(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)

    JuMP.@constraint(pm.model,
        ieff[k]
        ==
        0.0
    )

end
constraint_dc_current_mag_ungrounded_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag_ungrounded_xf(pm, nw, k)


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh)

    type = typeof(pm)
    Memento.error(_LOGGER, "Error: Function constraint_dc_current_mag_gwye_delta_xf needs to be implemented for PowerModel of type $type")

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    type = typeof(pm)
    Memento.error(_LOGGER, "Error: Function constraint_dc_current_mag_gwye_gwye_xf needs to be implemented for PowerModel of type $type")

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractPowerModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    type = typeof(pm)
    Memento.error(_LOGGER, "Error: Function constraint_dc_current_mag_gwye_gwye_auto_xf needs to be implemented for PowerModel of type $type")

end


"CONSTRAINT: computing the dc current magnitude"
function constraint_dc_current_mag(pm::_PM.AbstractPowerModel, n::Int, k)

    branch = _PM.ref(pm, n, :branch, k)

    if !(branch["type"] == "xfmr" || branch["type"] == "xf" || branch["type"] == "transformer")
        constraint_dc_current_mag_line(pm, k, nw=n)

    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        Memento.debug(_LOGGER, "UNGROUNDED CONFIGURATION. Ieff is constrained to ZERO.")
        constraint_dc_current_mag_ungrounded_xf(pm, k, nw=n)

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
    println(ooo)
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


"CONSTRAINT: nodal kcl for dc circuits"
function constraint_dc_kcl(pm::_PM.AbstractPowerModel, n::Int, i, dc_expr, gmd_bus_arcs, gs, blocker_status)
    v_dc = _PM.var(pm, n, :v_dc)[i]

    if length(gmd_bus_arcs) > 0

        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
        end

        if blocker_status != 0.0
            con = JuMP.@constraint(pm.model,
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


# ===   QLOSS CONSTRAINTS   === #

"CONSTRAINT: qloss calculcated from ac voltage and dc current"
function constraint_qloss(pm::_PM.AbstractPowerModel, n::Int, k, i, j, baseMVA, branchMVA, vm, busKV, K)
    branch    = _PM.ref(pm, n, :branch, k)

    qloss = _PM.var(pm, n, :qloss)
    ieff = _PM.var(pm, n, :i_dc_mag, k)

    if branch["type"] == "xfmr"
        JuMP.@constraint(pm.model,
            qloss[(k,i,j)] == K * ieff * vm
        )
    else
        JuMP.@constraint(pm.model,
            qloss[(k,i,j)] == 0.0
        )
    end
end


"CONSTRAINT: qloss calculcated from ac voltage and constant ieff"
function constraint_qloss_constant_ieff(pm::_PM.AbstractPowerModel, n::Int, k, i, j, baseMVA, K, ieff)

    qloss = _PM.var(pm, n, :qloss)
    vm    = _PM.var(pm, n, :vm)[i]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        # Use this if we implement piecewise K
        # (pm.data["baseMVA"]) / branchMVA ) * (K * vm * ieff) / (3.0 * branchMVA)
        (K * vm * ieff) / (3.0 * baseMVA) # need to change based on response 
            # K is per phase
    )


    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: more than a specified percentage of load is served"
function constraint_load_served(pm::_PM.AbstractPowerModel, n::Int, pds, min_load_served)

    z_demand = _PM.var(pm, n, :z_demand)

    JuMP.@constraint(pm.model,
        sum(pd*z_demand[i] for (i,pd) in pds)
        >=
        min_load_served
    )

end


"CONSTRAINT: nodal power balance for dc circuits with GIC blockers"
function constraint_dc_power_balance_ne_blocker(pm::_PM.AbstractPowerModel, n::Int, i, j, dc_expr, gmd_bus_arcs, gs)

    v_dc = _PM.var(pm, n, :v_dc)[i]
    zv_dc = _PM.var(pm, n, :zv_dc)[j]
    z = _PM.var(pm, n, :z_blocker)[j]

    if length(gmd_bus_arcs) > 0

        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
        end

        _IM.relaxation_product(pm.model, z, v_dc, zv_dc)

        con = JuMP.@constraint(pm.model,
            sum(dc_expr[a] for a in gmd_bus_arcs)
            ==
            gs * v_dc - gs * zv_dc
#            gs * v_dc  - gs * v_dc * z
#             (gs * v_dc)*(1 - z)
        )
    end

end


function constraint_gmd_connections(pm::_PM.AbstractPowerModel, n::Int, connections)
    z = [_PM.var(pm, n, :z_blocker)[sub] for sub in connections]
    con = JuMP.@constraint(pm.model,
        sum([1 - _PM.var(pm, n, :z_blocker)[sub] for sub in connections]) >= 1
    )
end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)
    delta_oil_ss = _PM.var(pm, n, :ross, i)
    delta_oil = _PM.var(pm, n, :ro, i)
    JuMP.@constraint(pm.model, delta_oil == delta_oil_ss)
end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, delta_oil_init)
    delta_oil = _PM.var(pm, n, :ro, i)
    JuMP.@constraint(pm.model, delta_oil == delta_oil_init)
end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i, tau)
    delta_oil_ss_prev = _PM.var(pm, n_1, :ross, i)
    delta_oil_ss = _PM.var(pm, n_2, :ross, i)
    delta_oil_prev = _PM.var(pm, n_1, :ro, i)
    delta_oil = _PM.var(pm, n_2, :ro, i)

    JuMP.@constraint(pm.model,
        (1 + tau) * delta_oil == delta_oil_ss + delta_oil_ss_prev - (1 - tau) * delta_oil_prev
    )
end


# ===   THERMAL CONSTRAINTS   === #


"CONSTRAINT: steady-state temperature state"
function constraint_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, rate_a, delta_oil_rated)
    p_fr = _PM.var(pm, n, :p, f_idx)
    q_fr = _PM.var(pm, n, :q, f_idx)
    delta_oil_ss = _PM.var(pm, n, :ross, i)

    JuMP.@constraint(pm.model,
        rate_a^2 * delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2
    )
end


"CONSTRAINT: steady-state hot-spot temperature state"
function constraint_hotspot_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, rate_a, Re)
    delta_hotspot_ss = _PM.var(pm, n, :hsss, i)
    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    JuMP.@constraint(pm.model,  delta_hotspot_ss == Re*ieff)
end


"CONSTRAINT: hot-spot temperature state"
function constraint_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)
    delta_hotspot_ss = _PM.var(pm, n, :hsss, i)
    delta_hotspot = _PM.var(pm, n, :hs, i)
    # oil_temp = _PM.var(pm, n, :ro, i)
    JuMP.@constraint(pm.model, delta_hotspot == delta_hotspot_ss)
end


"CONSTRAINT: absolute hot-spot temperature state"
function constraint_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, temp_ambient)
    hotspot = _PM.var(pm, n, :hsa, i)
    delta_hotspot = _PM.var(pm, n, :hs, i)
    oil_temp = _PM.var(pm, n, :ro, i)
    JuMP.@constraint(pm.model, hotspot == delta_hotspot + oil_temp + temp_ambient)
end


"CONSTRAINT: average absolute hot-spot temperature state"
function constraint_avg_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, i, f_idx, max_temp)
    N = length(_PM.nws(pm))

    JuMP.@constraint(pm.model,
        sum(_PM.var(pm, n, :hsa, i) for (n, nw_ref) in _PM.nws(pm)) <= N*max_temp
    )
end


"CONSTRAINT: thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractPowerModel, n::Int, i, coeff, ibase)
    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model, 
        i_ac_mag <= coeff[1] + coeff[2] * ieff/ibase + coeff[3] * ieff^2/ibase^2
    )
end
