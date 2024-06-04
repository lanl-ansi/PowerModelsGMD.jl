#############################################
# Polar Form of the Non-Convex AC Equations #
#############################################


# ===   CURRENT VARIABLES   === #


"VARIABLE: ac current"
function variable_ac_positive_current(pm::_PM.AbstractACPModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    variable_ac_positive_current_mag(pm; nw=nw, bounded=bounded, report=report)

end






# ===   CURRENT CONSTRAINTS   === #


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractACPModel, n::Int, k, kh, ih, jh, ieff_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    JuMP.@NLconstraint(pm.model, ieff == abs(ihi))
    JuMP.@constraint(pm.model, ieff <= ieff_max)
end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractACPModel, n::Int, k, kh, ih, jh, kl, il, jl, a, ieff_max)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]
    JuMP.@NLconstraint(pm.model, ieff == abs(a*ihi + ilo)/a)
    JuMP.@constraint(pm.model, ieff <= ieff_max)
end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractACPModel, n::Int, k, ks, is, js, kc, ic, jc, a, ieff_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]
    JuMP.@NLconstraint(pm.model, ieff == abs(a*is + ic)/(a + 1.0))
    JuMP.@constraint(pm.model, ieff <= ieff_max)
end


# ===   POWER BALANCE CONSTRAINTS   === #




# ===   THERMAL CONSTRAINTS   === #




"CONSTRAINT: qloss calculcated from ac voltage and dc current"
function constraint_qloss(pm::_PM.AbstractACPModel, n::Int, k, i, j, baseMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    vm = _PM.var(pm, n, :vm)[i]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * vm * i_dc_mag) / (3.0 * baseMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end
