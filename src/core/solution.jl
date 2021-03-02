
# "SOLUTION: get gmd solution"
# function sol_gmd!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PMs.add_setpoint_bus_voltage!(sol, pm) ==> OK
#     _PMs.add_setpoint_generator_power!(sol, pm) ==> OK
#     _PMs.add_setpoint_branch_flow!(sol, pm) ==> OK
#     _PMs.add_setpoint_branch_status!(sol, pm) ==> OK

#     add_setpoint_bus_dc_voltage!(sol, pm) ==> OK
#     add_setpoint_branch_dc_flow!(sol, pm) ==> OK

#     add_setpoint_load_demand!(sol, pm)
#     add_setpoint_bus_dc_current_mag!(sol, pm)
#     add_setpoint_load_shed!(sol, pm)
#     add_setpoint_bus_qloss!(sol, pm)

# end


# "SOLUTION: get gmd decoupled solution"
# function solution_gmd_decoupled!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> OK
#     _PM.add_setpoint_generator_power!(sol, pm) ==> OK
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> OK

#     add_setpoint_bus_qloss!(sol, pm)

# end


# "SOLUTION: get gmd ts solution"
# function solution_gmd_ts!(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})

#     _PM.add_setpoint_bus_voltage!(sol, pm) ==> OK
#     _PM.add_setpoint_generator_power!(sol, pm) ==> OK
#     _PM.add_setpoint_branch_flow!(sol, pm) ==> OK

#     add_setpoint_load_demand!(sol, pm) - OK

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

                remove = ["zone", "vmax", "area", "vmin", "bus_sid", "base_kv"]
                for j in remove
                    delete!(bus, j)
                end

            end
        end
    end

    # Branch
    solution["branch"] = pm.data["branch"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "branch")
            for (i, branch) in nw_data["branch"]

                remove = ["br_r", "gmd_br_series", "rate_a", "hotspot_coeff", "shift", "gmd_k", "tbus", "br_x", "topoil_init", "g_to", "hotspot_instant_limit", "topoil_rated",  "fbus", "g_fr", "b_fr", "gmd_br_hi", "baseMVA", "topoil_initialized", "topoil_time_const", "b_to", "gmd_br_common", "angmin", "temperature_ambient", "angmax", "hotspot_avg_limit", "hotspot_rated", "branch_sid", "gmd_br_lo", "tap", "transformer"]
                for j in remove
                    delete!(branch, j)
                end

            end
        end
    end

    # Gen
    solution["gen"] = pm.data["gen"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "gen")
            for (i, gen) in nw_data["gen"]

                remove = ["ncost",  "qc1max", "model", "shutdown", "startup", "gen_sid", "qc2max", "ramp_agc", "gen_bus", "pmax", "ramp_10", "vg", "mbase", "pc2", "cost", "qmax", "qmin", "qc1min", "qc2min", "pc1", "ramp_q", "ramp_30", "pmin", "apf"]
                for j in remove
                    delete!(gen, j)
                end

                gen["pg"] = gen["pg"] * solution["baseMVA"]
                gen["qg"] = gen["qg"] * solution["baseMVA"]

            end
        end
    end

    # Load
    solution["load"] = pm.data["load"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "load")
            for (i, load) in nw_data["load"]

                load["pd"] = load["pd"] * solution["baseMVA"]
                load["qd"] = load["qd"] * solution["baseMVA"]

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

    # GMD Bus
    solution["gmd_bus"] = pm.data["gmd_bus"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "gmd_bus")
            for (i, gmd_bus) in nw_data["gmd_bus"]

                remove = ["g_gnd", "name"]
                for j in remove
                    delete!(gmd_bus, j)
                end

                gmd_bus["gmd_vdc"] = JuMP.value.(pm.var[:nw][0][:v_dc]) #FIXME

                # RESULT
                # result["solution"]["gmd_bus"]["2"]["gmd_vdc"]
                # 1-dimensional DenseAxisArray{Float64,1,...} with index sets:
                #   Dimension 1, [4, 2, 3, 5, 6, 1]
                # And data, a 6-element Array{Float64,1}:
                #   32.008063648310255
                #   21.338709098873505
                #   -32.008063648310255
                #   0.0
                #   0.0
                #   -21.338709098873505

            end
        end
    end

    # GMD Branch
    solution["gmd_branch"] = pm.data["gmd_branch"]
    for (n, nw_data) in nws_data
        if haskey(nw_data, "gmd_branch")
            for (i, gmd_branch) in nw_data["gmd_branch"]

                remove = ["br_r", "name", "br_v", "len_km"]
                for j in remove
                    delete!(gmd_branch, j)
                end

                gmd_branch["gmd_idc"] = JuMP.value.(pm.var[:nw][0][:dc]) #FIXME

                # result["solution"]["gmd_branch"]["1"]["gmd_idc"]
                # 1-dimensional DenseAxisArray{Float64,1,...} with index sets:
                #   Dimension 1, [(2, 3, 4), (3, 4, 2), (1, 3, 1), (2, 4, 3), (3, 2, 4), (1, 1, 3)]
                # And data, a 6-element Array{Float64,1}:
                #   106.69354549436753
                #   106.69354549436753
                #   -106.69354549436753
                #   0.0
                #   0.0
                #   0.0

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



