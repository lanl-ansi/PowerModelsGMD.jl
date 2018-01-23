

""
const ACPPowerModel = GenericPowerModel{PowerModels.StandardACPForm}

"default AC constructor for GMD type problems"
ACPPowerModel(data::Dict{String,Any}; kwargs...) =
    GenericGMDPowerModel(data, PowerModels.StandardACPForm; kwargs...)

""
function variable_ac_current{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_ac_current_mag(pm,n;bounded=bounded)
end

""
function variable_ac_current_on_off{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T},n::Int=pm.cnw)
   variable_ac_current_mag(pm,n;bounded=false) # needs to be false because this is an on/off variable
end

""
function variable_dc_current{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_dc_current_mag(pm,n;bounded=bounded)
end

""
function variable_reactive_loss{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_qloss(pm,n;bounded=bounded)
end    
     
"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gmd_ls{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, pd, qd, gs, bs)
    vm = pm.var[:nw][n][:vm][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    qloss = pm.var[:nw][n][:qloss]  
    pd_ls = pm.var[:nw][n][:pd]
    qd_ls = pm.var[:nw][n][:qd]
      
    pm.con[:nw][n][:kcl_p][i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd - gs*vm^2 + pd_ls[i])
    pm.con[:nw][n][:kcl_q][i] = @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd + bs*vm^2 + qd_ls[i])
end

