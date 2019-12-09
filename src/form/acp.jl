
"VARIABLE: ac current"
function variable_ac_current(pm::PMs.AbstractACPModel; kwargs...)
    variable_ac_current_mag(pm; kwargs...)
end


"VARIABLE: ac current on/off"
function variable_ac_current_on_off(pm::PMs.AbstractACPModel; kwargs...)
    variable_ac_current_mag(pm; bounded=false, kwargs...)
    #NOTE: needs to be false because this is an on/off variable
end


"VARIABLE: dc current"
function variable_dc_current(pm::PMs.AbstractACPModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
end


"VARIABLE: reactive loss"
function variable_reactive_loss(pm::PMs.AbstractACPModel; kwargs...)
    variable_qloss(pm; kwargs...)
end


"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""


"CONSTRAINT: kcl with shunts for load shedding"
function constraint_kcl_shunt_gmd_ls(pm::PMs.AbstractACPModel, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = PMs.var(pm, n, c, :vm)[i]
    p = PMs.var(pm, n, c, :p)
    q = PMs.var(pm, n, c, :q)
    pg = PMs.var(pm, n, c, :pg)
    qg = PMs.var(pm, n, c, :qg)
    qloss = PMs.var(pm, n, c, :qloss)
    pd_ls = PMs.var(pm, n, c, :pd)
    qd_ls = PMs.var(pm, n, c, :qd)

    JuMP.@constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd - pd_ls[i] for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*vm^2)
    JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd - qd_ls[i] for (i, qd) in bus_qd) + sum(bs for (i, bs) in bus_bs)*vm^2)

end


"CONSTRAINT: kcl with shunts"
function constraint_kcl_gmd(pm::PMs.AbstractACPModel, n::Int, c::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = PMs.var(pm, n, c, :p)
    q = PMs.var(pm, n, c, :q)
    pg = PMs.var(pm, n, c, :pg)
    qg = PMs.var(pm, n, c, :qg)
    qloss = PMs.var(pm, n, c, :qloss)

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    JuMP.@constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd for (i, pd) in bus_pd))
    JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd for (i, qd) in bus_qd))

end


"FUNCTION: relating current to power flow"
function constraint_current(pm::PMs.AbstractACPModel, n::Int, c::Int, i, f_idx, f_bus, t_bus, tm)

    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    p_fr     = PMs.var(pm, n, c, :p)[f_idx]
    q_fr     = PMs.var(pm, n, c, :q)[f_idx]
    vm       = PMs.var(pm, n, c, :vm)[f_bus]

    JuMP.@NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)

end


"FUNCTION: relating current to power flow on/off"
function constraint_current_on_off(pm::PMs.AbstractACPModel, n::Int, c::Int, i, ac_max)

    z  = PMs.var(pm, n, :z_branch)[i]
    i_ac = PMs.var(pm, n, c, :i_ac_mag)[i]
    JuMP.@constraint(pm.model, i_ac <= z * ac_max)
    JuMP.@constraint(pm.model, i_ac >= z * 0.0)

end


"FUNCTION: computing thermal protection of transformers"
function constraint_thermal_protection(pm::PMs.AbstractACPModel, n::Int, c::Int, i, coeff, ibase)

    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    ieff = PMs.var(pm, n, c, :i_dc_mag)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))

end


"FUNCTION: computing qloss"
function constraint_qloss_vnom(pm::PMs.AbstractACPModel, n::Int, c::Int, k, i, j)

    qloss = PMs.var(pm, n, c, :qloss)
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"FUNCTION: computing qloss"
function constraint_qloss_vnom(pm::PMs.AbstractACPModel, n::Int, c::Int, k, i, j, K, branchMVA)

    qloss = PMs.var(pm, n, c, :qloss)
    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    vm = PMs.var(pm, n, c, :vm)[i]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")
    end

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*vm*i_dc_mag/(3.0*branchMVA)) #K is per phase
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


