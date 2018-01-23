" OPF objective"
function objective_gmd_min_fuel{T}(pm::GenericPowerModel{T}, nws=[pm.cnw])
    i_dc_mag = Dict(n => pm.var[:nw][n][:i_dc_mag] for n in nws) #pm.var[:i_dc_mag]
    pg = Dict(n => pm.var[:nw][n][:pg] for n in nws) #pm.var[:pg]

    return @objective(pm.model, Min, sum(
                                          sum(gen["cost"][1]*pg[n][i]^2 + gen["cost"][2]*pg[n][i] 
                                           + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen]) 
                                           + sum(i_dc_mag[n][i]^2 for i in keys(pm.ref[:nw][n][:branch]))
                                          for n in nws)
                     )
end

" SSE objective: keep generators as close as possible to original setpoint"
function objective_gmd_min_error{T}(pm::GenericPowerModel{T}, nws=[pm.cnw])
    i_dc_mag = Dict(n => pm.var[:nw][n][:i_dc_mag] for n in nws) #pm.var[:i_dc_mag]
    pg = Dict(n => pm.var[:nw][n][:pg] for n in nws) # pm.var[:pg]
    qg = Dict(n => pm.var[:nw][n][:qg] for n in nws) # pm.var[:qg]
    z_demand = Dict(n => pm.var[:nw][n][:z_demand] for n in nws) # pm.var[:z_demand]

    pmax = 0.0

    for n in nws
        for (i,gen) in pm.ref[:nw][n][:gen]
            @printf "sg[%d] = %f + j%f\n" i gen["pg"] gen["qg"]
            if gen["pmax"] > pmax
                pmax = gen["pmax"]
            end
        end
    end

    # return @objective(pm.model, Min, sum{ i_dc_mag[i]^2, i in keys(pm.ref[:branch])})
    # return @objective(pm.model, Min, sum(gen["cost"][1]*pg[i]^2 + gen["cost"][2]*pg[i] + gen["cost"][3] for (i,gen) in pm.ref[:gen]) )
    return @objective(pm.model, Min, sum(      
                                        sum((pg[n][i] - gen["pg"])^2  for (i,gen) in pm.ref[:nw][n][:gen])
                                         + sum((qg[n][i] - gen["qg"])^2  for (i,gen) in pm.ref[:nw][n][:gen]) 
                                         + sum(i_dc_mag[n][i]^2 for (i,branch) in pm.ref[:nw][n][:branch])
                                         - sum(100.0*pmax^2*z_demand[n][i] for (i,bus) in pm.ref[:nw][n][:bus])
                                           for n in nws)
                                           )

end

" Minimizes load shedding and fuel cost"
function objective_gmd_min_ls{T}(pm::GenericPowerModel{T}, nws=[pm.cnw])
    pg = Dict(n => pm.var[:nw][n][:pg] for n in nws) 
    pd = Dict(n => pm.var[:nw][n][:pd] for n in nws) 
    qd = Dict(n => pm.var[:nw][n][:qd] for n in nws)     
    shed_cost = calc_load_shed_cost(pm, nws)          
    return @objective(pm.model, Min, sum(
                                          sum(gen["cost"][1]*pg[n][i]^2 + gen["cost"][2]*pg[n][i] 
                                           + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen])                                             
                                           + sum(shed_cost*(pd[n][i]+qd[n][i]) for (i,bus) in pm.ref[:nw][n][:bus])                                            
                                          for n in nws)                    
                                        )
end

" Minimizes load shedding and fuel cost"
function objective_gmd_min_ls_on_off{T}(pm::GenericPowerModel{T}, nws=[pm.cnw])
    pg     = Dict(n => pm.var[:nw][n][:pg] for n in nws)
    pd     = Dict(n => pm.var[:nw][n][:pd] for n in nws) 
    qd     = Dict(n => pm.var[:nw][n][:qd] for n in nws)     
    z      = Dict(n => pm.var[:nw][n][:gen_z] for n in nws)     
  
    # perspective cut  
    for n in nws  
        pg_sqr = pm.var[:nw][n][:pg_sqr] = @variable(pm.model, [i in keys(pm.ref[:nw][n][:gen])], basename="$(n)_pg_sqr", lowerbound = 0.0, upperbound = pm.ref[:nw][n][:gen][i]["cost"][1] * pm.ref[:nw][n][:gen][i]["pmax"]^2) 
        for (i, gen) in pm.ref[:nw][n][:gen]
            @constraint(pm.model, z[n][i]*pg_sqr[i] >= gen["cost"][1]*pg[n][i]^2 )
        end  
    end        
 
    pg_sqr = Dict(n => pm.var[:nw][n][:pg_sqr] for n in nws)        

    shed_cost = calc_load_shed_cost(pm, nws)          
    return @objective(pm.model, Min, sum(
                                          sum(pg_sqr[n][i] + gen["cost"][2]*pg[n][i] 
                                           + gen["cost"][3]*z[n][i] for (i,gen) in pm.ref[:nw][n][:gen])                                             
                                           + sum(shed_cost*(pd[n][i]+qd[n][i]) for (i,bus) in pm.ref[:nw][n][:bus])                                            
                                          for n in nws)                    
                                        )
end