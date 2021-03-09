# --- General Variables --- #


"VARIABLE: dc voltage"
function variable_dc_voltage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `v_dc[j]` for `j` in `gmd_bus`
    if bounded
        _PM.var(pm, nw)[:v_dc] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_bus)], base_name="$(nw)_v_dc",
            lower_bound = calc_min_dc_voltage(pm, i, nw=nw),
            upper_bound = calc_max_dc_voltage(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "v_dc_start")
        )
    else
        _PM.var(pm, nw)[:v_dc] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_bus)], base_name="$(nw)_v_dc",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "v_dc_start")
        )
    end

end


"VARIABLE: dc voltage difference"
function variable_dc_voltage_difference(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)
    
    # `v_dc[j]` for `j` in `gmd_branch`
    if bounded
        _PM.var(pm, nw)[:v_dc_diff] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_v_dc_diff",
            lower_bound = -calc_max_dc_voltage_difference(pm, i, nw=nw),
            upper_bound = calc_max_dc_voltage_difference(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_dc_start_diff")
        )
    else
        _PM.var(pm, nw)[:v_dc_diff] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_v_dc_diff",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_dc_start_diff")
        )
    end

end


"VARIABLE: dc voltage on/off"
function variable_dc_voltage_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `v_dc[j]` for `j` in `gmd_bus`
    variable_dc_voltage(pm; nw=nw, bounded=bounded)
    variable_dc_voltage_difference(pm; nw=nw, bounded=bounded)

    # McCormick variable
    _PM.var(pm, nw)[:vz] = JuMP.@variable(pm.model,
          [i in _PM.ids(pm, nw, :gmd_branch)], base_name="$(nw)_vz",
          start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, i), "v_vz_start")
    )

end


"VARIABLE: dc current magnitude"
function variable_dc_current_mag(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `i_dc_mag[j]` for `j` in `branch`
    if bounded
        _PM.var(pm, nw)[:i_dc_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_start")
        )
    else
        _PM.var(pm, nw)[:i_dc_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_start")
        )
    end

end


"VARIABLE: dc current magnitude squared"
function variable_dc_current_mag_sqr(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default,bounded::Bool=true)

    # `i_dc_mag_sqr[j]` for `j` in `branch`
    if bounded
        _PM.var(pm, nw)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag_sqr",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw)^2,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start")
        )
    else
        _PM.var(pm, nw)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag_sqr",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start")
        )
    end

end


"VARIABLE: dc line flow"
function variable_dc_line_flow(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `dc[j]` for `j` in `gmd_branch`
    if bounded
        _PM.var(pm, nw)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_dc",
            lower_bound = -Inf,
            upper_bound = Inf,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, l), "dc_start")
        )
    else
        _PM.var(pm, nw)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_dc",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, l), "dc_start")
        )
    end

    dc_expr = Dict([((l,i,j), -1.0*_PM.var(pm, nw, :dc, (l,i,j))) for (l,i,j) in _PM.ref(pm, nw, :gmd_arcs_from)])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*_PM.var(pm, nw, :dc, (l,i,j))) for (l,i,j) in _PM.ref(pm, nw, :gmd_arcs_from)]))

    if !haskey(pm.model.ext, :nw)
        pm.model.ext[:nw] = Dict()
    end

    if !haskey(pm.model.ext[:nw], nw)
        pm.model.ext[:nw][nw] = Dict()
    end

    pm.model.ext[:nw][nw][:dc_expr] = dc_expr

end


"VARIABLE: Qloss"
function variable_qloss(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `qloss[j]` for `j` in `arcs`
    if bounded
       _PM.var(pm, nw)[:qloss] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_qloss",
            lower_bound = 0.0,
            upper_bound = Inf,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "qloss_start")
        )
    else
        _PM.var(pm, nw)[:qloss] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_qloss",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "qloss_start")
        )
    end

end


"VARIABLE: demand factor"
function variable_demand_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)

    _PM.var(pm, nw)[:z_demand] = JuMP.@variable(pm.model,
        0 <= z_demand[i in _PM.ids(pm, nw, :bus)] <= 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_demand_start", 1.0)
    )

end


"VARIABLE: shunt factor"
function variable_shunt_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)

    _PM.var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
        0 <= z_shunt[i in _PM.ids(pm, nw, :bus)] <= 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_shunt_nstart", 1.0)
    )

end


"VARIABLE: load"
function variable_load(pm::_PM.AbstractPowerModel; kwargs...)

    # generates variables for both `active` and `reactive` load
    variable_active_load(pm; kwargs...)
    variable_reactive_load(pm; kwargs...)

