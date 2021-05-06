# ===   SOLUTIONS   === #


# "SOLUTION: get gmd solution"
# function sol_gmd!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_generator_power!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_branch_status!(sol, pm) ==> solution_PM! -- OK!!

#     add_setpoint_bus_dc_voltage!(sol, pm) ==> solution_gmd! -- OK!!
#     add_setpoint_branch_dc_flow!(sol, pm) ==> solution_gmd! -- OK!!

#     add_setpoint_load_demand!(sol, pm) ==> solution_gmd_mls! -- OK!!
#     add_setpoint_bus_dc_current_mag!(sol, pm) ==> solution_gmd_mls! -- OK!!
#     add_setpoint_load_shed!(sol, pm) ==> solution_gmd_demand!
#     add_setpoint_bus_qloss!(sol, pm) ==> solution_gmd_qloss! -- OK!!

# end


# "SOLUTION: get gmd decoupled solution"
# function solution_gmd_decoupled!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_generator_power!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> solution_PM! -- OK!!

#     add_setpoint_bus_qloss!(sol, pm) ==> solution_gmd_qloss! -- OK!!

# end


# "SOLUTION: get gmd ts solution"
# function solution_gmd_ts!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_generator_power!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> solution_PM! -- OK!!

#     add_setpoint_load_demand!(sol, pm) ==> solution_gmd_mls! -- OK!!

#     add_setpoint_bus_dc_voltage!(sol, pm) ==> solution_gmd! -- OK!!
#     add_setpoint_bus_dc_current_mag!(sol, pm) ==> solution_gmd_mls! -- OK!!
#     add_setpoint_load_shed!(sol, pm) ==> solution_gmd_demand!
#     add_setpoint_branch_dc_flow!(sol, pm) ==> solution_gmd! -- OK!!
#     add_setpoint_bus_qloss!(sol, pm) ==> solution_gmd_qloss! -- OK!!

#     add_setpoint_top_oil_rise_steady_state!(sol, pm) ==> solution_gmd_xfmr_temp!
#     add_setpoint_top_oil_rise!(sol, pm) ==> solution_gmd_xfmr_temp!
#     add_setpoint_hotspot_rise_steady_state!(sol, pm) ==> solution_gmd_xfmr_temp!
#     add_setpoint_hotspot_rise!(sol, pm) ==> solution_gmd_xfmr_temp!
#     add_setpoint_hotspot_temperature!(sol, pm) ==> solution_gmd_xfmr_temp!

# end





"SOLUTION: add quasi-dc power flow solutions"
function solution_gmd!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # GMD Bus
    for (nw_id, nw_ref) in nws(pm)
        nws_data["$(nw_id)"]["gmd_bus"] = pm.data["gmd_bus"]
        for (n, nw_data) in nws_data
            if haskey(nw_data, "gmd_bus")
                for (i, gmd_bus) in nw_data["gmd_bus"]
                    remove = ["name", "parent_index"]
                    # remove = ["name", "g_gnd", "parent_index"]
                    for r in remove
                        delete!(gmd_bus, r)
                    end
                    key = gmd_bus["index"]
                    gmd_bus["gmd_vdc"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:v_dc][key])
                end
            end
        end
    end

    # GMD Branch
    for (nw_id, nw_ref) in nws(pm)
        nws_data["$(nw_id)"]["gmd_branch"] = pm.data["gmd_branch"]
        for (n, nw_data) in nws_data
            if haskey(nw_data, "gmd_branch")
                for (i, gmd_branch) in nw_data["gmd_branch"]
                    remove = ["name", "len_km", "parent_index"]
                    # remove = ["br_r", "br_v", "name", "len_km", "parent_index"]
                    for r in remove
                        delete!(gmd_branch, r)
                    end
                    key = (gmd_branch["index"], gmd_branch["f_bus"], gmd_branch["t_bus"])
                    gmd_branch["gmd_idc"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:dc][key])
                end
            end
        end
    end

