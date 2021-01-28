
"VARIABLE: ac current"
function variable_ac_current(pm::PMs.AbstractDCPModel; kwargs...)
end


"VARIABLE: ac current on/off"
function variable_ac_current_on_off(pm::PMs.AbstractDCPModel; kwargs...)
end


"VARIABLE: dc current"
function variable_dc_current(pm::PMs.AbstractDCPModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
end


"VARIABLE: reactive loss"
function variable_reactive_loss(pm::PMs.AbstractDCPModel; kwargs...)
end


"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""


"CONTRAINT: kcl with shunts for load shedding"
function constraint_kcl_shunt_gmd_ls(pm::PMs.AbstractDCPModel, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = PMs.var(pm, n, c, :vm)[i]
    p = PMs.var(pm, n, c, :p)
    pg = PMs.var(pm, n, c, :pg)
    pd_ls = PMs.var(pm, n, c, :pd)

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd - pd_ls[i] for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*vm^2)

end


"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""


"CONTRAINT: kcl with shunts"
function constraint_kcl_shunt_gmd(pm::PMs.AbstractDCPModel, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = PMs.var(pm, n, c, :vm)[i]
    p = PMs.var(pm, n, c, :p)
    pg = PMs.var(pm, n, c, :pg)

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*vm^2)

end


"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""


"CONTRAINT: klc"
function constraint_kcl_gmd(pm::PMs.AbstractDCPModel, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = PMs.var(pm, n, c, :p)
    pg = PMs.var(pm, n, c, :pg)

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd for (i, pd) in bus_pd))

end

"CONSTRAINT: relating current to power flow on/off"
function constraint_current_on_off(pm::PMs.AbstractDCPModel, n::Int, c::Int, i, ac_max)

    z  = PMs.var(pm, n, :z_branch)[i]
    i_ac = PMs.var(pm, n, c, :i_ac_mag)[i]
    JuMP.@constraint(pm.model, i_ac <= z * ac_max)
    JuMP.@constraint(pm.model, i_ac >= z * 0.0)

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::PMs.AbstractDCPModel, n::Int, c::Int, i, coeff, ibase)

    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    ieff = PMs.var(pm, n, c, :i_dc_mag)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))
end


"CONSTRAINT: computing qloss"
function constraint_qloss_vnom(pm::PMs.AbstractDCPModel, n::Int, c::Int, k, i, j, K, branchMVA)
end


"CONSTRAINT: computing qloss"
function constraint_qloss_vnom(pm::PMs.AbstractDCPModel, n::Int, c::Int, k, i, j)
end


