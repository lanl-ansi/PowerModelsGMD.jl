
# --- Templated Constraints --- #


"CONSTRAINT: DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model, ieff >= ihi)
    JuMP.@constraint(pm.model, ieff >= -ihi)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model, ieff >= (a*ihi + ilo)/a)
    JuMP.@constraint(pm.model, ieff >= -(a*ihi + ilo)/a)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractPowerModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model, ieff >= (a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= -(a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff >= 0.0)

end


"CONSTRAINT: KCL for DC (GIC) circuits"
function constraint_dc_kcl_shunt(pm::_PM.AbstractPowerModel, n::Int, i, dc_expr, gs, gmd_bus_arcs)

    v_dc = _PM.var(pm, n, :v_dc)[i]
    if length(gmd_bus_arcs) > 0
         if JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0
             println("Warning DC voltage cannot go to 0. This could make the DC KCL constraint overly constrained in switching applications")
         end
         JuMP.@constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc) # as long as v_dc can go to 0, this is ok
        return
    end

end


"CONSTRAINT: DC ohms for GIC"
function constraint_dc_ohms(pm::_PM.AbstractPowerModel, n::Int, i, f_bus, t_bus, vs, gs)

    vf = _PM.var(pm, n, :v_dc)[f_bus] # from dc voltage
    vt = _PM.var(pm, n, :v_dc)[t_bus] # to dc voltage
    dc = _PM.var(pm, n, :dc)[(i,f_bus,t_bus)]

    JuMP.@constraint(pm.model, dc == gs*(vf + vs - vt))

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, V, branchMVA)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*V*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::_PM.AbstractPowerModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: turning generators on and off"
function constraint_gen_on_off(pm::_PM.AbstractPowerModel, n::Int, i, pmin, pmax, qmin, qmax)

    z = _PM.var(pm, n, :gen_z)[i]
    pg = _PM.var(pm, n, :pg)[i]
    qg = _PM.var(pm, n, :qg)[i]

    JuMP.@constraint(pm.model, z * pmin <= pg)
    JuMP.@constraint(pm.model, pg <= z * pmax)
    JuMP.@constraint(pm.model, z * qmin <= qg)
    JuMP.@constraint(pm.model, qg <= z * qmax)

end


"CONSTRAINT: tieing ots variables to gen variables"
function constraint_gen_ots_on_off(pm::_PM.AbstractPowerModel, n::Int, i, bus_arcs)

    z = _PM.var(pm, n, :gen_z)[i]
    zb = _PM.var(pm, n, :z_branch)
    JuMP.@constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))

end


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::_PM.AbstractPowerModel, n::Int, i, cost)

    z = _PM.var(pm, n, :gen_z)[i]
    pg_sqr = _PM.var(pm, n, :pg_sqr)[i]
    pg = _PM.var(pm, n, :pg)[i]
    JuMP.@constraint(pm.model, z*pg_sqr >= cost[1]*pg^2)

end


"CONSTRAINT: DC Ohms constraint for GIC"
function constraint_dc_ohms_on_off(pm::_PM.AbstractPowerModel, n::Int, i, gs, vs, f_bus, t_bus, ac_branch)

    vf = _PM.var(pm, n, :v_dc)[f_bus] # from dc voltage
    vt = _PM.var(pm, n, :v_dc)[t_bus] # to dc voltage
    v_dc_diff = _PM.var(pm, n, :v_dc_diff)[i] # voltage diff
    vz = _PM.var(pm, n, :vz)[i] # voltage diff
    dc = _PM.var(pm, n, :dc)[(i,f_bus,t_bus)]
    z = _PM.var(pm, n, :z_branch)[ac_branch]

    JuMP.@constraint(pm.model, v_dc_diff == vf - vt)
    InfrastructureModels.relaxation_product(pm.model, z, v_dc_diff, vz)
    JuMP.@constraint(pm.model, dc == gs*(vz + z*vs) )

