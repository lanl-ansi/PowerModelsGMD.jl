# --- Templated Constraints --- #


"CONSTRAINT: DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, kh, ih, jh)

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    ihi = PMs.var(pm, n, c, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model, ieff >= ihi)
    JuMP.@constraint(pm.model, ieff >= -ihi)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    ihi = PMs.var(pm, n, c, :dc)[(kh,ih,jh)]
    ilo = PMs.var(pm, n, c, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model, ieff >= (a*ihi + ilo)/a)
    JuMP.@constraint(pm.model, ieff >= -(a*ihi + ilo)/a)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    is = PMs.var(pm, n, c, :dc)[(ks,is,js)]
    ic = PMs.var(pm, n, c, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model, ieff >= (a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= -(a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= 0.0)

end


"CONSTRAINT: KCL for DC (GIC) circuits"
function constraint_dc_kcl_shunt(pm::PMs.AbstractPowerModel, n::Int, c::Int, i, dc_expr, gs, gmd_bus_arcs)

    v_dc = PMs.var(pm, n, c, :v_dc)[i]
    if length(gmd_bus_arcs) > 0
         if JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0
             println("Warning DC voltage cannot go to 0. This could make the DC KCL constraint overly constrained in switching applications")
         end
         JuMP.@constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc) # as long as v_dc can go to 0, this is ok
        return
    end

end


"CONSTRAINT: DC ohms for GIC"
function constraint_dc_ohms(pm::PMs.AbstractPowerModel, n::Int, c::Int, i, f_bus, t_bus, vs, gs)

    vf = PMs.var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt = PMs.var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    dc = PMs.var(pm, n, c, :dc)[(i,f_bus,t_bus)]

    JuMP.@constraint(pm.model, dc == gs*(vf + vs - vt))

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, i, j, K, V, branchMVA)

    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*V*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, i, j)

    qloss = PMs.var(pm, n, c, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: turning generators on and off"
function constraint_gen_on_off(pm::PMs.AbstractPowerModel, n::Int, c::Int, i, pmin, pmax, qmin, qmax)

    z   = PMs.var(pm, n, c, :gen_z)[i]
    pg  = PMs.var(pm, n, c, :pg)[i]
    qg  = PMs.var(pm, n, c, :qg)[i]

    JuMP.@constraint(pm.model, z * pmin <= pg)
    JuMP.@constraint(pm.model, pg <= z * pmax)
    JuMP.@constraint(pm.model, z * qmin <= qg)
    JuMP.@constraint(pm.model, qg <= z * qmax)

end


"CONSTRAINT: tieing ots variables to gen variables"
function constraint_gen_ots_on_off(pm::PMs.AbstractPowerModel, n::Int, c::Int, i, bus_arcs)

    z   = PMs.var(pm, n, c, :gen_z)[i]
    zb  = PMs.var(pm, n, :z_branch)
    JuMP.@constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))

end


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::PMs.AbstractPowerModel, n::Int, c::Int, i, cost)

    z        = PMs.var(pm, n, c, :gen_z)[i]
    pg_sqr   = PMs.var(pm, n, c, :pg_sqr)[i]
    pg       = PMs.var(pm, n, c, :pg)[i]
    JuMP.@constraint(pm.model, z*pg_sqr >= cost[1]*pg^2)

end


"CONSTRAINT: DC Ohms constraint for GIC"
function constraint_dc_ohms_on_off(pm::PMs.AbstractPowerModel, n::Int, c::Int, i, gs, vs, f_bus, t_bus, ac_branch)

    vf        = PMs.var(pm, n, c, :v_dc)[f_bus] # from dc voltage
    vt        = PMs.var(pm, n, c, :v_dc)[t_bus] # to dc voltage
    v_dc_diff = PMs.var(pm, n, c, :v_dc_diff)[i] # voltage diff
    vz        = PMs.var(pm, n, c, :vz)[i] # voltage diff
    dc        = PMs.var(pm, n, c, :dc)[(i,f_bus,t_bus)]
    z         = PMs.var(pm, n, :z_branch)[ac_branch]

    JuMP.@constraint(pm.model, v_dc_diff == vf - vt)
    InfrastructureModels.relaxation_product(pm.model, z, v_dc_diff, vz)
    JuMP.@constraint(pm.model, dc == gs*(vz + z*vs) )

