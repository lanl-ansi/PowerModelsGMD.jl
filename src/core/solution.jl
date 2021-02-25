
# "SOLUTION: get gmd solution"
# function sol_gmd!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm)
#     _PM.add_setpoint_generator_power!(sol, pm)
#     _PM.add_setpoint_branch_flow!(sol, pm)
#     _PM.add_setpoint_branch_status!(sol, pm)

#     add_setpoint_load_demand!(sol, pm)
#     add_setpoint_bus_dc_voltage!(sol, pm)
#     add_setpoint_bus_dc_current_mag!(sol, pm)
#     add_setpoint_load_shed!(sol, pm)
#     add_setpoint_branch_dc_flow!(sol, pm)
#     add_setpoint_bus_qloss!(sol, pm)

# end


"SOLUTION: add PowerModels.jl solutions"
function solution_PM!(pm::_PM.AbstractPowerModel, solution::Dict{String,<:Any})

    if haskey(solution, "nw")
        nws_data = solution["nw"]
    else
        nws_data = Dict("0" => solution)
    end

    # Bus
    solution["bus"] = pm.data["bus"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "bus")
            for (i, bus) in nw_data["bus"]

                remove = ["zone", "bus_type", "vmax", "area", "vmin", "bus_sid", "base_kv"]
                for i in remove
                    delete!(bus, i)
                end

                #figure out how to get the 'vm' and 'va' values updated to JumP results from PowerModels 
                #[???] ... bus["vm"] = pm.var[:vm]

                #add_setpoint!(sol, pm, "bus", "vm", :vm)
                bus["vm"] = 0 #FIX
                #add_setpoint!(sol, pm, "bus", "va", :va)
                bus["va"] = 0 #FIX
                
            end
        end
    end

    # Branch
    solution["branch"] = pm.data["branch"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "branch")
            for (i, branch) in nw_data["branch"]
                
                remove = ["br_r", "gmd_br_series", "rate_a", "hotspot_coeff", "shift", "gmd_k", "tbus", "br_x", "topoil_init", "g_to", "hotspot_instant_limit", "topoil_rated",  "fbus", "g_fr", "b_fr", "gmd_br_hi", "baseMVA", "topoil_initialized", "topoil_time_const", "b_to", "gmd_br_common", "angmin", "temperature_ambient", "angmax", "hotspot_avg_limit", "hotspot_rated", "branch_sid", "gmd_br_lo", "tap", "transformer"]
                for i in remove
                    delete!(branch, i)
                end

                #add_setpoint!(sol, pm, "branch", "br_status", :br_status)
                branch["br_status"] = 1 #FIX

                #if haskey(pm.setting, "output") && haskey(pm.setting["output"], "branch_flows") && pm.setting["output"]["branch_flows"] == true
                #add_setpoint!(sol, pm, "branch", "pf", :p; extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])])	
                branch["pf"] = 0 #FIX
                #add_setpoint!(sol, pm, "branch", "qf", :q; extract_var = (var,idx,item) -> var[(idx, item["f_bus"], item["t_bus"])])	
                branch["qf"] = 0 #FIX
                #add_setpoint!(sol, pm, "branch", "pt", :p; extract_var = (var,idx,item) -> var[(idx, item["t_bus"], item["f_bus"])])	
                branch["pt"] = 0 #FIX
                #add_setpoint!(sol, pm, "branch", "qt", :q; extract_var = (var,idx,item) -> var[(idx, item["t_bus"], item["f_bus"])])	
                branch["qt"] = 0 #FIX

            end
        end
    end

    # Gen
    solution["gen"] = pm.data["gen"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "gen")
            for (i, gen) in nw_data["gen"]

                remove = ["ncost",  "qc1max", "model", "shutdown", "startup", "gen_sid", "qc2max", "ramp_agc", "gen_bus", "pmax", "ramp_10", "vg", "mbase", "pc2", "cost", "qmax", "qmin", "qc1min", "qc2min", "pc1", "ramp_q", "ramp_30", "pmin", "apf"]
                for i in remove
                    delete!(gen, i)
                end    

                #add_setpoint!(sol, pm, "gen", "pg", :pg)
                gen["pg"] = 0 #FIX
                #add_setpoint!(sol, pm, "gen", "qg", :qg)
                gen["qg"] = 0 #FIX

            end
        end
    end
end


