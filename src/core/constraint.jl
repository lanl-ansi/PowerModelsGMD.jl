# ===   GMD CONSTRAINTS   === #


"CONSTRAINT: voltage magnitude on/off constraint"
function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)

    vm = _PM.var(pm, n, :vm, i)
    z_voltage = _PM.var(pm, n, :z_voltage, i)

    JuMP.@constraint(pm.model,
        vm
        <=
        vmax * z_voltage
    )
    JuMP.@constraint(pm.model,
        vm
        >=
        vmin * z_voltage
    )

end


"CONSTRAINT: squared voltage magnitude on/off constraint"
function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)

    w = _PM.var(pm, n, :w, i)
    z_voltage = _PM.var(pm, n, :z_voltage, i)

    JuMP.@constraint(pm.model,
        w
        <=
        vmax^2 * z_voltage
    )
    JuMP.@constraint(pm.model,
        w
        >=
        vmin^2 * z_voltage
    )

end


"CONSTRAINT: power balance constraint for dc circuits"
function constraint_dc_power_balance_shunt(pm::_PM.AbstractPowerModel, n::Int, i, dc_expr, gs, blocker_status, gmd_bus_arcs)
    v_dc = _PM.var(pm, n, :v_dc)[i]

    if length(gmd_bus_arcs) > 0
        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
            println()
        end

        if blocker_status != 0.0
            JuMP.@constraint(pm.model,
                sum(dc_expr[a] for a in gmd_bus_arcs)
                ==
                0.0
            )
        else
            JuMP.@constraint(pm.model,
                sum(dc_expr[a] for a in gmd_bus_arcs)
                ==
                (gs * v_dc)
            )
        end
    end
end


"CONSTRAINT: power balance constraint for dc circuits with GIC blockers"
function constraint_blocker_dc_power_balance_shunt(pm::_PM.AbstractPowerModel, n::Int, i, dc_expr, gs, gmd_bus_arcs)
    v_dc = _PM.var(pm, n, :v_dc)[i]
    z = _PM.var(pm, n, :z_blocker)[i]

    if length(gmd_bus_arcs) > 0
        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
            println()
        end

        JuMP.@NLconstraint(pm.model,
            sum(dc_expr[a] for a in gmd_bus_arcs)
            ==
            (gs * v_dc)*(1 - z)
        )
    end
end


"CONSTRAINT: computing the dc current magnitude"
function constraint_dc_current_mag(pm::_PM.AbstractPowerModel, n::Int, k)

    # correct equation is ieff = |a*ihi + ilo|/a
    # just use ihi for now
    
    branch = _PM.ref(pm, n, :branch, k)

    if !(branch["type"] == "xfmr" || branch["type"] == "xf" || branch["type"] == "transformer")
        constraint_dc_current_mag_line(pm, k, nw=n)

    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        Memento.debug(_LOGGER, "UNGROUNDED CONFIGURATION. Ieff is constrained to ZERO.")
        constraint_dc_current_mag_grounded_xf(pm, k, nw=n)
    
    elseif branch["config"] in ["delta-gwye", "gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm, k, nw=n)

    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm, k, nw=n)
    
    elseif branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm, k, nw=n)

    elseif branch["config"] == "three-winding"
        ieff = _PM.var(pm, n, :i_dc_mag)
        JuMP.@constraint(pm.model,
            ieff[k]
            >=
            0.0
        )

    end

end
constraint_dc_current_mag(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag(pm, nw, k)


"CONSTRAINT: dc current on normal lines"
function constraint_dc_current_mag_line(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)

    JuMP.@constraint(pm.model,
        ieff[k]
        >=
        0.0
    )

end
constraint_dc_current_mag_line(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag_line(pm, nw, k)


"CONSTRAINT: dc current on grounded transformers"
function constraint_dc_current_mag_grounded_xf(pm::_PM.AbstractPowerModel, n::Int, k)

    ieff = _PM.var(pm, n, :i_dc_mag)

    JuMP.@constraint(pm.model,
        ieff[k]
        >=
        0.0
    )

end
constraint_dc_current_mag_grounded_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default) = constraint_dc_current_mag_grounded_xf(pm, nw, k)


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        ihi
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        -ihi
    )

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractPowerModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a * ihi + ilo) / a
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - (a * ihi + ilo) / a
    )

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractPowerModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a * is + ic) / (a + 1.0)
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - ( a * is + ic) / (a + 1.0)
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        0.0
    )

end


"CONSTRAINT: on/off dc current on the ac lines"
function constraint_dc_current_mag_on_off(pm::_PM.AbstractPowerModel, n::Int, k, dc_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    z = _PM.var(pm, n, :z_branch)[k]

    JuMP.@constraint(pm.model,
        ieff
        <=
        z * dc_max
    )

end


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::_PM.AbstractPowerModel, n::Int, i, cost)

    z = _PM.var(pm, n, :z_gen)[i]
    pg_sqr = _PM.var(pm, n, :pg_sqr)[i]
    pg = _PM.var(pm, n, :pg)[i]

    JuMP.@constraint(pm.model,
        z * pg_sqr
        >=
        cost[1] * pg^2
    )

