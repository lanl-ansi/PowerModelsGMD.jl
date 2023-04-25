###########################################
# Simple Active Power Only Approximations #
###########################################


# ===   VOLTAGE VARIABLES   === #


# ===   CURRENT CONSTRAINTS   === #

"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractDCPModel, n::Int, k, kh, ih, jh)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        ihi
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        -ihi
    )

end


"CONSTRAINT: dc current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractDCPModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

    Memento.debug(_LOGGER, "branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    ihi = _PM.var(pm, n, :dc)[(kh,ih,jh)]
    ilo = _PM.var(pm, n, :dc)[(kl,il,jl)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a * ihi + ilo) / a
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - (a * ihi + ilo) / a
    )

end


"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractDCPModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a * is + ic) / (a + 1.0)
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - ( a * is + ic) / (a + 1.0)
    )

end


"CONSTRAINT: qloss assuming constant ac primary voltage"
function constraint_qloss(pm::_PM.AbstractDCPModel, n::Int, k, i, j, branchMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    vm = 1.0

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        Memento.warn(_LOGGER, "DC voltage magnitude cannot take a 0 value. In OTS applications, this may result in incorrect results.")
    end

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        ((K * i_dc_mag * vm) / (3.0 * branchMVA))
            # K is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"VARIABLE: ac current"
function variable_ac_positive_current(pm::_PM.AbstractDCPModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    variable_ac_positive_current_mag(pm; nw=nw, bounded=bounded, report=report)

end
