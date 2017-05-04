# Formulations of GMD Problems
export run_gmd, run_ac_gmd

function run_ac_gmd(file, solver; kwargs...)
    return run_gmd(file, PMs.ACPPowerModel, solver; kwargs...)
end

function run_gmd(file::AbstractString, model_constructor, solver; kwargs...)
    data = PowerModels.parse_file(file)
    return run_gmd(data, model_constructor, solver; kwargs...)
end

function run_gmd(data::Dict{AbstractString,Any}, model_constructor, solver; kwargs...)
    pm = model_constructor(data; kwargs...)

    PowerModelsGMD.add_gmd_ref(pm)

    post_gmd(pm; kwargs...)

    solution = solve_generic_model(pm, solver; solution_builder = get_gmd_solution)

    return solution
    # TODO with improvements to PowerModels, see if this function can be replaced by,
    # return PMs.run_generic_model(file, model_constructor, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...) 
end

function post_gmd{T}(pm::GenericPowerModel{T}; kwargs...)
    #println("Power Model GMD data")
    #println("----------------------------------")
    PMs.variable_voltage(pm)

    variable_dc_voltage(pm)

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_generation(pm) 
    PMs.variable_line_flow(pm) 

    variable_dc_line_flow(pm)

    PMs.constraint_theta_ref(pm) 

    if :setting in keys(Dict(kwargs))
        setting = Dict(Dict(kwargs)[:setting])
    else
        setting = Dict()
    end

    println("kwargs: ", kwargs)
    println("setting: ",setting)

    if "objective" in keys(setting)
        objective = setting["objective"]
    else
        objective = "min_fuel"
    end

    println("objective: ",objective)

    # println("kwargs: ",Dict(kwargs)[:setting])
    # println("kwargs keys: ",keys(Dict(kwargs)[:setting]))

    # if "objective" in setting
    #     println("OBJECTIVE IS SPECIFIED")
    # else
    #     println("OBJECTIVE NOT SPECIFIED")
    # end

    if objective == "min_error"
        println("APPLYING MIN ERROR OBJECTIVE")
        objective_gmd_min_error(pm)
        # objective_gmd_min_fuel(pm)
    else
        println("APPLYING MIN FUEL OBJECTIVE")
        objective_gmd_min_fuel(pm)
    end

    for (i,bus) in pm.ref[:bus]
        constraint_gmd_kcl_shunt(pm, bus) 
    end

    for (i,branch) in pm.ref[:branch]
        constraint_dc_current_mag(pm, branch)
        constraint_qloss(pm, branch)

        PMs.constraint_ohms_yt_from(pm, branch) 
        PMs.constraint_ohms_yt_to(pm, branch) 


        if objective == "min_error"
            # println("APPLYING THERMAL LIMIT CONSTRAINT")
            # PMs.constraint_thermal_limit_from(pm, branch)
            # PMs.constraint_thermal_limit_to(pm, branch)
            # PMs.constraint_voltage(pm) 
            # PMs.constraint_phase_angle_difference(pm, branch) 
        else
            PMs.constraint_thermal_limit_from(pm, branch)
            PMs.constraint_thermal_limit_to(pm, branch)
            PMs.constraint_voltage(pm) 
            PMs.constraint_phase_angle_difference(pm, branch) 
            # println("DISABLING THERMAL LIMIT CONSTRAINT")
        end

    end

    #println()
    #println("Buses")
    #println("--------------------")

    ### DC network constraints ###
    for (i,bus) in pm.ref[:gmd_bus]
        # println("bus:")
        # println(bus)
        constraint_dc_kcl_shunt(pm, bus)
    end

    #println()
    #println("Branches")
    #println("--------------------")

    for (i,branch) in pm.ref[:gmd_branch]
        constraint_dc_ohms(pm, branch)
    end

    #println()
end


function get_gmd_solution{T}(pm::GenericPowerModel{T})
    sol = Dict{AbstractString,Any}()

    PMs.add_bus_voltage_setpoint(sol, pm);
    add_bus_dc_current_mag_setpoint(sol, pm)
    add_bus_qloss_setpoint(sol, pm)
    PMs.add_bus_demand_setpoint(sol, pm)
    PMs.add_generator_power_setpoint(sol, pm)
    PMs.add_branch_flow_setpoint(sol, pm)
    add_bus_dc_voltage_setpoint(sol, pm)
    add_branch_dc_flow_setpoint(sol, pm)

    return sol
end


# data to be concerned with:
# 1. shunt impedances aij
# 2. equivalent currents Jij?
# 3. transformer loss factor Ki? NO, UNITLESSS
# 4. electric field magnitude?
gmd_not_pu = Set(["gmd_gs","gmd_e_field_mag"])
gmd_not_rad = Set(["gmd_e_field_dir"])

