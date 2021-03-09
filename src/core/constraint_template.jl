
# --- Constraint Templates --- #


"CONSTRAINT: KCL without load shedding and no shunts"
function constraint_kcl_gmd(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)

    bus_pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    constraint_kcl_gmd(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

end


"CONSTRAINT: KCL with load shedding"
function constraint_kcl_shunt_gmd_ls(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    bus_pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt_gmd_ls(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

end


"CONSTRAINT: DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)

    kh = branch["gmd_br_hi"]
    br_hi = _PM.ref(pm, nw, :gmd_branch, kh)

    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    constraint_dc_current_mag_gwye_delta_xf(pm, nw, k, kh, ih, jh)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)

    kh = branch["gmd_br_hi"]
    kl = branch["gmd_br_lo"]

    br_hi = _PM.ref(pm, nw, :gmd_branch, kh)
    br_lo = _PM.ref(pm, nw, :gmd_branch, kl)

    i = branch["f_bus"]
    j = branch["t_bus"]

    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    il = br_lo["f_bus"]
    jl = br_lo["t_bus"]

    vhi = _PM.ref(pm, nw, :bus, i, "base_kv")
    vlo = _PM.ref(pm, nw, :bus, j, "base_kv")
    a = vhi/vlo

    constraint_dc_current_mag_gwye_gwye_xf(pm, nw, k, kh, ih, jh, kl, il, jl, a)

end


"CONSTRAINT: DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]

    Memento.debug(_LOGGER, "Series GMD branch: $ks, Common GMD branch: $kc \n")

    br_ser = _PM.ref(pm, nw, :gmd_branch, ks)
    br_com = _PM.ref(pm, nw, :gmd_branch, kc)

    i = branch["f_bus"]
    j = branch["t_bus"]

    is = br_ser["f_bus"]
    js = br_ser["t_bus"]

    ic = br_com["f_bus"]
    jc = br_com["t_bus"]


    ihi = -is
    ilo = ic + is

    vhi = _PM.ref(pm, nw, :bus, j, "base_kv")
    vlo = _PM.ref(pm, nw, :bus, i, "base_kv")
    a = vhi/vlo

    constraint_dc_current_mag_gwye_gwye_auto_xf(pm, nw, k, ks, is, js, kc, ic, jc, a)

end


"CONSTRAINT: KCL constraint for DC (GIC) circuits"
function constraint_dc_kcl_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    dcbus = _PM.ref(pm, nw, :gmd_bus, i)
    gmd_bus_arcs = _PM.ref(pm, nw, :gmd_bus_arcs, i)

    dc_expr = pm.model.ext[:nw][nw][:dc_expr]

    gs = dcbus["g_gnd"]

    constraint_dc_kcl_shunt(pm, nw, i, dc_expr, gs, gmd_bus_arcs)

end


"CONSTRAINT: DC ohms constraint for GIC"
function constraint_dc_ohms(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :gmd_branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]

    bus1 = _PM.ref(pm, nw, :gmd_bus, f_bus)
    bus2 = _PM.ref(pm, nw, :gmd_bus, t_bus)

#    dkm = branch["len_km"]
    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    Memento.debug(_LOGGER, "branch $i: ($f_bus,$t_bus), $vs, $gs \n")

    constraint_dc_ohms(pm, nw, i, f_bus, t_bus, vs, gs)

end


"CONSTRAINT: computing qloss assuming DC voltage is constant"
function constraint_qloss_vnom(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)
    branchMVA = branch["baseMVA"]

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        constraint_qloss_vnom(pm, nw, k, i, j, K, branchMVA)
    else
       constraint_qloss_vnom(pm, nw, k, i, j)
    end

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, i)
    if branch["type"] != "xfmr"
        return
    end

    coeff = calc_branch_thermal_coeff(pm, i, nw=nw)
    ibase = calc_branch_ibase(pm, i, nw=nw)

    constraint_thermal_protection(pm, nw, i, coeff, ibase)

end


"CONSTRAINT: relating current to power flow"
function constraint_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    tm = branch["tap"]^2

    constraint_current(pm, nw, i, f_idx, f_bus, t_bus, tm)

end


"CONSTRAINT: relating current to power flow on/off"
function constraint_current_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, i)
    ac_max = calc_ac_mag_max(pm, i, nw=nw)

    # constraint_current(pm,n,i)
    constraint_current_on_off(pm, nw, i, ac_max)

end


"CONSTRAINT: computing qloss"
function constraint_qloss(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)

    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        branchMVA = branch["baseMVA"]
        constraint_qloss_constant_v(pm, nw, k, i, j, K, 1.0, branchMVA)
    else

        constraint_qloss_constant_v(pm, nw, k, i, j)
    end

end