end


"CONSTRAINT: tieing OTS variables to gen variables"
function constraint_gen_ots_on_off(pm::_PM.AbstractPowerModel, n::Int, i, bus_arcs)

    z = _PM.var(pm, n, :z_gen)[i]
    zb = _PM.var(pm, n, :z_branch)

    JuMP.@constraint(pm.model,
        z
        <=
        sum(zb[a[1]] for a in bus_arcs)
    )

end


"CONSTRAINT: dc ohms constraint for GIC"
function constraint_dc_ohms(pm::_PM.AbstractPowerModel, n::Int, i, f_bus, t_bus, vs, gs)

    vf = _PM.var(pm, n, :v_dc)[f_bus]  # from dc voltage
    vt = _PM.var(pm, n, :v_dc)[t_bus]  # to dc voltage
    dc = _PM.var(pm, n, :dc)[(i, f_bus, t_bus)]

    JuMP.@constraint(pm.model,
        dc
        ==
        gs * (vf + vs - vt)
    )

end


"CONSTRAINT: dc ohms on/off constraint for dc circuits"
function constraint_dc_ohms_on_off(pm::_PM.AbstractPowerModel, n::Int, i, gs, vs, f_bus, t_bus, ac_branch)

    vf = _PM.var(pm, n, :v_dc)[f_bus] # from dc voltage
    vt = _PM.var(pm, n, :v_dc)[t_bus] # to dc voltage
    v_dc_diff = _PM.var(pm, n, :v_dc_diff)[i] # voltage diff
    vz = _PM.var(pm, n, :vz)[i] # voltage diff
    dc = _PM.var(pm, n, :dc)[(i,f_bus,t_bus)]
    z = _PM.var(pm, n, :z_branch)[ac_branch]

    JuMP.@constraint(pm.model,
        v_dc_diff
        ==
        vf - vt
    )

    JuMP.@constraint(pm.model,
        dc
        ==
        gs * (vz + z*vs)
    )

    _IM.relaxation_product(pm.model, z, v_dc_diff, vz)

end


"CONSTRAINT: computing qloss assuming ac primary voltage is 1.0 per unit"
function constraint_qloss_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, branchMVA)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * i_dc_mag) / (3.0 * branchMVA)  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: computing qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    branchMVA = branch["baseMVA"]
    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)

    if "gmd_k" in keys(branch)

        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (bus["base_kv"] * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)
        ieff = branch["ieff"]
        ih = branch["hi_bus"]

        constraint_qloss_decoupled(pm, nw, k, i, j, ih, K, ieff, branchMVA)

    else
        constraint_zero_qloss(pm, nw, k, i, j)
    end

end


"CONSTRAINT: computing qloss assuming ac voltage is 1.0 pu"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    Smax = 1000
    branchMVA = min(get(branch, "rate_a", Smax), Smax)
    # using hi/lo bus shouldn't be an issue because qloss is defined in arcs going in both directions

    if !("hi_bus" in keys(branch)) || !("lo_bus" in keys(branch)) || branch["hi_bus"] == -1 || branch["lo_bus"] == -1
        Memento.warn(_LOGGER, "Branch $k is missing hi bus/lo bus")
        return
    end

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)

    if branch["br_status"] == 0 
        return
    end

    if "gmd_k" in keys(branch)
        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (bus["base_kv"] * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)
        ieff = branch["ieff"]

        constraint_qloss_decoupled_vnom(pm, nw, k, i, j, K, ieff, branchMVA)

    else
        constraint_zero_qloss(pm, nw, k, i, j)
    end

end

"CONSTRAINT: computing qloss assuming ac voltage is 1.0 pu"
function constraint_qloss_decoupled_vnom_mld(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    Smax = 1000
    branchMVA = min(get(branch, "rate_a", Smax), Smax)
    # using hi/lo bus shouldn't be an issue because qloss is defined in arcs going in both directions

    if !("hi_bus" in keys(branch)) || !("lo_bus" in keys(branch)) || branch["hi_bus"] == -1 || branch["lo_bus"] == -1
        Memento.warn(_LOGGER, "Branch $k is missing hi bus/lo bus")
        return
    end

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)

    if branch["br_status"] == 0 
        return
    end

    if "gmd_k" in keys(branch)
        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (bus["base_kv"] * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)
        ieff = branch["ieff"]

        constraint_qloss_decoupled_vnom_mld(pm, nw, k, i, j, K, ieff, branchMVA)

    else
        constraint_zero_qloss(pm, nw, k, i, j)
    end

end


