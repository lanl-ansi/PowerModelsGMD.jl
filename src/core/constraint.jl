##### Templated Constraints #######

"Constraint of kcl with shunts"
function constraint_kcl_gmd(pm::PMs.GenericPowerModel, n::Int, c::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)
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

"DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k, kh, ih, jh)
    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    ihi = PMs.var(pm, n, c, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model, ieff >= ihi)
    JuMP.@constraint(pm.model, ieff >= -ihi)
end

"DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k, kh, ih, jh, kl, il, jl, a)
    Memento.debug(LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    ihi = PMs.var(pm, n, c, :dc)[(kh,ih,jh)]
    ilo = PMs.var(pm, n, c, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model, ieff >= (a*ihi + ilo)/a)
    JuMP.@constraint(pm.model, ieff >= -(a*ihi + ilo)/a)
end

"DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k, ks, is, js, kc, ic, jc, a)
    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    is = PMs.var(pm, n, c, :dc)[(ks,is,js)]
    ic = PMs.var(pm, n, c, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model, ieff >= (a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= -(a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= 0.0)
end

"The KCL constraint for DC (GIC) circuits"
function constraint_dc_kcl_shunt(pm::PMs.GenericPowerModel, n::Int, c::Int, i, dc_expr, gs, gmd_bus_arcs)
    v_dc = PMs.var(pm, n, c, :v_dc)[i]
    if length(gmd_bus_arcs) > 0
         if JuMP.getlowerbound(v_dc) > 0 || JuMP.getupperbound(v_dc) < 0
             println("Warning DC voltage cannot go to 0. This could make the DC KCL constraint overly constrained in switching applications")
         end
         JuMP.@constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc) # as long as v_dc can go to 0, this is ok
        return
    end
end

"The DC ohms constraint for GIC"
function constraint_dc_ohms(pm::PMs.GenericPowerModel, n::Int, c::Int, i, f_bus, t_bus, vs, gs)
    vf = PMs.var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt = PMs.var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    dc = PMs.var(pm, n, c, :dc)[(i,f_bus,t_bus)]

    JuMP.@constraint(pm.model, dc == gs*(vf + vs - vt))
end

"Constraint for computing qloss assuming DC voltage is constant"
function constraint_qloss_constant_v(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j, K, V, branchMVA)
    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*V*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss assuming DC voltage is constant"
function constraint_qloss_constant_v(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j)
    qloss = PMs.var(pm, n, c, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for turning generators on and off"
function constraint_gen_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, i, pmin, pmax, qmin, qmax)
    z   = PMs.var(pm, n, c, :gen_z)[i]
    pg  = PMs.var(pm, n, c, :pg)[i]
    qg  = PMs.var(pm, n, c, :qg)[i]

    JuMP.@constraint(pm.model, z * pmin <= pg)
    JuMP.@constraint(pm.model, pg <= z * pmax)
    JuMP.@constraint(pm.model, z * qmin <= qg)
    JuMP.@constraint(pm.model, qg <= z * qmax)
end

"Constraint for tieing ots variables to gen variables"
function constraint_gen_ots_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, i, bus_arcs)
    z   = PMs.var(pm, n, c, :gen_z)[i]
    zb  = PMs.var(pm, n, c, :branch_z)
    JuMP.@constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))
end

"Perspective Constraint for generation cost"
function constraint_gen_perspective(pm::PMs.GenericPowerModel, n::Int, c::Int, i, cost)
    z        = PMs.var(pm, n, c, :gen_z)[i]
    pg_sqr   = PMs.var(pm, n, c, :pg_sqr)[i]
    pg       = PMs.var(pm, n, c, :pg)[i]
    JuMP.@constraint(pm.model, z*pg_sqr >= cost[1]*pg^2)
end

"DC Ohms constraint for GIC"
function constraint_dc_ohms_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, i, gs, vs, f_bus, t_bus, ac_branch)
    vf        = PMs.var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt        = PMs.var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    v_dc_diff = PMs.var(pm, n, c, :v_dc_diff)[i] # voltage diff
    vz        = PMs.var(pm, n, c, :vz)[i] # voltage diff
    dc        = PMs.var(pm, n, c, :dc)[(i,f_bus,t_bus)]
    z         = PMs.var(pm, n, c, :branch_z)[ac_branch]

    JuMP.@constraint(pm.model, v_dc_diff == vf - vt)
    InfrastructureModels.relaxation_product(pm.model, z, v_dc_diff, vz)
    JuMP.@constraint(pm.model, dc == gs*(vz + z*vs) )
end

"On/off DC current on the AC lines"
function constraint_dc_current_mag_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, k, dc_max)
    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    z    = PMs.var(pm, n, c, :branch_z)[k]
    JuMP.@constraint(pm.model, ieff <= z*dc_max)
end

#### Constraints that don't require templates ######

"DC current on normal lines"
function constraint_dc_current_mag_line(pm::PMs.GenericPowerModel, n::Int, c::Int, k)
    ieff = PMs.var(pm, n, c, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)
end
constraint_dc_current_mag_line(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_line(pm, nw, cnd, k)

"DC current on grounded transformers"
function constraint_dc_current_mag_grounded_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k)
    ieff = PMs.var(pm, n, c, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)
end
constraint_dc_current_mag_grounded_xf(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_grounded_xf(pm, nw, cnd, k)

# correct equation is ieff = |a*ihi + ilo|/a
# just use ihi for now
"Constraint for computing the DC current magnitude"
function constraint_dc_current_mag(pm::PMs.GenericPowerModel, n::Int, c::Int, k)
    branch = PMs.ref(pm, n, :branch, k)

    if branch["type"] != "xf"
        constraint_dc_current_mag_line(pm, k, nw=n, cnd=c)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        Memento.debug(LOGGER, "  Ungrounded config, ieff constrained to zero")
        constraint_dc_current_mag_grounded_xf(pm, k, nw=n, cnd=c)
    elseif branch["config"] in ["delta-gwye","gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm, k, nw=n, cnd=c)
    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm, k, nw=n, cnd=c)
    elseif branch["type"] == "xf" && branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm, k, nw=n, cnd=c)
    else
        ieff = PMs.var(pm, n, c, :i_dc_mag)
        JuMP.@constraint(pm.model, ieff[k] >= 0.0)
    end
end
constraint_dc_current_mag(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag(pm, nw, cnd, k)