function make_gmd_per_unit!(data::Dict{AbstractString,Any})
    if !haskey(data, "GMDperUnit") || data["GMDperUnit"] == false
        make_gmd_per_unit!(data["baseMVA"], data)
        data["GMDperUnit"] = true
    end
end

function make_gmd_per_unit!(mva_base::Number, data::Dict{AbstractString,Any})
    # vb = 1e3*data["bus"][1]["base_kv"] # not sure h
    # data["gmd_e_field_mag"] /= vb
    # data["gmd_e_field_dir"] *= pi/180.0

    for bus in data["bus"]
        zb = bus["base_kv"]^2/mva_base
        #@printf "bus [%d] zb: %f a(pu): %f\n" bus["index"] zb bus["gmd_gs"]
        bus["gmd_gs"] *= zb
        # @printf " -> a(pu): %f\n" bus["gmd_gs"]
    end
end


################### Variables ###################
function variable_dc_voltage{T}(pm::GenericPowerModel{T}; bounded = true)
    @variable(pm.model, v_dc[i in keys(pm.ref[:gmd_bus])], start = PMs.getstart(pm.ref[:gmd_bus], i, "v_dc_start"))
    return v_dc
end

function variable_dc_current_mag{T}(pm::GenericPowerModel{T}; bounded = true)
    @variable(pm.model, i_dc_mag[i in keys(pm.ref[:branch])], start = PMs.getstart(pm.ref[:branch], i, "i_dc_mag_start"))
    return i_dc_mag
end

function variable_dc_line_flow{T}(pm::GenericPowerModel{T}; bounded = true)
    @variable(pm.model, dc[(l,i,j) in pm.ref[:gmd_arcs]], start = PMs.getstart(pm.ref[:gmd_branch], l, "dc_start"))

    dc_expr = Dict([((l,i,j), -1.0*dc[(l,i,j)]) for (l,i,j) in pm.ref[:gmd_arcs_from]])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*dc[(l,i,j)]) for (l,i,j) in pm.ref[:gmd_arcs_from]]))

    pm.model.ext[:dc_expr] = dc_expr

    return dc
end

# define qloss for each branch, it flows into the "to" side of the branch
function variable_qloss{T}(pm::GenericPowerModel{T})
    # TODO: if you want to define qloss only on the "to" side you should define on the set keys(pm.ref[:branch]) or :arcs_to
    @variable(pm.model, qloss[(l,i,j) in pm.ref[:arcs]], start = PMs.getstart(pm.ref[:branch], l, "qloss_start"))

    return qloss
end


################### Objective ###################
# OPF objective
function objective_gmd_min_fuel{T}(pm::GenericPowerModel{T})
    i_dc_mag = getvariable(pm.model, :i_dc_mag)
    pg = getvariable(pm.model, :pg)

    # return @objective(pm.model, Min, sum{ i_dc_mag[i]^2, i in keys(pm.ref[:branch])})
    # return @objective(pm.model, Min, sum(gen["cost"][1]*pg[i]^2 + gen["cost"][2]*pg[i] + gen["cost"][3] for (i,gen) in pm.ref[:gen]) )
    return @objective(pm.model, Min, sum(gen["cost"][1]*pg[i]^2 + gen["cost"][2]*pg[i] + gen["cost"][3] for (i,gen) in pm.ref[:gen]) + sum(i_dc_mag[i]^2 for i in keys(pm.ref[:branch])))
end

# SSE objective: keep generators as close as possible to original setpoint
function objective_gmd_min_error{T}(pm::GenericPowerModel{T})
    i_dc_mag = getvariable(pm.model, :i_dc_mag)
    pg = getvariable(pm.model, :pg)
    qg = getvariable(pm.model, :qg)

    for (i,gen) in pm.ref[:gen]
        @printf "sg[%d] = %f + j%f" i gen["pg"] gen["qg"]
    end

    # return @objective(pm.model, Min, sum{ i_dc_mag[i]^2, i in keys(pm.ref[:branch])})
    # return @objective(pm.model, Min, sum(gen["cost"][1]*pg[i]^2 + gen["cost"][2]*pg[i] + gen["cost"][3] for (i,gen) in pm.ref[:gen]) )
    return @objective(pm.model, Min, sum((pg[i] - gen["pg"])^2  for (i,gen) in pm.ref[:gen]) + sum((qg[i] - gen["qg"])^2  for (i,gen) in pm.ref[:gen]) + sum(i_dc_mag[i]^2 for i in keys(pm.ref[:branch]))
end


################### Constraints ###################

function constraint_gmd_kcl_shunt{T}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_arcs = pm.ref[:bus_arcs][i]
    bus_gens = pm.ref[:bus_gens][i]
    pd = bus["pd"]
    qd = bus["qd"]
    gs = bus["gs"]
    bs = bus["bs"]

    v = getvariable(pm.model, :v)[i]
    p = getvariable(pm.model, :p)
    q = getvariable(pm.model, :q)
    pg = getvariable(pm.model, :pg)
    qg = getvariable(pm.model, :qg)
    qloss = getvariable(pm.model, :qloss)

    c1 = @constraint(pm.model, sum(p[a] for a in bus_arcs) == sum(pg[g] for g in bus_gens) - pd - gs*v^2)
    c2 = @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - qd + bs*v^2)
    return Set([c1, c2])
