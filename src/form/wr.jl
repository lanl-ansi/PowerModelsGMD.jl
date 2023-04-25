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


"CONSTRAINT: qloss assuming constant ac primary voltage"
function constraint_qloss(pm::_PM.AbstractWRModel, n::Int, k, i, j, branchMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    iv = _PM.var(pm, n, :iv)[(k,i,j)]
    vm = _PM.var(pm, n, :vm)[i]

    if JuMP.lower_bound(i_dc_mag) > 0.0 || JuMP.upper_bound(i_dc_mag) < 0.0
        Memento.warn(_LOGGER, "DC voltage magnitude cannot take a 0 value. In OTS applications, this may result in incorrect results.")
    end

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        ((K * iv) / (3.0 * branchMVA))
            # K is per phase
    )
    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

    _IM.relaxation_product(pm.model, i_dc_mag, vm, iv)

end


# ===   THERMAL CONSTRAINTS   === #


"CONSTRAINT: dc current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf(pm::_PM.AbstractWRModel, n::Int, k, kh, ih, jh)

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
function constraint_dc_current_mag_gwye_gwye_xf(pm::_PM.AbstractWRModel, n::Int, k, kh, ih, jh, kl, il, jl, a)

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
function constraint_dc_current_mag_gwye_gwye_auto_xf(pm::_PM.AbstractWRModel, n::Int, k, ks, is, js, kc, ic, jc, a)

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
