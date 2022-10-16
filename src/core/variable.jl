# ===   GENERAL VARIABLES   === #


"VARIABLE: bus voltage indicator"
function variable_bus_voltage_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)

    if !relax
        z_voltage = _PM.var(pm, nw)[:z_voltage] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_z_voltage",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_voltage_start")
        )
    else
        z_voltage = _PM.var(pm, nw)[:z_voltage] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_z_voltage",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_voltage_start")
        )
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :status, _PM.ids(pm, nw, :bus), z_voltage)

end


"VARIABLE: bus voltage magnitude on/off"
function variable_bus_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    vm = _PM.var(pm, nw)[:vm] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_vm",
        lower_bound = 0.0,
        upper_bound = _PM.ref(pm, nw, :bus, i, "vmax"),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "vm_start", 1.0)
    )

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :vm, _PM.ids(pm, nw, :bus), vm)

end


"VARIABLE: squared bus voltage magnitude on/off"
function variable_bus_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    w = _PM.var(pm, nw)[:w] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_w",
        lower_bound = 0,
        upper_bound = _PM.ref(pm, nw, :bus, i, "vmax")^2,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "w_start", 1.001)
    )

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :w, _PM.ids(pm, nw, :bus), w)

end


"VARIABLE: dc voltage"
function variable_dc_voltage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        v_dc = _PM.var(pm, nw)[:v_dc] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_bus)], base_name="$(nw)_v_dc",
            lower_bound = calc_min_dc_voltage(pm, i, nw=nw),
            upper_bound = calc_max_dc_voltage(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "v_dc_start")
        )
    else
        v_dc = _PM.var(pm, nw)[:v_dc] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_bus)], base_name="$(nw)_v_dc",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "v_dc_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :gmd_bus, :v_dc, _PM.ids(pm, nw, :gmd_bus), v_dc)

end


"VARIABLE: dc voltage difference"
function variable_dc_voltage_difference(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        v_dc_diff = _PM.var(pm, nw)[:v_dc_diff] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_v_dc_diff",
            lower_bound = -calc_max_dc_voltage_difference(pm, i, nw=nw),
            upper_bound = calc_max_dc_voltage_difference(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_dc_start_diff")
        )
    else
        v_dc_diff = _PM.var(pm, nw)[:v_dc_diff] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_v_dc_diff",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_dc_start_diff")
        )
    end

    report && _PM.sol_component_value(pm, nw, :gmd_branch, :v_dc_diff, _PM.ids(pm, nw, :gmd_branch), v_dc_diff)

end


"VARIABLE: dc voltage on/off"
function variable_dc_voltage_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    variable_dc_voltage(pm; nw=nw, bounded=bounded)
    variable_dc_voltage_difference(pm; nw=nw, bounded=bounded)

    # McCormick variable
    vz = _PM.var(pm, nw)[:vz] = JuMP.@variable(pm.model,
          [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_vz",
          start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_vz_start")
    )

    report && _PM.sol_component_value(pm, nw, :gmd_branch, :vz, _PM.ids(pm, nw, :gmd_branch), vz)

end


"VARIABLE: dc current magnitude"
function variable_dc_current_mag(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        i_dc_mag = _PM.var(pm, nw)[:i_dc_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_start")
        )
    else
        i_dc_mag = _PM.var(pm, nw)[:i_dc_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :i_dc_mag, _PM.ids(pm, nw, :branch), i_dc_mag)

end


"VARIABLE: dc current magnitude squared"
function variable_dc_current_mag_sqr(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        i_dc_mag_sqr = _PM.var(pm, nw)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag_sqr",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw)^2,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start")
        )
    else
        i_dc_mag_sqr = _PM.var(pm, nw)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag_sqr",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :i_dc_mag_sqr, _PM.ids(pm, nw, :branch), i_dc_mag_sqr)

end


"VARIABLE: dc line flow"
function variable_dc_line_flow(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        dc = _PM.var(pm, nw)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_dc",
            lower_bound = -Inf,
            upper_bound = Inf,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, l), "dc_start")
        )
    else
        dc = _PM.var(pm, nw)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_dc",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, l), "dc_start")
        )
    end

    dc_expr = Dict{Any,Any}( (l,i,j) => -1.0 * dc[(l,i,j)] for (l,i,j) in _PM.ref(pm, nw, :gmd_arcs_from) )
    dc_expr = merge(dc_expr, Dict( (l,j,i) => 1.0 * dc[(l,i,j)] for (l,i,j) in _PM.ref(pm, nw, :gmd_arcs_from) ))

    report && _IM.sol_component_value_edge(pm, pm_it_sym, nw, :gmd_branch, :dcf, :dct, _PM.ref(pm, nw, :gmd_arcs_from), _PM.ref(pm, nw, :gmd_arcs_to), dc_expr)

    if !haskey(pm.model.ext, :nw)
        pm.model.ext[:nw] = Dict()
    end

    if !haskey(pm.model.ext[:nw], nw)
        pm.model.ext[:nw][nw] = Dict()
    end

    pm.model.ext[:nw][nw][:dc_expr] = dc_expr

