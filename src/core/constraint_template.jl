"KCL Constraint without load shedding and no shunts"
function constraint_kcl_gmd(pm::GenericPowerModel, n::Int, i::Int)
    bus = ref(pm, n, :bus, i)
    bus_arcs = ref(pm, n, :bus_arcs, i)
    bus_arcs_dc = ref(pm, n, :bus_arcs_dc, i)
    bus_gens = ref(pm, n, :bus_gens, i)
    bus_loads = ref(pm, n, :bus_loads, i)
    bus_shunts = ref(pm, n, :bus_shunts, i)

    pd = Dict(k => v["pd"] for (k,v) in ref(pm, n, :load))
    qd = Dict(k => v["qd"] for (k,v) in ref(pm, n, :load))

    constraint_kcl_gmd(pm, n, i, bus_arcs, bus_arcs_dc, bus_gens, bus_loads, bus_shunts, pd, qd)
end
constraint_kcl_gmd(pm::GenericPowerModel, i::Int) = constraint_kcl_gmd(pm, pm.cnw, i::Int)


"KCL Constraint with load shedding"
function constraint_kcl_shunt_gmd_ls(pm::GenericPowerModel, n::Int, i::Int)
    bus = ref(pm, n, :bus, i)
    bus_arcs = ref(pm, n, :bus_arcs, i)
    bus_arcs_dc = ref(pm, n, :bus_arcs_dc, i)
    bus_gens = ref(pm, n, :bus_gens, i)
    bus_loads = ref(pm, n, :bus_loads, i)
    bus_shunts = ref(pm, n, :bus_shunts, i)

    pd = Dict(k => v["pd"] for (k,v) in ref(pm, n, :load))
    qd = Dict(k => v["qd"] for (k,v) in ref(pm, n, :load))

    gs = Dict(k => v["gs"] for (k,v) in ref(pm, n, :shunt))
    bs = Dict(k => v["bs"] for (k,v) in ref(pm, n, :shunt))

    constraint_kcl_shunt_gmd_ls(pm, n, i, bus_arcs, bus_arcs_dc, bus_gens, bus_loads, bus_shunts, pd, qd, gs, bs)
end
constraint_kcl_shunt_gmd_ls(pm::GenericPowerModel, i::Int) = constraint_kcl_shunt_gmd_ls(pm, pm.cnw, i::Int)

"DC current on ungrounded gwye-delta transformers"
function constraint_dc_current_mag_gwye_delta_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
  
    kh = branch["gmd_br_hi"]
    br_hi = pm.ref[:nw][n][:gmd_branch][kh]

    ih = br_hi["f_bus"]
    jh = br_hi["t_bus"]

    constraint_dc_current_mag_gwye_delta_xf(pm, n, k, kh, ih, jh)        
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


    vhi = pm.ref[:nw][n][:bus][i]["base_kv"]
    vlo = pm.ref[:nw][n][:bus][j]["base_kv"]
    a = vhi/vlo

    constraint_dc_current_mag_gwye_gwye_xf(pm, n, k, kh, ih, jh, kl, il, jl, a)
end
constraint_dc_current_mag_gwye_gwye_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_gwye_gwye_xf(pm, pm.cnw, k)

"DC current on ungrounded gwye-gwye auto transformers"
function constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]

    debug(@sprintf "Series GMD branch: %d, Common GMD branch: %d\n" ks kc)

    br_ser = pm.ref[:nw][n][:gmd_branch][ks]
    br_com = pm.ref[:nw][n][:gmd_branch][kc]

    i = branch["f_bus"]
    j = branch["t_bus"]

    is = br_ser["f_bus"]
    js = br_ser["t_bus"]

    ic = br_com["f_bus"]
    jc = br_com["t_bus"]


    ihi = -is
    ilo = ic + is

    vhi = pm.ref[:nw][n][:bus][j]["base_kv"]
    vlo = pm.ref[:nw][n][:bus][i]["base_kv"]
    a = vhi/vlo

    
    constraint_dc_current_mag_gwye_gwye_auto_xf(pm, n, k, ks, is, js, kc, ic, jc, a)
end
constraint_dc_current_mag_gwye_gwye_auto_xf{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_gwye_gwye_auto_xf(pm, pm.cnw, k)

"The KCL constraint for DC (GIC) circuits"
function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, n::Int, i)
    dcbus = ref(pm, n, :gmd_bus, i)   
    gmd_bus_arcs = pm.ref[:nw][n][:gmd_bus_arcs][i]

    dc_expr = pm.model.ext[:nw][n][:dc_expr]

    gs = dcbus["g_gnd"]

    constraint_dc_kcl_shunt(pm, n, i, dc_expr, gs, gmd_bus_arcs)  
end
constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, i) = constraint_dc_kcl_shunt(pm, pm.cnw, i)

"The DC ohms constraint for GIC"
function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :gmd_branch, i)       
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]

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
   
    constraint_dc_ohms(pm, n, i, f_bus, t_bus, vs, gs)
end
constraint_dc_ohms{T}(pm::GenericPowerModel{T}, i) = constraint_dc_ohms(pm, pm.cnw, i)

