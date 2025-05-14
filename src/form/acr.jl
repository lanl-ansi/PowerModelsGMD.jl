#############################################
# Polar Form of the Non-Convex AC Equations #
#############################################
import Infiltrator

# ===   CURRENT VARIABLES   === #


"VARIABLE: ac current"
function variable_ac_positive_current(pm::_PM.AbstractACRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    variable_ac_positive_current_mag(pm; nw=nw, bounded=bounded, report=report)
end



# ===   CURRENT CONSTRAINTS   === #


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractACRModel, n::Int, k, kh, ih, jh, ieff_max)
    branch = _PM.ref(pm, n, :branch, k)
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    if haskey(branch,"hi_3w_branch")
        JuMP.@constraint(pm.model, ieff == 0.0)
    else
        # JuMP.@NLconstraint(pm.model, ieff == abs(ihi))
        JuMP.@constraint(pm.model, ieff^2 == ihi^2)
        JuMP.@constraint(pm.model, ieff >= 0)
    end
    
    # TODO: use variable bounds for this
    if !isnothing(ieff_max)
        JuMP.@constraint(pm.model, ieff <= ieff_max)
    end
end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractACRModel, n::Int, k, kh, ih, jh, kl, il, jl, a, ieff_max)
    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]

    # JuMP.@NLconstraint(pm.model, ieff == abs(a*ihi + ilo)/a)
    JuMP.@constraint(pm.model, ieff^2 == (a*ihi + ilo)^2/a^2)
    JuMP.@constraint(pm.model, ieff >= 0)
end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf_3w(pm::_PM.AbstractACRModel, n::Int, k, kh, ih, jh)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], 0.0")
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    # JuMP.@NLconstraint(pm.model, ieff == abs(ihi))
    JuMP.@constraint(pm.model, ieff^2 == ihi^2)
    JuMP.@constraint(pm.model, ieff >= 0)
    
    # TODO: use variable bounds for this
    if !isnothing(ieff_max)
        JuMP.@constraint(pm.model, ieff <= ieff_max)
    end    
end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractACRModel, n::Int, k, ks, is, js, kc, ic, jc, a, ieff_max)
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]
    # Infiltrator.@infiltrate
    # JuMP.@NLconstraint(pm.model, ieff == abs(a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff^2 == (a*is + ic)^2/(a + 1.0)^2)
    JuMP.@constraint(pm.model, ieff >= 0)

    # TODO: use variable bounds for this
    if !isnothing(ieff_max)
        JuMP.@constraint(pm.model, ieff <= ieff_max)
    end
end


# ===   POWER BALANCE CONSTRAINTS   === #




# ===   THERMAL CONSTRAINTS   === #


"  Constraint: constraints on modeling bus voltages that is primarly a pass through to _PM.constraint_model_voltage
  There are a few situations where the GMD problem formulations have additional voltage modeling than what _PM provides.
  For example, many of the GMD problem formulations need explict vm variables, which the WR formulations do not provide
"
function constraint_model_voltage(pm::_PM.AbstractACRModel; nw::Int=_PM.nw_id_default)
    _PM.constraint_model_voltage(pm; nw=nw)

    # Infiltrator.@infiltrate
    # w  = _PM.var(pm, nw,  :w)
    vi = _PM.var(pm, nw,  :vi)
    vr = _PM.var(pm, nw,  :vr)

    # vi    = _PM.var(pm, nw, :vi)[i]
    # vr    = _PM.var(pm, nw, :vr)[i]
    # vm    = JuMP.variable_by_name(pm.model, "vm["*string(i)*"]")
    # vms    = JuMP.variable_by_name(pm.model, "vms["*string(i)*"]")

    # Infiltrator.@infiltrate
    JuMP.@variable(pm.model, vm[_PM.ids(pm, nw, :bus)])
    JuMP.@variable(pm.model, vms[_PM.ids(pm, nw, :bus)])

    for i in _PM.ids(pm, nw, :bus)
        vml    = JuMP.variable_by_name(pm.model, "vm["*string(i)*"]")
        vmsl    = JuMP.variable_by_name(pm.model, "vms["*string(i)*"]")
        JuMP.@constraint(pm.model, vml^2==(vi[i]^2+vr[i]^2))
        JuMP.@constraint(pm.model, vml^2==vmsl)
    end
