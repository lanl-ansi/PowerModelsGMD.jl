#############################################
# Polar Form of the Non-Convex AC Equations #
#############################################


# ===   CURRENT VARIABLES   === #


"VARIABLE: ac current"
function variable_ac_current(pm::_PM.AbstractACPModel; kwargs...)

    variable_ac_current_mag(pm; kwargs...)

end


"VARIABLE: ac current on/off"
function variable_ac_current_on_off(pm::_PM.AbstractACPModel; kwargs...)

    variable_ac_current_mag(pm; bounded=false, kwargs...)

end


"VARIABLE: dc current"
function variable_dc_current(pm::_PM.AbstractACPModel; kwargs...)

    variable_dc_current_mag(pm; kwargs...)

end


# ===   CURRENT CONSTRAINTS   === #


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractACPModel, n::Int, k, kh, ih, jh)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    JuMP.@NLconstraint(pm.model, ieff == abs(ihi))

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractACPModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")
    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]
    JuMP.@NLconstraint(pm.model, ieff == abs(a*ihi + ilo)/a)

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractACPModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]
    JuMP.@NLconstraint(pm.model, ieff == abs(a*is + ic)/(a + 1.0))

end


# ===   POWER BALANCE CONSTRAINTS   === #




# ===   THERMAL CONSTRAINTS   === #




"CONSTRAINT: qloss calculcated from ac voltage and dc current"
function constraint_qloss(pm::_PM.AbstractACPModel, n::Int, k, i, j, branchMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]
    vm = _PM.var(pm, n, :vm)[i]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * vm * i_dc_mag) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end