end


"CONSTRAINT: on/off DC current on the AC lines"
function constraint_dc_current_mag_on_off(pm::_PM.AbstractPowerModel, n::Int, k, dc_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    z = _PM.var(pm, n, :z_branch)[k]
    JuMP.@constraint(pm.model, ieff <= z*dc_max)

end



# --- Non-Templated Constraints --- #


"CONSTRAINT: DC current on normal lines"
function constraint_dc_current_mag_line(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)

end
constraint_dc_current_mag_line(pm::_PM.AbstractPowerModel, k; nw::Int=pm.cnw) = constraint_dc_current_mag_line(pm, nw, k)


"CONSTRAINT: DC current on grounded transformers"
function constraint_dc_current_mag_grounded_xf(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)
    JuMP.@constraint(pm.model, ieff[k] >= 0.0)

end
constraint_dc_current_mag_grounded_xf(pm::_PM.AbstractPowerModel, k; nw::Int=pm.cnw) = constraint_dc_current_mag_grounded_xf(pm, nw, k)


"CONSTRAINT: computing the DC current magnitude"
function constraint_dc_current_mag(pm::_PM.AbstractPowerModel, n::Int, k)

    # correct equation is ieff = |a*ihi + ilo|/a
    # just use ihi for now
    
    branch = _PM.ref(pm, n, :branch, k)

    if branch["type"] != "xfmr"
        constraint_dc_current_mag_line(pm, k, nw=n)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        Memento.debug(_LOGGER, "  Ungrounded config, ieff constrained to zero")
        constraint_dc_current_mag_grounded_xf(pm, k, nw=n)
    elseif branch["config"] in ["delta-gwye","gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm, k, nw=n)
    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm, k, nw=n)
    elseif branch["type"] == "xfmr" && branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm, k, nw=n)
    else
        ieff = _PM.var(pm, n, :i_dc_mag)
        JuMP.@constraint(pm.model, ieff[k] >= 0.0)
    end

end
constraint_dc_current_mag(pm::_PM.AbstractPowerModel, k; nw::Int=pm.cnw) = constraint_dc_current_mag(pm, nw, k)



# --- Decoupled Formulation Constraints --- #


"CONSTRAINT: computing qloss accounting for ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, n::Int, k, i, j, ih, K, ieff, branchMVA)

    # This is what is called for each branch
    # constraint_qloss(pm, n, c, k, i, j, K, ieff, branchMVA)

    qloss = _PM.var(pm, n, c, :qloss)
    v = _PM.var(pm, n, c, :vm)[ih] # ih is the index of the high-side bus

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*v*ieff/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming 1.0 pu ac voltage"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, ieff, branchMVA)

    qloss = _PM.var(pm, n, :qloss)

    # K is per phase
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*ieff/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss"
function constraint_zero_qloss(pm::_PM.AbstractPowerModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model, qloss[(k,i,j)] == 0.0)
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is 1.0 pu"
function constraint_qloss_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, branchMVA)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)

    # K is per phase
    # Assume that V = 1.0 pu
    JuMP.@constraint(pm.model, qloss[(k,i,j)] == K*i_dc_mag/(3.0*branchMVA))
    JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)

end


"CONSTRAINT: computing qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, k; nw::Int=pm.cnw)

    branch = ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)
    branchMVA = branch["baseMVA"]

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        ih = branch["hi_bus"]
        constraint_qloss_decoupled(pm, nw, k, i, j, ih, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, k, i, j)
    end

end


"CONSTRAINT:  computing qloss assuming ac voltage is 1.0 pu"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, k; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)

    if ("gmd_k" in keys(branch)) && ("baseMVA" in keys(branch))
        branchMVA = branch["baseMVA"]
        ibase = branchMVA*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        ieff = branch["ieff"]
        constraint_qloss_decoupled_vnom(pm, nw, k, i, j, K, ieff, branchMVA)
    else
       constraint_zero_qloss(pm, nw, k, i, j)
    end

