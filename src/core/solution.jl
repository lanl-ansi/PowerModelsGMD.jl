# --- Solutions --- #


"SOLUTION: get gmd solution"
function get_gmd_solution(pm::PMs.AbstractPowerModel, sol::Dict{String,Any})

    PMs.add_setpoint_bus_voltage!(sol, pm)
    PMs.add_setpoint_generator_power!(sol, pm)
    PMs.add_setpoint_branch_flow!(sol, pm)
    PMs.add_setpoint_branch_status!(sol, pm)

    add_setpoint_load_demand!(sol, pm)
    add_setpoint_bus_dc_voltage!(sol, pm)
    add_setpoint_bus_dc_current_mag!(sol, pm)
    add_setpoint_load_shed!(sol, pm)
    add_setpoint_branch_dc_flow!(sol, pm)
    add_setpoint_bus_qloss!(sol, pm)

end


"SOLUTION: get gmd decoupled solution"
function get_gmd_decoupled_solution(pm::PMs.AbstractPowerModel, sol::Dict{String,Any})

    PMs.add_setpoint_bus_voltage!(sol, pm)
    PMs.add_setpoint_generator_power!(sol, pm)
    PMs.add_setpoint_branch_flow!(sol, pm)

    add_setpoint_bus_qloss!(sol, pm)

end


"SOLUTION: get gmd ts solution"
function get_gmd_ts_solution(pm::PMs.AbstractPowerModel, sol::Dict{String,Any})

    PMs.add_setpoint_bus_voltage!(sol, pm)
    PMs.add_setpoint_generator_power!(sol, pm)
    PMs.add_setpoint_branch_flow!(sol, pm)

    add_setpoint_load_demand!(sol, pm)
    add_setpoint_bus_dc_voltage!(sol, pm)
    add_setpoint_bus_dc_current_mag!(sol, pm)
    add_setpoint_load_shed!(sol, pm)
    add_setpoint_branch_dc_flow!(sol, pm)
    add_setpoint_bus_qloss!(sol, pm)

    add_setpoint_top_oil_rise_steady_state!(sol, pm)
    add_setpoint_top_oil_rise!(sol, pm)
    add_setpoint_hotspot_rise_steady_state!(sol, pm)
    add_setpoint_hotspot_rise!(sol, pm)
    add_setpoint_hotspot_temperature!(sol, pm)

end



# --- Add Setpoints --- #


"SETPOINT: add setpoint load demand"
function add_setpoint_load_demand!(sol, pm::PMs.AbstractPowerModel)
    mva_base = pm.data["baseMVA"]
    PMs.add_setpoint!(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
    PMs.add_setpoint!(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
end


"SETPOINT: add setpoint bus dc voltage"
function add_setpoint_bus_dc_voltage!(sol, pm::PMs.AbstractPowerModel)
    # dc voltage is measured line-neutral not line-line, so divide by sqrt(3)
    # fields are: solution, power model, dict name, index name, param name, variable symbol
    # add_setpoint!(sol, pm, "bus", "vm", :vm, status_name="bus_type", inactive_status_value = 4)
    PMs.add_setpoint!(sol, pm, "gmd_bus", "gmd_vdc", :v_dc, status_name="status", inactive_status_value=0)
end


"SETPOINT: add setpoint bus dc current mag"
function add_setpoint_bus_dc_current_mag!(sol, pm::PMs.AbstractPowerModel)
    # PMs.add_setpoint!(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    PMs.add_setpoint!(sol, pm, "branch", "gmd_idc_mag", :i_dc_mag, status_name="br_status", inactive_status_value=0)
end


"SETPOINT: add setpoint load shed"
function add_setpoint_load_shed!(sol, pm::PMs.AbstractPowerModel)
    PMs.add_setpoint!(sol, pm, "load", "demand_served_ratio", :z_demand)
end


"SETPOINT: add setpoint branch dc flow"
function add_setpoint_branch_dc_flow!(sol, pm::PMs.AbstractPowerModel)
    #if haskey(pm.setting, "output") && haskey(pm.setting["output"], "line_flows") && pm.setting["output"]["line_flows"] == true
    PMs.add_setpoint!(sol, pm, "gmd_branch", "gmd_idc", :dc, status_name="br_status", inactive_status_value=0, var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
    #end
end


"SETPOINT: add setpoint bus qloss"
function add_setpoint_bus_qloss!(sol, pm::PMs.AbstractPowerModel)
    # need to scale by base MVA
    mva_base = pm.data["baseMVA"]
    # mva_base = 1.0
    PMs.add_setpoint!(sol, pm, "branch", "gmd_qloss", :qloss, status_name="br_status", var_key = (idx,item) -> (idx, item["hi_bus"], item["lo_bus"]), scale = (x,item,i) -> x*mva_base)
end


"SETPOINT: current pu to si"
function current_pu_to_si(x,item,pm)
    mva_base = pm.data["baseMVA"]
    kv_base = pm.data["bus"]["1"]["base_kv"]
    return x*1e3*mva_base/(sqrt(3)*kv_base)
end


"SETPOINT: add setpoint steady-state top-oil temperature rise"
function add_setpoint_top_oil_rise_steady_state!(sol, pm::PMs.AbstractPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "topoil_rise_ss", :ross, status_name="br_status")
end


"SETPOINT: add setpoint top-oil temperature rise"
function add_setpoint_top_oil_rise!(sol, pm::PMs.AbstractPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "topoil_rise", :ro, status_name="br_status")
end


"SETPOINT: add setpoint steady-state hot-spot temperature rise"
function add_setpoint_hotspot_rise_steady_state!(sol, pm::PMs.AbstractPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "hotspot_rise_ss", :hsss, status_name="br_status")
end


"SETPOINT: add setpoint hot-spot temperature rise"
function add_setpoint_hotspot_rise!(sol, pm::PMs.AbstractPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "hotspot_rise", :hs, status_name="br_status")
end


"SETPOINT: add setpoint hot-spot temperature"
function add_setpoint_hotspot_temperature!(sol, pm::PMs.AbstractPowerModel)
    PMs.add_setpoint!(sol, pm, "branch", "hotspot", :hsa, status_name="br_status")
end


