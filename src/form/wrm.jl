##############################################
# SDP Relaxations in the Rectangular W-Space #
##############################################

# ===   VOLTAGE VARIABLES   === #

"CONSTRAINT: bus voltage on/off"
function constraint_bus_voltage_on_off(pm::_PM.AbstractWRMModel, n::Int)

    WR = _PM.var(pm, n, :WR)
    WI = _PM.var(pm, n, :WI)
    z_voltage = _PM.var(pm, n, :z_voltage)

    JuMP.@constraint(pm.model,
        [WR WI; -WI WR]
        in JuMP.PSDCone()
    )

    for (i,bus) in _PM.ref(pm, n, :bus)

        constraint_voltage_magnitude_sqr_on_off(pm, i; nw=n)

    end

    constraint_bus_voltage_product_on_off(pm; nw=n)

end
