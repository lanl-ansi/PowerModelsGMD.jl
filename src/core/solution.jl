
""
function get_gmd_solution(pm::PMs.GenericPowerModel, sol::Dict{String,Any})
    PMs.add_setpoint_bus_voltage!(sol, pm);
    PMs.add_setpoint_generator_power!(sol, pm)
    PMs.add_setpoint_branch_flow!(sol, pm)

    add_bus_dc_current_mag_setpoint(sol, pm)
    add_bus_qloss_setpoint(sol, pm)
    add_load_shed_setpoint(sol, pm)
    add_load_demand_setpoint(sol, pm)
    add_bus_dc_voltage_setpoint(sol, pm)
    add_branch_dc_flow_setpoint(sol, pm)
end

""
function get_gmd_decoupled_solution(pm::PMs.GenericPowerModel, sol::Dict{String,Any})
    PMs.add_setpoint_bus_voltage!(sol, pm);
    PMs.add_setpoint_generator_power!(sol, pm)
    PMs.add_setpoint_branch_flow!(sol, pm)
    PowerModelsGMD.add_bus_qloss_setpoint(sol, pm)
end


""

function add_load_demand_setpoint(sol, pm::PMs.GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    PMs.add_setpoint!(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
    PMs.add_setpoint!(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
end

""
function add_bus_dc_voltage_setpoint(sol, pm::PMs.GenericPowerModel)
    # dc voltage is measured line-neutral not line-line, so divide by sqrt(3)
    # fields are: solution, power model, dict name, index name, param name, variable symbol
    # add_setpoint!(sol, pm, "bus", "vm", :vm, status_name="bus_type", inactive_status_value = 4)
    PMs.add_setpoint!(sol, pm, "gmd_bus", "gmd_vdc", :v_dc, status_name="status", inactive_status_value=0)
end

""
function add_bus_dc_current_mag_setpoint(sol, pm::PMs.GenericPowerModel)
    # PMs.add_setpoint!(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    PMs.add_setpoint!(sol, pm, "branch", "gmd_idc_mag", :i_dc_mag, status_name="br_status", inactive_status_value=0)
end

""
function add_load_shed_setpoint(sol, pm::PMs.GenericPowerModel)
    PMs.add_setpoint!(sol, pm, "load", "demand_served_ratio", :z_demand)
end

""
function current_pu_to_si(x,item,pm)
    mva_base = pm.data["baseMVA"]
    kv_base = pm.data["bus"]["1"]["base_kv"]
    return x*1e3*mva_base/(sqrt(3)*kv_base)
end

# function add_setpoint_branch_flow!(sol, pm::GenericPowerModel)
#     # check the branch flows were requested
#     if haskey(pm.setting, "output") && haskey(pm.setting["output"], "branch_flows") && pm.setting["output"]["branch_flows"] == true
#         add_setpoint!(sol, pm, "branch", "pf", :p, status_name="br_status", var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
#         add_setpoint!(sol, pm, "branch", "qf", :q, status_name="br_status", var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
#         add_setpoint!(sol, pm, "branch", "pt", :p, status_name="br_status", var_key = (idx,item) -> (idx, item["t_bus"], item["f_bus"]))
#         add_setpoint!(sol, pm, "branch", "qt", :q, status_name="br_status", var_key = (idx,item) -> (idx, item["t_bus"], item["f_bus"]))
#     end
# end


""
function add_branch_dc_flow_setpoint(sol, pm::PMs.GenericPowerModel)
    if haskey(pm.setting, "output") && haskey(pm.setting["output"], "line_flows") && pm.setting["output"]["line_flows"] == true
        PMs.add_setpoint!(sol, pm, "gmd_branch", "gmd_idc", :dc, status_name="br_status", var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
    end
end

# need to scale by base MVA
function add_bus_qloss_setpoint(sol, pm::PMs.GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    # mva_base = 1.0
    PMs.add_setpoint!(sol, pm, "branch", "gmd_qloss", :qloss, status_name="br_status", var_key = (idx,item) -> (idx, item["hi_bus"], item["lo_bus"]))
end

