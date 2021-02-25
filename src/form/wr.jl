
"FUNCTION: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractWRModel; kwargs...)
   variable_ac_current_mag(pm; bounded=false, kwargs...)
   # needs to be false since this is an on/off variable
end


"FUNCTION: ac current"
function variable_ac_current(pm::_PM.AbstractWRModel; kwargs...)

   variable_ac_current_mag(pm; kwargs...)

   nw = pm.cnw

   parallel_branch = Dict(x for x in _PM.ref(pm, nw, :branch) if _PM.ref(pm, nw, :buspairs)[(x.second["f_bus"], x.second["t_bus"])]["branch"] != x.first)
   cm_min = Dict((l, 0) for l in keys(parallel_branch))
   cm_max = Dict((l, (branch["rate_a"]*branch["tap"]/_PM.ref(pm, nw, :bus)[branch["f_bus"]]["vmin"])^2) for (l, branch) in parallel_branch)

   _PM.var(pm, nw)[:cm_p] = JuMP.@variable(pm.model,
        [l in keys(parallel_branch)], base_name="$(nw)_cm_p",
        lower_bound = cm_min[l],
        upper_bound = cm_max[l],
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "cm_p_start")
   )

end


"FUNCTION: dc current"
function variable_dc_current(pm::_PM.AbstractWRModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
    variable_dc_current_mag_sqr(pm; kwargs...)
end


"FUNCTION: reactive loss"
function variable_reactive_loss(pm::_PM.AbstractWRModel; kwargs...)
    variable_qloss(pm; kwargs...)
    variable_iv(pm; kwargs...)
end


"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w[i] + pd_ls
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w[i] + qd_ls - qloss
```
"""


"CONSTRAINT: kcl with shunts for load shedding"
function constraint_kcl_shunt_gmd_ls(pm::_PM.AbstractWRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    w = _PM.var(pm, n, :w)[i]
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)

    qloss = _PM.var(pm, n, :qloss)
    pd_ls = _PM.var(pm, n, :pd)
    qd_ls = _PM.var(pm, n, :qd)

    if length(bus_arcs) > 0 || length(bus_gens) > 0 || length(bus_pd) > 0 || length(bus_gs) > 0
        JuMP.@constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd - pd_ls[i] for (i, pd) in bus_pd) - sum(gs for (i, gs) in bus_gs)*w)
    end

    if length(bus_arcs) > 0 || length(bus_gens) > 0 || length(bus_qd) > 0 || length(bus_bs) > 0
        JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd - qd_ls[i] for (i, qd) in bus_qd) + sum(bs for (i, bs) in bus_bs)*w)
    end

end


"CONSTRAINT: kcl with shunts"
function constraint_kcl_gmd(pm::_PM.AbstractWRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    qloss = _PM.var(pm, n, :qloss)

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    JuMP.@constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd for (i, pd) in bus_pd))
    JuMP.@constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd for (i, qd) in bus_qd))

end


"CONSTRAINT: relating current to power flow"
function constraint_current(pm::_PM.AbstractWRModel, n::Int, i, f_idx, f_bus, t_bus, tm)

    pair = (f_bus, t_bus)
    buspair = _PM.ref(pm, n, :buspairs, pair)
    arc_from = (i, f_bus, t_bus)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]

    if buspair["branch"] == i
        # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl
        l = _PM.var(pm, n, :ccm)[(f_bus, t_bus)]
        InfrastructureModels.relaxation_sqr(pm.model, i_ac_mag, l)
    else
        l = _PM.var(pm, n, :cm_p)[i]
        w = _PM.var(pm, n, :w)[f_bus]
        p_fr = _PM.var(pm, n, :p)[arc_from]
        q_fr = _PM.var(pm, n, :q)[arc_from]

        JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= l * w)
        InfrastructureModels.relaxation_sqr(pm.model, i_ac_mag, l)
    end

end


"CONSTRAINT: relating current to power flow on_off"
function constraint_current_on_off(pm::_PM.AbstractWRModel, n::Int, i, ac_ub)

    ac_lb = 0 # this implementation of the on/off relaxation is only valid for lower bounds of 0

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    l = _PM.var(pm, n, :ccm)[i]
    z = _PM.var(pm, n, :z_branch)[i]

    # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl
    JuMP.@constraint(pm.model, l >= i_ac_mag^2)
    JuMP.@constraint(pm.model, l <= ac_ub*i_ac_mag)

    JuMP.@constraint(pm.model, i_ac_mag <= z * ac_ub)
    JuMP.@constraint(pm.model, i_ac_mag >= z * ac_lb)

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractWRModel, n::Int, i, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    ieff_sqr = _PM.var(pm, n, :i_dc_mag_sqr)[i]

    JuMP.@constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff_sqr/(ibase^2))
    InfrastructureModels.relaxation_sqr(pm.model, ieff, ieff_sqr)

end


"CONSTRAINT: computing qloss"
function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)
    iv = _PM.var(pm, n, :iv)[(k,i,j)]
    vm = _PM.var(pm, n, :vm)[i]

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
    InfrastructureModels.relaxation_product(pm.model, i_dc_mag, vm, iv)

end


"CONSTRAINT: computing qloss"
function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j, K, branchMVA)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)
    iv = _PM.var(pm, n, :iv)[(k,i,j)]
    vm = _PM.var(pm, n, :vm)[i]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")
    end

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*iv/(3.0*branchMVA)) #K is per phase
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
    InfrastructureModels.relaxation_product(pm.model, i_dc_mag, vm, iv)

end