"CONSTRAINT: turning generators on and off"
function constraint_gen_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    gen = _PM.ref(pm, nw, :gen, i)
    pmin = gen["pmin"]
    pmax = gen["pmax"]
    qmin = gen["qmin"]
    qmax = gen["qmax"]

    constraint_gen_on_off(pm, nw, i, pmin, pmax, qmin, qmax)

end


"CONSTRAINT: tieing ots variables to gen variables"
function constraint_gen_ots_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    gen = _PM.ref(pm, nw, :gen, i)
    bus = _PM.ref(pm, nw, :bus, gen["gen_bus"])
    bus_loads = _PM.ref(pm, nw, :bus_loads, bus["index"])
    if length(bus_loads) > 0
        pd = sum([_PM.ref(pm, nw, :load, i)["pd"] for i in bus_loads])
        qd = sum([_PM.ref(pm, nw, :load, i)["qd"] for i in bus_loads])
    else
        pd = 0.0
        qd = 0.0
    end

    # has load, so gen can not be on if not connected
    if pd != 0.0 && qd != 0.0
        return
    end
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)

    constraint_gen_ots_on_off(pm, nw, i, bus_arcs)

end


"CONSTRAINT: generation cost"
function constraint_gen_perspective(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    gen  = _PM.ref(pm, nw, :gen, i)
    cost = gen["cost"]
    constraint_gen_perspective(pm, nw, i, cost)

end


"CONSTRAINT: Ohms constraint for DC circuits"
function constraint_dc_ohms_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :gmd_branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    ac_branch = branch["parent_index"]

    bus1 = _PM.ref(pm, nw, :gmd_bus, f_bus)
    bus2 = _PM.ref(pm, nw, :gmd_bus, t_bus)

   # dkm = branch["len_km"]

    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    constraint_dc_ohms_on_off(pm, nw, i, gs, vs, f_bus, t_bus, ac_branch)

end


"CONSTRAINT: On/off constraint for current magnitude "
function constraint_dc_current_mag_on_off(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    dc_max = calc_dc_mag_max(pm, k, nw=nw)
    constraint_dc_current_mag_on_off(pm, nw, k, dc_max)

end



# --- Thermal Constraints --- #


"CONSTRAINT: steady-state temperature state"
function constraint_temperature_state_ss(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    #temperature = ref(pm, nw, :storage, i)

    branch = _PM.ref(pm, nw, :branch, i)

    if branch["topoil_time_const"] >= 0
        rate_a = branch["rate_a"]

        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)

        constraint_temperature_steady_state(pm, nw, i, f_idx, rate_a, branch["topoil_rated"])
    end

end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if branch["topoil_time_const"] >= 0
        if branch["topoil_initialized"] > 0
            constraint_temperature_state_initial(pm, nw, i, f_idx, branch["topoil_init"])
        else
            constraint_temperature_state_initial(pm, nw, i, f_idx)
        end
    end

end


"CONSTRAINT: temperature state"
function constraint_temperature_state(pm::_PM.AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)

    branch = ref(pm, nw_1, :branch, i)

    if branch["topoil_time_const"] >= 0
        tau_oil = branch["topoil_time_const"]
        delta_t = 5

        if haskey(ref(pm, nw_1), :time_elapsed)
            delta_t = ref(pm, nw_1, :time_elapsed)
        else
            Memento.warn(_LOGGER, "network data should specify time_elapsed, using $delta_t as a default")
        end

        tau = 2*tau_oil/delta_t
        println("Oil Tau: $tau_oil, DT: $delta_t, tau: $tau")
        constraint_temperature_state(pm, nw_1, nw_2, i, tau)

    end

end


"CONSTRAINT: steady-state hot-spot temperature state"
function constraint_hotspot_temperature_state_ss(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    rate_a = branch["rate_a"]

    if branch["topoil_time_const"] >= 0
        Re = 0.63

        if "hotspot_coeff" in keys(branch)
            Re = branch["hotspot_coeff"]
        end

        constraint_hotspot_temperature_steady_state(pm, nw, i, f_idx, rate_a, Re)

    end

end


"CONSTRAINT: hot-spot temperature state"
function constraint_hotspot_temperature_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if branch["topoil_time_const"] >= 0
        constraint_hotspot_temperature(pm, nw, i, f_idx)
    end

end


"CONSTRAINT: absolute hot-spot temperature state"
function constraint_absolute_hotspot_temperature_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if branch["topoil_time_const"] >= 0
        constraint_absolute_hotspot_temperature(pm, nw, i, f_idx, branch["temperature_ambient"])
    end

end


"CONSTRAINT: average absolute hot-spot temperature state"
function constraint_avg_absolute_hotspot_temperature_state(pm::_PM.AbstractPowerModel, i::Int)

    branch = ref(pm, 1, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if branch["topoil_time_const"] >= 0
        constraint_avg_absolute_hotspot_temperature(pm, i, f_idx, branch["hotspot_avg_limit"])
    end

end
