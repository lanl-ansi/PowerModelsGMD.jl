####################################################
# Quadratic Relaxations in the Rectangular W-Space #
####################################################


# ===   VOLTAGE VARIABLES   === #

"
  Declaration of the bus voltage variables. This is a pass through to _PM.variable_bus_voltage except for those forms where vm is not
  created and it is needed for the GIC.  This function creates the vm variables to add to the WR formulation
"
function variable_bus_voltage(pm::_PM.AbstractWRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    _PM.variable_bus_voltage(pm;nw=nw,bounded=bounded,report=report)
    # make sure the voltage magntiude variable is created since some WR models don't need it, but GMD does
    if !haskey(_PM.var(pm,nw),:vm)
        _PM.variable_bus_voltage_magnitude(pm;nw=nw,bounded=bounded,report=report)
    end
end


"
  Declaration of the bus voltage variables. This is a pass through to _PM.variable_bus_voltage except for those forms where vm is not
  created and it is needed for the GIC.  This function creates the vm variables to add to the WR formulation
"
function variable_bus_voltage_on_off(pm::_PM.AbstractWRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    _PM.variable_bus_voltage_on_off(pm;nw=nw,report=report)

    # make sure the voltage magntiude variable is created since some WR models don't need it, but GMD does
    if !haskey(_PM.var(pm,nw),:vm)
        _PM.variable_bus_voltage_magnitude(pm;nw=nw,bounded=bounded,report=report)
    end
end


"
  Constraint: constraints on modeling bus voltages that is primarly a pass through to _PM.constraint_model_voltage
  There are a few situations where the GMD problem formulations have additional voltage modeling than what _PM provides.
  For example, many of the GMD problem formulations need explict vm variables, which the WR formulations do not provide
"
function constraint_model_voltage(pm::_PM.AbstractWRModel; nw::Int=_PM.nw_id_default)
    _PM.constraint_model_voltage(pm; nw=nw)

    w  = _PM.var(pm, nw,  :w)
    vm = _PM.var(pm, nw,  :vm)

    for i in _PM.ids(pm, nw, :bus)
        _IM.relaxation_sqr(pm.model, vm[i], w[i])
    end
end


# ===   CURRENT VARIABLES   === #

function variable_gic_current(pm::_PM.AbstractWRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    variable_dc_current_mag(pm; nw=nw, bounded=bounded,report=report)
    variable_iv(pm; nw=nw, report=report)
end


"FUNCTION: ac current"
function variable_ac_positive_current(pm::_PM.AbstractWRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    variable_ac_positive_current_mag(pm; nw=nw, bounded=bounded, report=report)
    variable_ac_current_mag_sqr(pm; nw=nw, bounded=bounded, report=report)
end








# ===   CURRENT CONSTRAINTS   === #


# "CONSTRAINT: qloss assuming constant ac primary voltage"
# function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j, baseMVA, K)
#     qloss = _PM.var(pm, n, :qloss)
#     i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

#     iv = _PM.var(pm, n, :iv)[(k,i,j)]
#     vm = _PM.var(pm, n, :vm)[i]

#     if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
#         Memento.warn(_LOGGER, "DC voltage magnitude cannot take a 0 value. In OTS applications, this may result in incorrect results.")
#     end

#     JuMP.@constraint(pm.model,
#         qloss[(k,i,j)] == ((K * iv) / (3.0 * baseMVA))
#             # K is per phase
#     )
#     JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
#     _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)
# end


# ===   THERMAL CONSTRAINTS   === #


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractWRModel, n::Int, k, kh, ih, jh, ieff_max)
    branch = _PM.ref(pm, n, :branch, k)
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    if haskey(branch,"hi_3w_branch")
        JuMP.@constraint(pm.model, ieff == 0.0)
    else 
        JuMP.@constraint(pm.model, ieff >= ihi)
        JuMP.@constraint(pm.model, ieff >= -ihi)
    end

    # TODO: use variable bounds for this
    if !isnothing(ieff_max)
        JuMP.@constraint(pm.model, ieff <= ieff_max)
    end
end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractWRModel, n::Int, k, kh, ih, jh, kl, il, jl, a, ieff_max)
    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model, ieff >= (a * ihi + ilo) / a)
    JuMP.@constraint(pm.model, ieff >= - (a * ihi + ilo) / a)

    if !isnothing(ieff_max)
        JuMP.@constraint(pm.model, ieff <= ieff_max)
    end
end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractWRModel, n::Int, k, ks, is, js, kc, ic, jc, a, ieff_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model, ieff >= (a*is + ic) / (a + 1.0))
    JuMP.@constraint(pm.model, ieff >= - (a*is + ic) / (a + 1.0))

    # TODO: use variable bounds for this
    if !isnothing(ieff_max)
        JuMP.@constraint(pm.model, ieff <= ieff_max)
    end
end



# ===   DC BOUNDS CONSTRAINTS   === #


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf_bound(pm::_PM.AbstractWRModel, n::Int, k, kh, ih, jh, ieff_max)
    branch = _PM.ref(pm, n, :branch, k)
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    if haskey(branch,"hi_3w_branch")
        JuMP.@constraint(pm.model, ieff == 0.0)
    else 
        JuMP.@constraint(pm.model, ieff == ihi)
    end

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf_bound(pm::_PM.AbstractWRModel, n::Int, k, kh, ih, jh, kl, il, jl, a, ieff_max)
    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]
    # JuMP.@constraint(pm.model, ieff == 0.0)
    JuMP.@constraint(pm.model, ieff == (a * ihi + ilo) / a)
