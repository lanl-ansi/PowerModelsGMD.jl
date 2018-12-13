##### Templated Constraints #######

"Constraint of kcl with shunts"
function constraint_kcl_gic{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)
    p = var(pm, n, c, :p)
    q = var(pm, n, c, :q)
    pg = var(pm, n, c, :pg)
    qg = var(pm, n, c, :qg)
    qloss = var(pm, n, c, :qloss)

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    @constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd for (i, pd) in bus_pd))
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd for (i, qd) in bus_qd))
end

"DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k, kh, ih, jh)
    ieff = var(pm, n, c, :i_dc_mag)[k]
    ihi = var(pm, n, c, :dc)[(kh,ih,jh)]

    @constraint(pm.model, ieff >= ihi)
    @constraint(pm.model, ieff >= -ihi)
end

"DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k, kh, ih, jh, kl, il, jl, a)
    debug(LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = var(pm, n, c, :i_dc_mag)[k]
    ihi = var(pm, n, c, :dc)[(kh,ih,jh)]
    ilo = var(pm, n, c, :dc)[(kl,il,jl)]

    @constraint(pm.model, ieff >= (a*ihi + ilo)/a)
    @constraint(pm.model, ieff >= -(a*ihi + ilo)/a)
end

"DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k, ks, is, js, kc, ic, jc, a)
    ieff = var(pm, n, c, :i_dc_mag)[k]
    is = var(pm, n, c, :dc)[(ks,is,js)]
    ic = var(pm, n, c, :dc)[(kc,ic,jc)]

    @constraint(pm.model, ieff >= (a*is + ic)/(a + 1.0))
    @constraint(pm.model, ieff >= -(a*is + ic)/(a + 1.0))
    @constraint(pm.model, ieff >= 0.0)
end

"The KCL constraint for DC (GIC) circuits"
function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, dc_expr, gs, gmd_bus_arcs)
    v_dc = var(pm, n, c, :v_dc)[i]
    if length(gmd_bus_arcs) > 0
         if getlowerbound(v_dc) > 0 || getupperbound(v_dc) < 0
             println("Warning DC voltage cannot go to 0. This could make the DC KCL constraint overly constrained in switching applications")  
         end 
         @constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc) # as long as v_dc can go to 0, this is ok
        return
    end
end

"The DC ohms constraint for GIC"
function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, f_bus, t_bus, vs, gs)
    vf = var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt = var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    dc = var(pm, n, c, :dc)[(i,f_bus,t_bus)]

    @constraint(pm.model, dc == gs*(vf + vs - vt))  
end

"Constraint for computing qloss assuming ac primary voltage is constant"
function constraint_qloss_vnom{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k, i, j, K, branchMVA)
    i_dc_mag = var(pm, n, c, :i_dc_mag)[k]
    qloss = var(pm, n, c, :qloss)

    # K is per phase
    # Assume that V = 1.0 pu
    @constraint(pm.model, qloss[(k,i,j)] == K*i_dc_mag/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

#"Constraint for computing qloss assuming ac primary voltage is constant"
#function constraint_qloss_vnom{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k, i, j)
#    qloss = var(pm, n, c, :qloss)
#
#    @constraint(pm.model, qloss[(k,i,j)] == 0.0)
#    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
#end

"Constraint for turning generators on and off"
function constraint_gen_on_off{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, pmin, pmax, qmin, qmax)
    z   = var(pm, n, c, :gen_z)[i]
    pg  = var(pm, n, c, :pg)[i]
    qg  = var(pm, n, c, :qg)[i]

    @constraint(pm.model, z * pmin <= pg)
    @constraint(pm.model, pg <= z * pmax)
    @constraint(pm.model, z * qmin <= qg)
    @constraint(pm.model, qg <= z * qmax)
end

"Constraint for tieing ots variables to gen variables"
function constraint_gen_ots_on_off{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, bus_arcs)
    z   = var(pm, n, c, :gen_z)[i]
    zb  = var(pm, n, c, :branch_z)
    @constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))
end

"Perspective Constraint for generation cost"
function constraint_gen_perspective{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, cost)
    z        = var(pm, n, c, :gen_z)[i]
    pg_sqr   = var(pm, n, c, :pg_sqr)[i]
    pg       = var(pm, n, c, :pg)[i]
    @constraint(pm.model, z*pg_sqr >= cost[1]*pg^2)
end