"SOLUTION: add GMD solutions"
function solution_gmd!(pm::_PM.AbstractPowerModel, solution::Dict)

    if haskey(solution, "nw")
        nws_data = solution["nw"]
    else
        nws_data = Dict("0" => solution)
    end

    # Bus
    solution["bus"] = pm.data["bus"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "bus")
            for (i, bus) in nw_data["bus"]
                
                 #add_setpoint!(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
                 bus["pd"] = pm.var[:nw][0][:pd]
                 #add_setpoint!(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
                 bus["qd"] = pm.var[:nw][0][:qd]

            end
        end
    end



    # add_setpoint_load_demand!(sol, pm)
    # function add_setpoint_load_demand!(sol, pm::_PM.AbstractPowerModel)
    #     mva_base = pm.data["baseMVA"]
    #     add_setpoint!(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
    #     add_setpoint!(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
    # end


    # add_setpoint_bus_dc_voltage!(sol, pm)
    # "SETPOINT: add bus dc voltage setpoint"
    # function add_setpoint_bus_dc_voltage!(sol, pm::_PM.AbstractPowerModel)
    #     add_setpoint!(sol, pm, "gmd_bus", "gmd_vdc", :v_dc, status_name="status", inactive_status_value=0)
    # end


    # add_setpoint_bus_dc_current_mag!(sol, pm)
    # "SETPOINT: add bus dc current magitude setpoint"
    # function add_setpoint_bus_dc_current_mag!(sol, pm::_PM.AbstractPowerModel)
    #     # add_setpoint!(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    #     add_setpoint!(sol, pm, "branch", "gmd_idc_mag", :i_dc_mag, status_name="br_status", inactive_status_value=0)
    # end


    # add_setpoint_load_shed!(sol, pm)
    # "SETPOINT: add load shed setpoint"
    # function add_setpoint_load_shed!(sol, pm::_PM.AbstractPowerModel)
    #     add_setpoint!(sol, pm, "load", "demand_served_ratio", :z_demand)
    # end


    # add_setpoint_branch_dc_flow!(sol, pm)
    # "SETPOINT: add branch dc flow setpoint"
    # function add_setpoint_branch_dc_flow!(sol, pm::_PM.AbstractPowerModel)
    #     add_setpoint!(sol, pm, "gmd_branch", "gmd_idc", :dc, status_name="br_status", inactive_status_value=0, var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
    # end
    

    # add_setpoint_bus_qloss!(sol, pm)
    # "SETPOINT: add bus qloss setpoint"
    # function add_setpoint_bus_qloss!(sol, pm::_PM.AbstractPowerModel)
    #     mva_base = pm.data["baseMVA"]
    #     add_setpoint!(sol, pm, "branch", "gmd_qloss", :qloss, status_name="br_status", var_key = (idx,item) -> (idx, item["hi_bus"], item["lo_bus"]), scale = (x,item,i) -> x*mva_base)
    # end


end




# "SOLUTION: get gmd decoupled solution"
# function solution_gmd_decoupled!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm)
#     _PM.add_setpoint_generator_power!(sol, pm)
#     _PM.add_setpoint_branch_flow!(sol, pm)

#     add_setpoint_bus_qloss!(sol, pm)

# end


# "SOLUTION: get gmd ts solution"
# function solution_gmd_ts!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm)
#     _PM.add_setpoint_generator_power!(sol, pm)
#     _PM.add_setpoint_branch_flow!(sol, pm)

#     add_setpoint_load_demand!(sol, pm)
#     add_setpoint_bus_dc_voltage!(sol, pm)
#     add_setpoint_bus_dc_current_mag!(sol, pm)
#     add_setpoint_load_shed!(sol, pm)
#     add_setpoint_branch_dc_flow!(sol, pm)
#     add_setpoint_bus_qloss!(sol, pm)

#     add_setpoint_top_oil_rise_steady_state!(sol, pm)
#     add_setpoint_top_oil_rise!(sol, pm)
#     add_setpoint_hotspot_rise_steady_state!(sol, pm)
#     add_setpoint_hotspot_rise!(sol, pm)
#     add_setpoint_hotspot_temperature!(sol, pm)

# end




##### TODO : move these into new format ...


"SETPOINT: add generator status setpoint"
function add_setpoint_generator_status!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "gen", "gen_status", :z_gen; conductorless=true, default_value = (item) -> item["gen_status"]*1.0)
end


"SETPOINT: add load demand setpoint"
function add_setpoint_load_demand!(sol, pm::_PM.AbstractPowerModel)
    mva_base = pm.data["baseMVA"]
    add_setpoint!(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
    add_setpoint!(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
end


"SETPOINT: add bus dc voltage setpoint"
function add_setpoint_bus_dc_voltage!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "gmd_bus", "gmd_vdc", :v_dc, status_name="status", inactive_status_value=0)
end


"SETPOINT: add bus dc current magitude setpoint"
function add_setpoint_bus_dc_current_mag!(sol, pm::_PM.AbstractPowerModel)
    # add_setpoint!(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    add_setpoint!(sol, pm, "branch", "gmd_idc_mag", :i_dc_mag, status_name="br_status", inactive_status_value=0)
end


"SETPOINT: add load shed setpoint"
function add_setpoint_load_shed!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "load", "demand_served_ratio", :z_demand)
end