end



# "CONSTRAINT: qloss calculcated from ac voltage and dc current"
# function constraint_qloss(pm::_PM.AbstractACRModel, n::Int, k, i, j, baseMVA, K)
#     qloss = _PM.var(pm, n, :qloss)
#     i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
#     vm = _PM.var(pm, n, :vm)[i]

#     JuMP.@constraint(pm.model, qloss[(k,i,j)] == (K * vm * i_dc_mag) / (3.0 * baseMVA)) # K is per phase
#     JuMP.@constraint(pm.model, qloss[(k,j,i)] == 0.0)
# end

"CONSTRAINT: qloss calculcated for ac formulation single phase"
function constraint_qloss_pu(pm::_PM.AbstractACRModel, n::Int, k, i, j, K)
    branch    = _PM.ref(pm, n, :branch, k)

    qloss = _PM.var(pm, n, :qloss)
    # vi    = _PM.var(pm, n, :vi)[i]
    # vr    = _PM.var(pm, n, :vr)[i]
    vm    = JuMP.variable_by_name(pm.model, "vm["*string(i)*"]")
    # vms    = JuMP.variable_by_name(pm.model, "vms["*string(i)*"]")
    ieff = _PM.var(pm, n, :i_dc_mag, k)
   
    if branch["type"] == "xfmr"
        # Infiltrator.@infiltrate
        JuMP.@constraint(pm.model,
            # qloss[(k,i,j)] == K / 3.0 * ieff * vm 
            qloss[(k,i,j)] == K * ieff * vm 
        )

    else
        JuMP.@constraint(pm.model,
            qloss[(k,i,j)] == 0.0
        )
    end
        # Use this if we implement piecewise K
        # (pm.data["baseMVA"]) / branchMVA ) * (K * vm * ieff) / (3.0 * branchMVA)
        # (K * vm * ieff) / (3.0 * baseMVA)
end


"CONSTRAINT: nodal power balance with gmd, shunts, and constant power factor load shedding"
function constraint_power_balance_gmd_shunt_ls(pm::_PM.AbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)

    # Infiltrator.@infiltrate
    # vi = _PM.var(pm, n, :vi, i)
    # vr = _PM.var(pm, n, :vr, i)
    # vm = JuMP.variable_by_name(pm.model, "vm["*string(i)*"]")
    vms    = JuMP.variable_by_name(pm.model, "vms["*string(i)*"]")
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
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * vms
        )
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * z_shunt[i] for (i,bs) in bus_bs) * (vi^2+vr^2)
        )
    else
        # Infiltrator.@infiltrate
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd * z_demand[i] for (i,pd) in bus_pd)
            - sum(gs * z_shunt[i] for (i,gs) in bus_gs) * vms
        )
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] + qloss[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd * z_demand[i] for (i,qd) in bus_qd)
            + sum(bs * z_shunt[i] for (i,bs) in bus_bs) * vms
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end



"CONSTRAINT: nodal power balance for dc circuits with GIC blockers"
function constraint_dc_kcl_ne_blocker(pm::_PM.AbstractACRModel, n::Int, i, j, dc_expr, gmd_bus_arcs, gs)
    v_dc = _PM.var(pm, n, :v_dc)[i]
    z = _PM.var(pm, n, :z_blocker)[j]

    if length(gmd_bus_arcs) > 0

        if (JuMP.lower_bound(v_dc) > 0 || JuMP.upper_bound(v_dc) < 0)
            Memento.warn(_LOGGER, "DC voltage cannot go to 0. This could make the DC power balance constraint overly constrained in switching applications.")
        end
            
        con = JuMP.@constraint(pm.model,
            sum(dc_expr[a] for a in gmd_bus_arcs)
            == 
            gs * v_dc - gs * z * v_dc
        )
    end
end