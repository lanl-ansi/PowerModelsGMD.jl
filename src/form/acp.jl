

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
      
    @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd - gs*vm^2 + pd_ls[i])
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd + bs*vm^2 + qd_ls[i])
end

"Constraint for relating current to power flow"
function constraint_current{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i, f_idx, f_bus, t_bus, tm)
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    p_fr     = pm.var[:nw][n][:p][f_idx]
    q_fr     = pm.var[:nw][n][:q][f_idx]
    vm       = pm.var[:nw][n][:vm][f_bus]          
      
    @NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)    
end

"Constraint for relating current to power flow on/off"
function constraint_current_on_off{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i, ac_max)
    z  = pm.var[:nw][n][:branch_z][i]
    i_ac = pm.var[:nw][n][:i_ac_mag][i]        
    @constraint(pm.model, i_ac <= z * ac_max)
    @constraint(pm.model, i_ac >= z * 0.0)      
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i, coeff, ibase)
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    ieff = pm.var[:nw][n][:i_dc_mag][i] 

    @constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))    
end

"Constraint for computing qloss"
function constraint_qloss{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, k, i, j, K, branchMVA)
    qloss = pm.var[:nw][n][:qloss]
    i_dc_mag = pm.var[:nw][n][:i_dc_mag][k]
    vm = pm.var[:nw][n][:vm][i]
    
    if getlowerbound(i_dc_mag) > 0.0 || getupperbound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")  
    end
        
    # K is per phase
    @constraint(pm.model, qloss[(k,i,j)] == K*vm*i_dc_mag/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss"
function constraint_qloss{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, k, i, j)
    qloss = pm.var[:nw][n][:qloss]    
    @constraint(pm.model, qloss[(k,i,j)] == 0.0)
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

