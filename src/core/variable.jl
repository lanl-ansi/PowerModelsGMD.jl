"variable: `v_dc[j]` for `j` in `gmd_bus`"
function variable_dc_voltage(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:v_dc] = @variable(pm.model, 
            [i in ids(pm, nw, :gmd_bus)], basename="$(nw)_$(cnd)_v_dc",
            lowerbound = calc_min_dc_voltage(pm, i, nw=nw),
            upperbound = calc_max_dc_voltage(pm, i, nw=nw),
            start = PMs.getval(ref(pm, nw, :gmd_bus, i), "v_dc_start", cnd)
        )
    else
        var(pm, nw, cnd)[:v_dc] = @variable(pm.model, 
            [i in ids(pm, nw, :gmd_bus)], basename="$(nw)_$(cnd)_v_dc",
            start = PMs.getval(ref(pm, nw, :gmd_bus, i), "v_dc_start", cnd)
        )
    end
end

"variable: `v_dc[j]` for `j` in `gmd_branch`"
function variable_dc_voltage_difference(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:v_dc_diff] = @variable(pm.model, 
            [i in ids(pm, nw, :gmd_branch)], basename="$(nw)_$(cnd)_v_dc_diff",
            lowerbound = -calc_max_dc_voltage_difference(pm, i, nw=nw),
            upperbound = calc_max_dc_voltage_difference(pm, i, nw=nw),
            start = PMs.getval(ref(pm, nw, :gmd_branch, i), "v_dc_start_diff", cnd)
        )
    else
        var(pm, nw, cnd)[:v_dc_diff] = @variable(pm.model, 
            [i in ids(pm, nw, :gmd_branch)], basename="$(nw)_$(cnd)_v_dc_diff",
            start = PMs.getval(ref(pm, nw, :gmd_branch, i), "v_dc_start_diff", cnd)
        )
    end

end

"variable: `v_dc[j]` for `j` in `gmd_bus`"
function variable_dc_voltage_on_off(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    variable_dc_voltage(pm; nw=nw, cnd=cnd, bounded=bounded)
    variable_dc_voltage_difference(pm; nw=nw, cnd=cnd, bounded=bounded)

    # McCormick variable
    var(pm, nw, cnd)[:vz] = @variable(pm.model,
          [i in ids(pm, nw, :gmd_branch)], basename="$(nw)_$(cnd)_vz",
          start = PMs.getval(ref(pm, nw, :gmd_branch, i), "v_vz_start", cnd)
    )
end

"variable: `i_dc_mag[j]` for `j` in `branch`"
function variable_dc_current_mag(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:i_dc_mag] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_i_dc_mag",
            lowerbound = 0,
            upperbound = calc_dc_mag_max(pm, i, nw=nw),
            start = PMs.getval(ref(pm, nw, :branch, i), "i_dc_mag_start", cnd)
        )
    else
        var(pm, nw, cnd)[:i_dc_mag] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_i_dc_mag",
            start = PMs.getval(ref(pm, nw, :branch, i), "i_dc_mag_start", cnd)
        )
    end
end

"variable: `i_dc_mag_sqr[j]` for `j` in `branch`"
function variable_dc_current_mag_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:i_dc_mag_sqr] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_i_dc_mag_sqr",
            lowerbound = 0,
            upperbound = calc_dc_mag_max(pm, i, nw=nw)^2,
            start = PMs.getval(ref(pm, nw, :branch, i), "i_dc_mag_sqr_start", cnd)
        )
    else
        var(pm, nw, cnd)[:i_dc_mag_sqr] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_i_dc_mag_sqr",
            start = PMs.getval(ref(pm, nw, :branch, i), "i_dc_mag_sqr_start", cnd)
        )
    end
end

"variable: `dc[j]` for `j` in `gmd_branch`"
function variable_dc_line_flow(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:dc] = @variable(pm.model, 
            [(l,i,j) in ref(pm, nw, :gmd_arcs)], basename="$(nw)_$(cnd)_dc",
            lowerbound = -Inf,
            upperbound = Inf,
            start = PMs.getval(ref(pm, nw, :gmd_branch, l), "dc_start", cnd)
        )
    else
        var(pm, nw, cnd)[:dc] = @variable(pm.model, 
            [(l,i,j) in ref(pm, nw, :gmd_arcs)], basename="$(nw)_$(cnd)_dc",
            start = PMs.getval(ref(pm, nw, :gmd_branch, l), "dc_start", cnd)
        )
    end

    dc_expr = Dict([((l,i,j), -1.0*var(pm, nw, cnd, :dc, (l,i,j))) for (l,i,j) in ref(pm, nw, :gmd_arcs_from)])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*var(pm, nw, cnd, :dc, (l,i,j))) for (l,i,j) in ref(pm, nw, :gmd_arcs_from)]))

    if !haskey(pm.model.ext, :nw)
        pm.model.ext[:nw] = Dict()
    end

    if !haskey(pm.model.ext[:nw], nw)
        pm.model.ext[:nw][nw] = Dict()
    end

    pm.model.ext[:nw][nw][:dc_expr] = dc_expr
end

