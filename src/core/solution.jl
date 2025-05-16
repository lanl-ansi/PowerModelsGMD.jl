########################
# Solution Definitions #
########################


"SOLUTION: add gmd qloss solution

 Adds an explict gmd_qloss term for each branch
"
function solution_gmd_qloss!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})
    nws_data = haskey(solution["it"][pm_it_name], "nw") ? solution["it"][pm_it_name]["nw"] : nws_data = Dict("0" => solution["it"][pm_it_name])

    # Branch
    for (n, nw_data) in nws_data
        nw_id = parse(Int64, n)
        indices = keys(_PM.var(pm,nw_id,:qloss))

        for (l, branch) in _PM.ref(pm,nw_id,:branch)
            key = (branch["index"], branch["hi_bus"], branch["lo_bus"])
            branch_solution = nw_data["branch"][string(l)]
            branch_solution["ieff"] = JuMP.value.(_PM.var(pm, nw_id, :i_dc_mag, l))
            branch_solution["gmd_qloss"] = JuMP.value.(_PM.var(pm,nw_id,:qloss,key))
        end
    end
end


function solution_gmd_qloss_max!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})
    nws_data = haskey(solution["it"][pm_it_name], "nw") ? solution["it"][pm_it_name]["nw"] : nws_data = Dict("0" => solution["it"][pm_it_name])

    for (n, nw_data) in nws_data
        nw_id = parse(Int64, n)
        indices = keys(_PM.var(pm,nw_id,:qloss))

        for (l, branch) in _PM.ref(pm,nw_id,:branch)
            key = (branch["index"], branch["hi_bus"], branch["lo_bus"])
            branch_solution = nw_data["branch"][string(l)]
            branch_solution["gmd_qloss"] = JuMP.value.(_PM.var(pm,nw_id,:qloss,key))
        end
    end
end


"SOLUTION: add quasi-dc power flow solutions

 Adds an explict gmd_idc term for each branch
ieff for all branches 
    qloss for all branches
"
function solution_gmd!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})
    nws_data = haskey(solution["it"][pm_it_name], "nw") ? solution["it"][pm_it_name]["nw"] : nws_data = Dict("0" => solution["it"][pm_it_name])
    for (n, nw_data) in nws_data
        nw_id = parse(Int64, n)
        
        nw_data["ieff"] = Dict{String,Any}()
        nw_data["qloss"] = Dict{String,Any}()
        for (n, branch) in _PM.ref(pm,nw_id,:branch)
            i = branch["hi_bus"]
            j = branch["lo_bus"]
            i_eff = JuMP.value(_PM.var(pm, nw_id, :i_dc_mag, n)) / 3
            q_loss = JuMP.value(_PM.var(pm, nw_id, :qloss)[(n,i,j)])
            nw_data["ieff"]["$(n)"] = i_eff < 1e-12 ? 0.0 : i_eff
            nw_data["qloss"]["$(n)"] = q_loss < 1e-12 ? 0.0 : q_loss
        end
    end
end


"""
    solution for matrix gms nl_solver
        returns dc bus voltages, neutral voltages and currents
"""
function solution_gmd(v::Vector{Float64}, case::Dict{String,Any})
    solution = Dict{String,Any}()
    solution["gmd_bus"] = Dict()
    solution["gmd_branch"] = Dict()
    result = Dict{String,Any}()
    result["status"] = :LocalOptimal
    result["solution"] = solution

    for (bus, val) in enumerate(v)
        solution["gmd_bus"]["$bus"] = Dict()
        solution["gmd_bus"]["$bus"]["gmd_vdc"] = val
    end

    # Note: calc_dc_current (formely calc_dc_current_mag) is different from
    # calc_ieff_current_mag as the latter is for ieff rather than idc
    # and associated with branches rather than gmd_branches
    for (n, branch) in case["gmd_branch"]
        solution["gmd_branch"]["$n"] = Dict()
        if haskey(branch, "parent_type") && branch["parent_type"] == "branch"
            type = case["branch"]["$(branch["parent_index"])"]["type"]
            idc = calc_dc_current(branch, type, solution)
            solution["gmd_branch"]["$n"]["dcf"] =  -idc
            solution["gmd_branch"]["$n"]["dct"] =   idc
        else
            Memento.warn(_LOGGER, "Branch $n doesn't have parent_type, skipping")
        end
    end

    # TODO: 
    solution["ieff"] = Dict{String,Any}()

    for (n, branch) in case["branch"]
        solution["ieff"][n] = calc_ieff_current_mag(branch, case, solution) / 3 # returns phase ieff
    end

    solution["qloss"] = Dict{String,Any}()
    for (n, branch) in case["branch"]
        solution["qloss"]["$n"] = calc_qloss(branch, case, solution)
    end

    return result
