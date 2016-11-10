
function constraint_active_kcl_shunt_fl{T <: PMs.AbstractWRForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    w = getvariable(pm.model, :w)
    p = getvariable(pm.model, :p)
    pg = getvariable(pm.model, :pg)
    pd = getvariable(pm.model, :pd)

    c = @constraint(pm.model, sum{p[a], a in bus_branches} == sum{pg[g], g in bus_gens} - pd[i] - bus["gs"]*w[i])
    return Set([c])
end

function constraint_reactive_kcl_shunt_fl{T <: PMs.AbstractWRForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    w = getvariable(pm.model, :w)
    q = getvariable(pm.model, :q)
    qg = getvariable(pm.model, :qg)
    qd = getvariable(pm.model, :qd)

    c = @constraint(pm.model, sum{q[a], a in bus_branches} == sum{qg[g], g in bus_gens} - qd[i] + bus["bs"]*w[i])
    return Set([c])
end