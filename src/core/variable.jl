# --- General Variables --- #


"VARIABLE: dc voltage"
function variable_dc_voltage(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `v_dc[j]` for `j` in `gmd_bus`
    if bounded
        PMs.var(pm, nw, cnd)[:v_dc] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :gmd_bus)], base_name="$(nw)_$(cnd)_v_dc",
            lower_bound = calc_min_dc_voltage(pm, i, nw=nw),
            upper_bound = calc_max_dc_voltage(pm, i, nw=nw),
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_bus, i), "v_dc_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:v_dc] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :gmd_bus)], base_name="$(nw)_$(cnd)_v_dc",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_bus, i), "v_dc_start", cnd)
        )
    end

end


"VARIABLE: dc voltage difference"
function variable_dc_voltage_difference(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    
    # `v_dc[j]` for `j` in `gmd_branch`
    if bounded
        PMs.var(pm, nw, cnd)[:v_dc_diff] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :gmd_branch)], base_name="$(nw)_$(cnd)_v_dc_diff",
            lower_bound = -calc_max_dc_voltage_difference(pm, i, nw=nw),
            upper_bound = calc_max_dc_voltage_difference(pm, i, nw=nw),
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_branch, i), "v_dc_start_diff", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:v_dc_diff] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :gmd_branch)], base_name="$(nw)_$(cnd)_v_dc_diff",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_branch, i), "v_dc_start_diff", cnd)
        )
    end

end


"VARIABLE: dc voltage on/off"
function variable_dc_voltage_on_off(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `v_dc[j]` for `j` in `gmd_bus`
    variable_dc_voltage(pm; nw=nw, cnd=cnd, bounded=bounded)
    variable_dc_voltage_difference(pm; nw=nw, cnd=cnd, bounded=bounded)

    # McCormick variable
    PMs.var(pm, nw, cnd)[:vz] = JuMP.@variable(pm.model,
          [i in PMs.ids(pm, nw, :gmd_branch)], base_name="$(nw)_$(cnd)_vz",
          start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_branch, i), "v_vz_start", cnd)
    )

end


"VARIABLE: dc current magnitude"
function variable_dc_current_mag(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `i_dc_mag[j]` for `j` in `branch`
    if bounded
        PMs.var(pm, nw, cnd)[:i_dc_mag] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_i_dc_mag",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw),
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, i), "i_dc_mag_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:i_dc_mag] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_i_dc_mag",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, i), "i_dc_mag_start", cnd)
        )
    end

end


"VARIABLE: dc current magnitude squared"
function variable_dc_current_mag_sqr(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `i_dc_mag_sqr[j]` for `j` in `branch`
    if bounded
        PMs.var(pm, nw, cnd)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_i_dc_mag_sqr",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw)^2,
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_i_dc_mag_sqr",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start", cnd)
        )
    end

end


"VARIABLE: dc line flow"
function variable_dc_line_flow(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `dc[j]` for `j` in `gmd_branch`
    if bounded
        PMs.var(pm, nw, cnd)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in PMs.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_$(cnd)_dc",
            lower_bound = -Inf,
            upper_bound = Inf,
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_branch, l), "dc_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in PMs.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_$(cnd)_dc",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gmd_branch, l), "dc_start", cnd)
        )
    end

    dc_expr = Dict([((l,i,j), -1.0*PMs.var(pm, nw, cnd, :dc, (l,i,j))) for (l,i,j) in PMs.ref(pm, nw, :gmd_arcs_from)])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*PMs.var(pm, nw, cnd, :dc, (l,i,j))) for (l,i,j) in PMs.ref(pm, nw, :gmd_arcs_from)]))

    if !haskey(pm.model.ext, :nw)
        pm.model.ext[:nw] = Dict()
    end

    if !haskey(pm.model.ext[:nw], nw)
        pm.model.ext[:nw][nw] = Dict()
    end

    pm.model.ext[:nw][nw][:dc_expr] = dc_expr

end


