

"default AC constructor for GMD type problems"
ACPPowerModel(data::Dict{String,Any}; kwargs...) =
    GenericGMDPowerModel(data, PowerModels.StandardACPForm; kwargs...)

""
function variable_ac_current(pm::GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_ac_current_mag(pm; kwargs...)
end

""
function variable_ac_current_on_off(pm::GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_ac_current_mag(pm; bounded=false, kwargs...) # needs to be false because this is an on/off variable
end

""
function variable_dc_current(pm::GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_dc_current_mag(pm; kwargs...)
end

""
function variable_reactive_loss(pm::GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractACPForm
    variable_qloss(pm; kwargs...)
end


"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gic_ls(pm::GenericPowerModel{T}, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs) where T <: PowerModels.AbstractACPForm
    vm = var(pm, n, c, :vm)[i]
    p = var(pm, n, c, :p)
    q = var(pm, n, c, :q)
    pg = var(pm, n, c, :pg)
    qg = var(pm, n, c, :qg)
    qloss = var(pm, n, c, :qloss)
    pd_ls = var(pm, n, c, :pd)
    qd_ls = var(pm, n, c, :qd)

    @constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd - pd_ls[i] for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*vm^2)
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd - qd_ls[i] for (i, qd) in bus_qd) + sum(bs for (i, bs) in bus_bs)*vm^2)
end

"Constraint for relating current to power flow"
function constraint_current(pm::GenericPowerModel{T}, n::Int, c::Int, i, f_idx, f_bus, t_bus, tm) where T <: PowerModels.AbstractACPForm
    i_ac_mag = var(pm, n, c, :i_ac_mag)[i] 
    p_fr     = var(pm, n, c, :p)[f_idx]
    q_fr     = var(pm, n, c, :q)[f_idx]
    vm       = var(pm, n, c, :vm)[f_bus]

    @NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)
end

"Constraint for relating current to power flow on/off"
function constraint_current_on_off(pm::GenericPowerModel{T}, n::Int, c::Int, i, ac_max) where T <: PowerModels.AbstractACPForm
    z  = var(pm, n, c, :branch_z)[i]
    i_ac = var(pm, n, c, :i_ac_mag)[i]
    @constraint(pm.model, i_ac <= z * ac_max)
    @constraint(pm.model, i_ac >= z * 0.0)
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection(pm::GenericPowerModel{T}, n::Int, c::Int, i, coeff, ibase) where T <: PowerModels.AbstractACPForm
    i_ac_mag = var(pm, n, c, :i_ac_mag)[i] 
    ieff = var(pm, n, c, :i_dc_mag)[i] 

    @constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))
end

"Constraint for computing qloss"
function constraint_qloss_vnom(pm::GenericPowerModel{T}, n::Int, c::Int, k, i, j, K, branchMVA) where T <: PowerModels.AbstractACPForm
    qloss = var(pm, n, c, :qloss)
    i_dc_mag = var(pm, n, c, :i_dc_mag)[k]
    vm = var(pm, n, c, :vm)[i]

    if getlowerbound(i_dc_mag) > 0.0 || getupperbound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")  
    end

    # K is per phase
    @constraint(pm.model, qloss[(k,i,j)] == K*vm*i_dc_mag/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss"
function constraint_qloss_vnom(pm::GenericPowerModel{T}, n::Int, c::Int, k, i, j) where T <: PowerModels.AbstractACPForm
    qloss = var(pm, n, c, :qloss)
    @constraint(pm.model, qloss[(k,i,j)] == 0.0)
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