end


# correct equation is ieff = |a*ihi + ilo|/a
# just use ihi for now
function constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, branch)
    # print(keys(branch))

    if "config" in keys(branch)
        cfg = branch["config"]
    else
        cfg = "N/A"
    end

    #@printf "Branch: %s, type=%s, config=%s\n" branch["name"] branch["type"] cfg

    if branch["type"] != "xf"
        k = branch["index"]
        ieff = getvariable(pm.model, :i_dc_mag)
        c = @constraint(pm.model, ieff[k] >= 0.0)
        return Set([c])
    end


    if branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        println("  Ungrounded config, ieff constrained to zero")
        k = branch["index"]
        ieff = getvariable(pm.model, :i_dc_mag)
        c = @constraint(pm.model, ieff[k] >= 0.0)
        return Set([c])
    end


    # Ungrounded types:
    # lines, series capacitors, delta-delta xfs, delta-wye xfs, wye-delta xfs, wye-wye xfs
    # Delta-Gywe transformer
    # GWye-Delta transformer
    if branch["config"] in ["delta-gwye","gwye-delta"] 
        k = branch["index"]

        kh = branch["gmd_br_hi"]
        br_hi = pm.ref[:gmd_branch][kh]

        ih = br_hi["f_bus"]
        jh = br_hi["t_bus"]

        ieff = getvariable(pm.model, :i_dc_mag)
        ihi = getvariable(pm.model, :dc)[(kh,ih,jh)]        

        # println("branch[$k]: hi_branch[$kh]")

        c = @constraint(pm.model, ieff[k] >= ihi)
        c = @constraint(pm.model, ieff[k] >= -ihi)

        return Set([c])
    end

    # need to add support for other trarnsformer types
    # println("Key not found")

    # Gwye-Gwye transformer
    if branch["config"] == "gwye-gwye" 
        kh = branch["gmd_br_hi"]
        kl = branch["gmd_br_lo"]

        br_hi = pm.ref[:gmd_branch][kh]
        br_lo = pm.ref[:gmd_branch][kl]

        k = branch["index"]
        i = branch["f_bus"]
        j = branch["t_bus"]

        ih = br_hi["f_bus"]
        jh = br_hi["t_bus"]

        il = br_lo["f_bus"]
        jl = br_lo["t_bus"]

        ieff = getvariable(pm.model, :i_dc_mag)
        ihi = getvariable(pm.model, :dc)[(kh,ih,jh)]        
        ilo = getvariable(pm.model, :dc)[(kl,il,jl)]        

        vhi = pm.ref[:bus][i]["base_kv"]
        vlo = pm.ref[:bus][j]["base_kv"]
        a = vhi/vlo

        println("branch[$k]: hi_branch[$kh], lo_branch[$kl]")

        c = @constraint(pm.model, ieff[k] >= (a*ihi + ilo)/a)
        c = @constraint(pm.model, ieff[k] >= -(a*ihi + ilo)/a)

        return Set([c])
    end

    # GWye-GWye autodransformer
    #if "gmd_br_series" in keys(branch) && "gmd_br_common" in keys(branch)
    if branch["type"] == "xf" && branch["config"] == "gwye-gwye-auto" 
        ks = branch["gmd_br_series"]
        kc = branch["gmd_br_common"]

        br_ser = pm.ref[:gmd_branch][ks]
        br_com = pm.ref[:gmd_branch][kc]

        k = branch["index"]
        i = branch["f_bus"]
        j = branch["t_bus"]

        is = br_ser["f_bus"]
        js = br_ser["t_bus"]

        ic = br_com["f_bus"]
        jc = br_com["t_bus"]

        ieff = getvariable(pm.model, :i_dc_mag)
        is = getvariable(pm.model, :dc)[(ks,is,js)]        
        ic = getvariable(pm.model, :dc)[(kc,ic,jc)]        

        ihi = -is
        ilo = ic + is

        vhi = pm.ref[:bus][j]["base_kv"]
        vlo = pm.ref[:bus][i]["base_kv"]
        a = vhi/vlo

        # println("branch[$k]: ser_branch[$ks], com_branch[$kc]")

        c = @constraint(pm.model, ieff[k] >= (a*ihi + ilo)/a)
        c = @constraint(pm.model, ieff[k] >= -(a*ihi + ilo)/a)
        c = @constraint(pm.model, ieff[k] >= 0.0)
        return Set([c])
    end


    #@printf "Unrecognized branch: %s, type=%s, config=%s\n" branch["name"] branch["type"] cfg
    k = branch["index"]
    ieff = getvariable(pm.model, :i_dc_mag)
    c = @constraint(pm.model, ieff[k] >= 0.0)
    return Set([c])
