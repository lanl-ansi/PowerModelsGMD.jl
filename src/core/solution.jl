
# "SOLUTION: get gmd solution"
# function sol_gmd!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_generator_power!(sol, pm) ==> solution_PM! -- ...
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> solution_PM! -- ...
#     _PM.add_setpoint_branch_status!(sol, pm) ==> solution_PM! -- ...

#     add_setpoint_bus_dc_voltage!(sol, pm) ==> solution_gmd! -- OK!!
#     add_setpoint_branch_dc_flow!(sol, pm) ==> solution_gmd! -- OK!!

#   NEED TO INCLUDE THESE LATER:

#     add_setpoint_load_demand!(sol, pm)
#     add_setpoint_bus_dc_current_mag!(sol, pm)
#     add_setpoint_load_shed!(sol, pm)
#     add_setpoint_bus_qloss!(sol, pm) ==> solution_gmd_decoupled! -- not needed

# end


# "SOLUTION: get gmd decoupled solution"
# function solution_gmd_decoupled!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_generator_power!(sol, pm) ==> solution_PM! -- ...
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> solution_PM! -- ...

#     add_setpoint_bus_qloss!(sol, pm) ==> solution_gmd_decoupled! -- OK!!

# end


# "SOLUTION: get gmd ts solution"
# function solution_gmd_ts!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> solution_PM! -- OK!!
#     _PM.add_setpoint_generator_power!(sol, pm) ==> solution_PM! -- ...
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> solution_PM! -- ...

#     add_setpoint_load_demand!(sol, pm) - OK

#     add_setpoint_bus_dc_voltage!(sol, pm)
#     add_setpoint_bus_dc_current_mag!(sol, pm)
#     add_setpoint_load_shed!(sol, pm)
#     add_setpoint_branch_dc_flow!(sol, pm)
#     add_setpoint_bus_qloss!(sol, pm) ==> solution_gmd_decoupled! -- not needed

#     add_setpoint_top_oil_rise_steady_state!(sol, pm)
#     add_setpoint_top_oil_rise!(sol, pm)
#     add_setpoint_hotspot_rise_steady_state!(sol, pm)
#     add_setpoint_hotspot_rise!(sol, pm)
#     add_setpoint_hotspot_temperature!(sol, pm)

# end





"SOLUTION: initialize solutions"
function solution_init!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

    if haskey(solution["it"][pm_it_name], "nw")
        nws_data = solution["it"][pm_it_name]["nw"]
    else
        nws_data = Dict("0" => solution["it"][pm_it_name])
    end

    # Bus
    for (nw_id, nw_ref) in nws(pm)
        nws_data["$(nw_id)"]["bus"] = pm.data["bus"]

        for (n, nw_data) in nws_data
            if haskey(nw_data, "bus")
                for (i, bus) in nw_data["bus"]

                    remove = ["zone", "area", "bus_sid"]
                    for j in remove
                        delete!(bus, j)
                    end

                end
            end
        end
    end

    # Branch
    for (nw_id, nw_ref) in nws(pm)
        nws_data["$(nw_id)"]["branch"] = pm.data["branch"]

        for (n, nw_data) in nws_data
            if haskey(nw_data, "branch")
                for (i, branch) in nw_data["branch"]

                    remove = ["tbus", "fbus", "branch_sid", "transformer"]
                    for j in remove
                        delete!(branch, j)
                    end

                    branch["pf"] = 0.0
                    branch["pt"] = 0.0
                    branch["qf"] = 0.0
                    branch["qt"] = 0.0

                end
            end
        end
    end

    # Gen
    for (nw_id, nw_ref) in nws(pm)
        nws_data["$(nw_id)"]["gen"] = pm.data["gen"]

        for (n, nw_data) in nws_data
            if haskey(nw_data, "gen")
                for (i, gen) in nw_data["gen"]

                    remove = ["ncost", "qc1max", "shutdown", "startup", "gen_sid", "qc2max", "ramp_agc", "ramp_10", "mbase", "pc2", "qc1min", "qc2min", "pc1", "ramp_q", "ramp_30", "apf"]
                    for j in remove
                        delete!(gen, j)
                    end

                end
            end
        end
    end

   # Load
    for (nw_id, nw_ref) in nws(pm)
        nws_data["$(nw_id)"]["load"] = pm.data["load"]

        for (n, nw_data) in nws_data
            if haskey(nw_data, "load")
                for (i, load) in nw_data["load"]

                    load["pd"] = load["pd"] * nws_data["$(nw_id)"]["baseMVA"]
                    load["qd"] = load["qd"] * nws_data["$(nw_id)"]["baseMVA"]

                end
            end
        end
    end

