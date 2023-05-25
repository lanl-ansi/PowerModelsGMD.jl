###################################
# Constraint Template Definitions #
###################################

# Constraint templates help simplify data wrangling across multiple formulations
# by providing an abstraction layer between the network data and network constraint
# definitions. The constraint template's job is to extract the required parameters
# from a given network data structure and pass the data as named arguments to the
# formulations.

# Constraint templates should always be defined over "AbstractPowerModel" and
# should never refer to model variables.


# ===   VOLTAGE CONSTRAINTS   === #

"
  Constraint: constraints on modeling bus voltages that is primarly a pass through to _PM.constraint_model_voltage
  There are a few situations where the GMD problem formulations have additional voltage modeling than what _PM provides.
  This adds connection between w and vm variables in the WR formulation space
"
function constraint_model_voltage(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    _PM.constraint_model_voltage(pm; nw=nw)
end


"
  Constraint: constraints on modeling bus voltages that is primarly a pass through to _PMR.constraint_bus_voltage_on_off(
  There are a few situations where the GMD problem formulations have additional voltage modeling than what _PM provides.
  This adds connection between w and vm variables in the WR formulation space
"
function constraint_model_voltage_on_off(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    _PM.constraint_model_voltage_on_off(pm; nw=nw)
end


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    kh = branch["gmd_br_hi"]

    br_hi = _PM.ref(pm, nw, :gmd_branch, kh)
    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    constraint_dc_current_mag_gwye_delta_xf(pm, nw, k, kh, ih, jh)

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    kh = branch["gmd_br_hi"]
    kl = branch["gmd_br_lo"]
    i = branch["f_bus"]
    j = branch["t_bus"]

    br_hi = _PM.ref(pm, nw, :gmd_branch, kh)
    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    br_lo = _PM.ref(pm, nw, :gmd_branch, kl)
    il = br_lo["f_bus"]
    jl = br_lo["t_bus"]

    vhi = _PM.ref(pm, nw, :bus, i, "base_kv")
    vlo = _PM.ref(pm, nw, :bus, j, "base_kv")
    a = vhi / vlo

    constraint_dc_current_mag_gwye_gwye_xf(pm, nw, k, kh, ih, jh, kl, il, jl, a)

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :branch, k)
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]
    i = branch["f_bus"]
    j = branch["t_bus"]

    br_ser = _PM.ref(pm, nw, :gmd_branch, ks)
    is = br_ser["f_bus"]
    js = br_ser["t_bus"]

    br_com = _PM.ref(pm, nw, :gmd_branch, kc)
    ic = br_com["f_bus"]
    jc = br_com["t_bus"]

    ihi = -is
    ilo = ic + is

    vlo = _PM.ref(pm, nw, :bus, i, "base_kv")
    vhi = _PM.ref(pm, nw, :bus, j, "base_kv")
    a = vhi / vlo

    constraint_dc_current_mag_gwye_gwye_auto_xf(pm, nw, k, ks, is, js, kc, ic, jc, a)

end


# ===   POWER BALANCE CONSTRAINTS   === #


"CONSTRAINT: nodal power balance with gmd"
function constraint_power_balance_gmd(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = _PM.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_storage = _PM.ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    constraint_power_balance_gmd(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd)

end


"CONSTRAINT: nodal power balance with gmd and shunts"
function constraint_power_balance_gmd_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = _PM.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)
    bus_storage = _PM.ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_gmd_shunt(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = _PM.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)
    bus_storage = _PM.ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_gmd_shunt_ls(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

end


"CONSTRAINT: nodal power balance for dc circuits with shunts"
function constraint_dc_power_balance(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    dc_expr = pm.model.ext[:nw][nw][:dc_expr]
    gmd_bus = _PM.ref(pm, nw, :gmd_bus, i)
    gmd_bus_arcs = _PM.ref(pm, nw, :gmd_bus_arcs, i)
    blockers = get(_PM.ref(pm,nw,:gmd_bus_blockers),i,Dict())

    gs = gmd_bus["g_gnd"]
    blocker_status = length(blockers) > 0 ? 1 : 0

    constraint_dc_power_balance(pm, nw, i, dc_expr, gmd_bus_arcs, gs, blocker_status)
end


# ===   OHM'S LAW CONSTRAINTS   === #


"CONSTRAINT: ohms constraint for dc circuits"
function constraint_dc_ohms(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    branch = _PM.ref(pm, nw, :gmd_branch, i)

    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    vs = branch["br_v"]
        # line dc series voltage
    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0 / branch["br_r"]
            # line dc series resistance
    end

    constraint_dc_ohms(pm, nw, i, f_bus, t_bus, f_idx, t_idx, vs, gs)

end



# ===   QLOSS CONSTRAINTS   === #


"CONSTRAINT: Calculation of qloss on a per edge basis"
function constraint_qloss(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch    = _PM.ref(pm, nw, :branch, k)
    branchMVA = branch["baseMVA"]
    i         = branch["hi_bus"]
    j         = branch["lo_bus"]

    bus       = _PM.ref(pm, nw, :bus, i)
    busKV     = bus["base_kv"]

    ibase     = (branchMVA * 1000.0 * sqrt(2.0)) / (busKV * sqrt(3.0))
    K         = haskey(branch, "gmd_k") ? (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase) : 0.0

    constraint_qloss(pm, nw, k, i, j, branchMVA, K)

end


"CONSTRAINT: Calculation of qloss on a per edge basis where ieff is a constant"

function constraint_qloss_constant_ieff(pm::_PM.AbstractPowerModel, k; nw::Int=nw_id_default)

    branch    = _PM.ref(pm, nw, :branch, k)
    branchMVA = branch["baseMVA"]
    ieff      = branch["ieff"]
    i         = branch["hi_bus"]
    j         = branch["lo_bus"]

    bus       = _PM.ref(pm, nw, :bus, i)
    busKV     = bus["base_kv"]

    ibase     = (branchMVA * 1000.0 * sqrt(2.0)) / (busKV * sqrt(3.0))
    K         = haskey(branch, "gmd_k") ? (branch["gmd_k"] * pm.data["baseMVA"]) / (ibase) : 0.0

    constraint_qloss_constant_ieff(pm, nw, k, i, j, branchMVA, K, ieff)

end

"CONSTRAINT: more than a specified percentage of load is served"

function constraint_load_served(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)

    load_ratio = _PM.ref(pm, nw, :load_served_ratio)

    total_load = 0
    for (i,load) in _PM.ref(pm, nw, :load)
        total_load += abs(load["pd"])
    end
    min_load_served = total_load * load_ratio

    pd = Dict(k => abs(_PM.ref(pm, nw, :load, k, "pd")) for (k,load) in _PM.ref(pm, nw, :load))

    constraint_load_served(pm, nw, pd, min_load_served)

end


"CONSTRAINT: nodal power balance for dc circuits with GIC blockers and shunts"
function constraint_dc_power_balance_ne_blocker(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)

    dc_expr = pm.model.ext[:nw][nw][:dc_expr]
    gmd_bus = _PM.ref(pm, nw, :gmd_bus, i)
    gmd_bus_arcs = _PM.ref(pm, nw, :gmd_bus_arcs, i)
    ne_blockers = get(_PM.ref(pm,nw,:gmd_bus_ne_blockers),i, Dict())
    blockers = get(_PM.ref(pm,nw,:gmd_bus_blockers),i,Dict())

    gs = gmd_bus["g_gnd"]
    blocker_status = length(blockers) > 0 ? 1 : 0
    #has_blocker = get(gmd_bus, "blocker", 0.0)
    #blocker_status = min(get(gmd_bus, "blocker_status", 1.0), has_blocker)
    #blocker_status = 0

    if blocker_status == 0 && length(ne_blockers) > 0
        if (length(ne_blockers) > 1)
            Memento.warn(_LOGGER, "Bus ", i, " has more than one expansion blocker defined for it. Only using one of them")
        end

        constraint_dc_power_balance_ne_blocker(pm, nw, i, ne_blockers[1], dc_expr, gmd_bus_arcs, gs)
    else
        constraint_dc_power_balance(pm, nw, i, dc_expr, gmd_bus_arcs, gs, blocker_status)
    end

end
