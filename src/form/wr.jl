
"default SOC constructor"
SOCWRPowerModel(data::Dict{String,Any}; kwargs...) = GenericGMDPowerModel(data, PMs.SOCWRForm; kwargs...)

"default QC constructor"
function QCWRPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, PMs.QCWRForm; kwargs...)
end

"default QC trilinear model constructor"
function QCWRTriPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, PMs.QCWRTriForm; kwargs...)
end

""
function variable_ac_current_on_off(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractWRForm
   variable_ac_current_mag(pm; bounded=false, kwargs...) # needs to be false since this is an on/off variable
end

""
function variable_ac_current(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractWRForm
   variable_ac_current_mag(pm; kwargs...)

   nw = pm.cnw
   cnd = pm.ccnd

   parallel_branch = Dict(x for x in PMs.ref(pm, nw, :branch) if PMs.ref(pm, nw, :buspairs)[(x.second["f_bus"], x.second["t_bus"])]["branch"] != x.first)
   cm_min = Dict((l, 0) for l in keys(parallel_branch))
   cm_max = Dict((l, (branch["rate_a"]*branch["tap"]/PMs.ref(pm, nw, :bus)[branch["f_bus"]]["vmin"])^2) for (l, branch) in parallel_branch)

   PMs.var(pm, nw, cnd)[:cm_p] = JuMP.@variable(pm.model,
        [l in keys(parallel_branch)], basename="$(nw)_$(cnd)_cm_p",
        lowerbound = cm_min[l],
        upperbound = cm_max[l],
        start = PMs.getval(PMs.ref(pm, nw, :branch, l), "cm_p_start", cnd)
   )
end

""
function variable_dc_current(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractWRForm
    variable_dc_current_mag(pm; kwargs...)
    variable_dc_current_mag_sqr(pm; kwargs...)
end

""
function variable_reactive_loss(pm::PMs.GenericPowerModel{T}; kwargs...) where T <: PowerModels.AbstractWRForm
    variable_qloss(pm; kwargs...)
    variable_iv(pm; kwargs...)
end

"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w[i] + pd_ls
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w[i] + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gmd_ls(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs) where T <: PowerModels.AbstractWRForm
    w = PMs.var(pm, n, c, :w)[i]
    pg = PMs.var(pm, n, c, :pg)
    qg = PMs.var(pm, n, c, :qg)
    p = PMs.var(pm, n, c, :p)
    q = PMs.var(pm, n, c, :q)

    qloss = PMs.var(pm, n, c, :qloss)
    pd_ls = PMs.var(pm, n, c, :pd)
    qd_ls = PMs.var(pm, n, c, :qd)

    JuMP.@constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd - pd_ls[i] for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*w)
    JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd - qd_ls[i] for (i, qd) in bus_qd) + sum(bs for (i, bs) in bus_bs)*w)

end

"Constraint for relating current to power flow"
function constraint_current(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, f_idx, f_bus, t_bus, tm) where T <: PowerModels.AbstractWRForm
    pair = (f_bus, t_bus)
    buspair = PMs.ref(pm, n, :buspairs, pair)
    arc_from = (i, f_bus, t_bus)

    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]

    if buspair["branch"] == i
        # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl
        l = PMs.var(pm, n, c, :cm)[(f_bus, t_bus)]
        InfrastructureModels.relaxation_sqr(pm.model, i_ac_mag, l)
    else
        l = PMs.var(pm, n, c, :cm_p)[i]
        w = PMs.var(pm, n, c, :w)[f_bus]
        p_fr = PMs.var(pm, n, c, :p)[arc_from]
        q_fr = PMs.var(pm, n, c, :q)[arc_from]

        JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= l * w)
        InfrastructureModels.relaxation_sqr(pm.model, i_ac_mag, l)
    end
end

"Constraint for relating current to power flow on_off"
function constraint_current_on_off(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, ac_ub) where T <: PowerModels.AbstractWRForm
    ac_lb    = 0 # this implementation of the on/off relaxation is only valid for lower bounds of 0

    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    l        = PMs.var(pm, n, c, :cm)[i]
    z        = PMs.var(pm, n, c, :branch_z)[i]

    # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl
    JuMP.@constraint(pm.model, l >= i_ac_mag^2)
    JuMP.@constraint(pm.model, l <= ac_ub*i_ac_mag)

    JuMP.@constraint(pm.model, i_ac_mag <= z * ac_ub)
    JuMP.@constraint(pm.model, i_ac_mag >= z * ac_lb)
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, i, coeff, ibase) where T <: PowerModels.AbstractWRForm
    i_ac_mag = PMs.var(pm, n, c, :i_ac_mag)[i]
    ieff = PMs.var(pm, n, c, :i_dc_mag)[i]
    ieff_sqr = PMs.var(pm, n, c, :i_dc_mag_sqr)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff_sqr/(ibase^2))
    InfrastructureModels.relaxation_sqr(pm.model, ieff, ieff_sqr)
end

"Constraint for computing qloss"
function constraint_qloss(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, k, i, j) where T <: PowerModels.AbstractWRForm
    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)
    iv = PMs.var(pm, n, c, :iv)[(k,i,j)]
    vm = PMs.var(pm, n, c, :vm)[i]

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
    InfrastructureModels.relaxation_product(pm.model, i_dc_mag, vm, iv)
end

"Constraint for computing qloss"
function constraint_qloss(pm::PMs.GenericPowerModel{T}, n::Int, c::Int, k, i, j, K, branchMVA) where T <: PowerModels.AbstractWRForm
    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)
    iv = PMs.var(pm, n, c, :iv)[(k,i,j)]
    vm = PMs.var(pm, n, c, :vm)[i]

    if JuMP.getlowerbound(i_dc_mag) > 0.0 || JuMP.getupperbound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")
    end

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*iv/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
    InfrastructureModels.relaxation_product(pm.model, i_dc_mag, vm, iv)
end
