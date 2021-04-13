# ===   WR   === #


"VARIABLE: bus voltage on/off"
function variable_bus_voltage_on_off(pm::_PM.AbstractWRModel; kwargs...)
    variable_bus_voltage_magnitude_sqr_on_off(pm; kwargs...)
    variable_bus_voltage_product_on_off(pm; kwargs...)
end


"VARIABLE: bus voltage product on/off"
function variable_bus_voltage_product_on_off(pm::_PM.AbstractWRModel; nw::Int=nw_id_default)

    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, nw, :buspairs))

    _PM.var(pm, nw)[:wr] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs)], base_name="$(nw)_wr",
        lower_bound = min(0,wr_min[bp]),
        upper_bound = max(0,wr_max[bp]),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs, bp), "wr_start", 1.0)
    )
    _PM.var(pm, nw)[:wi] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs)], base_name="$(nw)_wi",
        lower_bound = min(0,wi_min[bp]),
        upper_bound = max(0,wi_max[bp]),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs, bp), "wi_start")
    )

end


"FUNCTION: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractWRModel; kwargs...)
   variable_ac_current_mag(pm; bounded=false, kwargs...)
end


"FUNCTION: ac current"
function variable_ac_current(pm::_PM.AbstractWRModel; kwargs...)

    nw = nw_id_default

    variable_ac_current_mag(pm; kwargs...)

    parallel_branch = Dict(x for x in _PM.ref(pm, nw, :branch) if _PM.ref(pm, nw, :buspairs)[(x.second["f_bus"], x.second["t_bus"])]["branch"] != x.first)
    cm_min = Dict((l, 0) for l in keys(parallel_branch))
    cm_max = Dict((l, (branch["rate_a"]*branch["tap"]/_PM.ref(pm, nw, :bus)[branch["f_bus"]]["vmin"])^2) for (l, branch) in parallel_branch)

    _PM.var(pm, nw)[:cm_p] = JuMP.@variable(pm.model,
        [l in keys(parallel_branch)], base_name="$(nw)_cm_p",
        lower_bound = cm_min[l],
        upper_bound = cm_max[l],
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "cm_p_start")
    )

end


"FUNCTION: dc current"
function variable_dc_current(pm::_PM.AbstractWRModel; kwargs...)
    variable_dc_current_mag(pm; kwargs...)
    variable_dc_current_mag_sqr(pm; kwargs...)
end


"FUNCTION: reactive loss"
function variable_reactive_loss(pm::_PM.AbstractWRModel; kwargs...)
    variable_qloss(pm; kwargs...)
    variable_iv(pm; kwargs...)
end


"CONSTRAINT: bus voltage product on/off"
function constraint_bus_voltage_product_on_off(pm::_PM.AbstractWRModels; nw::Int=nw_id_default)

    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, nw, :buspairs))

    wr = _PM.var(pm, nw, :wr)
    wi = _PM.var(pm, nw, :wi)
    z_voltage = _PM.var(pm, nw, :z_voltage)

    for bp in _PM.ids(pm, nw, :buspairs)
        (i,j) = bp
        z_fr = z_voltage[i]
        z_to = z_voltage[j]

        JuMP.@constraint(pm.model,
            wr[bp]
            <=
            z_fr * wr_max[bp]
        )
        JuMP.@constraint(pm.model,
            wr[bp]
            >=
            z_fr * wr_min[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            <=
            z_fr * wi_max[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            >=
            z_fr * wi_min[bp]
        )

        JuMP.@constraint(pm.model,
            wr[bp]
            <=
            z_to*wr_max[bp]
        )
        JuMP.@constraint(pm.model,
            wr[bp]
            >=
            z_to*wr_min[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            <=
            z_to*wi_max[bp]
        )
        JuMP.@constraint(pm.model,
            wi[bp]
            >=
            z_to*wi_min[bp]
        )

    end
end


"CONSTRAINT: bus voltage on/off"
function constraint_bus_voltage_on_off(pm::_PM.AbstractWRModels, n::Int; kwargs...)

    for (i,bus) in _PM.ref(pm, n, :bus)
        constraint_voltage_magnitude_sqr_on_off(pm, i; nw=n)
    end

    constraint_bus_voltage_product_on_off(pm; nw=n)

    w = _PM.var(pm, n, :w)
    wr = _PM.var(pm, n, :wr)
    wi = _PM.var(pm, n, :wi)

    for (i,j) in _PM.ids(pm, n, :buspairs)
        _IM.relaxation_complex_product(pm.model, w[i], w[j], wr[(i,j)], wi[(i,j)])
    end

end


"CONSTRAINT: power balance with shunts for load shedding"
function constraint_power_balance_shunt_gmd_mls(pm::_PM.AbstractWRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)

    w = _PM.var(pm, n, :w)[i]
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    qloss = _PM.var(pm, n, :qloss)
    pd_mls = _PM.var(pm, n, :pd)
    qd_mls = _PM.var(pm, n, :qd)

    if length(bus_arcs) > 0 || length(bus_gens) > 0 || length(bus_pd) > 0 || length(bus_gs) > 0
        JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(pd - pd_mls[i] for (i, pd) in bus_pd)
            - sum(gs for (i, gs) in bus_gs) * w
        )
    end

    if length(bus_arcs) > 0 || length(bus_gens) > 0 || length(bus_qd) > 0 || length(bus_bs) > 0
        JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qd - qd_mls[i] for (i, qd) in bus_qd)
            + sum(bs for (i, bs) in bus_bs) * w
        )
    end