"VARIABLE: Qloss"
function variable_qloss(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `qloss[j]` for `j` in `arcs`
    if bounded
       PMs.var(pm, nw, cnd)[:qloss] = JuMP.@variable(pm.model,
            [(l,i,j) in PMs.ref(pm, nw, :arcs)], base_name="$(nw)_$(cnd)_qloss",
            lower_bound = 0.0,
            upper_bound = Inf,
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, l), "qloss_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:qloss] = JuMP.@variable(pm.model,
            [(l,i,j) in PMs.ref(pm, nw, :arcs)], base_name="$(nw)_$(cnd)_qloss",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, l), "qloss_start", cnd)
        )
    end

end


"VARIABLE: demand factor"
function variable_demand_factor(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    PMs.var(pm, nw, cnd)[:z_demand] = JuMP.@variable(pm.model,
        0 <= z_demand[i in PMs.ids(pm, nw, :bus)] <= 1,
        start = PMs.comp_start_value(PMs.ref(pm, nw, :bus, i), "z_demand_start", 1.0, cnd)
    )

end


"VARIABLE: shunt factor"
function variable_shunt_factor(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    PMs.var(pm, nw, cnd)[:z_shunt] = JuMP.@variable(pm.model,
        0 <= z_shunt[i in PMs.ids(pm, nw, :bus)] <= 1,
        start = PMs.comp_start_value(PMs.ref(pm, nw, :bus, i), "z_shunt_nstart", 1.0, cnd)
    )

end


"VARIABLE: load"
function variable_load(pm::PMs.AbstractPowerModel; kwargs...)

    # generates variables for both `active` and `reactive` load
    variable_active_load(pm; kwargs...)
    variable_reactive_load(pm; kwargs...)

end


"VARIABLE: active load"
function variable_active_load(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `pd[j]` for `j` in `bus`
    if bounded
        PMs.var(pm, nw, cnd)[:pd] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :load)], base_name="$(nw)_$(cnd)_pd",
            lower_bound = min(0,PMs.ref(pm, nw, :load, i)["pd"][cnd]),
            upper_bound = max(0,PMs.ref(pm, nw, :load, i)["pd"][cnd]),
            start = PMs.comp_start_value(PMs.ref(pm, nw, :load, i), "pd_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:pd] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :load)], base_name="$(nw)_$(cnd)_pd",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :load, i), "pd_start", cnd)
        )
    end

end


"VARIABLE: reactive load"
function variable_reactive_load(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `qd[j]` for `j` in `bus`
    if bounded
        PMs.var(pm, nw, cnd)[:qd] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :load)], base_name="$(nw)_$(cnd)_qd",
            lower_bound = min(0, PMs.ref(pm, nw, :load, i)["qd"][cnd]),
            upper_bound = max(0, PMs.ref(pm, nw, :load, i)["qd"][cnd]),
            start = PMs.comp_start_value(PMs.ref(pm, nw, :load, i), "qd_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:qd] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :load)], base_name="$(nw)_$(cnd)_qd",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :load, i), "qd_start", cnd)
        )
    end

end


