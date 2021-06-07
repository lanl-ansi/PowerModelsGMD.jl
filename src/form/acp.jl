# ===   ACP   === #


"VARIABLE: bus voltage on/off"
function variable_bus_voltage_on_off(pm::_PM.AbstractACPModel; kwargs...)
    _PM.variable_bus_voltage_angle(pm; kwargs...)
    variable_bus_voltage_magnitude_on_off(pm; kwargs...)
end


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


"CONSTRAINT: bus voltage on/off"
function constraint_bus_voltage_on_off(pm::_PM.AbstractACPModel; nw::Int=nw_id_default, kwargs...)
    for (i,bus) in _PM.ref(pm, nw, :bus)
        constraint_voltage_magnitude_on_off(pm, i; nw=nw)
    end
end


"CONSTRAINT: power balance for load shedding"
function constraint_power_balance_shed(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")
    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor scale", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor scale", "shunt")

    _PM.con(pm, n, :kcl_p)[i] = JuMP.@NLconstraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd * z_demand[i] for (i,pd) in bus_pd)
        - sum(gs * vm^2 * z_shunt[i] for (i,gs) in bus_gs)
    )
    _PM.con(pm, n, :kcl_q)[i] = JuMP.@NLconstraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd * z_demand[i] for (i,qd) in bus_qd)
        + sum(bs * vm^2 * z_shunt[i] for (i,bs) in bus_bs)
    )

end


"CONSTRAINT: power balance with shunts for load shedding"
function constraint_power_balance_shunt_gmd_mls(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = _PM.var(pm, n, :vm)[i]
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    qloss = _PM.var(pm, n, :qloss)
    pd_mls = _PM.var(pm, n, :pd)
    qd_mls = _PM.var(pm, n, :qd)

    JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(pd - pd_mls[i] for (i, pd) in bus_pd)
        - sum(gs for (i, gs) in bus_gs) * vm^2
    )
    JuMP.@constraint(pm.model,
        sum(q[a] + qloss[a] for a in bus_arcs)
        == sum(qg[g] for g in bus_gens)
        - sum(qd - qd_mls[i] for (i, qd) in bus_qd)
        + sum(bs for (i, bs) in bus_bs) * vm^2
    )

end


"CONSTRAINT: power balance without shunts and load shedding"
function constraint_power_balance_gmd(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    qloss = _PM.var(pm, n, :qloss)

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(pd for (i, pd) in bus_pd)
    )
    JuMP.@constraint(pm.model,
        sum(q[a] + qloss[a] for a in bus_arcs)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qd for (i, qd) in bus_qd)
    )

end


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


"FUNCTION: computing qloss"
function constraint_qloss_vnom(pm::_PM.AbstractACPModel, n::Int, k, i, j)

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


"FUNCTION: computing qloss"
function constraint_qloss_vnom(pm::_PM.AbstractACPModel, n::Int, k, i, j, K, branchMVA)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    vm = _PM.var(pm, n, :vm)[i]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        println("WARNING")
        println("DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.")
        println()
    end

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * vm * i_dc_mag) / (3.0 * branchMVA)  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end

