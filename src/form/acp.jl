
function constraint_active_kcl_shunt_flf{T <: PMs.AbstractACPForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    v = getvariable(pm.model, :v)
    p = getvariable(pm.model, :p)
    pg = getvariable(pm.model, :pg)
    loading = getvariable(pm.model, :loading)

    c = @constraint(pm.model, sum{p[a], a in bus_branches} == sum{pg[g], g in bus_gens} - bus["pd"]*loading[i] - bus["gs"]*v[i]^2)
    return Set([c])
end

function constraint_reactive_kcl_shunt_flf{T <: PMs.AbstractACPForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    v = getvariable(pm.model, :v)
    q = getvariable(pm.model, :q)
    qg = getvariable(pm.model, :qg)
    loading = getvariable(pm.model, :loading)

    c = @constraint(pm.model, sum{q[a], a in bus_branches} == sum{qg[g], g in bus_gens} - bus["qd"]*loading[i] + bus["bs"]*v[i]^2)
    return Set([c])
end


# this is legacy code, might be removed after regression tests are confirmed
function constraint_active_kcl_shunt_fl{T <: PMs.AbstractACPForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    v = getvariable(pm.model, :v)
    p = getvariable(pm.model, :p)
    pg = getvariable(pm.model, :pg)
    pd = getvariable(pm.model, :pd)

    c = @constraint(pm.model, sum{p[a], a in bus_branches} == sum{pg[g], g in bus_gens} - pd[i] - bus["gs"]*v[i]^2)
    return Set([c])
end

function constraint_reactive_kcl_shunt_fl{T <: PMs.AbstractACPForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    v = getvariable(pm.model, :v)
    q = getvariable(pm.model, :q)
    qg = getvariable(pm.model, :qg)
    qd = getvariable(pm.model, :qd)

    c = @constraint(pm.model, sum{q[a], a in bus_branches} == sum{qg[g], g in bus_gens} - qd[i] + bus["bs"]*v[i]^2)
    return Set([c])
end
