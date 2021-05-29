# ===   DCP   === #


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


"VARIABLE: ac current"
function variable_ac_current(pm::_PM.AbstractDCPModel; kwargs...)
end


"VARIABLE: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractDCPModel; kwargs...)
end


"VARIABLE: dc current"
function variable_dc_current(pm::_PM.AbstractDCPModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
end


"VARIABLE: reactive loss"
function variable_reactive_loss(pm::_PM.AbstractDCPModel; kwargs...)
end


"CONTRAINT: bus voltage on/off"
function constraint_bus_voltage_on_off(pm::_PM.AbstractDCPModel; nw::Int=nw_id_default, kwargs...)
end


"CONSTRAINT: power balance for load shedding"
function constraint_power_balance_shed_gmd(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor scale", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor scale", "shunt")

    _PM.con(pm, n, :kcl_p)[i] = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd * z_demand[i] for (i,pd) in bus_pd)
        - sum(gs * 1.0^2 * z_shunt[i] for (i,gs) in bus_gs)
    )

end


"CONTRAINT: power balance with shunts for load shedding"
function constraint_power_balance_shunt_gmd_mls(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = _PM.var(pm, n, :vm)[i]
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)
    pd_mls = _PM.var(pm, n, :pd)

    JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(pd - pd_mls[i] for (i, pd) in bus_pd)
        - sum(gs for (i, gs) in bus_gs) * vm^2
    )

end


"CONTRAINT: power balance with shunts without load shedding"
function constraint_power_balance_shunt_gmd(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    vm = _PM.var(pm, n, :vm)[i]
    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)

    JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(pd for (i, pd) in bus_pd)
        - sum(gs for (i, gs) in bus_gs) * vm^2
    )

end


"CONTRAINT: power balance without shunts and load shedding"
function constraint_power_balance_gmd(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = _PM.var(pm, n, :p)
    pg = _PM.var(pm, n, :pg)

    JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(pd for (i, pd) in bus_pd)
    )

end

"CONSTRAINT: relating current to power flow on/off"
function constraint_current_on_off(pm::_PM.AbstractDCPModel, n::Int, i, ac_max)

    z  = _PM.var(pm, n, :z_branch)[i]
    i_ac = _PM.var(pm, n, :i_ac_mag)[i]

    JuMP.@constraint(pm.model,
        i_ac
        <=
        z * ac_max
    )
    JuMP.@constraint(pm.model,
        i_ac
        >=
        z * 0
    )

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractDCPModel, n::Int, i, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2] * ieff / ibase + coeff[3] * ieff^2 / (ibase^2)
    )

end


"CONSTRAINT: computing qloss"
function constraint_qloss_vnom(pm::_PM.AbstractDCPModel, n::Int, k, i, j, K, branchMVA)
end


"CONSTRAINT: computing qloss"
function constraint_qloss_vnom(pm::_PM.AbstractDCPModel, n::Int, k, i, j)
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