end


"VARIABLE: qloss"
function variable_qloss(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        qloss = _PM.var(pm, nw)[:qloss] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_qloss",
            lower_bound = 0.0,
            upper_bound = Inf,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "qloss_start")
        )
     else
        qloss = _PM.var(pm, nw)[:qloss] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_qloss",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "qloss_start")
        )
     end

    report && _IM.sol_component_value_edge(pm, pm_it_sym, nw, :branch, :qlossf, :qlosst, _PM.ref(pm, nw, :arcs_from), _PM.ref(pm, nw, :arcs_to), qloss)

end

"VARIABLE: demand factor"
function variable_demand_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    z_demand = _PM.var(pm, nw)[:z_demand] = JuMP.@variable(pm.model,
        0 <= z_demand[i in _PM.ids(pm, nw, :bus)] <= 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_demand_start", 1.0)
    )

    report && _PM.sol_component_value(pm, nw, :bus, :z_demand, _PM.ids(pm, nw, :bus), z_demand)
end


"VARIABLE: shunt factor"
function variable_shunt_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    z_shunt = _PM.var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
        0 <= z_shunt[i in _PM.ids(pm, nw, :bus)] <= 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_shunt_nstart", 1.0)
    )

    report && _PM.sol_component_value(pm, nw, :bus, :z_shunt, _PM.ids(pm, nw, :bus), z_shunt)

end


"VARIABLE: active and reactive load"
function variable_load(pm::_PM.AbstractPowerModel; kwargs...)

    variable_active_load(pm; kwargs...)
    variable_reactive_load(pm; kwargs...)

end