"DC Ohms constraint for GIC"
function constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, n::Int, c::Int, i, gs, vs, f_bus, t_bus, ac_branch)
    vf        = var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt        = var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    v_dc_diff = var(pm, n, c, :v_dc_diff)[i] # voltage diff
    vz        = var(pm, n, c, :vz)[i] # voltage diff
    dc        = var(pm, n, c, :dc)[(i,f_bus,t_bus)]
    z         = var(pm, n, c, :branch_z)[ac_branch]

    @constraint(pm.model, v_dc_diff == vf - vt)
    InfrastructureModels.relaxation_product(pm.model, z, v_dc_diff, vz)
    @constraint(pm.model, dc == gs*(vz + z*vs) )
end

"On/off DC current on the AC lines"
function constraint_dc_current_mag_on_off{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k, dc_max)
    ieff = var(pm, n, c, :i_dc_mag)[k]
    z    = var(pm, n, c, :branch_z)[k]
    @constraint(pm.model, ieff <= z*dc_max)
end

#### Constraints that don't require templates ######

"DC current on normal lines"
function constraint_dc_current_mag_line{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k)
    ieff = var(pm, n, c, :i_dc_mag)
    @constraint(pm.model, ieff[k] >= 0.0)
end
constraint_dc_current_mag_line{T}(pm::GenericPowerModel{T}, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_line(pm, nw, cnd, k)

"DC current on grounded transformers"
function constraint_dc_current_mag_grounded_xf{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k)
    ieff = var(pm, n, c, :i_dc_mag)
    @constraint(pm.model, ieff[k] >= 0.0)
end
constraint_dc_current_mag_grounded_xf{T}(pm::GenericPowerModel{T}, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_grounded_xf(pm, nw, cnd, k)

# correct equation is ieff = |a*ihi + ilo|/a
# just use ihi for now
"Constraint for computing the DC current magnitude"
function constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, n::Int, c::Int, k)
    branch = ref(pm, n, :branch, k)

    if branch["type"] != "xf"
        constraint_dc_current_mag_line(pm, k, nw=n, cnd=c)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        debug(LOGGER, "  Ungrounded config, ieff constrained to zero")
        constraint_dc_current_mag_grounded_xf(pm, k, nw=n, cnd=c)
    elseif branch["config"] in ["delta-gwye","gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm, k, nw=n, cnd=c)
    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm, k, nw=n, cnd=c)
    elseif branch["type"] == "xf" && branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm, k, nw=n, cnd=c)
    else
        ieff = var(pm, n, c, :i_dc_mag)
        @constraint(pm.model, ieff[k] >= 0.0)
    end
end
constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag(pm, nw, cnd, k)


#### Constraints for the decoupled formulation ####

# This is what is called for each branch
# constraint_qloss(pm, n, c, k, i, j, K, ieff, branchMVA)
"Constraint for computing qloss accounting for ac voltage"
function constraint_qloss(pm, n::Int, c::Int, k, i, j, ih, K, ieff, branchMVA)
    qloss = var(pm, n, c, :qloss)
    v = var(pm, n, c, :vm)[ih] # ih is the index of the high-side bus

    # K is per phase
    @constraint(pm.model, qloss[(k,i,j)] == K*v*ieff/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end


"Constraint for computing qloss assuming 1.0 pu ac voltage"
function constraint_qloss_vnom(pm, n::Int, c::Int, k, i, j, K, ieff, branchMVA)
    qloss = var(pm, n, c, :qloss)

    # K is per phase
    @constraint(pm.model, qloss[(k,i,j)] == K*ieff/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end


"Constraint for computing qloss"
function constraint_zero_qloss(pm::GenericPowerModel, n::Int, c::Int, k, i, j)
    qloss = var(pm, n, c, :qloss)

    @constraint(pm.model, qloss[(k,i,j)] == 0.0)
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end


"Constraint for computing qloss assuming varying ac voltage"
function constraint_qloss(pm::GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = ref(pm, nw, :bus, i)
    branchMVA = branch["baseMVA"]

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        ih = branch["hi_bus"]
        constraint_qloss(pm, nw, cnd, k, i, j, ih, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, cnd, k, i, j)
    end
end


"Constraint for computing qloss assuming ac voltage is 1.0 pu"
function constraint_qloss_vnom(pm::GenericPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = ref(pm, nw, :bus, i)
    branchMVA = branch["baseMVA"]

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        constraint_qloss_vnom(pm, nw, cnd, k, i, j, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, cnd, k, i, j)
    end
end