"CONSTRAINT: computing qloss accounting for ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, n::Int, k, i, j, ih, K, ieff, branchMVA)

    qloss = _PM.var(pm, n, :qloss)
    v = _PM.var(pm, n, :vm)[ih]  # 'ih' is the index of the high-side bus

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * v * ieff) / (3.0 * branchMVA)  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: computing qloss assuming 1.0 pu ac voltage"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, ieff, branchMVA)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * ieff) / (3.0 * branchMVA)  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end

"CONSTRAINT: computing qloss assuming 1.0 pu ac voltage"
function constraint_qloss_decoupled_vnom_mld(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, ieff, branchMVA)

    qloss = _PM.var(pm, n, :qloss)
    z_voltage = _PM.var(pm, n, :z_voltage)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * ieff * z_voltage[i]) / (3.0 * branchMVA)  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: computing qloss"
function constraint_zero_qloss(pm::_PM.AbstractPowerModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        0.0
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, V, branchMVA)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * V * i_dc_mag) / (3.0 * branchMVA)  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: computing qloss assuming ac primary voltage is constant"
function constraint_qloss_constant_v(pm::_PM.AbstractPowerModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        0.0
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end




# ===   THERMAL CONSTRAINTS   === #


"CONSTRAINT: steady-state temperature"
function constraint_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, rate_a, delta_oil_rated)

    p_fr = _PM.var(pm, n, :p, f_idx)
    q_fr = _PM.var(pm, n, :q, f_idx)
    delta_oil_ss = _PM.var(pm, n, :ross, i)

    JuMP.@constraint(pm.model,
        rate_a^2 * delta_oil_ss / delta_oil_rated
        >=
        p_fr^2 + q_fr^2
    )

end


"CONSTRAINT: steady-state temperature"
function constraint_temperature_steady_state(pm::_PM.AbstractDCPModel, n::Int, i, f_idx, rate_a, delta_oil_rated)

    p_fr = _PM.var(pm, n, :p, f_idx)
    delta_oil_ss = _PM.var(pm, n, :ross, i)

    JuMP.@constraint(pm.model,
        sqrt(rate_a) * delta_oil_ss / sqrt(delta_oil_rated)
        >=
        p_fr
    )

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)

    delta_oil = _PM.var(pm, n, :ro, i) 
    delta_oil_ss = _PM.var(pm, n, :ross, i)

    JuMP.@constraint(pm.model,
        delta_oil
        ==
        delta_oil_ss
    )

end


"CONSTRAINT: initial temperature state"
function constraint_temperature_state_initial(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, delta_oil_init)

    delta_oil = _PM.var(pm, n, :ro, i) 

    JuMP.@constraint(pm.model,
        delta_oil
        ==
        delta_oil_init
    )

end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::_PM.AbstractPowerModel, n_1::Int, n_2::Int, i, tau)

    delta_oil_ss = _PM.var(pm, n_2, :ross, i) 
    delta_oil_ss_prev = _PM.var(pm, n_1, :ross, i)
    delta_oil = _PM.var(pm, n_2, :ro, i) 
    delta_oil_prev = _PM.var(pm, n_1, :ro, i)

    JuMP.@constraint(pm.model,
        (1 + tau) * delta_oil
        ==
        delta_oil_ss + delta_oil_ss_prev - (1 - tau) * delta_oil_prev
    )

end


"CONSTRAINT: steady-state hot-spot temperature"
function constraint_hotspot_temperature_steady_state(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, rate_a, Re)

    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    delta_hotspot_ss = _PM.var(pm, n, :hsss, i)

    JuMP.@constraint(pm.model,
        delta_hotspot_ss
        ==
        Re*ieff
    )

end


"CONSTRAINT: hot-spot temperature"
function constraint_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)

    delta_hotspot_ss = _PM.var(pm, n, :hsss, i) 
    delta_hotspot = _PM.var(pm, n, :hs, i) 
    oil_temp = _PM.var(pm, n, :ro, i)

    JuMP.@constraint(pm.model,
        delta_hotspot
        ==
        delta_hotspot_ss
    )
 
end


"CONSTRAINT: absolute hot-spot temperature"
function constraint_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, temp_ambient)

    delta_hotspot = _PM.var(pm, n, :hs, i)
    hotspot = _PM.var(pm, n, :hsa, i)
    oil_temp = _PM.var(pm, n, :ro, i)

    JuMP.@constraint(pm.model,
        hotspot
        ==
        delta_hotspot + oil_temp + temp_ambient
    )

end


"CONSTRAINT: average absolute hot-spot temperature"
function constraint_avg_absolute_hotspot_temperature(pm::_PM.AbstractPowerModel, i, f_idx, max_temp)

    N = length(_PM.nws(pm))

    JuMP.@constraint(pm.model,
        sum(_PM.var(pm, n, :hsa, i) for (n, nw_ref) in _PM.nws(pm))
        <=
        N * max_temp
    )

end