"VARIABLE: active load"
function variable_active_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        pd = _PM.var(pm, nw)[:pd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pd",
            lower_bound = min(0,_PM.ref(pm, nw, :load, i)["pd"]),
            upper_bound = max(0,_PM.ref(pm, nw, :load, i)["pd"]),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd_start")
        )
    else
        pd = _PM.var(pm, nw)[:pd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pd",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)

end


"VARIABLE: reactive load"
function variable_reactive_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        qd = _PM.var(pm, nw)[:qd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qd",
            lower_bound = min(0, _PM.ref(pm, nw, :load, i)["qd"]),
            upper_bound = max(0, _PM.ref(pm, nw, :load, i)["qd"]),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd_start")
        )
    else
        qd = _PM.var(pm, nw)[:qd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qd",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)

end


"VARIABLE: ac current magnitude"
function variable_ac_current_mag(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        i_ac_mag = _PM.var(pm, nw)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag",
            lower_bound = calc_ac_mag_min(pm, i, nw=nw),
            upper_bound = calc_ac_mag_max(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_ac_mag_start")
        )
    else
        i_ac_mag = _PM.var(pm, nw)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_ac_mag_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :i_ac_mag, _PM.ids(pm, nw, :branch), i_ac_mag)

end


"VARIABLE: iv"
function variable_iv(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    iv = _PM.var(pm, nw)[:iv] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_iv",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "iv_start")
    )

    report && _IM.sol_component_value_edge(pm, pm_it_sym, nw, :branch, :ivf, :ivt, _PM.ref(pm, nw, :arcs_from), _PM.ref(pm, nw, :arcs_to), iv)

end


"VARIABLE: active generation squared cost"
function variable_active_generation_sqr_cost(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        pg_sqr = _PM.var(pm, nw)[:pg_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_sqr",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :gen, i)["cost"][1] * _PM.ref(pm, nw, :gen, i)["pmax"]^2,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_sqr_start")
        )
    else
        pg_sqr = _PM.var(pm, nw)[:pg_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_sqr",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_sqr_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :gen, :pg_sqr, _PM.ids(pm, nw, :gen), pg_sqr)

end




# ===   THERMAL VARIABLES   === #


"VARIABLE: steady-state top-oil temperature rise"
function variable_delta_oil_ss(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        delta_oil_ss = _PM.var(pm, nw)[:ross] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil_ss",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_ss_start")
        )
    else
        delta_oil_ss = _PM.var(pm, nw)[:ross] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil_ss",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_ss_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :delta_oil_ss, _PM.ids(pm, nw, :branch), delta_oil_ss)

end


"VARIABLE: top-oil temperature rise"
function variable_delta_oil(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        delta_oil = _PM.var(pm, nw)[:ro] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_start")
        )
    else
        delta_oil = _PM.var(pm, nw)[:ro] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :delta_oil, _PM.ids(pm, nw, :branch), delta_oil)

end


"VARIABLE: steady-state hot-spot temperature rise"
function variable_delta_hotspot_ss(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    tmax = 1000

    if bounded
        delta_hotspot_ss = _PM.var(pm, nw)[:hsss] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot_ss",
            lower_bound = 0,
            upper_bound = tmax,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_hotspot_ss_start")
        )
    else
        delta_hotspot_ss = _PM.var(pm, nw)[:hsss] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot_ss",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_hotspot_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :delta_hotspot_ss, _PM.ids(pm, nw, :branch), delta_hotspot_ss)

end


"VARIABLE: hot-spot temperature rise"
function variable_delta_hotspot(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    tmax = 1000

    if bounded
        delta_hotspot = _PM.var(pm, nw)[:hs] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot",
            lower_bound = 0,
            upper_bound = tmax,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_hotspot_start")
        )
    else
        delta_hotspot = _PM.var(pm, nw)[:hs] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_hotspot_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :delta_hotspot, _PM.ids(pm, nw, :branch), delta_hotspot)

end


"VARIABLE: hot-spot temperature"
function variable_hotspot(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        hotspot = _PM.var(pm, nw)[:hsa] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_hotspot",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "hotspot_start")
        )
    else
        hotspot = _PM.var(pm, nw)[:hsa] = JuMP.@variable(pm.model, 
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_hotspot",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "hotspot_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :hotspot, _PM.ids(pm, nw, :branch), hotspot)

end




# ===   CASCADING VARIABLES   === #