end


"CONSTRAINT: on/off DC current on the AC lines"
function constraint_dc_current_mag_on_off(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, dc_max)

    ieff = PMs.var(pm, n, c, :i_dc_mag)[k]
    z    = PMs.var(pm, n, :z_branch)[k]
    JuMP.@constraint(pm.model, ieff <= z*dc_max)

end



# --- Non-Templated Constraints --- #


"CONSTRAINT: DC current on normal lines"
function constraint_dc_current_mag_line(pm::PMs.AbstractPowerModel, n::Int, c::Int, k)

    ieff = PMs.var(pm, n, c, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)

end
constraint_dc_current_mag_line(pm::PMs.AbstractPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_line(pm, nw, cnd, k)


"CONSTRAINT: DC current on grounded transformers"
function constraint_dc_current_mag_grounded_xf(pm::PMs.AbstractPowerModel, n::Int, c::Int, k)

    ieff = PMs.var(pm, n, c, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)

end
constraint_dc_current_mag_grounded_xf(pm::PMs.AbstractPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag_grounded_xf(pm, nw, cnd, k)


"CONSTRAINT: computing the DC current magnitude"
function constraint_dc_current_mag(pm::PMs.AbstractPowerModel, n::Int, c::Int, k)

    # correct equation is ieff = |a*ihi + ilo|/a
    # just use ihi for now
    
    branch = PMs.ref(pm, n, :branch, k)

    if branch["type"] != "xfmr"
        constraint_dc_current_mag_line(pm, k, nw=n, cnd=c)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        Memento.debug(LOGGER, "  Ungrounded config, ieff constrained to zero")
        constraint_dc_current_mag_grounded_xf(pm, k, nw=n, cnd=c)
    elseif branch["config"] in ["delta-gwye","gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm, k, nw=n, cnd=c)
    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm, k, nw=n, cnd=c)
    elseif branch["type"] == "xfmr" && branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm, k, nw=n, cnd=c)
    else
        ieff = PMs.var(pm, n, c, :i_dc_mag)
        JuMP.@constraint(pm.model, ieff[k] >= 0.0)
    end

end
constraint_dc_current_mag(pm::PMs.AbstractPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd) = constraint_dc_current_mag(pm, nw, cnd, k)



# --- Decoupled Formulation Constraints --- #


"CONSTRAINT: computing qloss accounting for ac voltage"
function constraint_qloss_decoupled(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, i, j, ih, K, ieff, branchMVA)

    # This is what is called for each branch
    # constraint_qloss(pm, n, c, k, i, j, K, ieff, branchMVA)

    qloss = PMs.var(pm, n, c, :qloss)
    v = PMs.var(pm, n, c, :vm)[ih] # ih is the index of the high-side bus

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*v*ieff/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming 1.0 pu ac voltage"
function constraint_qloss_decoupled_vnom(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, i, j, K, ieff, branchMVA)

    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*ieff/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss"
function constraint_zero_qloss(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, i, j)

    qloss = PMs.var(pm, n, c, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is 1.0 pu"
function constraint_qloss_vnom(pm::PMs.AbstractPowerModel, n::Int, c::Int, k, i, j, K, branchMVA)

    i_dc_mag = PMs.var(pm, n, c, :i_dc_mag)[k]
    qloss = PMs.var(pm, n, c, :qloss)

    # K is per phase
    # Assume that V = 1.0 pu
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::PMs.AbstractPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

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
function constraint_qloss_decoupled_vnom(pm::PMs.AbstractPowerModel, k; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    branch = PMs.ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = PMs.ref(pm, nw, :bus, i)

    if ("gmd_k" in keys(branch)) && ("baseMVA" in keys(branch))
        branchMVA = branch["baseMVA"]
        ibase = branchMVA*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        constraint_qloss_decoupled_vnom(pm, nw, cnd, k, i, j, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, cnd, k, i, j)
    end

end



# --- Thermal Constraints --- #


"CONSTRAINT: steady-state temperature"
#TODO: check if types are correct
function constraint_temperature_steady_state(pm::PMs.AbstractPowerModel, n::Int, i::Int, fi, c::Int, rate_a, delta_oil_rated)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = PMs.var(pm, n, c, :p, fi) # real power
    q_fr = PMs.var(pm, n, c, :q, fi) # reactive power
    delta_oil_ss = PMs.var(pm, n, c, :ross, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)
    # println("Branch $i[$n] delta_hotspot_ss = 100")
    # JuMP.@constraint(pm.model, delta_oil_ss == 150)

end


"CONSTRAINT: steady-state temperature"
#TODO: check if types are correct
function constraint_temperature_steady_state(pm::PMs.AbstractDCPModel, n::Int, i::Int, fi, c::Int, rate_a, delta_oil_rated)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = PMs.var(pm, n, c, :p, fi) # real power
    delta_oil_ss = PMs.var(pm, n, c, :ross, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, sqrt(rate_a)*delta_oil_ss/sqrt(delta_oil_rated) >= p_fr)
    # println("Branch $i[$n] delta_hotspot_ss = 100")
    # JuMP.@constraint(pm.model, delta_oil_ss == 150)

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::PMs.AbstractPowerModel, n::Int, i::Int, fi, c::Int)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    # assume that transformer starts at equilibrium 
    delta_oil = var(pm, n, c, :ro, i) 
    delta_oil_ss = var(pm, n, c, :ross, i) 
    JuMP.@constraint(pm.model, delta_oil == delta_oil_ss)

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::PMs.AbstractPowerModel, n::Int, i::Int, fi, c::Int, delta_oil_init)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    delta_oil = var(pm, n, c, :ro, i) 
    JuMP.@constraint(pm.model, delta_oil == delta_oil_init)

end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::PMs.AbstractPowerModel, n_1::Int, n_2::Int, i::Int, c::Int, tau)

    delta_oil_ss = var(pm, n_2, c, :ross, i) 
    delta_oil_ss_prev = var(pm, n_1, c, :ross, i)
    delta_oil = var(pm, n_2, c, :ro, i) 
    delta_oil_prev = var(pm, n_1, c, :ro, i)

    JuMP.@constraint(pm.model, (1 + tau)*delta_oil == delta_oil_ss + delta_oil_ss_prev - (1 - tau)*delta_oil_prev)
    # @constraint(pm.model, delta_oil == delta_oil_ss)