end


"CONSTRAINT: power balance without shunts and load shedding"
function constraint_power_balance_gmd(pm::_PM.AbstractWRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd)

    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    qloss = _PM.var(pm, n, :qloss)

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(pd for (i, pd) in bus_pd)
    )
    JuMP.@constraint(pm.model,
        sum(q[a] + qloss[a] for a in bus_arcs)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qd for (i, qd) in bus_qd)
    )

end


"CONSTRAINT: relating current to power flow"
function constraint_current(pm::_PM.AbstractWRModel, n::Int, i, f_idx, f_bus, t_bus, tm)

    pair = (f_bus, t_bus)
    arc_from = (i, f_bus, t_bus)

    buspair = _PM.ref(pm, n, :buspairs, pair)
    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]

    if buspair["branch"] == i
        l = _PM.var(pm, n, :ccm)[(f_bus, t_bus)]
        _IM.relaxation_sqr(pm.model, i_ac_mag, l)
    else
        l = _PM.var(pm, n, :cm_p)[i]
        w = _PM.var(pm, n, :w)[f_bus]
        p_fr = _PM.var(pm, n, :p)[arc_from]
        q_fr = _PM.var(pm, n, :q)[arc_from]

        JuMP.@constraint(pm.model,
            p_fr^2 + q_fr^2
            <=
            l * w
        )

        _IM.relaxation_sqr(pm.model, i_ac_mag, l)

    end

end


"CONSTRAINT: relating current to power flow on_off"
function constraint_current_on_off(pm::_PM.AbstractWRModel, n::Int, i, ac_ub)

    # this implementation of the on/off relaxation is only valid for lower bounds of 0
    ac_lb = 0 

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    l = _PM.var(pm, n, :ccm)[i]
    z = _PM.var(pm, n, :z_branch)[i]

    # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl
    JuMP.@constraint(pm.model,
        l
        >=
        i_ac_mag^2
    )
    JuMP.@constraint(pm.model,
        l
        <=
        ac_ub*i_ac_mag
    )
    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        z * ac_ub
    )
    JuMP.@constraint(pm.model,
        i_ac_mag
        >=
        z * ac_lb
    )

end


"CONSTRAINT: computing thermal protection of transformers"
function constraint_thermal_protection(pm::_PM.AbstractWRModel, n::Int, i, coeff, ibase)

    i_ac_mag = _PM.var(pm, n, :i_ac_mag)[i]
    ieff = _PM.var(pm, n, :i_dc_mag)[i]
    ieff_sqr = _PM.var(pm, n, :i_dc_mag_sqr)[i]

    JuMP.@constraint(pm.model,
        i_ac_mag
        <=
        coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff_sqr/(ibase^2)
    )

    _IM.relaxation_sqr(pm.model, ieff, ieff_sqr)

end


"CONSTRAINT: computing qloss"
function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)
    iv = _PM.var(pm, n, :iv)[(k,i,j)]
    vm = _PM.var(pm, n, :vm)[i]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        0.0
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

    _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)

end


"CONSTRAINT: computing qloss"
function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j, K, branchMVA)

    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    qloss = _PM.var(pm, n, :qloss)
    iv = _PM.var(pm, n, :iv)[(k,i,j)]
    vm = _PM.var(pm, n, :vm)[i]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        println("WARNING")
        println("DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.")
        println()
    end

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        ((K * iv) / (3.0 * branchMVA))  # 'K' is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

    _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)

end

