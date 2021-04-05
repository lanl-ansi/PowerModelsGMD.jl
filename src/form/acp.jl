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

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd - pd_mls[i] for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*vm^2)
    JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd - qd_mls[i] for (i, qd) in bus_qd) + sum(bs for (i, bs) in bus_bs)*vm^2)

end


"CONSTRAINT: power balance without shunts and load shedding"
function constraint_power_balance_gmd(pm::_PM.AbstractACPModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    qloss = _PM.var(pm, n, :qloss)

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd for (i, pd) in bus_pd))
    JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd for (i, qd) in bus_qd))

end


"FUNCTION: relating current to power flow"
function constraint_current(pm::_PM.AbstractACPModel, n::Int, i, f_idx, f_bus, t_bus, tm)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    p_fr = _PM.var(pm, n, :p)[f_idx]
    q_fr = _PM.var(pm, n, :q)[f_idx]
    vm = _PM.var(pm, n, :vm)[f_bus]

    JuMP.@NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)

end


"FUNCTION: relating current to power flow on/off"
function constraint_current_on_off(pm::_PM.AbstractACPModel, n::Int, i, ac_max)

    z = _PM.var(pm, n, :z_branch)[i]
    i_ac = _PM.var(pm, n, :i_ac_mag)[i]

    JuMP.@constraint(pm.model, i_ac <= z * ac_max)
    JuMP.@constraint(pm.model, i_ac >= z * 0.0)

end


"FUNCTION: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractACPModel, n::Int, i, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))

end


"FUNCTION: computing qloss"
function constraint_qloss_vnom(pm::_PM.AbstractACPModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

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

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == ((K * vm * i_dc_mag) / (3.0 * branchMVA)))  # 'K' is per phase
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end

