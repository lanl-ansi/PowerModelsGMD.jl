# Formulations of GMD Problems
export run_gmd

# Maximum loadability with generator participation fixed
function run_gmd(file, model_constructor, solver; kwargs...)
    return PMs.run_generic_model(file, model_constructor, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...) 
end

function post_gmd{T}(pm::GenericPowerModel{T})
    PMs.variable_complex_voltage(pm)

    variable_dc_voltage(pm)

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
    end

    for (i,branch) in pm.set.branches
        PMs.constraint_active_ohms_yt(pm, branch)
        PMs.constraint_reactive_ohms_yt(pm, branch)
        constraint_dc_ohms(pm, branch)

        PMs.constraint_phase_angle_difference(pm, branch)

        PMs.constraint_thermal_limit_from(pm, branch)
        PMs.constraint_thermal_limit_to(pm, branch)
    end
end


function get_gmd_solution{T}(pm::GenericPowerModel{T})
    sol = Dict{AbstractString,Any}()
    PMs.add_bus_voltage_setpoint(sol, pm)
    PMs.add_bus_demand_setpoint(sol, pm)
    PMs.add_generator_power_setpoint(sol, pm)
    PMs.add_branch_flow_setpoint(sol, pm)
    return sol
end


#function add_bus_demand_setpoint{T}(sol, pm::GenericPowerModel{T})
#    mva_base = pm.data["baseMVA"]
#    add_setpoint(sol, pm, "bus", "bus_i", "pd", :pd; default_value = (item) -> item["pd"]*mva_base, scale = (x,item) -> x*mva_base, extract_var = (var,idx,item) -> ())
#    add_setpoint(sol, pm, "bus", "bus_i", "qd", :qd; default_value = (item) -> item["qd"]*mva_base, scale = (x,item) -> x*mva_base, extract_var = (var,idx,item) -> ())
#end


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

function constraint_dc_kcl_shunt{T}(pm::GenericPowerModel{T}, bus)
    i = bus["index"]
    bus_branches = pm.set.bus_branches[i]
    bus_gens = pm.set.bus_gens[i]

    v_dc = getvariable(pm.model, :v_dc)
    dc_expr = pm.model.ext[:dc_expr]


    a = 1.0 # bus["a"]

    c = @constraint(pm.model, sum{dc_expr[a], a in bus_branches} == a*v_dc[i])
    return Set([c])
end

function constraint_dc_ohms{T}(pm::GenericPowerModel{T}, branch)
    i = branch["index"]
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    v_dc_fr = getvariable(pm.model, :v_dc)[f_bus]
    v_dc_to = getvariable(pm.model, :v_dc)[t_bus]
    dc = getvariable(pm.model, :dc)[f_idx]

    a = 1.0 # branch["a"]
    j = 0.5 # branch["j"]

    c = @constraint(pm.model, dc == a * (v_dc_fr - v_dc_to) + j )
    return Set([c])
end

