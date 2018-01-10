import Logging

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
    #c1 = @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd*z_demand)
    #c2 = @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd*z_demand)
    c1 = @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd*z_demand)
    c2 = @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd*z_demand)  
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

    debug("branch[$k]: hi_branch[$kh], lo_branch[$kl]")

    c = @constraint(pm.model, ieff[k] >= (a*ihi + ilo)/a)
    c = @constraint(pm.model, ieff[k] >= -(a*ihi + ilo)/a)
end
constraint_dc_current_mag_gwye_gwye_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_gwye_gwye_xf(pm, pm.cnw, k)

"DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]

    debug(@sprintf "Series GMD branch: %d, Common GMD branch: %d\n" ks kc)
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

    dc_expr = pm.model.ext[:dc_expr]

    gs = dcbus["g_gnd"]
    # println()
    # println("bus: $i branches: $gmd_bus_arcs")

    #@printf "bus %d: gs = %0.3f, %d branches:\n" i gs length(gmd_bus_arcs)
    for arc in gmd_bus_arcs
        k = arc[1]
        branch = pm.ref[:nw][n][:gmd_branch][k]

        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]        
        dkm = branch["len_km"]
        vs = float(branch["br_v"][1])       # line dc series voltage
        rdc = branch["br_r"]
        #@printf "    branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, rdc = %0.3f\n" k f_bus t_bus dkm vs rdc
    end

    if length(gmd_bus_arcs) > 0
        c = @constraint(pm.model, sum(dc_expr[a] for a in gmd_bus_arcs) == gs*v_dc[i])
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

    debug(@sprintf "branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, gs = %0.3f\n" i f_bus t_bus dkm vs gs)

    c = @constraint(pm.model, dc == gs*(vf + vs - vt))
    return 
end
constraint_dc_ohms{T}(pm::GenericPowerModel{T}, i) = constraint_dc_ohms(pm, pm.cnw, i)

""
function constraint_qloss{T}(pm::GenericPowerModel{T}, n::Int, k)
   branch = ref(pm, n, :branch, k)        
#   k = branch["index"]

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:nw][n][:bus][i]

    i_dc_mag = pm.var[:nw][n][:i_dc_mag]
    qloss = pm.var[:nw][n][:qloss]
        
    if "gmd_k" in keys(branch)

        # a = bus["gmd_gs"]

        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase

        # println("bus[$i]: a = $a, K = $K")

          
        #@printf "k = %d, Kold = %f, vb = %f, ib = %f, Knew = %f\n" k branch["gmd_k"] bus["base_kv"] ibase K 
        # K is per phase
        c = @constraint(pm.model, qloss[(k,i,j)] == K*i_dc_mag[k]/(3.0*branch["baseMVA"]))
        c = @constraint(pm.model, qloss[(k,j,i)] == 0.0)
        # c = @constraint(pm.model, qloss[l] == i_dc_mag[k])
    else
        c = @constraint(pm.model, qloss[(k,i,j)] == 0.0)
        c = @constraint(pm.model, qloss[(k,j,i)] == 0.0)
    end

    return 
end
constraint_qloss{T}(pm::GenericPowerModel{T}, k) = constraint_qloss(pm, pm.cnw, k)