end



# --- Thermal Constraints --- #


"CONSTRAINT: steady-state temperature"
function constraint_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i::Int, fi, rate_a, delta_oil_rated)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = _PM.var(pm, n, :p, fi) # real power
    q_fr = _PM.var(pm, n, :q, fi) # reactive power
    delta_oil_ss = _PM.var(pm, n, :ross, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, rate_a^2*delta_oil_ss/delta_oil_rated >= p_fr^2 + q_fr^2)

end


"CONSTRAINT: steady-state temperature"
function constraint_temperature_steady_state(pm::_PM.AbstractDCPModel, n::Int, i::Int, fi, rate_a, delta_oil_rated)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    # return delta_oil_rated*K^2
    println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    p_fr = _PM.var(pm, n, :p, fi) # real power
    delta_oil_ss = _PM.var(pm, n, :ross, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, sqrt(rate_a)*delta_oil_ss/sqrt(delta_oil_rated) >= p_fr)

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int, fi)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    # assume that transformer starts at equilibrium 
    delta_oil = var(pm, n, :ro, i) 
    delta_oil_ss = var(pm, n, :ross, i) 
    JuMP.@constraint(pm.model, delta_oil == delta_oil_ss)

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i::Int, fi, delta_oil_init)
    # i is index of the (transformer) branch
    # fi is index of the "from" branch terminal

    delta_oil = var(pm, n, :ro, i) 
    JuMP.@constraint(pm.model, delta_oil == delta_oil_init)

end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i::Int, tau)

    delta_oil_ss = var(pm, n_2, :ross, i) 
    delta_oil_ss_prev = var(pm, n_1, :ross, i)
    delta_oil = var(pm, n_2, :ro, i) 
    delta_oil_prev = var(pm, n_1, :ro, i)

    JuMP.@constraint(pm.model, (1 + tau)*delta_oil == delta_oil_ss + delta_oil_ss_prev - (1 - tau)*delta_oil_prev)
    # @constraint(pm.model, delta_oil == delta_oil_ss)

end


"CONSTRAINT: steady-state hot-spot temperature"
function constraint_hotspot_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i::Int, fi, rate_a, Re)
    # return delta_oil_rated*K^2
    # println("Branch $i rating: $rate_a, TO rise: $delta_oil_rated")

    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    delta_hotspot_ss = _PM.var(pm, n, :hsss, i) # top-oil temperature rise
    JuMP.@constraint(pm.model, delta_hotspot_ss == Re*ieff)
    # JuMP.@constraint(pm.model, delta_hotspot_ss == 100)

end


"CONSTRAINT: hot-spot temperature"
function constraint_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i::Int, fi)

    delta_hotspot_ss = _PM.var(pm, n, :hsss, i) 
    delta_hotspot = _PM.var(pm, n, :hs, i) 
    oil_temp = _PM.var(pm, n, :ro, i)
    JuMP.@constraint(pm.model, delta_hotspot == delta_hotspot_ss)
 
end


"CONSTRAINT: absolute hot-spot temperature"
function constraint_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i::Int, fi, temp_ambient)

    delta_hotspot = _PM.var(pm, n, :hs, i) 
    #delta_hotspot = _PM.var(pm, n, :hsss, i) 
    hotspot = _PM.var(pm, n, :hsa, i)     
    oil_temp = _PM.var(pm, n, :ro, i)
    JuMP.@constraint(pm.model, hotspot == delta_hotspot + oil_temp + temp_ambient) 

end


"CONSTRAINT: average absolute hot-spot temperature"
function constraint_avg_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, i::Int, fi, max_temp)

    N = length(_PM.nws(pm))
    JuMP.@constraint(pm.model, sum(_PM.var(pm, n, :hsa, i) for (n, nw_ref) in _PM.nws(pm)) <= N*max_temp)

end
