# Formulations of GMD Mitigation Problems that allow load shedding and generation dispatch
# Reference - "Optimal Transmission Line Switching under Geomagnetic Disturbances", IEEE Transactions on Power Systems
# This corresponds to model C4

export run_gmd_ls, run_ac_gmd_ls, run_qc_gmd_ls

"Run the GMD mitigation with the nonlinear AC equations"
function run_ac_gmd_ls(file, solver; kwargs...)
    return run_gmd_ls(file, ACPPowerModel, solver; kwargs...)
end

"Run the GMD mitigation with the QC AC equations"
function run_qc_gmd_ls(file, solver; kwargs...)
    return run_gmd_ls(file, QCWRTriPowerModel, solver; kwargs...)
end

"Minimize load shedding and fuel costs for GMD mitigation"
function run_gmd_ls(file::AbstractString, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gmd_ls; solution_builder = get_gmd_solution, kwargs...)
end

"GMD Model - Minimizes Generator Dispatch and Load Shedding"
function post_gmd_ls{T}(pm::GenericPowerModel{T}; kwargs...)

    # AC modeling
    PowerModels.variable_voltage(pm) # theta_i and V_i, includes constraint 3o 
    PowerModels.variable_active_branch_flow(pm) # p_ij 
    PowerModels.variable_reactive_branch_flow(pm) # q_ij
    PowerModels.variable_generation(pm) # f^p_i, f^q_i, includes a variation of constraints 3q, 3r 
    variable_load(pm) # l_i^p, l_i^q
    variable_ac_current(pm) # \tilde I^a_e and l_e
    
    # DC modeling
    variable_dc_voltage(pm) # V^d_i 
    variable_qloss(pm) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)
    variable_dc_current_mag(pm) # \tilde I^d_e
    variable_dc_line_flow(pm) # I^d_e

    # Minimize load shedding and fuel cost 
    objective_gmd_min_ls(pm) # variation of equation 3a

    for i in ids(pm, :ref_buses)
        PowerModels.constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_kcl_shunt_gmd_ls(pm, i) # variation of 3b, 3c
    end
    
    for (i,branch) in ref(pm,:branch)
        constraint_dc_current_mag(pm, i) # constraints 3u
        constraint_qloss(pm, i) # individual terms of righthand side of constraints 3x
        constraint_thermal_protection(pm, i) # constraints 3w
        constraint_current(pm, i) # constraints 3k and 3l

        PowerModels.constraint_ohms_yt_from(pm, i) # variation of constraints 3d, 3e
        PowerModels.constraint_ohms_yt_to(pm, i)   # variation of constraints 3f, 3g
      
        
        PowerModels.constraint_thermal_limit_from(pm, i) # variation of constraints 3m
        PowerModels.constraint_thermal_limit_to(pm, i)   # variation of constraints 3m
        PowerModels.constraint_voltage(pm) # Make this on/off
        PowerModels.constraint_voltage_angle_difference(pm, i) # variation of constraints 3p
    end
 
    ### DC network constraints ###
    for (i,bus) in ref(pm,:gmd_bus)
       constraint_dc_kcl_shunt(pm, i) # variation of constraint 3s
    end

    for (i,branch) in ref(pm,:gmd_branch)
        constraint_dc_ohms(pm, i) # variation of constraint 3t
    end   
end


## Variables ####

#### Objective ####

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

###### Constraints #####

"Constraint for computing qloss"
function constraint_qloss{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)        

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:nw][n][:bus][i]

    i_dc_mag = pm.var[:nw][n][:i_dc_mag]
    qloss = pm.var[:nw][n][:qloss]
    vm = pm.var[:nw][n][:vm]
        
    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase

        # K is per phase
        @constraint(pm.model, qloss[(k,i,j)] == K*vm[i]*i_dc_mag[k]/(3.0*branch["baseMVA"]))
        @constraint(pm.model, qloss[(k,j,i)] == 0.0)
    else
        @constraint(pm.model, qloss[(k,i,j)] == 0.0)
        @constraint(pm.model, qloss[(k,j,i)] == 0.0)
    end

    return 
end
constraint_qloss{T}(pm::GenericPowerModel{T}, k) = constraint_qloss(pm, pm.cnw, k)

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    if branch["type"] != "xf"
        return  
    end  

    coeff = calc_branch_thermal_coeff(pm,i,n)  #branch["thermal_coeff"]
    ibase = calc_branch_ibase(pm, i, n)

    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] #getindex(pm.model, :i_ac_mag)[i]
    ieff = pm.var[:nw][n][:i_dc_mag][i] #getindex(pm.model, :i_dc_mag)[i]

    @constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))    
end
constraint_thermal_protection{T}(pm::GenericPowerModel{T}, i) = constraint_thermal_protection(pm, pm.cnw, i)

"Constraint for relating current to power flow"
function constraint_current{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    p_fr     = pm.var[:nw][n][:p][f_idx]
    q_fr     = pm.var[:nw][n][:q][f_idx]
    vm       = pm.var[:nw][n][:vm][f_bus]    
      
    @NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2)    
end
constraint_current{T}(pm::GenericPowerModel{T}, i) = constraint_current(pm, pm.cnw, i)
