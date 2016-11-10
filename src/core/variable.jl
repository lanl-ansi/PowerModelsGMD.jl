
function variable_loading_factor{T}(pm::GenericPowerModel{T})
    @variable(pm.model, 0 <= loading[i in pm.set.bus_indexes] <= 1, start = PMs.getstart(pm.set.buses, i, "loading_start", 1.0))
    return loading
end

function variable_generation_indicator{T}(pm::GenericPowerModel{T})
    @variable(pm.model, 0 <= gen_z[l in pm.set.gen_indexes] <= 1, Int, start = PMs.getstart(pm.set.gens, l, "gen_z_start", 1.0))
    return gen_z
end


# this is legacy code, might be removed after regression tests are confirmed
function variable_active_load{T}(pm::GenericPowerModel{T})
    @variable(pm.model, min(0, pm.set.buses[i]["pd"]) <= pd[i in pm.set.bus_indexes] <= max(0, pm.set.buses[i]["pd"]), start = PMs.getstart(pm.set.buses, i, "pd_start"))
    return pd
end

function variable_reactive_load{T}(pm::GenericPowerModel{T})
    @variable(pm.model, min(0, pm.set.buses[i]["qd"]) <= qd[i in pm.set.bus_indexes] <= max(0, pm.set.buses[i]["qd"]), start = PMs.getstart(pm.set.buses, i, "qd_start"))
    return qd
end

