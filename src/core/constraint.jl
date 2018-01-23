"KCL constraint"
function constraint_gmd_kcl_shunt{T}(pm::GenericPowerModel{T}, n::Int, i)
    bus = ref(pm, n, :bus, i)  
    bus_arcs = pm.ref[:nw][n][:bus_arcs][i]
    bus_gens = pm.ref[:nw][n][:bus_gens][i]
    pd = bus["pd"]
    qd = bus["qd"]
    gs = bus["gs"]
    bs = bus["bs"]

    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    qloss = pm.var[:nw][n][:qloss]

    # why is gs and bs missing?
    c1 = @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd)
    c2 = @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd)
   
end
constraint_gmd_kcl_shunt{T}(pm::GenericPowerModel{T}, i) = constraint_gmd_kcl_shunt(pm, pm.cnw, i)

"KCL constraint with load shedding"
function constraint_gmd_kcl_shunt_ls{T}(pm::GenericPowerModel{T}, n::Int, i)
    bus = ref(pm, n, :bus, i)  
    bus_arcs = pm.ref[:nw][n][:bus_arcs][i]
    bus_gens = pm.ref[:nw][n][:bus_gens][i]
    pd = bus["pd"]
    qd = bus["qd"]
    gs = bus["gs"]
    bs = bus["bs"]

    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    qloss = pm.var[:nw][n][:qloss]

    z_demand = pm.var[:nw][n][:z_demand][i]
    @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd*z_demand)
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd*z_demand)  
end
constraint_gmd_kcl_shunt_ls{T}(pm::GenericPowerModel{T}, i) = constraint_gmd_kcl_shunt_ls(pm, pm.cnw, i)

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

"DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
  
    kh = branch["gmd_br_hi"]
    br_hi = pm.ref[:nw][n][:gmd_branch][kh]

    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    ieff = pm.var[:nw][n][:i_dc_mag]
    ihi = pm.var[:nw][n][:dc][(kh,ih,jh)]        

    # println("branch[$k]: hi_branch[$kh]")

    c = @constraint(pm.model, ieff[k] >= ihi)
    c = @constraint(pm.model, ieff[k] >= -ihi)  
end
constraint_dc_current_mag_gwye_delta_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_gwye_delta_xf(pm, pm.cnw, k)