end


function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, dcbus)
    i = dcbus["index"]
    gmd_bus_arcs = pm.ref[:gmd_bus_arcs][i]

    # print("Bus branches:")
    # println(bus_branches)

    v_dc = getvariable(pm.model, :v_dc)
    # println()
    # println("v_dc: $v_dc")

    dc_expr = pm.model.ext[:dc_expr]

    gs = dcbus["g_gnd"]
    # println()
    # println("bus: $i branches: $gmd_bus_arcs")

    #@printf "bus %d: gs = %0.3f, %d branches:\n" i gs length(gmd_bus_arcs)
    for arc in gmd_bus_arcs
        k = arc[1]
        branch = pm.ref[:gmd_branch][k]

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
        return Set([c])
    end

    # println("solo bus, skipping")
    # println("done")
end


function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, branch)
    i = branch["index"]
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]

    vf = getvariable(pm.model, :v_dc)[f_bus] # from dc voltage
    vt = getvariable(pm.model, :v_dc)[t_bus] # to dc voltage
    dc = getvariable(pm.model, :dc)[(i,f_bus,t_bus)]

    bus1 = pm.ref[:gmd_bus][f_bus]
    bus2 = pm.ref[:gmd_bus][t_bus]

    dkm = branch["len_km"]

    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    #@printf "branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, gs = %0.3f\n" i f_bus t_bus dkm vs gs

    c = @constraint(pm.model, dc == gs*(vf + vs - vt))
    return Set([c])
end

function constraint_qloss{T}(pm::GenericPowerModel{T}, branch)
    k = branch["index"]

    i = branch["hi_bus"]
    j = branch["lo_bus"]

    bus = pm.ref[:bus][i]

    i_dc_mag = getvariable(pm.model, :i_dc_mag)
    qloss = getvariable(pm.model, :qloss)
        
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

    return Set([c])
end



################### Outputs ###################
function add_bus_dc_voltage_setpoint{T}(sol, pm::GenericPowerModel{T})
    # dc voltage is measured line-neutral not line-line, so divide by sqrt(3)
    # fields are: solution, power model, dict name, index name, param name, variable symbol
    PMs.add_setpoint(sol, pm, "gmd_bus", "index", "gmd_vdc", :v_dc)
end

function add_bus_dc_current_mag_setpoint{T}(sol, pm::GenericPowerModel{T})
    # PMs.add_setpoint(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    PMs.add_setpoint(sol, pm, "branch", "index", "gmd_idc_mag", :i_dc_mag)
end

function current_pu_to_si(x,item,pm)
    mva_base = pm.data["baseMVA"]
    kv_base = pm.data["bus"]["1"]["base_kv"]
    return x*1e3*mva_base/(sqrt(3)*kv_base)
end

function add_branch_dc_flow_setpoint{T}(sol, pm::GenericPowerModel{T})
    # check the line flows were requested
    # mva_base = pm.data["baseMVA"]

    if haskey(pm.setting, "output") && haskey(pm.setting["output"], "line_flows") && pm.setting["output"]["line_flows"] == true
        PMs.add_setpoint(sol, pm, "gmd_branch", "index", "gmd_idc", :dc; extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])])
        # PMs.add_setpoint(sol, pm, "branch", "index", "gmd_idc", :dc; extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])])
    end
end

# need to scale by base MVA
function add_bus_qloss_setpoint{T}(sol, pm::GenericPowerModel{T})
    mva_base = pm.data["baseMVA"]
    # mva_base = 1.0
    PMs.add_setpoint(sol, pm, "branch", "index", "gmd_qloss", :qloss; extract_var = (var,idx,item) -> var[(idx, item["hi_bus"], item["lo_bus"])], scale = (x,item) -> x*mva_base)
end
