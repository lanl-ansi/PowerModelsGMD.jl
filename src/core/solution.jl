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
"
function solution_gmd!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})
    nws_data = haskey(solution["it"][pm_it_name], "nw") ? solution["it"][pm_it_name]["nw"] : nws_data = Dict("0" => solution["it"][pm_it_name])

    for (n, nw_data) in nws_data
        nw_id = parse(Int64, n)
        for (l, branch) in _PM.ref(pm,nw_id,:gmd_branch)
            key             = (branch["index"], branch["f_bus"], branch["t_bus"])
            branch_solution = nw_data["gmd_branch"][string(l)]
            branch_solution["gmd_idc"] = JuMP.value.(_PM.var(pm,nw_id,:dc,key))
        end
    end
end