"variable: `qloss[j]` for `j` in `arcs`"
function variable_qloss(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
       var(pm, nw, cnd)[:qloss] = @variable(pm.model, 
            [(l,i,j) in ref(pm, nw, :arcs)], basename="$(nw)_$(cnd)_qloss",
            lowerbound = 0.0,
            upperbound = Inf,
            start = PMs.getval(ref(pm, nw, :branch, l), "qloss_start", cnd)
        )
    else
        var(pm, nw, cnd)[:qloss] = @variable(pm.model, 
            [(l,i,j) in ref(pm, nw, :arcs)], basename="$(nw)_$(cnd)_qloss",
            start = PMs.getval(ref(pm, nw, :branch, l), "qloss_start", cnd)
        )
    end
end

""
function variable_demand_factor(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    var(pm, nw, cnd)[:z_demand] = @variable(pm.model,
        0 <= z_demand[i in ids(pm, nw, :bus)] <= 1,
        start = PMs.getval(ref(pm, nw, :bus, i), "z_demand_start", 1.0, cnd)
    )
end

""
function variable_shunt_factor(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    var(pm, nw, cnd)[:z_shunt] = @variable(pm.model,
        0 <= z_shunt[i in ids(pm, nw, :bus)] <= 1,
        start = PMs.getval(ref(pm, nw, :bus, i), "z_shunt_nstart", 1.0, cnd)
    )
end


"variable: `pd[j]` for `j` in `bus`"
function variable_active_load(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:pd] = @variable(pm.model,
            [i in ids(pm, nw, :load)], basename="$(nw)_$(cnd)_pd",
            lowerbound = min(0,ref(pm, nw, :load, i)["pd"][cnd]),
            upperbound = max(0,ref(pm, nw, :load, i)["pd"][cnd]),
            start = PMs.getval(ref(pm, nw, :load, i), "pd_start", cnd)
        )
    else
        var(pm, nw, cnd)[:pd] = @variable(pm.model,
            [i in ids(pm, nw, :load)], basename="$(nw)_$(cnd)_pd",
            start = PMs.getval(ref(pm, nw, :load, i), "pd_start", cnd)
        )
    end
end

"variable: `qd[j]` for `j` in `bus`"
function variable_reactive_load(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:qd] = @variable(pm.model,
            [i in ids(pm, nw, :load)], basename="$(nw)_$(cnd)_qd",
            lowerbound = min(0, ref(pm, nw, :load, i)["qd"][cnd]),
            upperbound = max(0, ref(pm, nw, :load, i)["qd"][cnd]),
            start = PMs.getval(ref(pm, nw, :load, i), "qd_start", cnd)
        )
    else
        var(pm, nw, cnd)[:qd] = @variable(pm.model,
            [i in ids(pm, nw, :load)], basename="$(nw)_$(cnd)_qd",
            start = PMs.getval(ref(pm, nw, :load, i), "qd_start", cnd)
        )
    end
end

"generates variables for both `active` and `reactive` load"
function variable_load(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, kwargs...)
    variable_active_load(pm; kwargs...)
    variable_reactive_load(pm; kwargs...)
end

"variable: `i_ac_mag[j]` for `j` in `branch'"
function variable_ac_current_mag(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:i_ac_mag] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_i_ac_mag",
            lowerbound = calc_ac_mag_min(pm, i, nw=nw), 
            upperbound = calc_ac_mag_max(pm, i, nw=nw),
            start = PMs.getval(ref(pm, nw, :branch, i), "i_ac_mag_start", cnd)
        )
    else
        var(pm, nw, cnd)[:i_ac_mag] = @variable(pm.model, 
            [i in ids(pm, nw, :branch)], basename="$(nw)_$(cnd)_i_ac_mag",
            start = PMs.getval(ref(pm, nw, :branch, i), "i_ac_mag_start", cnd)
        )
    end
end

"variable: `iv[j]` for `j` in `arcs`"
function variable_iv(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    var(pm, nw, cnd)[:iv] = @variable(pm.model, 
        [(l,i,j) in ref(pm, nw, :arcs)], basename="$(nw)_$(cnd)_iv",
        start = PMs.getval(ref(pm, nw, :branch, l), "iv_start", cnd)
    )
end

"variable: `0 <= gen_z[i] <= 1` for `i` in `generator`s"
function variable_gen_indicator(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    var(pm, nw, cnd)[:gen_z] = @variable(pm.model, 
        [i in ids(pm, nw, :gen)], basename="$(nw)_$(cnd)_gen_z",
        lowerbound = 0,
        upperbound = 1,
        category = :Int,
        start = PMs.getval(ref(pm, nw, :gen, i), "gen_z_start", cnd, 1.0)
    )
end

"variable: `pg[j]^2` for `j` in `gen`"
function variable_active_generation_sqr_cost(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        var(pm, nw, cnd)[:pg_sqr] = @variable(pm.model,
            [i in ids(pm, nw, :gen)], basename="$(nw)_$(cnd)_pg_sqr",
            lowerbound = 0,
            upperbound = ref(pm, nw, :gen, i)["cost"][1] * ref(pm, nw, :gen, i)["pmax"]^2,
            start = PMs.getval(ref(pm, nw, :gen, i), "pg_sqr_start", cnd)
        )
    else
        var(pm, nw, cnd)[:pg_sqr] = @variable(pm.model,
            [i in ids(pm, nw, :gen)], basename="$(nw)_$(cnd)_pg_sqr",
            start = PMs.getval(ref(pm, nw, :gen, i), "pg_sqr_start", cnd)
        )
    end
end
