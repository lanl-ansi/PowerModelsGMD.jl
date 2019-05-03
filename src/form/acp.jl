

"default AC constructor for GMD type problems"
ACPPowerModel(data::Dict{String,<:Any}; kwargs...) =
    GenericGMDPowerModel(data, PowerModels.StandardACPForm; kwargs...)

""
function variable_ac_current(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_ac_current_mag(pm; kwargs...)
end

""
function variable_ac_current_on_off(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_ac_current_mag(pm; bounded=false, kwargs...) # needs to be false because this is an on/off variable
end

""
function variable_dc_current(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_dc_current_mag(pm; kwargs...)
end

""
function variable_reactive_loss(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_qloss(pm; kwargs...)
end


"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gmd_ls(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs) where T <: PowerModels.AbstractACPForm
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

"Constraint for relating current to power flow"
function constraint_current(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, f_idx, f_bus, t_bus, tm) where T <: PowerModels.AbstractACPForm
    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    p_fr     = PMs.var(pm, n, c, :p)[f_idx]
    q_fr     = PMs.var(pm, n, c, :q)[f_idx]
    vm       = PMs.var(pm, n, c, :vm)[f_bus]

    JuMP.@NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)
end

"Constraint for relating current to power flow on/off"
function constraint_current_on_off(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, ac_max) where T <: PowerModels.AbstractACPForm
    z  = PMs.var(pm, n, c, :branch_z)[i]
    i_ac = PMs.var(pm, n, c, :i_ac_mag)[i]
    JuMP.@constraint(pm.model, i_ac <= z * ac_max)
    JuMP.@constraint(pm.model, i_ac >= z * 0.0)
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, coeff, ibase) where T <: PowerModels.AbstractACPForm
    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    ieff = PMs.var(pm, n, c, :i_dc_mag)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))
end

"Constraint for computing qloss"
function constraint_qloss(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, k, i, j, K, branchMVA) where T <: PowerModels.AbstractACPForm
    qloss = PMs.var(pm, n, c, :qloss)
    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    vm = PMs.var(pm, n, c, :vm)[i]

    if JuMP.getlowerbound(i_dc_mag) > 0.0 || JuMP.getupperbound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")
    end

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*vm*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss"
function constraint_qloss(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, k, i, j) where T <: PowerModels.AbstractACPForm
    qloss = PMs.var(pm, n, c, :qloss)
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