end


"CONSTRAINT: steady-state hot-spot temperature"
function constraint_hotspot_temperature_steady_state(pm::PMs.AbstractPowerModel, n::Int, i::Int, fi, c::Int, rate_a, Re)
    # return delta_oil_rated*K^2
    # println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    ieff = PMs.var(pm, n, c, :i_dc_mag)[i]
    delta_hotspot_ss = PMs.var(pm, n, c, :hsss, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, delta_hotspot_ss == Re*ieff)
    # JuMP.@constraint(pm.model, delta_hotspot_ss == 100)

end


"CONSTRAINT: hot-spot temperature"
function constraint_hotspot_temperature(pm::PMs.AbstractPowerModel, n::Int, i::Int, fi, c::Int)

    delta_hotspot_ss = PMs.var(pm, n, c, :hsss, i) 
    delta_hotspot = PMs.var(pm, n, c, :hs, i) 
    oil_temp = PMs.var(pm, n, c, :ro, i)
    JuMP.@constraint(pm.model, delta_hotspot == delta_hotspot_ss)
 
end


"CONSTRAINT: absolute hot-spot temperature"
function constraint_absolute_hotspot_temperature(pm::PMs.AbstractPowerModel, n::Int, i::Int, fi, c::Int, temp_ambient)

    delta_hotspot = PMs.var(pm, n, c, :hs, i) 
    #delta_hotspot = PMs.var(pm, n, c, :hsss, i) 
    hotspot = PMs.var(pm, n, c, :hsa, i)     
    oil_temp = PMs.var(pm, n, c, :ro, i)
    JuMP.@constraint(pm.model, hotspot == delta_hotspot + oil_temp + temp_ambient) 

end


"CONSTRAINT: average absolute hot-spot temperature"
function constraint_avg_absolute_hotspot_temperature(pm::PMs.AbstractPowerModel, i::Int, fi, c::Int, max_temp)

    N = length(PMs.nws(pm))
    JuMP.@constraint(pm.model, sum(PMs.var(pm, n, c, :hsa, i) for (n, nw_ref) in PMs.nws(pm)) <= N*max_temp)

end