"Constraint for computing qloss assuming DC voltage is constant"
function constraint_qloss_constant_v{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)        

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:nw][n][:bus][i]
    V = 1.0
    branchMVA = branch["baseMVA"]
        
    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase          
        constraint_qloss_constant_v(pm, n, k, i, j, K, V, branchMVA)        
    else
       constraint_qloss_constant_v(pm, n, k, i, j)        
    end
end
constraint_qloss_constant_v{T}(pm::GenericPowerModel{T}, k) = constraint_qloss_constant_v(pm, pm.cnw, k)

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    if branch["type"] != "xf"
        return  
    end  

    coeff = calc_branch_thermal_coeff(pm,i,n)  
    ibase = calc_branch_ibase(pm, i, n)

    constraint_thermal_protection(pm, n, i, coeff, ibase)  
end
constraint_thermal_protection{T}(pm::GenericPowerModel{T}, i) = constraint_thermal_protection(pm, pm.cnw, i)

"Constraint for relating current to power flow"
function constraint_current{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    tm       = branch["tap"]^2 
      
    constraint_current(pm, n, i, f_idx, f_bus, t_bus, tm)   
end
constraint_current{T}(pm::GenericPowerModel{T}, i) = constraint_current(pm, pm.cnw, i)

"Constraint for relating current to power flow on/off"
function constraint_current_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :branch, i)
    ac_max = calc_ac_mag_max(pm, i, n)
    
#    constraint_current(pm,n,i)
    constraint_current_on_off(pm, n, i, ac_max)    
end
constraint_current_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_current_on_off(pm, pm.cnw, i)

"Constraint for computing qloss"
function constraint_qloss{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)        

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:nw][n][:bus][i]
        
    if "gmd_k" in keys(branch)
        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase
        branchMVA = branch["baseMVA"]  
        constraint_qloss(pm, n, k, i, j, K, branchMVA)            
    else 
        constraint_qloss(pm, n, k, i, j)  
    end
end
constraint_qloss{T}(pm::GenericPowerModel{T}, k) = constraint_qloss(pm, pm.cnw, k)

"Constraint for turning generators on and off"
function constraint_gen_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    gen = ref(pm, n, :gen, i)
    pmin = gen["pmin"]
    pmax = gen["pmax"]
    qmin = gen["qmin"]
    qmax = gen["qmax"]  
    
    constraint_gen_on_off(pm, n, i, pmin, pmax, qmin, qmax)
end
constraint_gen_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_gen_on_off(pm, pm.cnw, i)

"Constraint for tieing ots variables to gen variables"
function constraint_gen_ots_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    gen = ref(pm, n, :gen, i)
    bus = ref(pm, n, :bus, gen["gen_bus"])
    bus_loads = ref(pm, n, :bus_loads, bus["index"])
    if length(bus_loads) > 0 
        pd = sum([ref(pm, n, :load, i)["pd"] for i in bus_loads])
        qd = sum([ref(pm, n, :load, i)["qd"] for i in bus_loads])
    else
        pd = 0.0
        qd = 0.0
    end

    # has load, so gen can not be on if not connected
    if pd != 0.0 && qd != 0.0
        return
    end
    bus_arcs = ref(pm, n, :bus_arcs, i)

    constraint_gen_ots_on_off(pm, n, i, bus_arcs)
end
constraint_gen_ots_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_gen_ots_on_off(pm, pm.cnw, i)

"Perspective Constraint for generation cost"
function constraint_gen_perspective{T}(pm::GenericPowerModel{T}, n::Int, i)
    gen      = ref(pm, n, :gen, i)
    cost     = gen["cost"]    
    constraint_gen_perspective(pm, n, i, cost)        
end
constraint_gen_perspective{T}(pm::GenericPowerModel{T}, i) = constraint_gen_perspective(pm, pm.cnw, i)

"Ohms Constraint for DC circuits"
function constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, n::Int, i)
    branch = ref(pm, n, :gmd_branch, i)       
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    ac_branch = branch["parent_index"]  

    bus1 = pm.ref[:nw][n][:gmd_bus][f_bus]
    bus2 = pm.ref[:nw][n][:gmd_bus][t_bus]

    dkm = branch["len_km"]

    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    constraint_dc_ohms_on_off(pm, n, i, gs, vs, f_bus, t_bus, ac_branch)
end
constraint_dc_ohms_on_off{T}(pm::GenericPowerModel{T}, i) = constraint_dc_ohms_on_off(pm, pm.cnw, i)

"On/off constraint for current magnitude "
function constraint_dc_current_mag_on_off{T}(pm::GenericPowerModel{T}, n::Int, k)
    branch = ref(pm, n, :branch, k)  
    dc_max = calc_dc_mag_max(pm,k,n)
    constraint_dc_current_mag_on_off(pm, n, k, dc_max)        
end
constraint_dc_current_mag_on_off{T}(pm::GenericPowerModel{T}, k) = constraint_dc_current_mag_on_off(pm, pm.cnw, k)