#"""
#    variable_mc_load_block_indicator(pm::PMD.AbstractUnbalancedPowerModel; nw::Int=PMD.nw_id_default, relax::Bool=false, report::Bool=true)
#
#create variables for demand status by connected component
#"""
#function variable_mc_block_demand_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
#    if relax
#        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
#            [i in _PM.ids(pm, nw, :ref_buses)], base_name="$(nw)_z_demand",
#            lower_bound = 0,
#            upper_bound = 1,
#            start = 1.0
#        )
#    else
#        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
#            [i in _PM.ids(pm, nw, :ref_buses)], base_name="$(nw)_z_demand",
#            binary = true,
#            start = 1
#        )
#    end
#
#
#    load_block_map = _PM.ref(pm, nw, :load_block_map)
#    _PM.var(pm, nw)[:z_demand] = Dict(l => z_demand[load_ref_bus_map[l]] for l in _PM.ids(pm, nw, :load))
#
#    # expressions for pd and qd
#    pd = _PM.var(pm, nw)[:pd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["pd"] for i in _PM.ids(pm, nw, :load))
#    qd = _PM.var(pm, nw)[:qd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["qd"] for i in _PM.ids(pm, nw, :load))
#
#    report && _PM._IM.sol_component_value(pm, _PM.pmd_it_sym, nw, :load, :status, _PM.ids(pm, nw, :load), _PM.var(pm, nw)[:z_demand])
#    report && _PM._IM.sol_component_value(pm, _PM.pmd_it_sym, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)
#    report && _PM._IM.sol_component_value(pm, _PM.pmd_it_sym, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)
#end

"""
variable_block_demand_indicator(pm::PMD.AbstractUnbalancedPowerModel; nw::Int=PMD.nw_id_default, relax::Bool=false, report::Bool=true)
create a single for demand status by largest connected component
"""
function variable_block_demand_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, relax::Bool=false)
    # JuMP allows for declaring scalar variables. 
    # Declaring this as a vector for compatibility when using multiple islands
    if relax
        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_demand",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    else
        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_demand",
            binary = true,
            start = 1
        )
    end

    #load_block_map = _PM.ref(pm, nw, :load_block_map)
    #_PM.var(pm, nw)[:z_demand] = Dict(l => z_demand[load_ref_bus_map[l]] for l in _PM.ids(pm, nw, :load))
    _PM.var(pm, nw)[:z_demand] = Dict(l => z_demand[1] for l in _PM.ids(pm, nw, :load))

    # expressions for pd and qd
    pd = _PM.var(pm, nw)[:pd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["pd"] for i in _PM.ids(pm, nw, :load))
    qd = _PM.var(pm, nw)[:qd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["qd"] for i in _PM.ids(pm, nw, :load))

    report && _PM.sol_component_value(pm, nw, :load, :status, _PM.ids(pm, nw, :load), _PM.var(pm, nw)[:z_demand])
    report && _PM.sol_component_value(pm, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)
    report && _PM.sol_component_value(pm, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)
end


# function variable_gen_indicator(pm::AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
#     if !relax
#         z_gen = var(pm, nw)[:z_gen] = JuMP.@variable(pm.model,
#             [i in ids(pm, nw, :gen)], base_name="$(nw)_z_gen",
#             binary = true,
#             start = comp_start_value(ref(pm, nw, :gen, i), "z_gen_start", 1.0)
#         )
#     else
#         z_gen = var(pm, nw)[:z_gen] = JuMP.@variable(pm.model,
#             [i in ids(pm, nw, :gen)], base_name="$(nw)_z_gen",
#             lower_bound = 0,
#             upper_bound = 1,
#             start = comp_start_value(ref(pm, nw, :gen, i), "z_gen_start", 1.0)
#         )
#     end

#     report && _IM.sol_component_value(pm, nw, :gen, :gen_status, ids(pm, nw, :gen), z_gen)
# end