"SETPOINT: add branch dc flow setpoint"
function add_setpoint_branch_dc_flow!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "gmd_branch", "gmd_idc", :dc, status_name="br_status", inactive_status_value=0, var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
end


"SETPOINT: add bus qloss setpoint"
function add_setpoint_bus_qloss!(sol, pm::_PM.AbstractPowerModel)
    mva_base = pm.data["baseMVA"]
    add_setpoint!(sol, pm, "branch", "gmd_qloss", :qloss, status_name="br_status", var_key = (idx,item) -> (idx, item["hi_bus"], item["lo_bus"]), scale = (x,item,i) -> x*mva_base)
end


"SETPOINT: current pu to si"
function current_pu_to_si(x,item,pm)
    mva_base = pm.data["baseMVA"]
    kv_base = pm.data["bus"]["1"]["base_kv"]
    return x*1e3*mva_base/(sqrt(3)*kv_base)
end


"SETPOINT: add steady-state top-oil temperature rise setpoint"
function add_setpoint_top_oil_rise_steady_state!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "branch", "topoil_rise_ss", :ross, status_name="br_status")
end


"SETPOINT: add top-oil temperature rise setpoint"
function add_setpoint_top_oil_rise!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "branch", "topoil_rise", :ro, status_name="br_status")
end


"SETPOINT: add steady-state hot-spot temperature rise setpoint"
function add_setpoint_hotspot_rise_steady_state!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "branch", "hotspot_rise_ss", :hsss, status_name="br_status")
end


"SETPOINT: add hot-spot temperature rise setpoint"
function add_setpoint_hotspot_rise!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "branch", "hotspot_rise", :hs, status_name="br_status")
end


"SETPOINT: add hot-spot temperature setpoint"
function add_setpoint_hotspot_temperature!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "branch", "hotspot", :hsa, status_name="br_status")
end







# "GENERAL: add setpoint values based on JuMP variables"
# function add_setpoint!(
#     sol,
#     pm::_PM.AbstractPowerModel,
#     dict_name,
#     param_name,
#     variable_symbol;
#     index_name = "index",
#     default_value = (item) -> NaN,
#     scale = (x,item,cnd) -> x,
#     var_key = (idx,item) -> idx,
#     sol_dict = get(sol, dict_name, Dict{String,Any}()),
#     status_name = "status",
#     inactive_status_value = 0,
#     )

#     has_variable_symbol = haskey(var(pm, pm.cnw), variable_symbol)

#     variables = []
#     if has_variable_symbol
#         variables = var(pm, pm.cnw, variable_symbol)
#     end

#     if !has_variable_symbol || length(variables) == 0
#         add_setpoint_fixed!(sol, pm, dict_name, param_name; index_name=index_name, default_value=default_value)
#         return
#     end

#     if _IM.ismultinetwork(pm.data)
#         data_dict = pm.data["nw"]["$(pm.cnw)"][dict_name]
#     else
#         idx = Int(item[index_name])
#         sol_item = sol_dict[i] = get(sol_dict, i, Dict{String,Any}())

#         sol_item[param_name] = default_value(item)
#         if item[status_name] != inactive_status_value
#             var_id = var_key(idx, item)
#             variables = var(pm, pm.cnw, variable_symbol)
#             sol_item[param_name] = scale(JuMP.value(variables[var_id]), item, 1)
#         end

#         if _PM.ismulticonductor(pm)
#             sol_item[param_name] = default_value(item)
#             if item[status_name] != inactive_status_value
#                 var_id = var_key(idx, item)
#                 variables = var(pm, variable_symbol)
#                 sol_item[param_name] = scale(JuMP.value(variables[var_id]), item, 1)
#             end
#         end
#     end
# end


# "GENERAL: add setpoint values based on a given default_value function"
# function add_setpoint_fixed!(
#     sol,
#     pm::_PM.AbstractPowerModel,
#     dict_name,
#     param_name;
#     index_name = "index",
#     default_value = (item) -> NaN,
#     sol_dict = get(sol, dict_name, Dict{String,Any}()),
#     )

#     if _IM.ismultinetwork(pm.data)
#         data_dict = pm.data["nw"]["$(pm.cnw)"][dict_name]
#     else
#         data_dict = pm.data[dict_name]
#     end

#     if length(data_dict) > 0
#         sol[dict_name] = sol_dict
#     end

#     for (i,item) in data_dict
#         idx = Int(item[index_name])
#         sol_item = sol_dict[i] = get(sol_dict, i, Dict{String,Any}())

#         sol_item[param_name] = default_value(item)

#         if _PM.ismulticonductor(pm)
#             sol_item[param_name] = sol_item[param_name][1]
#         end
#     end
# end
