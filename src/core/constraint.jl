import Logging

##### Templated Constraints #######

"Constraint of kcl with shunts"
function constraint_kcl_gmd{T}(pm::GenericPowerModel{T}, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, pd, qd)
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    qloss = pm.var[:nw][n][:qloss]

    # Bus Shunts for gs and bs are missing.  If you add it, you'll have to bifurcate one form of this constraint
    # for the acp model (uses v^2) and the wr model (uses w).  See how the ls version of these constraints does it
    @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd)
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd)   
end

"DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf{T}(pm::GenericPowerModel{T}, n::Int, k, kh, ih, jh)
    ieff = pm.var[:nw][n][:i_dc_mag]
    ihi = pm.var[:nw][n][:dc][(kh,ih,jh)]        

    c = @constraint(pm.model, ieff[k] >= ihi)
    c = @constraint(pm.model, ieff[k] >= -ihi)  
end

"DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf{T}(pm::GenericPowerModel{T}, n::Int, k, kh, ih, jh, kl, il, jl, a)
    debug("branch[$k]: hi_branch[$kh], lo_branch[$kl]")
    
    ieff = pm.var[:nw][n][:i_dc_mag]
    ihi = pm.var[:nw][n][:dc][(kh,ih,jh)]        
    ilo = pm.var[:nw][n][:dc][(kl,il,jl)]        
    
    c = @constraint(pm.model, ieff[k] >= (a*ihi + ilo)/a)
    c = @constraint(pm.model, ieff[k] >= -(a*ihi + ilo)/a)    
end

"DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, n::Int, k, ks, is, js, kc, ic, jc, a)
    ieff = pm.var[:nw][n][:i_dc_mag]
    is = pm.var[:nw][n][:dc][(ks,is,js)]        
    ic = pm.var[:nw][n][:dc][(kc,ic,jc)]        
    
    c = @constraint(pm.model, ieff[k] >= (a*is + ic)/(a + 1.0))
    c = @constraint(pm.model, ieff[k] >= -(a*is + ic)/(a + 1.0))
    c = @constraint(pm.model, ieff[k] >= 0.0)
     
end

"The KCL constraint for DC (GIC) circuits"
function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, n::Int, i, dc_expr, gs, gmd_bus_arcs)
    v_dc = pm.var[:nw][n][:v_dc][i]
    if length(gmd_bus_arcs) > 0
         if getlowerbound(v_dc) > 0 || getupperbound(v_dc) < 0
             println("Warning DC voltage cannot go to 0. This could make the DC KCL constraint overly constrained in switching applications")  
         end 
         @constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc) # as long as v_dc can go to 0, this is ok
        return
    end    
end

"The DC ohms constraint for GIC"
function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, n::Int, i, f_bus, t_bus, vs, gs)
    vf = pm.var[:nw][n][:v_dc][f_bus] # from dc voltage
    vt = pm.var[:nw][n][:v_dc][t_bus] # to dc voltage
    dc = pm.var[:nw][n][:dc][(i,f_bus,t_bus)]
    
    @constraint(pm.model, dc == gs*(vf + vs - vt))  
end

"Constraint for computing qloss assuming DC voltage is constant"
function constraint_qloss_constant_v{T}(pm::GenericPowerModel{T}, n::Int, k, i, j, K, V, branchMVA)
    i_dc_mag = pm.var[:nw][n][:i_dc_mag][k]
    qloss = pm.var[:nw][n][:qloss]      
            
    # K is per phase
    c = @constraint(pm.model, qloss[(k,i,j)] == K*V*i_dc_mag/(3.0*branchMVA))
    c = @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss assuming DC voltage is constant"
function constraint_qloss_constant_v{T}(pm::GenericPowerModel{T}, n::Int, k, i, j)
    qloss = pm.var[:nw][n][:qloss]      
        
    c = @constraint(pm.model, qloss[(k,i,j)] == 0.0)
    c = @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection{T}(pm::GenericPowerModel{T}, n::Int, i, coeff, ibase)
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    ieff = pm.var[:nw][n][:i_dc_mag][i] 

    @constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))    
end

"Constraint for relating current to power flow"
function constraint_current{T}(pm::GenericPowerModel{T}, n::Int, i, f_idx, f_bus, tm)
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    p_fr     = pm.var[:nw][n][:p][f_idx]
    q_fr     = pm.var[:nw][n][:q][f_idx]
    vm       = pm.var[:nw][n][:vm][f_bus]          
      
    @NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)    
end

"Constraint for relating current to power flow on/off"
function constraint_current_on_off{T}(pm::GenericPowerModel{T}, n::Int, i, ac_max)
    z  = pm.var[:nw][n][:branch_z][i]
    i_ac = pm.var[:nw][n][:i_ac_mag][i]        
    @constraint(pm.model, i_ac <= z * ac_max)
    @constraint(pm.model, i_ac >= z * 0.0)      
end

