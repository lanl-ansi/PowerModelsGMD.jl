########################
# Variable Definitions #
########################

# Commonly used variables are defined here.

"
  Declaration of the bus voltage variables. This is a pass through to _PM.variable_bus_voltage except for those forms where vm is not
  created and it is needed for the GIC.  For example, the WR models are formulated in the space of V^2, so there is no vm variable,
  so those variables need to be created
"
function variable_bus_voltage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    _PM.variable_bus_voltage(pm;nw=nw,bounded=bounded,report=report)
end


"
  Declaration of the bus voltage variables. This is a pass through to _PMR.variable_bus_voltage_on_off except for those forms where vm is not
  created and it is needed for the GIC.  For example, the WR models are formulated in the space of V^2, so there is no vm variable,
  so those variables need to be created
"
function variable_bus_voltage_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    _PM.variable_bus_voltage_on_off(pm;nw=nw, report=report)
end

"
VARIABLE: Declaration of variables associated with modeling of injected GIC
"
function variable_gic_current(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    variable_dc_current_mag(pm; nw=nw, bounded=bounded,report=report)
end

# ===   VOLTAGE VARIABLES   === #

"VARIABLE: bus dc voltage"
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

    report && _PM.sol_component_value(pm, nw, :gmd_bus, :gmd_vdc, _PM.ids(pm, nw, :gmd_bus), v_dc)

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

    report && _PM.sol_component_value(pm, nw, :branch, :gmd_idc_mag, _PM.ids(pm, nw, :branch), i_dc_mag)

end




# ===   POWER BALANCE VARIABLES   === #

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

"VARIABLE: gen xfrm flow"
function variable_dc_gen_flow(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        dc = _PM.var(pm, nw)[:dc_gen_flow] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs_imxfrm)], base_name="$(nw)_dc_gen_flow",
            lower_bound = -Inf,
            upper_bound = Inf,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, l), "dc_start")
        )
    else
        dc = _PM.var(pm, nw)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_dc",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, l), "dc_start")
        )
    end

end


function variable_dc_bus_flow(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        dc = _PM.var(pm, nw)[:dc_bus_sub_flow] = JuMP.@variable(pm.model,
            [(i,j) in _PM.ref(pm, nw, :gmd_arcs_bus_g)], base_name="$(nw)_dc_bus_sub_flow",
            lower_bound = -Inf,
            upper_bound = Inf,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, i), "dc_start")
        )
    else
        dc = _PM.var(pm, nw)[:dc] = JuMP.@variable(pm.model,
            [(l,i,j) in _PM.ref(pm, nw, :gmd_arcs)], base_name="$(nw)_dc",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_branch, l), "dc_start")
        )
    end
end

# ===   QLOSS VARIABLES   === #


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


#"VARIABLE: iv"
function variable_iv(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    iv = _PM.var(pm, nw)[:iv] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs)], base_name="$(nw)_iv",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "iv_start")
    )

    report && _IM.sol_component_value_edge(pm, pm_it_sym, nw, :branch, :ivf, :ivt, _PM.ref(pm, nw, :arcs_from), _PM.ref(pm, nw, :arcs_to), iv)

end


"VARIABLE: ac current magnitude"
function variable_ac_positive_current_mag(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        i_ac_mag = _PM.var(pm, nw)[:i_ac_mag] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag",
            lower_bound = calc_ac_positive_current_mag_min(pm, i, nw=nw),
            upper_bound = calc_ac_current_mag_max(pm, i, nw=nw),
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
function variable_ac_current_mag_sqr(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        i_ac_mag_sqr = _PM.var(pm, nw)[:i_ac_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag_sqr",
            lower_bound = 0,
            upper_bound = calc_ac_current_mag_max(pm, i, nw=nw)^2,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_ac_mag_sqr_start")
        )
    else
        i_ac_mag_sqr = _PM.var(pm, nw)[:i_ac_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_ac_mag_sqr",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_ac_mag_sqr_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :i_ac_mag_sqr, _PM.ids(pm, nw, :branch), i_ac_mag_sqr)

end


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


"VARIABLE: gic ne_blocker indicator"
function variable_ne_blocker_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, relax::Bool=false, report::Bool=true)

    if !relax
        z_gic_blocker = _PM.var(pm, nw)[:z_blocker] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_ne_blocker)], base_name="$(nw)_z_blocker",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_ne_blocker, i), "z_blocker_start", 1.0)
        )
    else
        z_gic_blocker = _PM.var(pm, nw)[:z_blocker] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gmd_ne_blocker)], base_name="$(nw)_z_blocker",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_ne_blocker, i), "z_blocker_start", 1.0)
        )
    end

    zv_dc = _PM.var(pm, nw)[:zv_dc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gmd_ne_blocker)], base_name="$(nw)_zv_dc",
        lower_bound = min(calc_min_dc_voltage(pm, _PM.ref(pm, nw, :gmd_ne_blocker,i)["gmd_bus"], nw=nw), 0.0),
        upper_bound = max(calc_max_dc_voltage(pm, _PM.ref(pm, nw, :gmd_ne_blocker,i)["gmd_bus"], nw=nw), 0.0),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :gmd_bus, _PM.ref(pm, nw, :gmd_ne_blocker,i)["gmd_bus"]), "v_dc_start")
    )

    report && _PM.sol_component_value(pm, nw, :gmd_ne_blocker, :blocker_placed, _PM.ids(pm, nw, :gmd_ne_blocker), z_gic_blocker)
    report && _PM.sol_component_value(pm, nw, :gmd_ne_blocker, :zv_dc, _PM.ids(pm, nw, :gmd_ne_blocker), zv_dc)
end
