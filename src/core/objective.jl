
function objective_max_loadability{T}(pm::GenericPowerModel{T})
    loading = getvariable(pm.model, :loading)
    return @objective(pm.model, Max, sum{ pm.set.buses[i]["pd"]*loading[i], i in pm.set.bus_indexes } )
end

function objective_max_active_and_reactive_loadability{T}(pm::GenericPowerModel{T})
    pd = getvariable(pm.model, :pd)
    qd = getvariable(pm.model, :qd)

    c_qd = Dict(bp => 1 for bp in pm.set.bus_indexes)
    c_pd = Dict(bp => 1 for bp in pm.set.bus_indexes) 
    
    for (i,bus) in pm.set.buses
        if (bus["qd"] < 0)  
            c_qd[i] = -1
        end
        if (bus["pd"] < 0)  
            c_pd[i] = -1
        end
    end

    return @objective(pm.model, Max, sum{ c_pd[i]*pd[i] + c_qd[i]*qd[i], i in pm.set.bus_indexes })
end
