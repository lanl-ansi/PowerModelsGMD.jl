
"default SOC constructor"
SOCWRPowerModel(data::Dict{String,Any}; kwargs...) = GenericGMDPowerModel(data, SOCWRForm; kwargs...)

"default QC constructor"
function QCWRPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, QCWRForm; kwargs...)
end

"default QC trilinear model constructor"
function QCWRTriPowerModel(data::Dict{String,Any}; kwargs...)
    return GenericGMDPowerModel(data, QCWRTriForm; kwargs...)
end


""
function variable_ac_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
   variable_ac_current_mag(pm,n)
end



"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w[i] + pd_ls
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w[i] + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gmd_ls{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, pd, qd, gs, bs)
    w = pm.var[:nw][n][:w][i]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    
    qloss = pm.var[:nw][n][:qloss]  
    pd_ls = pm.var[:nw][n][:pd]
    qd_ls = pm.var[:nw][n][:qd]     

    @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd - gs*w + pd_ls[i])
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*w + qd_ls[i])
end

"Constraint for relating current to power flow"
function constraint_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    l        = pm.var[:nw][n][:cm][(f_bus, t_bus)]       
          
    # p_fr^2 + q_fr^2 <= l * w comes for free with constraint_power_magnitude_sqr of PowerModels.jl        
    # we just need to connect current and current squared with this constraint
      
    PowerModels.relaxation_sqr(pm.model, i_ac_mag, l)
end