"Constraint for computing qloss"
function constraint_qloss{T}(pm::GenericPowerModel{T}, n::Int, k, i, j, K, branchMVA)
    qloss = pm.var[:nw][n][:qloss]
    i_dc_mag = pm.var[:nw][n][:i_dc_mag]
    vm = pm.var[:nw][n][:vm]
           
    # K is per phase
    @constraint(pm.model, qloss[(k,i,j)] == K*vm[i]*i_dc_mag[k]/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss"
function constraint_qloss{T}(pm::GenericPowerModel{T}, n::Int, k, i, j)
    qloss = pm.var[:nw][n][:qloss]    
    @constraint(pm.model, qloss[(k,i,j)] == 0.0)
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for turning generators on and off"
function constraint_gen_on_off{T}(pm::GenericPowerModel{T}, n::Int, i, pmin, pmax, qmin, qmax)
    z   = pm.var[:nw][n][:gen_z][i]
    pg  = pm.var[:nw][n][:pg][i]  
    qg  = pm.var[:nw][n][:qg][i]  
                      
    @constraint(pm.model, z * pmin <= pg)
    @constraint(pm.model, pg <= z * pmax)                
    @constraint(pm.model, z * qmin <= qg)
    @constraint(pm.model, qg <= z * qmax)                          
end

"Constraint for tieing ots variables to gen variables"
function constraint_gen_ots_on_off{T}(pm::GenericPowerModel{T}, n::Int, i, bus_arcs)
    z   = pm.var[:nw][n][:gen_z][i]
    zb  = pm.var[:nw][n][:branch_z]      
    @constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))    
end

#### Constraints that don't require templates ######

"DC current on normal lines"
function constraint_dc_current_mag_line{T}(pm::GenericPowerModel{T}, n::Int, k)
    ieff = pm.var[:nw][n][:i_dc_mag]
    c = @constraint(pm.model, ieff[k] >= 0.0)  
end
constraint_dc_current_mag_line{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_line(pm, pm.cnw, k)

"DC current on grounded transformers"
function constraint_dc_current_mag_grounded_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    ieff = pm.var[:nw][n][:i_dc_mag]
    c = @constraint(pm.model, ieff[k] >= 0.0)  
end
constraint_dc_current_mag_grounded_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_grounded_xf(pm, pm.cnw, k)

# correct equation is ieff = |a*ihi + ilo|/a
# just use ihi for now
"Constraint for computing the DC current magnitude"
function constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
        
    if branch["type"] != "xf"
        constraint_dc_current_mag_line(pm,n,k)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        debug("  Ungrounded config, ieff constrained to zero")        
        constraint_dc_current_mag_grounded_xf(pm,n,k)   
    elseif branch["config"] in ["delta-gwye","gwye-delta"]
        constraint_dc_current_mag_gwye_delta_xf(pm,n,k)
    elseif branch["config"] == "gwye-gwye"
        constraint_dc_current_mag_gwye_gwye_xf(pm,n,k)
    elseif branch["type"] == "xf" && branch["config"] == "gwye-gwye-auto"
        constraint_dc_current_mag_gwye_gwye_auto_xf(pm,n,k)
    else
        ieff = pm.var[:nw][n][:i_dc_mag]
        c = @constraint(pm.model, ieff[k] >= 0.0)      
    end
end
constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag(pm, pm.cnw, k)

### Todo ######




"Perspective Constraint for generation cost"
function constraint_gen_perspective{T}(pm::GenericPowerModel{T}, n::Int, i)
    gen      = ref(pm, n, :gen, i)
    z        = pm.var[:nw][n][:gen_z][i]
    pg_sqr   = pm.var[:nw][n][:pg_sqr][i]
    pg       = pm.var[:nw][n][:pg][i]
      
    @constraint(pm.model, z*pg_sqr >= gen["cost"][1]*pg^2 )    
end
constraint_gen_perspective{T}(pm::GenericPowerModel{T}, i) = constraint_gen_perspective(pm, pm.cnw, i)


""
function constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :gmd_branch, i)       
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    ac_branch = branch["parent_index"]  

    vf = pm.var[:nw][n][:v_dc][f_bus] # from dc voltage
    vt = pm.var[:nw][n][:v_dc][t_bus] # to dc voltage
    v_dc_diff = pm.var[:nw][n][:v_dc_diff][i] # voltage diff
    vz = pm.var[:nw][n][:vz][i] # voltage diff

    dc = pm.var[:nw][n][:dc][(i,f_bus,t_bus)]
    z  = pm.var[:nw][n][:branch_z][ac_branch]  

    bus1 = pm.ref[:nw][n][:gmd_bus][f_bus]
    bus2 = pm.ref[:nw][n][:gmd_bus][t_bus]

    dkm = branch["len_km"]

    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    @constraint(pm.model, v_dc_diff == vf - vt)
    PowerModels.relaxation_product(pm.model, z, v_dc_diff, vz)
    @constraint(pm.model, dc == gs*(vz + z*vs) )
        
    return 
end
constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_dc_ohms_on_off(pm, pm.cnw, i)