"""
variable_block_gen_indicator(pm::PMD.AbstractUnbalancedPowerModel; nw::Int=PMD.nw_id_default, relax::Bool=false, report::Bool=true)
create a single for demand status by largest connected component
"""
function variable_block_gen_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, relax::Bool=false)
    # JuMP allows for declaring scalar variables. 
    # Declaring this as a vector for compatibility when using multiple islands
    if relax
        z_gen = _PM.var(pm, nw)[:z_gen_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    else
        z_gen = _PM.var(pm, nw)[:z_gen_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_gen",
            binary = true,
            start = 1
        )
    end

    #load_block_map = _PM.ref(pm, nw, :load_block_map)
    #_PM.var(pm, nw)[:z_gen] = Dict(l => z_gen[load_ref_bus_map[l]] for l in _PM.ids(pm, nw, :load))
    _PM.var(pm, nw)[:z_gen] = Dict(g => z_gen[1] for g in _PM.ids(pm, nw, :gen))

    # expressions for pd and qd
    # pd = _PM.var(pm, nw)[:pd] = Dict(i => _PM.var(pm, nw)[:z_gen][i].*_PM.ref(pm, nw, :load, i)["pd"] for i in _PM.ids(pm, nw, :load))
    # qd = _PM.var(pm, nw)[:qd] = Dict(i => _PM.var(pm, nw)[:z_gen][i].*_PM.ref(pm, nw, :load, i)["qd"] for i in _PM.ids(pm, nw, :load))

    report && _PM.sol_component_value(pm, nw, :load, :gen, _PM.ids(pm, nw, :gen), _PM.var(pm, nw)[:z_gen])
    # report && _PM.sol_component_value(pm, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)
    # report && _PM.sol_component_value(pm, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)
end


# ""
# function variable_shunt_admittance_factor(pm::AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
#     if !relax
#         z_shunt = var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
#             [i in ids(pm, nw, :shunt)], base_name="$(nw)_z_shunt",
#             binary = true,
#             start = comp_start_value(ref(pm, nw, :shunt, i), "z_shunt_start", 1.0)
#         )
#     else
#         z_shunt = var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
#             [i in ids(pm, nw, :shunt)], base_name="$(nw)_z_shunt",
#             upper_bound = 1,
#             lower_bound = 0,
#             start = comp_start_value(ref(pm, nw, :shunt, i), "z_shunt_start", 1.0)
#         )
#     end

#     if report
#         _IM.sol_component_value(pm, nw, :shunt, :status, ids(pm, nw, :shunt), z_shunt)
#         sol_gs = Dict(i => z_shunt[i]*ref(pm, nw, :shunt, i)["gs"] for i in ids(pm, nw, :shunt))
#         _IM.sol_component_value(pm, nw, :shunt, :gs, ids(pm, nw, :shunt), sol_gs)
#         sol_bs = Dict(i => z_shunt[i]*ref(pm, nw, :shunt, i)["bs"] for i in ids(pm, nw, :shunt))
#         _IM.sol_component_value(pm, nw, :shunt, :bs, ids(pm, nw, :shunt), sol_bs)
#     end
# end

"""
variable_block_demand_indicator(pm::PMD.AbstractUnbalancedPowerModel; nw::Int=PMD.nw_id_default, relax::Bool=false, report::Bool=true)
create a single for demand status by largest connected component
"""
function variable_block_shunt_admittance_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, relax::Bool=false)
    # JuMP allows for declaring scalar variables. 
    # Declaring this as a vector for compatibility when using multiple islands
    if relax
        z_shunt = _PM.var(pm, nw)[:z_shunt_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_shunt",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    else
        z_shunt = _PM.var(pm, nw)[:z_shunt_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_shunt",
            binary = true,
            start = 1
        )
    end

    _PM.var(pm, nw)[:z_shunt] = Dict(g => z_shunt[1] for g in _PM.ids(pm, nw, :shunt))

    wz_shunt = _PM.var(pm, nw)[:wz_shunt] = JuMP.@variable(pm.model,
    [1], base_name="$(nw)_wz_shunt",
    lower_bound = 0,
    upper_bound = 1.1,
    start = 1.001
    )

    _PM.var(pm, nw)[:wz_shunt] = Dict(g => wz_shunt[1] for g in _PM.ids(pm, nw, :shunt))

    if report
        # TODO: will this fail if there are no shunts in the system?
        # _IM.sol_component_value(pm, nw, :shunt, :status, ids(pm, nw, :shunt), z_shunt)
        _PM.sol_component_value(pm, nw, :load, :shunt, _PM.ids(pm, nw, :shunt), _PM.var(pm, nw)[:z_shunt])
        sol_gs = Dict(i => z_shunt[1]*_PM.ref(pm, nw, :shunt, i)["gs"] for i in _PM.ids(pm, nw, :shunt))
        _PM.sol_component_value(pm, nw, :shunt, :gs, _PM.ids(pm, nw, :shunt), sol_gs)
        sol_bs = Dict(i => z_shunt[1]*_PM.ref(pm, nw, :shunt, i)["bs"] for i in _PM.ids(pm, nw, :shunt))
        _PM.sol_component_value(pm, nw, :shunt, :bs, _PM.ids(pm, nw, :shunt), sol_bs)
    end
end

# "variable: `0 <= gic_blocker_placement[l] <= 1` for `l` in `gmd_bus`es"
# function variable_gic_blocker_placement_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
#     if !relax
#         z_gic_blocker_placement = var(pm, nw)[:gic_blocker_placement] = JuMP.@variable(pm.model,
#             [l in ids(pm, nw, :placement_gic_blocker)], base_name="$(nw)_gic_blocker_placement",
#             binary = true,
#             start = comp_start_value(ref(pm, nw, :placement_gic_blocker, l), "gic_blocker_placement_start", 1.0)
#         )
#     else
#         z_gic_blocker_placement = var(pm, nw)[:gic_blocker_placement] = JuMP.@variable(pm.model,
#             [l in ids(pm, nw, :placement_gic_blocker)], base_name="$(nw)_gic_blocker_placement",
#             lower_bound = 0.0,
#             upper_bound = 1.0,
#             start = comp_start_value(ref(pm, nw, :placement_gic_blocker, l), "gic_blocker_placement_start", 1.0)
#         )
#     end
# 
#     report && sol_component_value(pm, nw, :placement_gic_blocker, :built, ids(pm, nw, :placement_gic_blocker), z_gic_blocker_placement)
# end
# 
# "variable: `0 <= gic_blocker[l] <= 1` for `l` in `gmd_bus`es"
# function variable_gic_blocker_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
#     if !relax
#         z_gic_blocker = var(pm, nw)[:gic_blocker] = JuMP.@variable(pm.model,
#             [l in ids(pm, nw, :gic_blocker)], base_name="$(nw)_gic_blocker",
#             binary = true,
#             start = comp_start_value(ref(pm, nw, :gic_blocker, l), "gic_blocker_start", 1.0)
#         )
#     else
#         z_gic_blocker = var(pm, nw)[:gic_blocker] = JuMP.@variable(pm.model,
#             [l in ids(pm, nw, :gic_blocker)], base_name="$(nw)_gic_blocker",
#             lower_bound = 0.0,
#             upper_bound = 1.0,
#             start = comp_start_value(ref(pm, nw, :gic_blocker, l), "gic_blocker_start", 1.0)
#         )
#     end
# 
#     report && sol_component_value(pm, nw, :gic_blocker, :built, ids(pm, nw, :gic_blocker), z_gic_blocker)
# end


"variable: `0 <= gic_blocker[l] <= 1` for `l` in `gmd_bus`es"
function variable_blocker_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, relax::Bool=false, report::Bool=true)
    # TODO: only create GIC blocker variables where GIC blockers are installed
    if !relax
        z_gic_blocker = _PM.var(pm, nw)[:z_blocker] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_bus)], base_name="$(nw)_z_blocker",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "z_blocker_start", 1.0)
        )
    else
        z_gic_blocker = _PM.var(pm, nw)[:z_blocker] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_bus)], base_name="$(nw)_z_blocker",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "z_blocker_start", 1.0)
        )
    end

    report && _PM.sol_component_value(pm, nw, :gmd_bus, :z_blocker, _PM.ids(pm, nw, :gmd_bus), z_gic_blocker)
end