end


function add_ieff_solution!(data::Dict{String,Any}, dc_sol::Dict{String,Any})
    if !(haskey(data, "ieff"))
        data["ieff"] = dc_sol["solution"]["ieff"]
    end
end

function source_id_keys!(solution::Dict{String, Any}, network::Dict{String, Any})
    solution_keys_pairs = [["qloss", "branch"], ["gmd_branch", "gmd_branch"], ["gmd_bus", "gmd_bus"], ["ieff", "branch"]]

    for key_pair in solution_keys_pairs
        _convert_table!(solution["solution"], network, key_pair)
    end
end

function _convert_table!(solution::Dict{String, Any}, network::Dict{String, Any}, key_pair::Vector{String})
    valType = valtype(solution[key_pair[1]])
    new_table = Dict{Array, valType}()

    for (key, element) in solution[key_pair[1]]
        new_table[network[key_pair[2]][key]["source_id"]] = element
    end

    solution[key_pair[1]] = new_table
end


function solution_add_qloss_bound_case!(case::Dict{String,Any}, results::Dict{String,Any})
    for (i, result) in results
        if result["max"]["termination_status"] == _PM.LOCALLY_SOLVED
            case["branch"][i]["qloss_max"] = result["max"]["objective"]
        end
    end
end


function solution_get_qloss_bound(case::Dict{String,Any}, results::Dict{String,Any})
    bounds = Dict{String, Any}(
        "qloss" => Dict{String, Any}(),
    )
    for (i, result) in results
        bounds["qloss"][i] = Dict{String, Any}()
        if result["max"]["termination_status"] == _PM.LOCALLY_SOLVED
            bounds["qloss"][i]["qloss_max"] = result["max"]["objective"]
        end
    end
    return bounds
end


function solution_add_gmd_bus_v_bounds_case!(case::Dict{String,Any}, results::Dict{String,Any})
    for (i, result) in results
        if result["max"]["termination_status"] == _PM.LOCALLY_SOLVED
            case["gmd_bus"][i]["vmax"] = result["max"]["objective"]
        end
        if result["min"]["termination_status"] == _PM.LOCALLY_SOLVED
            case["gmd_bus"][i]["vmin"] = result["min"]["objective"]
        end
    end
end


function solution_get_gmd_bus_v_bounds(case::Dict{String,Any}, results::Dict{String,Any})
    bounds = Dict{String, Any}(
        "gmd_bus" => Dict{String, Any}(),
    )
    for (i, result) in results
        bounds["gmd_bus"][i] = Dict{String, Any}()
        if result["max"]["termination_status"] == _PM.LOCALLY_SOLVED
            bounds["gmd_bus"][i]["vmax"] = result["max"]["objective"]
        elseif result["max"]["termination_status"] == _PM.TIME_LIMIT
            bounds["gmd_bus"][i]["vmax"] = result["max"]["objective_lb"]
        end
        if result["min"]["termination_status"] == _PM.LOCALLY_SOLVED
            bounds["gmd_bus"][i]["vmin"] = result["min"]["objective"]
        elseif result["min"]["termination_status"] == _PM.TIME_LIMIT
            bounds["gmd_bus"][i]["vmin"] = result["min"]["objective_lb"]
        end
    end
    return bounds
end


function  solution_get_ieff_bounds(case::Dict{String,Any}, results::Dict{String,Any})
    bounds = Dict{String, Any}(
        "branch" => Dict{String, Any}(),
    )
    for (i, result) in results
        bounds["branch"][i] = Dict{String, Any}()
        if result["max"]["termination_status"] == _PM.LOCALLY_SOLVED
            bounds["branch"][i]["vmax"] = result["max"]["objective"]
        elseif result["max"]["termination_status"] == _PM.TIME_LIMIT
            bounds["branch"][i]["vmax"] = result["max"]["objective_lb"]
        end
        if result["min"]["termination_status"] == _PM.LOCALLY_SOLVED
            bounds["branch"][i]["vmin"] = result["min"]["objective"]
        elseif result["min"]["termination_status"] == _PM.TIME_LIMIT
            bounds["branch"][i]["vmin"] = result["min"]["objective_lb"]
        end
    end
    return bounds
end