end


"SOLUTION: add gmd solutions"
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

                    remove = ["name"]
                    for j in remove
                        delete!(gmd_bus, j)
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

                    remove = ["name", "len_km"]
                    for j in remove
                        delete!(gmd_branch, j)
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

                    key = bus["index"]
                    bus["va"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:va][key])
                    bus["vm"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:vm][key])

                end
            end
        end
    end

    # Branch
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "branch")
                for (i, branch) in nw_data["branch"]

                    key = branch["index"]
                    #branch["pf"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:pf][key])
                    #branch["pt"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:pt][key])
                    #branch["qf"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qf][key])
                    #branch["qt"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qt][key])

                end
            end
        end
    end

    # Gen
    for (nw_id, nw_ref) in nws(pm)
        for (n, nw_data) in nws_data
            if haskey(nw_data, "gen")
                for (i, gen) in nw_data["gen"]

                    key = gen["index"]
                    gen["pg"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:pg][key])
                    gen["qg"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qg][key])
 
                end
            end
        end
    end

end


"SOLUTION: add gmd decoupled solutions"
function solution_gmd_decoupled!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

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
                    branch["gmd_qloss"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qloss][key]) * nws_data["$(nw_id)"]["baseMVA"]

                end
            end
        end
    end

end





# =============================================================================== #

##### TODO : move these into new format ... commented has been already moved ...


# "SETPOINT: add generator status setpoint"
# function add_setpoint_generator_status!(sol, pm::_PM.AbstractPowerModel)
#     add_setpoint!(sol, pm, "gen", "gen_status", :z_gen; conductorless=true, default_value = (item) -> item["gen_status"]*1.0)
# end


# "SETPOINT: add load demand setpoint"
# function add_setpoint_load_demand!(sol, pm::_PM.AbstractPowerModel)
#     mva_base = pm.data["baseMVA"]
#     add_setpoint!(sol, pm, "load", "pd", :pd; default_value = (item) -> item["pd"]*mva_base)
#     add_setpoint!(sol, pm, "load", "qd", :qd; default_value = (item) -> item["qd"]*mva_base)
# end


# "SETPOINT: add bus dc voltage setpoint"
# function add_setpoint_bus_dc_voltage!(sol, pm::_PM.AbstractPowerModel)
#     add_setpoint!(sol, pm, "gmd_bus", "gmd_vdc", :v_dc, status_name="status", inactive_status_value=0)
# end


"SETPOINT: add bus dc current magitude setpoint"
function add_setpoint_bus_dc_current_mag!(sol, pm::_PM.AbstractPowerModel)
    # add_setpoint!(sol, pm, "bus", "bus_i", "gmd_idc_mag", :i_dc_mag)
    add_setpoint!(sol, pm, "branch", "gmd_idc_mag", :i_dc_mag, status_name="br_status", inactive_status_value=0)
end


"SETPOINT: add load shed setpoint"
function add_setpoint_load_shed!(sol, pm::_PM.AbstractPowerModel)
    add_setpoint!(sol, pm, "load", "demand_served_ratio", :z_demand)
end


# "SETPOINT: add branch dc flow setpoint"
# function add_setpoint_branch_dc_flow!(sol, pm::_PM.AbstractPowerModel)
#     add_setpoint!(sol, pm, "gmd_branch", "gmd_idc", :dc, status_name="br_status", inactive_status_value=0, var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
# end


# "SETPOINT: add bus qloss setpoint"
# function add_setpoint_bus_qloss!(sol, pm::_PM.AbstractPowerModel)
#     mva_base = pm.data["baseMVA"]
#     add_setpoint!(sol, pm, "branch", "gmd_qloss", :qloss, status_name="br_status", var_key = (idx,item) -> (idx, item["hi_bus"], item["lo_bus"]), scale = (x,item,i) -> x*mva_base)
# end


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