"DC current on ungrounded gwye-gwye transformers"
function constraint_dc_current_mag_gwye_gwye_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
  
    kh = branch["gmd_br_hi"]
    kl = branch["gmd_br_lo"]

    br_hi = pm.ref[:nw][n][:gmd_branch][kh]
    br_lo = pm.ref[:nw][n][:gmd_branch][kl]

    i = branch["f_bus"]
    j = branch["t_bus"]

    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    il = br_lo["f_bus"]
    jl = br_lo["t_bus"]

    ieff = pm.var[:nw][n][:i_dc_mag]
    ihi = pm.var[:nw][n][:dc][(kh,ih,jh)]        
    ilo = pm.var[:nw][n][:dc][(kl,il,jl)]        

    vhi = pm.ref[:nw][n][:bus][i]["base_kv"]
    vlo = pm.ref[:nw][n][:bus][j]["base_kv"]
    a = vhi/vlo

    println("branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    c = @constraint(pm.model, ieff[k] >= (a*ihi + ilo)/a)
    c = @constraint(pm.model, ieff[k] >= -(a*ihi + ilo)/a)
end
constraint_dc_current_mag_gwye_gwye_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_gwye_gwye_xf(pm, pm.cnw, k)

"DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]

    @printf "Series GMD branch: %d, Common GMD branch: %d\n" ks kc
    #println("GMD branches:", keys(pm.ref[:gmd_branch]))

    br_ser = pm.ref[:nw][n][:gmd_branch][ks]
    br_com = pm.ref[:nw][n][:gmd_branch][kc]

    #k = branch["index"]
    i = branch["f_bus"]
    j = branch["t_bus"]

    is = br_ser["f_bus"]
    js = br_ser["t_bus"]

    ic = br_com["f_bus"]
    jc = br_com["t_bus"]

    ieff = pm.var[:nw][n][:i_dc_mag]
    is = pm.var[:nw][n][:dc][(ks,is,js)]        
    ic = pm.var[:nw][n][:dc][(kc,ic,jc)]        

    ihi = -is
    ilo = ic + is

    vhi = pm.ref[:nw][n][:bus][j]["base_kv"]
    vlo = pm.ref[:nw][n][:bus][i]["base_kv"]
    a = vhi/vlo

    # println("branch[$k]: ser_branch[$ks], com_branch[$kc]")

    c = @constraint(pm.model, ieff[k] >= (a*ihi + ilo)/a)
    c = @constraint(pm.model, ieff[k] >= -(a*ihi + ilo)/a)
    c = @constraint(pm.model, ieff[k] >= 0.0)  
end
constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_gwye_gwye_auto_xf(pm, pm.cnw, k)

# correct equation is ieff = |a*ihi + ilo|/a
# just use ihi for now
function constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
        
#    if "config" in keys(branch)
 #       cfg = branch["config"]
  #  else
   #     cfg = "N/A"
   # end

    #@printf "Branch: %s, type=%s, config=%s\n" branch["name"] branch["type"] cfg

    if branch["type"] != "xf"
        constraint_dc_current_mag_line(pm,n,k)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        println("  Ungrounded config, ieff constrained to zero")        
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

""
function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, n::Int, i)
    dcbus = ref(pm, n, :gmd_bus, i)   
#    i = dcbus["index"]
    gmd_bus_arcs = pm.ref[:nw][n][:gmd_bus_arcs][i]

    # print("Bus branches:")
    # println(bus_branches)

    v_dc = pm.var[:nw][n][:v_dc]
    # println()
    # println("v_dc: $v_dc")

    dc_expr = pm.model.ext[:nw][n][:dc_expr]

    gs = dcbus["g_gnd"]
    # println()
    # println("bus: $i branches: $gmd_bus_arcs")

    #@printf "bus %d: gs = %0.3f, %d branches:\n" i gs length(gmd_bus_arcs)
#    for arc in gmd_bus_arcs
 #       k = arc[1]
  #      branch = pm.ref[:nw][n][:gmd_branch][k]

   #     f_bus = branch["f_bus"]
    #    t_bus = branch["t_bus"]        
     #   dkm = branch["len_km"]
      #  vs = float(branch["br_v"][1])       # line dc series voltage
       # rdc = branch["br_r"]
        #@printf "    branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, rdc = %0.3f\n" k f_bus t_bus dkm vs rdc
    #end

    if length(gmd_bus_arcs) > 0
         @constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc[i]) # as long as v_dc can go to 0, this is ok
#        println(c)
        # println("done")
        return
    end

    # println("solo bus, skipping")
    # println("done")
end
constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, i) = constraint_dc_kcl_shunt(pm, pm.cnw, i)

""
function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :gmd_branch, i)       
    #i = branch["index"]
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]

    vf = pm.var[:nw][n][:v_dc][f_bus] # from dc voltage
    vt = pm.var[:nw][n][:v_dc][t_bus] # to dc voltage
    dc = pm.var[:nw][n][:dc][(i,f_bus,t_bus)]

    bus1 = pm.ref[:nw][n][:gmd_bus][f_bus]
    bus2 = pm.ref[:nw][n][:gmd_bus][t_bus]

    dkm = branch["len_km"]

    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    @printf "branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, gs = %0.3f\n" i f_bus t_bus dkm vs gs

    c = @constraint(pm.model, dc == gs*(vf + vs - vt))
    return 
end
constraint_dc_ohms{T}(pm::GenericPowerModel{T}, i) = constraint_dc_ohms(pm, pm.cnw, i)

