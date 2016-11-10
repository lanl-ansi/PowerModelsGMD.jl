
function constraint_active_kcl_shunt_fl{T <: PMs.AbstractWRMForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    WR = getvariable(pm.model, :WR)
    w_index = pm.model.ext[:lookup_w_index][i]
    w_i = WR[w_index, w_index]

    p = getvariable(pm.model, :p)
    pg = getvariable(pm.model, :pg)
    pd = getvariable(pm.model, :pd)

    c = @constraint(pm.model, sum{p[a], a in bus_branches} == sum{pg[g], g in bus_gens} - pd[i] - bus["gs"]*w_i)
    return Set([c])
end

function constraint_reactive_kcl_shunt_fl{T <: PMs.AbstractWRMForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    WR = getvariable(pm.model, :WR)
    w_index = pm.model.ext[:lookup_w_index][i]
    w_i = WR[w_index, w_index]

    q = getvariable(pm.model, :q)
    qg = getvariable(pm.model, :qg)
    qd = getvariable(pm.model, :qd)

    c = @constraint(pm.model, sum{q[a], a in bus_branches} == sum{qg[g], g in bus_gens} - qd[i] + bus["bs"]*w_i)
    return Set([c])
end