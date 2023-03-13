##############################################
# SDP Relaxations in the Rectangular W-Space #
##############################################

"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractWRMModel, n::Int, k, kh, ih, jh)

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
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractWRMModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

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
