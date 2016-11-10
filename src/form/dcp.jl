function variable_reactive_load{T <: PMs.AbstractDCPForm}(pm::GenericPowerModel{T})
    # do nothing, this model does not have reactive variables
end

# need to overload this objective becouse reactive power vars do not exiest in DC models
function objective_max_active_and_reactive_loadability{T <: PMs.AbstractDCPForm}(pm::GenericPowerModel{T})
    pd = getvariable(pm.model, :pd)
    c_pd = [bp => 1 for bp in pm.set.bus_indexes] 
    
    for (i,bus) in pm.set.buses
        if (bus["pd"] < 0)  
            c_pd[i] = -1
        end
    end

    return @objective(pm.model, Max, sum{ c_pd[i]*pd[i], i in pm.set.bus_indexes })
end


function constraint_active_kcl_shunt_fl{T <: PMs.AbstractDCPForm}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    pg = getvariable(pm.model, :pg)
    p_expr = pm.model.ext[:p_expr]
    pd = getvariable(pm.model, :pd)

    c = @constraint(pm.model, sum{p_expr[a], a in bus_branches} == sum{pg[g], g in bus_gens} - pd[i] - bus["gs"]*1.0^2)
    return Set([c])
end

function constraint_reactive_kcl_shunt_fl{T <: PMs.AbstractDCPForm}(pm::GenericPowerModel{T}, bus)
    # Do nothing, this model does not have reactive variables
    return Set()
    i = bus["index"]

    qd = getvariable(pm.model, :qd)

    #c = @constraint(pm.model, qd[i] == 0)
    return Set([c])
end