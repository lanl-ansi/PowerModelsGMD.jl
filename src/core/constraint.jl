# --- Templated Constraints --- #


"CONSTRAINT: kcl with shunts"
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


"CONSTRAINT: DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k, kh, ih, jh)

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    ihi = PMs.var(pm, n, c, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model, ieff >= ihi)
    JuMP.@constraint(pm.model, ieff >= -ihi)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    ihi = PMs.var(pm, n, c, :dc)[(kh,ih,jh)]
    ilo = PMs.var(pm, n, c, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model, ieff >= (a*ihi + ilo)/a)
    JuMP.@constraint(pm.model, ieff >= -(a*ihi + ilo)/a)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    is = PMs.var(pm, n, c, :dc)[(ks,is,js)]
    ic = PMs.var(pm, n, c, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model, ieff >= (a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= -(a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= 0.0)

end


"CONSTRAINT: the KCL constraint for DC (GIC) circuits"
function constraint_dc_kcl_shunt(pm::PMs.GenericPowerModel, n::Int, c::Int, i, dc_expr, gs, gmd_bus_arcs)

    v_dc = PMs.var(pm, n, c, :v_dc)[i]
    if length(gmd_bus_arcs) > 0
         if JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0
             println("Warning DC voltage cannot go to 0. This could make the DC KCL constraint overly constrained in switching applications")
         end
         JuMP.@constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc) # as long as v_dc can go to 0, this is ok
        return
    end

end


"CONSTRAINT: the DC ohms constraint for GIC"
function constraint_dc_ohms(pm::PMs.GenericPowerModel, n::Int, c::Int, i, f_bus, t_bus, vs, gs)

    vf = PMs.var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt = PMs.var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    dc = PMs.var(pm, n, c, :dc)[(i,f_bus,t_bus)]

    JuMP.@constraint(pm.model, dc == gs*(vf + vs - vt))

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j, K, V, branchMVA)

    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*V*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j)

    qloss = PMs.var(pm, n, c, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: turning generators on and off"
function constraint_gen_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, i, pmin, pmax, qmin, qmax)

    z   = PMs.var(pm, n, c, :gen_z)[i]
    pg  = PMs.var(pm, n, c, :pg)[i]
    qg  = PMs.var(pm, n, c, :qg)[i]

    JuMP.@constraint(pm.model, z * pmin <= pg)
    JuMP.@constraint(pm.model, pg <= z * pmax)
    JuMP.@constraint(pm.model, z * qmin <= qg)
    JuMP.@constraint(pm.model, qg <= z * qmax)

end


"CONSTRAINT: tieing ots variables to gen variables"
function constraint_gen_ots_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, i, bus_arcs)

    z   = PMs.var(pm, n, c, :gen_z)[i]
    zb  = PMs.var(pm, n, c, :branch_z)
    JuMP.@constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))

end


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::PMs.GenericPowerModel, n::Int, c::Int, i, cost)

    z        = PMs.var(pm, n, c, :gen_z)[i]
    pg_sqr   = PMs.var(pm, n, c, :pg_sqr)[i]
    pg       = PMs.var(pm, n, c, :pg)[i]
    JuMP.@constraint(pm.model, z*pg_sqr >= cost[1]*pg^2)

end


"CONSTRAINT: DC Ohms constraint for GIC"
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


"CONSTRAINT: on/off DC current on the AC lines"
function constraint_dc_current_mag_on_off(pm::PMs.GenericPowerModel, n::Int, c::Int, k, dc_max)

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    z    = PMs.var(pm, n, c, :branch_z)[k]
    JuMP.@constraint(pm.model, ieff <= z*dc_max)

end




# --- Non-Templated Constraints --- #


"CONSTRAINT: DC current on normal lines"
function constraint_dc_current_mag_line(pm::PMs.GenericPowerModel, n::Int, c::Int, k)
    ieff = PMs.var(pm, n, c, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)