end


"SOLUTION: add PowerModels.jl power flow solutions"
function solution_PM!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # Bus
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "bus")
                for (i, bus) in nw_data["bus"]
                    add = ["bus_type", "source_id", "index"]
                    # add = ["lat", "lon", "bus_i", "bus_type", "vmax", "source_id", "vmin", "index", "base_kv"]
                    for a in add
                        bus["$(a)"] = pm.data["bus"]["$(i)"]["$(a)"]
                    end
                end
            end
        end
    end

    # Branch
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "branch")
                for (i, branch) in nw_data["branch"]
                    add = ["lo_bus", "source_id", "f_bus", "br_status", "hi_bus", "config", "t_bus", "index", "type"]
                    # add = ["br_r", "gmd_br_series", "rate_a", "hotspot_coeff", "shift", "gmd_k", "lo_bus", "xfmr", "br_x", "topoil_init", "g_to", "hotspot_instant_limit", "topoil_rated", "g_fr", "source_id", "b_fr", "f_bus", "gmd_br_hi", "baseMVA", "br_status", "topoil_initialized", "hi_bus", "config", "topoil_time_const", "t_bus", "b_to", "index", "gmd_br_common", "angmin", "temperature_ambient", "angmax", "hotspot_avg_limit", "hotspot_rated", "gmd_br_lo", "tap", "type"]
                    for a in add
                        branch["$(a)"] = pm.data["branch"]["$(i)"]["$(a)"]
                    end
                end
            end
        end
    end

    # Gen
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "gen")
                for (i, gen) in nw_data["gen"]
                    add = ["gen_bus", "index", "source_id", "gen_status"]
                    # add = ["ncost", "qc1max", "pg", "model", "shutdown", "startup", "gen_sid", "qc2max", "ramp_agc", "bus_i", "qg", "gen_bus", "pmax", "ramp_10", "vg", "mbase", "source_id", "pc2", "index", "cost", "qmax", "gen_status", "qmin", "qc1min", "qc2min", "pc1", "ramp_q", "ramp_30", "pmin", "apf"]
                    for a in add
                        gen["$(a)"] = pm.data["gen"]["$(i)"]["$(a)"]
                    end
                end
            end
        end
    end

end


"SOLUTION: add gmd qloss solution"
function solution_gmd_qloss!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # Branch
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "branch")
                for (i, branch) in nw_data["branch"]
                    key = (branch["index"], branch["hi_bus"], branch["lo_bus"])
                    branch["gmd_qloss"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qloss][key])
                end
            end
        end
    end

end


"SOLUTION: add minimum-load-shed solutions"
function solution_gmd_mls!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # Branch
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "branch")
                for (i, branch) in nw_data["branch"]
                    key = (branch["index"])               
                    branch["gmd_idc_mag"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:i_dc_mag][key])
                end
            end
        end
    end

    # Load
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "load")
                for (i, load) in nw_data["load"]
                    add = ["source_id", "load_bus", "status", "index"]
                    for a in add
                        load["$(a)"] = pm.data["load"]["$(i)"]["$(a)"]
                    end
                end
            end
        end
    end

end


"SOLUTION: add transformer temperature solutions"
function solution_gmd_xfmr_temp!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # Branch
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "branch")
                for (i, branch) in nw_data["branch"]
                    key = (branch["index"])               
                    branch["topoil_rise_ss"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:ross][key])
                    branch["topoil_rise"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:ro][key])
                    branch["hotspot_rise_ss"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:hsss][key])
                    branch["hotspot_rise"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:hs][key])
                    branch["actual_hotspot"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:hsa][key])
                end
            end
        end
    end

end


"SOLUTION: add demand factor solution"
function solution_gmd_demand!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # Load
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "load")
                for (i, load) in nw_data["load"]
                    key = (load["index"])
                    load["demand_served_ratio"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:z_demand][key])
                end
            end
        end
    end

end