""
function constraint_qloss_constant_v{T}(pm::GenericPowerModel{T}, n::Int, k)
   branch = ref(pm, n, :branch, k)        
#   k = branch["index"]

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:nw][n][:bus][i]

    i_dc_mag = pm.var[:nw][n][:i_dc_mag]
    qloss = pm.var[:nw][n][:qloss]
      
    V = 1.0  
        
    if "gmd_k" in keys(branch)

        # a = bus["gmd_gs"]

        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase

        # println("bus[$i]: a = $a, K = $K")

          
        #@printf "k = %d, Kold = %f, vb = %f, ib = %f, Knew = %f\n" k branch["gmd_k"] bus["base_kv"] ibase K 
        # K is per phase
        c = @constraint(pm.model, qloss[(k,i,j)] == K*V*i_dc_mag[k]/(3.0*branch["baseMVA"]))
        c = @constraint(pm.model, qloss[(k,j,i)] == 0.0)
        # c = @constraint(pm.model, qloss[l] == i_dc_mag[k])
    else
        c = @constraint(pm.model, qloss[(k,i,j)] == 0.0)
        c = @constraint(pm.model, qloss[(k,j,i)] == 0.0)
    end

    return 
end
constraint_qloss_constant_v{T}(pm::GenericPowerModel{T}, k) = constraint_qloss_constant_v(pm, pm.cnw, k)

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
    tm       = branch["tap"]^2  
      
    @NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)    
end
constraint_current{T}(pm::GenericPowerModel{T}, i) = constraint_current(pm, pm.cnw, i)

"Constraint for relating current to power flow on/off"
function constraint_current_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    constraint_current(pm,n,i)
    
    branch = ref(pm, n, :branch, i)
    z  = pm.var[:nw][n][:branch_z][i]
    i_ac = pm.var[:nw][n][:i_ac_mag][i]        
    @constraint(pm.model, i_ac <= z * calc_ac_mag_max(pm, i, n))
    @constraint(pm.model, i_ac >= z * 0.0)      
end
constraint_current_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_current_on_off(pm, pm.cnw, i)


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

"Constraint for turning generators on and off"
function constraint_gen_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    gen = ref(pm, n, :gen, i)
    z   = pm.var[:nw][n][:gen_z][i]
    pg  = pm.var[:nw][n][:pg][i]  
    qg  = pm.var[:nw][n][:qg][i]  
                      
    @constraint(pm.model, z * gen["pmin"] <= pg)
    @constraint(pm.model, pg <= z * gen["pmax"])                
    @constraint(pm.model, z * gen["qmin"] <= qg)
    @constraint(pm.model, qg <= z * gen["qmax"])                          
end
constraint_gen_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_gen_on_off(pm, pm.cnw, i)

"Constraint for tieing ots variables to gen variables"
function constraint_gen_ots_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    gen = ref(pm, n, :gen, i)
    bus = ref(pm, n, :bus, gen["gen_bus"])

    # has load, so gen can not be on if not connected      
    if bus["pd"] != 0.0 && bus["qd"] != 0.0     
        return  
    end
      
    z   = pm.var[:nw][n][:gen_z][i]
    zb  = pm.var[:nw][n][:branch_z]      
    bus_arcs = ref(pm, n, :bus_arcs, i)                      
    @constraint(pm.model, z <= sum(zb[a[1]] for a in bus_arcs))    
end
constraint_gen_ots_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_gen_ots_on_off(pm, pm.cnw, i)


""
function constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :gmd_branch, i)       
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    ac_branch = branch["parent_index"]  

    vf = pm.var[:nw][n][:v_dc][f_bus] # from dc voltage
    vt = pm.var[:nw][n][:v_dc][t_bus] # to dc voltage
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

    @constraint(pm.model, dc == z*gs*(vf + vs - vt))
      
    return 
end
constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_dc_ohms_on_off(pm, pm.cnw, i)
