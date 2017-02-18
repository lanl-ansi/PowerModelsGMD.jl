# Formulations of GMD Problems
export run_gmd

function setup_gmd(data)
    data["gmd_bus_indexes"] = []
    data["gmd_bus_branches"] = []

    gmd_bus_branches = Dict()

    for i in 1:length(data["gmd_bus"])
      b = data["gmd_bus"][i]
      push!(data["gmd_bus_indexes"],i)
      gmd_bus_branches[i] = []
      push!(data["gmd_bus_branches"],nothing)
    end

    # add line sets & xf sets to data
    data["gmd_branch_indexes"] = []
    data["gmd_arcs"] = []
    data["gmd_arcs_from"] = []
    data["gmd_arcs_to"] = []

    for k in 1:length(data["gmd_branch"])
    b = data["gmd_branch"][k]
    nf = b["f_bus"]
    nt = b["t_bus"]

    push!(data["gmd_branch_indexes"],k)
    push!(data["gmd_arcs"],(k,nf,nt,))
    push!(data["gmd_arcs"],(k,nt,nf,))
    push!(data["gmd_arcs_from"],(k,nf,nt,))
    push!(data["gmd_arcs_to"],(k,nt,nf))
    end

    for (l,i,j) in data["gmd_arcs_from"]
      push!(gmd_bus_branches[i], (l,i,j))
      push!(gmd_bus_branches[j], (l,j,i))
    end 


    # convert list of attached branches to list from dict
    for (k,b) in gmd_bus_branches
      data["gmd_bus_branches"][k] = b
    end

    return data
end

function merge_result(data,result)
    sol = result["solution"]

    # merge the result
    for k in 1:length(sol["gen"])
        data["gen"][k]["pg"] = sol["gen"][k]["pg"]
        data["gen"][k]["qg"] = sol["gen"][k]["qg"]
    end


    if "do_gmd" in keys(data) && data["do_gmd"]
    # need to merge this into the regular branches
        for k in 1:length(sol["gmd_branch"])
            data["gmd_branch"][k]["gmd_idc"] = sol["gmd_branch"][k]["gmd_idc"]
        end

        # need to merge this into the regular branches
        for k in 1:length(sol["gmd_bus"])
            data["gmd_bus"][k]["gmd_vdc"] = sol["gmd_bus"][k]["gmd_vdc"]
        end
    end


    for k in 1:length(sol["bus"])
        i = data["bus"][k]["index"] 
        data["bus"][k]["va"] = sol["bus"][i]["va"]
        data["bus"][k]["vm"] = sol["bus"][i]["vm"]

        if "do_gmd" in keys(data) && data["do_gmd"]
            i = data["bus"][k]["gmd_bus"]
            data["bus"][k]["gmd_vdc"] = data["gmd_bus"][i]["gmd_vdc"] 
        end
    end

    if "do_gmd" in keys(data) && data["do_gmd"]
        for k in 1:length(data["sub"])
            i = data["sub"][k]["gmd_bus"]
            data["sub"][k]["gmd_vdc"] = sol["gmd_bus"][i]["gmd_vdc"]
        end
    end

    for k in 1:length(sol["branch"])
        br = data["branch"][k]

        br["p_from"] = sol["branch"][k]["p_from"]
        br["p_to"] = sol["branch"][k]["p_to"]
        br["q_from"] = sol["branch"][k]["q_from"] + sol["branch"][k]["gmd_qloss"]
        br["q_to"] = sol["branch"][k]["q_to"]
        br["ieff"] = sol["branch"][k]["gmd_idc_mag"]
        br["qloss_from"] = sol["branch"][k]["gmd_qloss"]


        if "do_gmd" in keys(data) && data["do_gmd"] && br["type"] == "line"
            i = br["gmd_br"]
            br["gmd_idc"] = data["gmd_branch"][i]["gmd_idc"]
        end
    end

    return data
end

function clear_indexes!(data)
    delete!(data,"gmd_bus_indexes")
    delete!(data,"gmd_bus_branches")
    delete!(data,"gmd_arcs")
    delete!(data,"gmd_arcs_from")
    delete!(data,"gmd_arcs_to")
    delete!(data,"gmd_branch_indexes")

    return data
end

# Maximum loadability with generator participation fixed
function run_gmd(file, model_constructor, solver; kwargs...)
    return PMs.run_generic_model(file, model_constructor, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...) 
end