end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf_bound(pm::_PM.AbstractWRModel, n::Int, k, ks, is, js, kc, ic, jc, a, ieff_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]
    # JuMP.@constraint(pm.model, ieff == 0.0)
    JuMP.@constraint(pm.model, ieff == (a*is + ic) / (a + 1.0))

end


"
  Constraint: constraints on modeling bus voltages that is primarly a pass through to _PMR.constraint_bus_voltage_on_off
  There are a few situations where the GMD problem formulations have additional voltage modeling than what _PMR provides.
  For example, many of the GMD problem formulations need explict vm variables, which the WR formulations do not provide
"
function constraint_model_voltage_on_off(pm::_PM.AbstractWRModel; nw::Int=_PM.nw_id_default)
    _PM.constraint_model_voltage_on_off(pm; nw=nw)

    w  = _PM.var(pm, nw,  :w)
    vm = _PM.var(pm, nw,  :vm)

    for i in _PM.ids(pm, nw, :bus)
        _IM.relaxation_sqr(pm.model, vm[i], w[i])
    end
end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractWRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    w = _PM.var(pm, n, :w, i)
    p = get(_PM.var(pm, n), :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q = get(_PM.var(pm, n), :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    qloss = get(_PM.var(pm, n), :qloss, Dict()); _PM._check_var_keys(qloss, bus_arcs, "reactive power", "branch")
    pg = get(_PM.var(pm, n), :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = get(_PM.var(pm, n), :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps = get(_PM.var(pm, n), :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs = get(_PM.var(pm, n), :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw = get(_PM.var(pm, n), :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PM.var(pm, n), :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor", "shunt")
    wz_shunt = get(_PM.var(pm, n), :wz_shunt, Dict()); _PM._check_var_keys(wz_shunt, keys(bus_gs), "voltage square power factor scale", "shunt")

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
            - sum(gs * wz_shunt[i] for (i,gs) in bus_gs)
        )
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * wz_shunt[i] for (i,bs) in bus_bs)
        )
    else
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * wz_shunt[i] for (i,gs) in bus_gs) 
        )
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * wz_shunt[i] for (i,bs) in bus_bs)
        )
    end

    for s in keys(bus_gs)
        _IM.relaxation_product(pm.model, w, z_shunt[s], wz_shunt[s])
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


"CONSTRAINT: nodal current balance for dc circuits with GIC blockers"
function constraint_dc_kcl_ne_blocker(pm::_PM.AbstractWRModel, n::Int, i, j, dc_expr, gmd_bus_arcs, gs)

    v_dc = _PM.var(pm, n, :v_dc)[i]
    zv_dc = _PM.var(pm, n, :zv_dc)[j]
    z = _PM.var(pm, n, :z_blocker)[j]

    if length(gmd_bus_arcs) > 0

        # if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
        #     Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
        # end

        _IM.relaxation_product(pm.model, z, v_dc, zv_dc)
            
        con = JuMP.@constraint(pm.model,
            sum(dc_expr[a] for a in gmd_bus_arcs)
            == 
            gs * v_dc - gs * zv_dc

        )
    end
end


"""
CONSTRAINT: relaxed qloss calculcated for ac formulation single phase
"""
function constraint_qloss_pu(pm::_PM.AbstractWRModel, n::Int, k, i, j, K)
    branch    = _PM.ref(pm, n, :branch, k)

    qloss = _PM.var(pm, n, :qloss)
    vm    = _PM.var(pm, n, :vm)[i]
    ieff = _PM.var(pm, n, :i_dc_mag, k)

    if branch["type"] == "xfmr"
        # scaled_relaxation_product(pm.model, K/3.0, ieff, vm, qloss[(k,i,j)])
        scaled_relaxation_product(pm.model, K, ieff, vm, qloss[(k,i,j)])
    else
        JuMP.@constraint(pm.model,
            qloss[(k,i,j)] == 0.0
        )
    end
end

"""
general relaxation of bilinear term (McCormick) for y = K*x*y
```
z/K >= JuMP.lower_bound(x)*y + JuMP.lower_bound(y)*x - JuMP.lower_bound(x)*JuMP.lower_bound(y)
z/K >= JuMP.upper_bound(x)*y + JuMP.upper_bound(y)*x - JuMP.upper_bound(x)*JuMP.upper_bound(y)
z/K <= JuMP.lower_bound(x)*y + JuMP.upper_bound(y)*x - JuMP.lower_bound(x)*JuMP.upper_bound(y)
z/K <= JuMP.upper_bound(x)*y + JuMP.lower_bound(y)*x - JuMP.upper_bound(x)*JuMP.lower_bound(y)
```
"""
function scaled_relaxation_product(m::JuMP.Model, K::Float64, x::JuMP.VariableRef, y::JuMP.VariableRef, z::JuMP.VariableRef)
    x_lb, x_ub = _IM.variable_domain(x)
    y_lb, y_ub = _IM.variable_domain(y)

    JuMP.@constraint(m, z/K >= x_lb*y + y_lb*x - x_lb*y_lb)
    JuMP.@constraint(m, z/K >= x_ub*y + y_ub*x - x_ub*y_ub)
    JuMP.@constraint(m, z/K <= x_lb*y + y_ub*x - x_lb*y_ub)
    JuMP.@constraint(m, z/K <= x_ub*y + y_lb*x - x_ub*y_lb)
end