"VARIABLE: ac current magnitude"
function variable_ac_current_mag(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `i_ac_mag[j]` for `j` in `branch'
    if bounded
        PMs.var(pm, nw, cnd)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_i_ac_mag",
            lower_bound = calc_ac_mag_min(pm, i, nw=nw),
            upper_bound = calc_ac_mag_max(pm, i, nw=nw),
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, i), "i_ac_mag_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_i_ac_mag",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, i), "i_ac_mag_start", cnd)
        )
    end

end


"VARIABLE: iv"
function variable_iv(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    # `iv[j]` for `j` in `arcs`
    PMs.var(pm, nw, cnd)[:iv] = JuMP.@variable(pm.model,
        [(l,i,j) in PMs.ref(pm, nw, :arcs)], base_name="$(nw)_$(cnd)_iv",
        start = PMs.comp_start_value(PMs.ref(pm, nw, :branch, l), "iv_start", cnd)
    )

end


"VARIABLE: generation indicator"
function variable_gen_indicator(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
 
    # `0 <= gen_z[i] <= 1` for `i` in `generator`s
    PMs.var(pm, nw, cnd)[:gen_z] = JuMP.@variable(pm.model,
        [i in PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_gen_z",
        lower_bound = 0,
        upper_bound = 1,
        integer = true,
        start = PMs.comp_start_value(PMs.ref(pm, nw, :gen, i), "gen_z_start", cnd, 1.0)
    )

end


"VARIABLE: active generation squared cost"
function variable_active_generation_sqr_cost(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    # `pg[j]^2` for `j` in `gen`
    if bounded
        PMs.var(pm, nw, cnd)[:pg_sqr] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_pg_sqr",
            lower_bound = 0,
            upper_bound = PMs.ref(pm, nw, :gen, i)["cost"][1] * PMs.ref(pm, nw, :gen, i)["pmax"]^2,
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gen, i), "pg_sqr_start", cnd)
        )
    else
        PMs.var(pm, nw, cnd)[:pg_sqr] = JuMP.@variable(pm.model,
            [i in PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_pg_sqr",
            start = PMs.comp_start_value(PMs.ref(pm, nw, :gen, i), "pg_sqr_start", cnd)
        )
    end

end



# --- Thermal Variables --- #

tmax = 1000

"VARIABLE: steady-state top-oil temperature rise"
function variable_delta_oil_ss(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    if bounded
    
        #hsl = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit")
        #println("hotspot limit for $i: $hsl")
        PMs.var(pm, nw, cnd)[:ross] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil_ss",
            lower_bound = 0,
            upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            #upper_bound = tmax,
            #upper_bound = 280,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_ss_start", cnd)
        )
    else

        PMs.var(pm, nw, cnd)[:ross] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil_ss",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_ss_start", cnd)
        )
    end

end


# "VARIABLE: absolute steady-state top-oil temperature"
# function variable_absolute_oil_ss(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
#
#    if bounded
#        PMs.var(pm, nw, cnd)[:rossa] = JuMP.@variable(pm.model, 
#            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_oil_ss",
#            lower_bound = 0,
#            upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
#            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "oil_ss_start", cnd)
#        )
#    else
#
#        PMs.var(pm, nw, cnd)[:rossa] = JuMP.@variable(pm.model, 
#            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_oil_ss",
#            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "oil_ss_start", cnd)
#        )
#    end
#
# end


"VARIABLE: top-oil temperature rise"
function variable_delta_oil(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    if bounded
        PMs.var(pm, nw, cnd)[:ro] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil",
            lower_bound = 0,
            upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            #upper_bound = tmax,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_start", cnd)
        )
    else

        PMs.var(pm, nw, cnd)[:ro] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_oil",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_start", cnd)
        )
    end

end


"VARIABLE: steady-state hot-spot temperature rise"
function variable_delta_hotspot_ss(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    if bounded
        PMs.var(pm, nw, cnd)[:hsss] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot_ss",
            lower_bound = 0,
            #upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            upper_bound = tmax,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_hotspot_ss_start", cnd)
        )
    else

        PMs.var(pm, nw, cnd)[:hsss] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot_ss",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_oil_hotspot_start", cnd)
        )
    end

end


"VARIABLE: hot-spot temperature rise"
function variable_delta_hotspot(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    if bounded
        PMs.var(pm, nw, cnd)[:hs] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot",
            lower_bound = 0,
            #upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            upper_bound = tmax,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_hotspot_start", cnd)
        )
    else

        PMs.var(pm, nw, cnd)[:hs] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_delta_hotspot",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "delta_hotspot_start", cnd)
        )
    end

end


"VARIABLE: hot-spot temperature"
function variable_hotspot(pm::PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)

    if bounded
        PMs.var(pm, nw, cnd)[:hsa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_hotspot",
            lower_bound = 0,
            upper_bound = PMs.ref(pm, nw, :branch, i, "hotspot_instant_limit"),
            #upper_bound = tmax,
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "hotspot_start", cnd)
        )
    else

        PMs.var(pm, nw, cnd)[:hsa] = JuMP.@variable(pm.model, 
            [i in PowerModels.ids(pm, nw, :branch)], base_name="$(nw)_$(cnd)_hotspot",
            start = PowerModels.comp_start_value(PMs.ref(pm, nw, :branch, i), "hotspot_start", cnd)
        )
    end

end


