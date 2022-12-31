###########################################
# Simple Active Power Only Approximations #
###########################################


# ===   VOLTAGE VARIABLES   === #


"VARIABLE: bus voltage indicator"
function variable_bus_voltage_indicator(pm::_PM.AbstractDCPModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)

    report && _IM.sol_component_fixed(pm, _PM.pm_it_sym, nw, :bus, :status, _PM.ids(pm, nw, :bus), 1.0)

end


"VARIABLE: bus voltage on/off"
function variable_bus_voltage_on_off(pm::_PM.AbstractDCPModel; kwargs...)

    _PM.variable_bus_voltage_angle(pm; kwargs...)

    variable_bus_voltage_magnitude_on_off(pm; kwargs...)

end


"VARIABLE: bus voltage magnitude on/off"
function variable_bus_voltage_magnitude_on_off(pm::_PM.AbstractDCPModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)

    report && _IM.sol_component_fixed(pm, _PM.pm_it_sym, nw, :bus, :vm, _PM.ids(pm, nw, :bus), 1.0)

end


# ===   POWER BALANCE CONSTRAINTS   === #


"CONSTRAINT: nodal power balance with gmd"
function constraint_power_balance_gmd(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd)

    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")


    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end

end


"CONSTRAINT: nodal power balance with gmd and shunts"
function constraint_power_balance_gmd_shunt(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_gs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs) * vm^2
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs) * vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end

end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_gs)

    vm = _PM.var(pm, n, :vm, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor", "shunt")

    # this is required for improved performance in NLP models
    if length(z_shunt) <= 0
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * vm^2
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end

end


# ===   THERMAL CONSTRAINTS   === #

##########






"CONSTRAINT: relating current to power flow on/off"
function constraint_current_on_off(pm::_PM.AbstractDCPModel, n::Int, i::Int, ac_max)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    z  = _PM.var(pm, n, :z_branch)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        z * ac_max
    )
    JuMP.@constraint(pm.model,
        i_ac_mag
        >=
        z * 0
    )

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractDCPModel, n::Int, i::Int, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2] * ieff / ibase + coeff[3] * ieff^2 / (ibase^2)
    )

end



"OBJECTIVE: needed because dc models do not have the z_voltage variable"
function objective_max_loadability(pm::_PM.AbstractDCPModel)

    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    M = Dict()
    for n in nws
        scaled_weight = [load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]
        if isempty(scaled_weight)
            scaled_weight = [1.0]
        end
        M[n] = 10*maximum(scaled_weight)
    end

    return JuMP.@objective(pm.model, Max,
        sum(
            (
                time_elapsed[n]*(
                 sum(M[n]*z_gen[n][i] for (i,gen) in _PM.ref(pm, n, :gen)) +
                 sum(M[n]*z_shunt[n][i] for (i,shunt) in _PM.ref(pm, n, :shunt)) +
                 sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
             )
            )
        for n in nws)
    )

end