end


"VARIABLE: active load"
function variable_active_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `pd[j]` for `j` in `bus`
    if bounded
        _PM.var(pm, nw)[:pd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pd",
            lower_bound = min(0,_PM.ref(pm, nw, :load, i)["pd"]),
            upper_bound = max(0,_PM.ref(pm, nw, :load, i)["pd"]),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd_start")
        )
    else
        _PM.var(pm, nw)[:pd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pd",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd_start")
        )
    end

end


"VARIABLE: reactive load"
function variable_reactive_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `qd[j]` for `j` in `bus`
    if bounded
        _PM.var(pm, nw)[:qd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qd",
            lower_bound = min(0, _PM.ref(pm, nw, :load, i)["qd"]),
            upper_bound = max(0, _PM.ref(pm, nw, :load, i)["qd"]),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd_start")
        )
    else
        _PM.var(pm, nw)[:qd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qd",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd_start")
        )
    end

end


"VARIABLE: ac current magnitude"
function variable_ac_current_mag(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default,bounded::Bool=true)

    # `i_ac_mag[j]` for `j` in `branch'
    if bounded
        _PM.var(pm, nw)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag",
            lower_bound = calc_ac_mag_min(pm, i, nw=nw),
            upper_bound = calc_ac_mag_max(pm, i, nw=nw),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_ac_mag_start")
        )
    else
        _PM.var(pm, nw)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_ac_mag_start")
        )
    end

end


"VARIABLE: iv"
function variable_iv(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)

    # `iv[j]` for `j` in `arcs`
    _PM.var(pm, nw)[:iv] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_iv",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "iv_start")
    )

end


"VARIABLE: generation indicator"
function variable_gen_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)
 
    # `0 <= gen_z[i] <= 1` for `i` in `generator`s
    _PM.var(pm, nw)[:gen_z] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_gen_z",
        lower_bound = 0,
        upper_bound = 1,
        integer = true,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "gen_z_start", 1.0)
    )

end


"VARIABLE: active generation squared cost"
function variable_active_generation_sqr_cost(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    # `pg[j]^2` for `j` in `gen`
    if bounded
        _PM.var(pm, nw)[:pg_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_sqr",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :gen, i)["cost"][1] * _PM.ref(pm, nw, :gen, i)["pmax"]^2,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_sqr_start")
        )
    else
        _PM.var(pm, nw)[:pg_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_sqr",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_sqr_start")
        )
    end

end



# --- Thermal Variables --- #

tmax = 1000

"VARIABLE: steady-state top-oil temperature rise"
function variable_delta_oil_ss(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    if bounded
    
        #hsl = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit")
        #println("hotspot limit for $i: $hsl")
        _PM.var(pm, nw)[:ross] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil_ss",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            #upper_bound = tmax,
            #upper_bound = 280,
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_ss_start")
        )
    else

        _PM.var(pm, nw)[:ross] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil_ss",
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_ss_start")
        )
    end

end


"VARIABLE: top-oil temperature rise"
function variable_delta_oil(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    if bounded
        _PM.var(pm, nw)[:ro] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            #upper_bound = tmax,
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_start")
        )
    else

        _PM.var(pm, nw)[:ro] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_oil",
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_start")
        )
    end

end


"VARIABLE: steady-state hot-spot temperature rise"
function variable_delta_hotspot_ss(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    if bounded
        _PM.var(pm, nw)[:hsss] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot_ss",
            lower_bound = 0,
            #upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            upper_bound = tmax,
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_hotspot_ss_start")
        )
    else

        _PM.var(pm, nw)[:hsss] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot_ss",
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_oil_hotspot_start")
        )
    end

end


"VARIABLE: hot-spot temperature rise"
function variable_delta_hotspot(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    if bounded
        _PM.var(pm, nw)[:hs] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot",
            lower_bound = 0,
            #upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            upper_bound = tmax,
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_hotspot_start")
        )
    else

        _PM.var(pm, nw)[:hs] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_delta_hotspot",
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "delta_hotspot_start")
        )
    end

end


"VARIABLE: hot-spot temperature"
function variable_hotspot(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true)

    if bounded
        _PM.var(pm, nw)[:hsa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_hotspot",
            lower_bound = 0,
            upper_bound = _PM.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            #upper_bound = tmax,
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "hotspot_start")
        )
    else

        _PM.var(pm, nw)[:hsa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_hotspot",
            start = PowerModels.comp_start_value(_PM.ref(pm, nw, :branch, i), "hotspot_start")
        )
    end

end