function post_gmd{T}(pm::GenericPowerModel{T})
    #println("Power Model GMD data")
    #println("----------------------------------")
    PMs.variable_complex_voltage(pm)

    if "do_gmd" in keys(pm.data) && pm.data["do_gmd"]
        variable_dc_voltage(pm)
    end

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_active_generation(pm) 
    PMs.variable_reactive_generation(pm) 

    PMs.variable_active_line_flow(pm) 
    PMs.variable_reactive_line_flow(pm) 

    if "do_gmd" in keys(pm.data) && pm.data["do_gmd"]
        variable_dc_line_flow(pm)
    end

    PMs.constraint_theta_ref(pm) 
    PMs.constraint_complex_voltage(pm) 

    PMs.objective_min_fuel_cost(pm) 
    #objective_gmd_min_fuel(pm)

    for (i,bus) in pm.set.buses
        # turn off linking between dc & ac powerflow
        PMs.constraint_active_kcl_shunt(pm, bus) 
        # PMs.constraint_reactive_kcl_shunt(pm, bus) 
        constraint_qloss_kcl_shunt(pm, bus)        # turn on linking between dc & ac powerflow
    end

    for (k,branch) in pm.set.branches
        constraint_dc_current_mag(pm, branch)
        constraint_qloss(pm, branch)

        PMs.constraint_active_ohms_yt(pm, branch) 
        PMs.constraint_reactive_ohms_yt(pm, branch) 

        PMs.constraint_phase_angle_difference(pm, branch) 

        PMs.constraint_thermal_limit_from(pm, branch)
        PMs.constraint_thermal_limit_to(pm, branch)
    end

    if "do_gmd" in keys(pm.data) && pm.data["do_gmd"]
        println()
        println("Buses")
        println("--------------------")

        ### DC network constraints ###
        for bus in pm.data["gmd_bus"]
            # println("bus:")
            # println(bus)
            constraint_dc_kcl_shunt(pm, bus)
        end

        println()
        println("Branches")
        println("--------------------")

        for branch in pm.data["gmd_branch"]
            constraint_dc_ohms(pm, branch)
        end

        println()
    end
end


function get_gmd_solution{T}(pm::GenericPowerModel{T})
    sol = Dict{AbstractString,Any}()
    PMs.add_bus_voltage_setpoint(sol, pm)
    add_bus_dc_current_mag_setpoint(sol, pm)
    add_bus_qloss_setpoint(sol, pm)
    PMs.add_bus_demand_setpoint(sol, pm)
    PMs.add_generator_power_setpoint(sol, pm)
    PMs.add_branch_flow_setpoint(sol, pm)
    
    if pm.data["do_gmd"]
        add_bus_dc_voltage_setpoint(sol, pm)
        add_branch_dc_flow_setpoint(sol, pm)
    end

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
        @printf "bus [%d] zb: %f a(pu): %f\n" bus["index"] zb bus["gmd_gs"]
        bus["gmd_gs"] *= zb
        # @printf " -> a(pu): %f\n" bus["gmd_gs"]
    end
end


################### Variables ###################
function variable_dc_voltage{T}(pm::GenericPowerModel{T}; bounded = true)
    #gmd_branch_indexes = 1:length(pm.data["gmd_branch"])
    #@variable(pm.model, v_dc[i in gmd_branch_indexes], start = PMs.getstart(pm.data["gmd_branch"], i, "v_dc_start"))
    @variable(pm.model, v_dc[i in pm.data["gmd_bus_indexes"]], start = PMs.getstart(pm.data["gmd_bus"], i, "v_dc_start"))
    return v_dc
end

function variable_dc_current_mag{T}(pm::GenericPowerModel{T}; bounded = true)
    @variable(pm.model, i_dc_mag[i in pm.set.branch_indexes], start = PMs.getstart(pm.set.branches, i, "i_dc_mag_start"))
    return i_dc_mag
end

function variable_dc_line_flow{T}(pm::GenericPowerModel{T}; bounded = true)
    # print("arcs: ")
    # println(pm.set.arcs)
    # print("branches: ")
    # println(pm.set.branches)
    # print("arcs_from: ")
    # println(pm.set.arcs_from)
    #@variable(pm.model, -pm.set.branches[l]["rate_a"] <= dc[(l,i,j) in pm.set.arcs] <= pm.set.branches[l]["rate_a"], start = PMs.getstart(pm.set.branches, l, "dc_start"))
    @variable(pm.model, dc[(l,i,j) in pm.data["gmd_arcs"]], start = PMs.getstart(pm.data["gmd_branch"], l, "dc_start"))

    dc_expr = Dict([((l,i,j), -1.0*dc[(l,i,j)]) for (l,i,j) in pm.data["gmd_arcs_from"]])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*dc[(l,i,j)]) for (l,i,j) in pm.data["gmd_arcs_from"]]))

    pm.model.ext[:dc_expr] = dc_expr

    return dc
end

# define qloss for each branch, it flows into the "to" side of the branch
function variable_qloss{T}(pm::GenericPowerModel{T})
    @variable(pm.model, qloss[(l,i,j) in pm.set.arcs], start = PMs.getstart(pm.set.branches, l, "qloss_start"))

    return qloss
end


################### Objective ###################
# function objective_gmd_min_fuel{T}(pm::GenericPowerModel{T})
#     # @variable(pm.model, pm.set.gens[i]["pmin"]^2 <= pg_sqr[i in pm.set.gen_indexes] <= pm.set.gens[i]["pmax"]^2)

#     pg = getvariable(pm.model, :pg)
#     i_dc_mag = getvariable(pm.model, :i_dc_mag)