end
constraint_dc_current_mag_line(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_line(pm, nw, cnd, k)


"CONSTRAINT: DC current on grounded transformers"
function constraint_dc_current_mag_grounded_xf(pm::PMs.GenericPowerModel, n::Int, c::Int, k)
    ieff = PMs.var(pm, n, c, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)
end
constraint_dc_current_mag_grounded_xf(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_grounded_xf(pm, nw, cnd, k)


"CONSTRAINT: computing the DC current magnitude"
function constraint_dc_current_mag(pm::PMs.GenericPowerModel, n::Int, c::Int, k)
    
    # correct equation is ieff = |a*ihi + ilo|/a
    # just use ihi for now
    
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




# --- Decoupled Formulation Constraints --- #


"CONSTRAINT: computing qloss accounting for ac voltage"
function constraint_qloss_decoupled(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j, ih, K, ieff, branchMVA)

    # This is what is called for each branch
    # constraint_qloss(pm, n, c, k, i, j, K, ieff, branchMVA)

    qloss = PMs.var(pm, n, c, :qloss)
    v = PMs.var(pm, n, c, :vm)[ih] # ih is the index of the high-side bus

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*v*ieff/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming 1.0 pu ac voltage"
function constraint_qloss_decoupled_vnom(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j, K, ieff, branchMVA)

    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*ieff/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss"
function constraint_zero_qloss(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j)

    qloss = PMs.var(pm, n, c, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is 1.0 pu"
function constraint_qloss_vnom(pm::PMs.GenericPowerModel, n::Int, c::Int, k, i, j, K, branchMVA)

    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    # Assume that V = 1.0 pu
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    branch = ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = PMs.ref(pm, nw, :bus, i)
    branchMVA = branch["baseMVA"]

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        ih = branch["hi_bus"]
        constraint_qloss_decoupled(pm, nw, cnd, k, i, j, ih, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, cnd, k, i, j)
    end

end


"CONSTRAINT:  computing qloss assuming ac voltage is 1.0 pu"
function constraint_qloss_decoupled_vnom(pm::PMs.GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    branch = PMs.ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = PMs.ref(pm, nw, :bus, i)
    branchMVA = branch["baseMVA"]

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        constraint_qloss_decoupled_vnom(pm, nw, cnd, k, i, j, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, cnd, k, i, j)
    end

end




# --- Thermal Constraints --- #


"CONSTRAINT: top-oil temperature rise"
# Todo: break up into init & regular
function constraint_delta_topoilrise(pm::PMs.GenericPowerModel, n::Int, c::Int; tau_oil, Delta_t, delta_topoilrise_prev, delta_topoilrise_ss_prev)

    tau = 2*tau_oil/Delta_t

    # Variables:
    delta_topoilrise =  PMs.var(pm, n, c, :tor)
    delta_topoilrise_ss = PMs.var(pm, n, c, :torss)
    
    # Constraint:
    JuMP.@constraint(pm.model, (delta_topoilrise <= ((delta_topoilrise_ss + delta_topoilrise_ss_prev)/(1 + tau) - delta_topoilrise_prev*(1 - tau)/(1 + tau))))

end


"CONSTRAINT: steady-state top-oil temperature rise"
function constraint_delta_topoilrise_ss(pm::PMs.GenericPowerModel, n::Int, c::Int; base_mva, delta_oil_rated, f_idx, t_idx, rate_a)

    # FROM end
    p_from = PMs.var(pm, n, c, :p, f_idx)
    q_from = PMs.var(pm, n, c, :p, f_idx)
    S_from = sqrt(p_from^2 + q_from^2)
    K_from = S_from / (rate_a * base_mva)
    
    # TO end
    p_to = PMs.var(pm, n, c, :p, t_idx)
    q_to = PMs.var(pm, n, c, :p, t_idx)
    S_to = sqrt(p_to^2 + q_to^2)
    K_to = S_to / (rate_a * base_mva)

    # Variables:
    delta_topoilrise_ss = PMs.var(pm, n, c, :torss)

    # Constraints:
    JuMP.@constraint(pm.model, ((S_from^2) <= (rate_a^2)))
    JuMP.@constraint(pm.model, ((S_to^2) <= (rate_a^2)))

    JuMP.@constraint(pm.model, (delta_topoilrise_ss >= (delta_oil_rated * K_from^2)))
    JuMP.@constraint(pm.model, (delta_topoilrise_ss >= (delta_oil_rated * K_to^2)))

end


"CONSTRAINT: hotspot temperature rise"
function constraint_delta_hotspotrise_initital(pm::PMs.GenericPowerModel, n::Int, c::Int; Re)

    # Variables:
    Ie = PMs.var(pm, n, c, :i_dc_mag)

    # Constraints:
    JuMP.@constraint(pm.model, (delta_hotspotrise <= (Re*Ie)))
end

function constraint_delta_hotspotrise(pm::PMs.GenericPowerModel, n::Int, c::Int; tau_hs, Delta_t, Re, delta_hotspotrise_prev)

    tau = 2*tau_hs/Delta_t

    # Variables:
    Ie = PMs.var(pm, n, c, :i_dc_mag)

    # Constraints:

    JuMP.@constraint(pm.model, (delta_hotspotrise <= (Re*(Ie + Ie_prev)/(1 + tau) - delta_hotspotrise_prev*(1 - tau)/(1 + tau))))

end


"CONSTRAINT: steady-state hotspot temperature rise"
function constraint_delta_hotspotrise_ss(pm::PMs.GenericPowerModel, n::Int, c::Int; Re)

    # Variables:
    Ie = PMs.var(pm, n, c, :i_dc_mag)

    # Constraints:
    JuMP.@constraint(pm.model, (delta_hotspotrise_ss <= (Re*Ie)))

end





