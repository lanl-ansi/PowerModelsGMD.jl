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

"CONSTRAINT: dc current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractWRMModel, n::Int, k, ks, is, js, kc, ic, jc, a)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    is = _PM.var(pm, n, :dc)[(ks,is,js)]
    ic = _PM.var(pm, n, :dc)[(kc,ic,jc)]

    JuMP.@constraint(pm.model,
        ieff
        >=
        (a*is + ic) / (a + 1.0)
    )
    JuMP.@constraint(pm.model,
        ieff
        >=
        - (a*is + ic) / (a + 1.0)
    )

end

# "CONSTRAINT: qloss assuming constant ac primary voltage"
# function constraint_qloss(pm::_PM.AbstractWRMModel, n::Int, k, i, j, baseMVA, K)

#     qloss = _PM.var(pm, n, :qloss)
#     i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

#     iv = _PM.var(pm, n, :iv)[(k,i,j)]
#     vm = _PM.var(pm, n, :vm)[i]

#     if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
#         Memento.warn(_LOGGER, "DC voltage magnitude cannot take a 0 value. In OTS applications, this may result in incorrect results.")
#     end

#     JuMP.@constraint(pm.model,
#         qloss[(k,i,j)]
#         ==
#         ((K * iv) / (3.0 * baseMVA))
#             # K is per phase
#     )
#     JuMP.@constraint(pm.model,
#         qloss[(k,j,i)]
#         ==
#         0.0
#     )

#     _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)

# end


"FUNCTION: ac current"
function variable_ac_positive_current(pm::_PM.AbstractWRMModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    variable_ac_positive_current_mag(pm; nw=nw, bounded=bounded, report=report)
    variable_ac_current_mag_sqr(pm; nw=nw, bounded=bounded, report=report)

end
