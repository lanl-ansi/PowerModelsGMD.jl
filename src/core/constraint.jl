

# Generic generator on/off constraint
function constraint_generation_active_on_off{T}(pm::GenericPowerModel{T}, gen)
    i = gen["index"]

    pg = getvariable(pm.model, :pg)[i]
    z = getvariable(pm.model, :gen_z)[i]

    c1 = @constraint(pm.model, pg >= gen["pmin"]*z)
    c2 = @constraint(pm.model, pg <= gen["pmax"]*z)
    return Set([c1, c2])
end

# Generic generator on/off constraint
function constraint_generation_reactive_on_off{T}(pm::GenericPowerModel{T}, gen)
    i = gen["index"]

    qg = getvariable(pm.model, :qg)[i]
    z = getvariable(pm.model, :gen_z)[i]

    c1 = @constraint(pm.model, qg >= gen["qmin"]*z)
    c2 = @constraint(pm.model, qg <= gen["qmax"]*z)
    return Set([c1, c2])
end
