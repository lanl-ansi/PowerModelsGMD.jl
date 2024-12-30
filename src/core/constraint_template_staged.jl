"CONSTRAINT: voltage magnitude on/off constraint"
function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_on_off(pm, nw, i, bus["vmin"], bus["vmax"])

end


"CONSTRAINT: squared voltage magnitude on/off constraint"
function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_sqr_on_off(pm, nw, i, bus["vmin"], bus["vmax"])

end


# ===   CURRENT CONSTRAINTS   === #


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

    constraint_current_on_off(pm, nw, i, ac_max)

end

"CONSTRAINT: on/off constraint for current magnitude"
function constraint_dc_current_mag_on_off(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)

    dc_max = calc_dc_mag_max(pm, k, nw=nw)

    constraint_dc_current_mag_on_off(pm, nw, k, dc_max)

end

# ===   GENERATOR CONSTRAINTS   === #


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    gen  = _PM.ref(pm, nw, :gen, i)
    cost = gen["cost"]

    constraint_gen_perspective(pm, nw, i, cost)

end


"CONSTRAINT: tie OTS variables to gen variables"
function constraint_gen_ots_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    gen = _PM.ref(pm, nw, :gen, i)
    g = gen["gen_bus"]

    bus = _PM.ref(pm, nw, :bus, g)
    b = bus["index"]

    bus_loads = _PM.ref(pm, nw, :bus_loads, b)

    if length(bus_loads) > 0
        pd = sum([_PM.ref(pm, nw, :load, i)["pd"] for i in bus_loads])
        qd = sum([_PM.ref(pm, nw, :load, i)["qd"] for i in bus_loads])
    else
        pd = 0.0
        qd = 0.0
    end

    if (pd != 0.0 && qd != 0.0)
        # has load => gen cannot be on if not connected
        return
    end

    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)

    constraint_gen_ots_on_off(pm, nw, i, bus_arcs)

end





"CONSTRAINT: ohms on/off constraint for dc circuits"
function constraint_dc_ohms_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :gmd_branch, i)

    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    ac_branch = branch["parent_index"]
    vs = branch["br_v"]
        # line dc series voltage
    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = (1.0 / branch["br_r"])
            # line dc series resistance
    end

    constraint_dc_ohms_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, ac_branch, vs, gs)

end


"CONSTRAINT: qloss assuming constant dc voltage"
function constraint_qloss_vnom(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    branchMVA = branch["baseMVA"]
    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)
    busKV = bus["base_kv"]

    if "gmd_k" in keys(branch)

        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (busKV * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)

        constraint_qloss_vnom(pm, nw, k, i, j, branchMVA, K)

    else

        constraint_zero_qloss(pm, nw, k, i, j)

    end

end


"CONSTRAINT: decoupled qloss assuming constant ac voltage"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    Smax = 1000
    branchMVA = min(get(branch, "rate_a", Smax), Smax)
        # using hi/lo bus (qloss is defined in arcs going in both directions)
    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)
    busKV = bus["base_kv"]

    if !("hi_bus" in keys(branch)) || !("lo_bus" in keys(branch)) || branch["hi_bus"] == -1 || branch["lo_bus"] == -1
        Memento.warn(_LOGGER, "Branch $k is missing hi bus/lo bus.")
        return
    end

    if branch["br_status"] == 0
        return
    end

    if "gmd_k" in keys(branch)

        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (busKV * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)
        ieff = branch["ieff"]

        constraint_qloss_decoupled_vnom(pm, nw, k, i, j, K, branchMVA, ieff)

    else

        constraint_zero_qloss(pm, nw, k, i, j)

    end

end


"CONSTRAINT: decoupled qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    branchMVA = branch["baseMVA"]
    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)
    busKV = bus["base_kv"]

    if "gmd_k" in keys(branch)

        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (busKV * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)
        ieff = branch["ieff"]
        ih = branch["hi_bus"]

        constraint_qloss_decoupled(pm, nw, k, i, j, branchMVA, K, ieff, ih)

    else

        constraint_zero_qloss(pm, nw, k, i, j)

    end

end


"CONSTRAINT: decoupled qloss assuming constant ac voltage for MLD"
function constraint_qloss_decoupled_vnom_mld(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    Smax = 1000
    branchMVA = min(get(branch, "rate_a", Smax), Smax)
        # using hi/lo bus (qloss is defined in arcs going in both directions)
    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = _PM.ref(pm, nw, :bus, i)
    busKV = bus["base_kv"]

    if !("hi_bus" in keys(branch)) || !("lo_bus" in keys(branch)) || branch["hi_bus"] == -1 || branch["lo_bus"] == -1
        Memento.warn(_LOGGER, "Branch $k is missing hi bus/lo bus.")
        return
    end

    if branch["br_status"] == 0
        return
    end

    if "gmd_k" in keys(branch)

        ibase = (branchMVA * 1000.0 * sqrt(2.0)) / (busKV * sqrt(3.0))
        K = (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase)
        ieff = branch["ieff"]

        constraint_qloss_decoupled_vnom_mld(pm, nw, k, i, j, K, branchMVA, ieff)

    else

        constraint_zero_qloss(pm, nw, k, i, j)

    end

end


"CONSTRAINT: steady-state temperature state"
function constraint_temperature_state_ss(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)

    if branch["topoil_time_const"] >= 0
        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)
        rate_a = branch["rate_a"]
        constraint_temperature_steady_state(pm, nw, i, f_idx, rate_a, branch["topoil_rated"])
    end
end


"CONSTRAINT: steady-state hot-spot temperature state"
function constraint_hotspot_temperature_state_ss(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)

    if branch["topoil_time_const"] >= 0
        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)
        rate_a = branch["rate_a"]
        Re = get_warn(branch, "hotspot_coeff", 0.63)
        constraint_hotspot_temperature_steady_state(pm, nw, i, f_idx, rate_a, Re)
    end
end


"CONSTRAINT: hot-spot temperature state"
function constraint_hotspot_temperature_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)

    if branch["topoil_time_const"] >= 0
        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)

        constraint_hotspot_temperature(pm, nw, i, f_idx)
    end
end


"CONSTRAINT: absolute hot-spot temperature state"
function constraint_absolute_hotspot_temperature_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)

    if branch["topoil_time_const"] >= 0
        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)

        # TODO: use get_warn with defaults
        temp_ambient = branch["temperature_ambient"]

        constraint_absolute_hotspot_temperature(pm, nw, i, f_idx, temp_ambient)
    end
end


"CONSTRAINT: average absolute hot-spot temperature state"
function constraint_avg_absolute_hotspot_temperature_state(pm::_PM.AbstractPowerModel, i::Int)
    branch = _PM.ref(pm, 1, :branch, i)

    if branch["topoil_time_const"] >= 0
        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]
        f_idx = (i, f_bus, t_bus)

        max_temp = branch["hotspot_avg_limit"]
        constraint_avg_absolute_hotspot_temperature(pm, i, f_idx, max_temp)
    end
end


"CONSTRAINT: thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)
    if !(branch["type"] == "xfmr" || branch["type"] == "xf" || branch["type"] == "transformer")
        return
    end

    coeff = calc_branch_thermal_coeff(pm, i, nw=nw)
    ibase = calc_branch_ibase(pm, i, nw=nw)

    constraint_thermal_protection(pm, nw, i, coeff, ibase)
end
