# ===   OBJECTIVES   === #


"OBJECTIVE: computes a load shed cost"
function calc_load_shed_cost(pm::_PM.AbstractPowerModel)

    max_cost = 0
    for (n, nw_ref) in _PM.nws(pm)
        for (i, gen) in nw_ref[:gen]
            if gen["pmax"] != 0
                cost_mw = (get(gen["cost"], 1, 0.0) * gen["pmax"]^2 + get(gen["cost"], 2, 0.0) * gen["pmax"]) / gen["pmax"] + get(gen["cost"], 3, 0.0)
                max_cost = max(max_cost, cost_mw)
            end
        end
    end
    return max_cost * 2.0

end


"OBJECTIVE: OPF objective"
function objective_gmd_min_fuel(pm::_PM.AbstractPowerModel)

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            get(gen["cost"], 1, 0.0) * sum( _PM.var(pm, n, :pg, i) for c in _PM.conductor_ids(pm, n) )^2 +
            get(gen["cost"], 2, 0.0) * sum( _PM.var(pm, n, :pg, i) for c in _PM.conductor_ids(pm, n) ) +
            get(gen["cost"], 3, 0.0)
        for (i,gen) in nw_ref[:gen]) +
        sum(
            sum( _PM.var(pm, n, :i_dc_mag, i)^2 for c in _PM.conductor_ids(pm, n) )
        for (i, branch) in nw_ref[:branch])
    for (n, nw_ref) in _PM.nws(pm))
    )

end


"OBJECTIVE: SSE -- keep generators as close as possible to original setpoint"
function objective_gmd_min_error(pm::_PM.AbstractPowerModel)

    @assert all(!_PM.ismulticonductor(pm) for n in _PM.nws(pm))

    M_p = Dict(n => max([gen["pmax"] for (i, gen) in nw_ref[:gen]]) for (n, nw_ref) in _PM.nws(pm))
    
    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            (gen["pg"] - _PM.var(pm, :pg, i, nw=n))^2 + (gen["qg"] - _PM.var(pm, :qg, i, nw=n))^2
        for (i, gen) in _PM.ref(pm, n, :gen)) +
        sum(
            _PM.var(pm, :i_dc_mag, i, nw=n)^2
        for (i, branch) in _PM.ref(pm, n, :branch)) +
        sum(
            -100.0 * M_p^2 * _PM.var(pm, :z_demand, i, nw=n)
        for (i, load) in _PM.ref(pm, n, :load))
    for (n, nw_ref) in _PM.nws(pm))
    )

end


"OBJECTIVE: minimizes load shedding and fuel cost"
function objective_gmd_min_mls(pm::_PM.AbstractPowerModel)

    @assert all(!_PM.ismulticonductor(pm) for n in _PM.nws(pm))

    shed_cost = calc_load_shed_cost(pm)

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            get(gen["cost"], 1, 0.0) * _PM.var(pm, :pg, i, nw=n)^2 +
            get(gen["cost"], 2, 0.0) * _PM.var(pm, :pg, i, nw=n) +
            get(gen["cost"], 3, 0.0)
        for (i, gen) in nw_ref[:gen]) +
        sum(
            shed_cost * (_PM.var(pm, :pd, i, nw=n) + _PM.var(pm, :qd, i, nw=n))
        for (i, load) in nw_ref[:load])
    for (n, nw_ref) in _PM.nws(pm))
    )

end


"OBJECTIVE: minimizes load shedding and fuel cost"
function objective_gmd_mls_on_off(pm::_PM.AbstractPowerModel)

    @assert all(!_PM.ismulticonductor(pm) for n in _PM.nws(pm))

    shed_cost = calc_load_shed_cost(pm)

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            get(gen["cost"], 1, 0.0) * _PM.var(pm, :pg_sqr, i, nw=n) +
            get(gen["cost"], 2, 0.0) * _PM.var(pm, :pg, i, nw=n) +
            get(gen["cost"], 3, 0.0) * _PM.var(pm, :z_gen, i, nw=n)
        for (i, gen) in nw_ref[:gen]) +
        sum(
            shed_cost * (_PM.var(pm, :pd, i, nw=n) + _PM.var(pm, :qd, i, nw=n))
        for (i, load) in nw_ref[:load])
    for (n, nw_ref) in _PM.nws(pm))
    )

end


"OBJECTIVE: minimizes transfomer heating caused by GMD"
function objective_gmd_min_transformer_heating(pm::_PM.AbstractPowerModel)
    # TODO: add i_dc_mag minimization

    return JuMP.@objective(pm.model, Min,
    sum(
        sum(
            sum( _PM.var(pm, n, :hsa, i) for c in _PM.conductor_ids(pm, n) )
        for (i, branch) in nw_ref[:branch])
    for (n, nw_ref) in _PM.nws(pm))
    )

end


"OBJECTIVE: maximizes loadability with generator and bus participation relaxed"
function objective_max_loadability(pm::_PM.AbstractPowerModel)

    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    z_voltage = Dict(n => _PM.var(pm, n, :z_voltage) for n in nws)
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
                sum(M[n]*10*z_voltage[n][i] for (i,bus) in _PM.ref(pm, n, :bus)) +
                sum(M[n]*z_gen[n][i] for (i,gen) in _PM.ref(pm, n, :gen)) +
                sum(M[n]*z_shunt[n][i] for (i,shunt) in _PM.ref(pm, n, :shunt)) +
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
                )
            )
            for n in nws)
        )

end

