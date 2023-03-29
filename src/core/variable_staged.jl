"VARIABLE: bus dc voltage difference"
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


"VARIABLE: bus dc voltage on/off"
function variable_dc_voltage_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    variable_dc_voltage(pm; nw=nw, bounded=bounded)
    variable_dc_voltage_difference(pm; nw=nw, bounded=bounded)

    # McCormick variable:
    vz = _PM.var(pm, nw)[:vz] = JuMP.@variable(pm.model,
          [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_vz",
          start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_vz_start")
    )

    report && _PM.sol_component_value(pm, nw, :gmd_branch, :vz, _PM.ids(pm, nw, :gmd_branch), vz)

end


# ===   CURRENT VARIABLES   === #


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


# ===   GENERATOR VARIABLES   === #


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

    report && _PM.sol_component_value(pm, nw, :branch, :actual_hotspot, _PM.ids(pm, nw, :branch), hotspot)
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

    report && _PM.sol_component_value(pm, nw, :branch, :hotspot_rise_ss, _PM.ids(pm, nw, :branch), delta_hotspot_ss)

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

    report && _PM.sol_component_value(pm, nw, :branch, :hotspot_rise, _PM.ids(pm, nw, :branch), delta_hotspot)

end


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

    report && _PM.sol_component_value(pm, nw, :branch, :topoil_rise_ss, _PM.ids(pm, nw, :branch), delta_oil_ss)

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

    report && _PM.sol_component_value(pm, nw, :branch, :topoil_rise, _PM.ids(pm, nw, :branch), delta_oil)

end


# ===   MLD VARIABLES   === #


"VARIABLE: block gen indicator"
function variable_block_gen_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
# Reference:
#   variable is based on "variable_gen_indicator" of PowerModels.jl
#   (https://github.com/lanl-ansi/PowerModels.jl/blob/31f8273ec18aeea158a2995a0bfe6a31094fe98e/src/core/variable.jl#L350)

    if !relax
        z_gen = _PM.var(pm, nw)[:z_gen_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_gen",
            binary = true,
            start = 1
        )
    else
        z_gen = _PM.var(pm, nw)[:z_gen_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    end

    _PM.var(pm, nw)[:z_gen] = Dict(g => z_gen[1] for g in _PM.ids(pm, nw, :gen))

    report && _PM.sol_component_value(pm, nw, :gen, :gen_status, _PM.ids(pm, nw, :gen), _PM.var(pm, nw)[:z_gen])

end


"VARIABLE: block demand factor"
function variable_block_demand_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
# Reference:
#   variable is based on "variable_gen_indicator" of PowerModels.jl
#   (https://github.com/lanl-ansi/PowerModels.jl/blob/31f8273ec18aeea158a2995a0bfe6a31094fe98e/src/core/variable.jl#L1273)

    if !relax
        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_demand",
            binary = true,
            start = 1
        )
    else
        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_demand",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    end

    _PM.var(pm, nw)[:z_demand] = Dict(l => z_demand[1] for l in _PM.ids(pm, nw, :load))

    pd = _PM.var(pm, nw)[:pd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["pd"] for i in _PM.ids(pm, nw, :load))
    qd = _PM.var(pm, nw)[:qd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["qd"] for i in _PM.ids(pm, nw, :load))

    report && _PM.sol_component_value(pm, nw, :load, :status, _PM.ids(pm, nw, :load), _PM.var(pm, nw)[:z_demand])
    report && _PM.sol_component_value(pm, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)
    report && _PM.sol_component_value(pm, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)

end


"VARIABLE: block shunt admittance factor"
function variable_block_shunt_admittance_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default,  relax::Bool=false, report::Bool=true)
# Reference:
#   variable is based on "variable_shunt_admittance_factor" of PowerModels.jl
#   (https://github.com/lanl-ansi/PowerModels.jl/blob/31f8273ec18aeea158a2995a0bfe6a31094fe98e/src/core/variable.jl#L1300)

    if !relax
        z_shunt = _PM.var(pm, nw)[:z_shunt_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_shunt",
            binary = true,
            start = 1
        )
    else
        z_shunt = _PM.var(pm, nw)[:z_shunt_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_shunt",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    end

    _PM.var(pm, nw)[:z_shunt] = Dict(g => z_shunt[1] for g in _PM.ids(pm, nw, :shunt))

    if report
        _PM.sol_component_value(pm, nw, :load, :shunt, _PM.ids(pm, nw, :shunt), _PM.var(pm, nw)[:z_shunt])
        sol_gs = Dict(i => z_shunt[1]*_PM.ref(pm, nw, :shunt, i)["gs"] for i in _PM.ids(pm, nw, :shunt))
        _PM.sol_component_value(pm, nw, :shunt, :gs, _PM.ids(pm, nw, :shunt), sol_gs)
        sol_bs = Dict(i => z_shunt[1]*_PM.ref(pm, nw, :shunt, i)["bs"] for i in _PM.ids(pm, nw, :shunt))
        _PM.sol_component_value(pm, nw, :shunt, :bs, _PM.ids(pm, nw, :shunt), sol_bs)
    end

    wz_shunt = _PM.var(pm, nw)[:wz_shunt] = JuMP.@variable(pm.model,
        [1], base_name="$(nw)_wz_shunt",
        lower_bound = 0,
        upper_bound = 1.1,
        start = 1.001
    )

    _PM.var(pm, nw)[:wz_shunt] = Dict(g => wz_shunt[1] for g in _PM.ids(pm, nw, :shunt))

    report && _PM.sol_component_value(pm, nw, :load, :shunt, _PM.ids(pm, nw, :shunt), _PM.var(pm, nw)[:wz_shunt])

end


# ===   GIC BLOCKER VARIABLES   === #


"VARIABLE: gic blocker indicator"
function variable_blocker_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, relax::Bool=false, report::Bool=true)

    # TODO: only create GIC blocker variables where GIC blockers are installed
    if !relax
        z_gic_blocker = _PM.var(pm, nw)[:z_blocker] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :bus_blockers)], base_name="$(nw)_z_blocker",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :blocker_buses, i), "z_blocker_start", 1.0)
        )
    else
        z_gic_blocker = _PM.var(pm, nw)[:z_blocker] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :bus_blockers)], base_name="$(nw)_z_blocker",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :blocker_buses, i), "z_blocker_start", 1.0)
        )
    end

    report && _PM.sol_component_value(pm, nw, :gmd_bus, :blocker_placed, _PM.ids(pm, nw, :bus_blockers), z_gic_blocker)
end
