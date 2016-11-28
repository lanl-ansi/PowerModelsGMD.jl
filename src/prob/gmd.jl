# Formulations of GMD Problems
export run_gmd

# Maximum loadability with generator participation fixed
function run_gmd(file, model_constructor, solver; kwargs...)
    return PMs.run_generic_model(file, model_constructor, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...) 
end

function post_gmd{T}(pm::GenericPowerModel{T})
    println("Power Model GMD data")
    println("----------------------------------")
    m = pm.data["gmd_e_field_mag"]
    a = pm.data["gmd_e_field_dir"]
    ad = a*180.0/pi
    println("GMD magnitude: $m V/km, GMD angle: $ad degrees from East")

    E = m*[cos(a) sin(a)]
    print("GMD vector: ")
    println(E)

    println("arcs:")
    println(pm.set.arcs_from)

    PMs.variable_complex_voltage(pm)

    variable_dc_voltage(pm)
    variable_qloss(pm)

    PMs.variable_active_generation(pm)
    PMs.variable_reactive_generation(pm)

    PMs.variable_active_line_flow(pm)
    PMs.variable_reactive_line_flow(pm)
    variable_dc_line_flow(pm)

    PMs.constraint_theta_ref(pm)
    PMs.constraint_complex_voltage(pm)

    PMs.objective_min_fuel_cost(pm)

    for (i,bus) in pm.set.buses
        PMs.constraint_active_kcl_shunt(pm, bus)
        PMs.constraint_reactive_kcl_shunt(pm, bus)

        constraint_dc_kcl_shunt(pm, bus)
        constraint_qloss(pm, bus)
        #constraint_qloss_kcl_shunt(pm, bus)
    end

    for (k,branch) in pm.set.branches
        PMs.constraint_active_ohms_yt(pm, branch)
        PMs.constraint_reactive_ohms_yt(pm, branch)
        constraint_dc_ohms(pm, branch, E)

        PMs.constraint_phase_angle_difference(pm, branch)

        PMs.constraint_thermal_limit_from(pm, branch)
        PMs.constraint_thermal_limit_to(pm, branch)
    end
end


function get_gmd_solution{T}(pm::GenericPowerModel{T})
    sol = Dict{AbstractString,Any}()
    PMs.add_bus_voltage_setpoint(sol, pm)
    add_bus_dc_voltage_setpoint(sol, pm)
    add_bus_qloss_setpoint(sol, pm)
    PMs.add_bus_demand_setpoint(sol, pm)
    PMs.add_generator_power_setpoint(sol, pm)
    PMs.add_branch_flow_setpoint(sol, pm)
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
    vb = 1e3*data["bus"][1]["base_kv"] # not sure h
    data["gmd_e_field_mag"] /= vb
    data["gmd_e_field_dir"] *= pi/180.0

    for bus in data["bus"]
        zb = bus["base_kv"]^2/mva_base
        @printf "bus [%d] zb: %f a(si): %f" bus["index"] zb bus["gmd_gs"]
        bus["gmd_gs"] *= zb
        @printf " -> a(pu): %f\n" bus["gmd_gs"]
    end
end


################### Variables ###################
function variable_dc_voltage{T}(pm::GenericPowerModel{T}; bounded = true)
    @variable(pm.model, v_dc[i in pm.set.bus_indexes], start = PMs.getstart(pm.set.buses, i, "v_dc_start", 1.0))
    return v_dc
end

function variable_dc_line_flow{T}(pm::GenericPowerModel{T}; bounded = true)
    #@variable(pm.model, -pm.set.branches[l]["rate_a"] <= dc[(l,i,j) in pm.set.arcs] <= pm.set.branches[l]["rate_a"], start = PMs.getstart(pm.set.branches, l, "dc_start"))
    @variable(pm.model, dc[(l,i,j) in pm.set.arcs], start = PMs.getstart(pm.set.branches, l, "dc_start"))

    dc_expr = Dict([((l,i,j), 1.0*dc[(l,i,j)]) for (l,i,j) in pm.set.arcs_from])
    dc_expr = merge(dc_expr, Dict([((l,j,i), -1.0*dc[(l,i,j)]) for (l,i,j) in pm.set.arcs_from]))

    pm.model.ext[:dc_expr] = dc_expr

    return dc
end

function variable_qloss{T}(pm::GenericPowerModel{T})
  @variable(pm.model, qloss[i in pm.set.bus_indexes], start = PMs.getstart(pm.set.buses, i, "qloss_start"))
  return qloss
end


################### Constraints ###################
function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    
    print("Bus branches:")
    println(bus_branches)

    bus_gens = pm.set.bus_gens[i]

    v_dc = getvariable(pm.model, :v_dc)
    dc_expr = pm.model.ext[:dc_expr]


    a = bus["gmd_gs"]
    println("Adding dc shunt $a to bus $i")

    c = @constraint(pm.model, sum{dc_expr[a], a in bus_branches} == a*v_dc[i])
    return Set([c])
end

function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, branch, E)
    i = branch["index"]
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    v_dc_fr = getvariable(pm.model, :v_dc)[f_bus]
    v_dc_to = getvariable(pm.model, :v_dc)[t_bus]
    dc = getvariable(pm.model, :dc)[f_idx]

    bus1 = pm.data["bus"][f_bus]
    bus2 = pm.data["bus"][t_bus]

    # get the direction vector
    d = [bus2["x"] bus2["y"]] - [bus1["x"] bus1["y"]]
    v = dot(E,d)
    
    a = 1.0/branch["br_r"]
    j = a*v
    println("branch $i: ($f_bus,$t_bus) v = $v, j = $j, a = $a")
    # j = v

    # j = branch["gmd_dc_i"]

    c = @constraint(pm.model, dc == a * (v_dc_fr - v_dc_to) + j )
    return Set([c])
end

function constraint_qloss{T}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    v_dc = getvariable(pm.model, :v_dc)
    qloss = getvariable(pm.model, :qloss)
    a = bus["gmd_gs"]
    K = bus["gmd_k"]

    c = @constraint(pm.model, qloss[i] == K*a*v_dc[i]^2)
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

    c = @constraint(pm.model, sum{q[a], a in bus_branches} == sum{qg[g], g in bus_gens} - bus["qd"] - qloss[i] + bus["bs"]*v[i]^2)
    return Set([c])
end

################### Outputs ###################
function add_bus_dc_voltage_setpoint{T}(sol, pm::GenericPowerModel{T})
    PMs.add_setpoint(sol, pm, "bus", "bus_i", "gmd_vdc", :v_dc)
end

function current_pu_to_si(x,item,pm)
    mva_base = pm.data["baseMVA"]
    kv_base = item["base_kv"]
    i_base = 1e3*mva_base/kv_base 

    return x*i_base
end

function add_branch_dc_flow_setpoint{T}(sol, pm::GenericPowerModel{T})
    # check the line flows were requested
    if haskey(pm.setting, "output") && haskey(pm.setting["output"], "line_flows") && pm.setting["output"]["line_flows"] == true
        PMs.add_setpoint(sol, pm, "branch", "index", "gmd_idc", :dc; scale = (x,item) -> current_pu_to_si(x,item,pm), extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])])
    end
end

# need to scale by base MVA
function add_bus_qloss_setpoint{T}(sol, pm::GenericPowerModel{T})
    mva_base = pm.data["baseMVA"]
    PMs.add_setpoint(sol, pm, "bus", "bus_i", "gmd_qloss", :qloss; scale = (x,item) -> x*mva_base)
end