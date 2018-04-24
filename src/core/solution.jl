
""
function get_gmd_solution{T}(pm::GenericPowerModel{T}, sol::Dict{String,Any})
    PMs.add_bus_voltage_setpoint(sol, pm);
    PMs.add_generator_power_setpoint(sol, pm)
    PMs.add_branch_flow_setpoint(sol, pm)
      
    add_bus_dc_current_mag_setpoint(sol, pm)
    add_bus_qloss_setpoint(sol, pm)
    add_load_shed_setpoint(sol, pm)
    add_load_demand_setpoint(sol, pm)
    add_bus_dc_voltage_setpoint(sol, pm)
    add_branch_dc_flow_setpoint(sol, pm)
end

""
function add_load_demand_setpoint(sol, pm::GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    PMs.add_setpoint(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
    PMs.add_setpoint(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
end

""
function add_bus_dc_voltage_setpoint(sol, pm::GenericPowerModel)
    # dc voltage is measured line-neutral not line-line, so divide by sqrt(3)
    # fields are: solution, power model, dict name, index name, param name, variable symbol
    PMs.add_setpoint(sol, pm, "gmd_bus", "gmd_vdc", :v_dc)
end

""
function add_bus_dc_current_mag_setpoint(sol, pm::GenericPowerModel)
    # PMs.add_setpoint(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    PMs.add_setpoint(sol, pm, "branch", "gmd_idc_mag", :i_dc_mag)
end

""
function add_load_shed_setpoint(sol, pm::GenericPowerModel)
    PMs.add_setpoint(sol, pm, "load", "demand_served_ratio", :z_demand)
end

""
function current_pu_to_si(x,item,pm)
    mva_base = pm.data["baseMVA"]
    kv_base = pm.data["bus"]["1"]["base_kv"]
    return x*1e3*mva_base/(sqrt(3)*kv_base)
end

""
function add_branch_dc_flow_setpoint(sol, pm::GenericPowerModel)
    # check the line flows were requested
    # mva_base = pm.data["baseMVA"]

   # if haskey(pm.setting, "output") && haskey(pm.setting["output"], "line_flows") && pm.setting["output"]["line_flows"] == true
        PMs.add_setpoint(sol, pm, "gmd_branch", "gmd_idc", :dc; extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])])
   # end
end

# need to scale by base MVA
function add_bus_qloss_setpoint(sol, pm::GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    # mva_base = 1.0
    PMs.add_setpoint(sol, pm, "branch", "gmd_qloss", :qloss; extract_var = (var,idx,item) -> var[(idx, item["hi_bus"], item["lo_bus"])], scale = (x,item) -> x*mva_base)
end