#     # for (i, gen) in pm.set.gens
#     #     @constraint(pm.model, norm([2*pg[i], pg_sqr[i]-1]) <= pg_sqr[i]+1)
#     # end

#     cost = (i) -> pm.set.gens[i]["cost"]
#     return @objective(pm.model, Min, sum{ cost(i)[2]*pg[i], i in pm.set.gen_indexes} + sum{ 0.01*i_dc_mag[i], i in pm.set.bus_indexes})
# end

################### Constraints ###################
# correct equation is ieff = |a*ihi + ilo|/a
# just use ihi for now
function constraint_dc_current_mag{T}(pm::GenericPowerModel{T}, branch)

    # print(keys(branch))

    # it's a transformer!
    if  "gmd_br_hi" in keys(branch) || "gmd_br_series" in keys(branch)

        if "gmd_br_hi" in keys(branch)
            kd = branch["gmd_br_hi"]
        elseif "gmd_br_series" in keys(branch)
            kd = branch["gmd_br_series"]
        end

        dc_br = pm.data["gmd_branch"][kd]

        k = branch["index"]
        i = dc_br["f_bus"]
        j = dc_br["t_bus"]

        v_dc = getvariable(pm.model, :v_dc)
        i_dc_mag = getvariable(pm.model, :i_dc_mag)
        dc = getvariable(pm.model, :dc)[(kd,i,j)]        

        println("branch[$k]: dc_branch[$kd]")

        c = @constraint(pm.model, i_dc_mag[k] >= dc)
        c = @constraint(pm.model, i_dc_mag[k] >= -dc)

        return Set([c])
    else
        # println("Key not found")
    end

    return Set([])
end

function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, dcbus)
    i = dcbus["index"]
    bus_branch_ids = pm.data["gmd_bus_branches"][i]
    # bus_branches = []

    # for k in bus_branch_ids
    #     push!(bus_branches,pm.data["gmd_branch"][k])
    # end
    
    # print("Bus branches:")
    # println(bus_branches)

    v_dc = getvariable(pm.model, :v_dc)
    # println()
    # println("v_dc: $v_dc")

    dc_expr = pm.model.ext[:dc_expr]

    gs = dcbus["g_gnd"]
    # println()
    # println("bus: $i branches: $bus_branch_ids")

    @printf "bus %d: gs = %0.3f, %d branches:\n" i gs length(bus_branch_ids)
    for arc in bus_branch_ids
        k = arc[1]
        branch = pm.data["gmd_branch"][k]

        f_bus = branch["f_bus"]
        t_bus = branch["t_bus"]        
        dkm = branch["len_km"]
        vs = branch["br_v"]       # line dc series voltage
        rdc = branch["br_r"]
        @printf "    branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, rdc = %0.3f\n" k f_bus t_bus dkm vs rdc
    end

    if length(bus_branch_ids) > 0
        c = @constraint(pm.model, sum{dc_expr[a], a in bus_branch_ids} == gs*v_dc[i])
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

    bus1 = pm.data["gmd_bus"][f_bus]
    bus2 = pm.data["gmd_bus"][t_bus]

    dkm = branch["len_km"]

    vs = branch["br_v"]       # line dc series voltage

    if branch["br_r"] === nothing
        gs = 0.0
    else
        gs = 1.0/branch["br_r"]   # line dc series resistance
    end

    @printf "branch %d: (%d,%d): d (mi) = %0.3f, vs = %0.3f, gs = %0.3f\n" i f_bus t_bus dkm vs gs

    c = @constraint(pm.model, dc == gs*(vf + vs - vt))
    return Set([c])
end

function constraint_qloss{T}(pm::GenericPowerModel{T}, branch)
    k = branch["index"]
    i = branch["f_bus"]
    j = branch["t_bus"]
    bus = pm.set.buses[i]

    i_dc_mag = getvariable(pm.model, :i_dc_mag)
    qloss = getvariable(pm.model, :qloss)
        
    if "gmd_k" in keys(branch)

        # a = bus["gmd_gs"]

        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*pm.data["baseMVA"]/ibase

        # println("bus[$i]: a = $a, K = $K")

          
        @printf "k = %d, Kold = %f, ib = %f, Knew = %f\n" k branch["gmd_k"] ibase K 
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

function constraint_qloss_kcl_shunt{T}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    v = getvariable(pm.model, :v)
    q = getvariable(pm.model, :q)
    qg = getvariable(pm.model, :qg)
    qloss = getvariable(pm.model, :qloss)

    c = @constraint(pm.model, sum{q[a] + qloss[a], a in bus_branches} == sum{qg[g], g in bus_gens} - bus["qd"] + bus["bs"]*v[i]^2)
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
    kv_base = pm.data["bus"][1]["base_kv"]
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
    PMs.add_setpoint(sol, pm, "branch", "index", "gmd_qloss", :qloss; extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])], scale = (x,item) -> x*mva_base)
end
