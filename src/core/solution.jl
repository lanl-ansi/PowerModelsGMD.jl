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
            key             = (branch["index"], branch["hi_bus"], branch["lo_bus"])
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

        for (l, branch) in _PM.ref(pm,nw_id,:gmd_branch)
            key = (branch["index"], branch["f_bus"], branch["t_bus"])
            branch_solution = nw_data["gmd_branch"][string(l)]
            branch_solution["gmd_idc"] = JuMP.value.(_PM.var(pm,nw_id,:dc,key)) / 3
        end
        
        nw_data["ieff"] = Dict{String,Any}()
        for (n, branch) in _PM.ref(pm,nw_id,:branch)
            nw_data["ieff"]["$(n)"] = calc_ieff_current_mag(branch, _PM.ref(pm,nw_id), nw_data)
        end

        nw_data["qloss"] = Dict{String,Any}()
        for (n, branch) in _PM.ref(pm,nw_id,:branch)
            nw_data["qloss"]["$(n)"] = calc_qloss(branch, _PM.ref(pm,nw_id), nw_data)
        end

    end
end

"""
    solution for matrix gms nl_solver
        returns dc bus voltages, neutral voltages and currents
"""
function solution_gmd(v::Vector{Float64}, busMap::Dict{Int64,Int64}, case::Dict{String,Any})
    solution = Dict{String,Any}()
    solution["gmd_bus"] = Dict()
    solution["gmd_branch"] = Dict()
    result = Dict{String,Any}()
    result["status"] = :LocalOptimal
    result["solution"] = solution

    for (bus, i) in busMap
        solution["gmd_bus"]["$bus"] = Dict()
        solution["gmd_bus"]["$bus"]["gmd_vdc"] = v[i]
    end
    for (n, branch) in case["gmd_branch"]
        solution["gmd_branch"]["$n"] = Dict()

        if branch["parent_type"] != "branch"
            continue
        end

        type = case["branch"]["$(branch["parent_index"])"]["type"]
        solution["gmd_branch"]["$n"]["gmd_idc"] = calc_dc_current_mag(branch, type, solution)
    end

    solution["ieff"] = Dict{String,Any}()

    for (n, branch) in case["branch"]
        solution["ieff"][n] = calc_ieff_current_mag(branch, case, solution)
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