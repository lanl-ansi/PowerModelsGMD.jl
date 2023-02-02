########################
# Solution Definitions #
########################


# ===   POWER FLOW SOLUTIONS   === #


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
                    for a in add
                        if "$(a)" in keys(pm.data["branch"]["$(i)"])
                            branch["$(a)"] = pm.data["branch"]["$(i)"]["$(a)"]
                        else
                            branch["$(a)"] = nothing
                        end
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
                    for a in add
                        gen["$(a)"] = pm.data["gen"]["$(i)"]["$(a)"]
                    end
                end
            end
        end
    end

end


# ===   GMD SOLUTIONS   === #


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
            if !haskey(nw_data, "branch")
                continue
            end

            for (i, branch) in nw_data["branch"]
                branch["gmd_qloss"] = 0.0

                if !("hi_bus" in keys(branch) && "lo_bus" in keys(branch))
                    continue
                end

                key = (branch["index"], branch["hi_bus"], branch["lo_bus"])

                if !(:qloss in keys(pm.var[:it][pm_it_sym][:nw][0]))
                    continue
                end

                if !(key in keys(JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qloss])))
                    Memento.warn(_LOGGER, "Qloss key $key not found, setting qloss for branch to zero")
                    continue
                end
                
                branch["gmd_qloss"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:qloss][key])
            end
        end
    end

end


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
                    if gmd_branch["br_status"] == 0
                        gmd_branch["gmd_idc"] = 0.0
                    else
                        key = (gmd_branch["index"], gmd_branch["f_bus"], gmd_branch["t_bus"])
                        gmd_branch["gmd_idc"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:dc][key])
                    end
                end
            end
        end
    end

end


# ===   LOAD SHEDDING SOLUTIONS   === #


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


# ===   THERMAL SOLUTIONS   === #


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


# ===   GIC BLOCKER SOLUTIONS   === #


"SOLUTION: add quasi-dc power flow solutions"
function solution_gmd_blocker!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})

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
                    if haskey(nw_data, "bus_blockers") && haskey(nw_data["bus_blockers"], i)
                        key = gmd_bus["index"]
                        z = JuMP.value.(pm.var[:it][pm_it_sym][:nw][0][:z_blocker][key])
                        #gmd_bus["blocker_placed"] = Int64(z)
                        gmd_bus["blocker_placed"] = z
                    else
                        gmd_bus["blocker_placed"] = 0.0
                    end
                end
            end
        end
    end

end

