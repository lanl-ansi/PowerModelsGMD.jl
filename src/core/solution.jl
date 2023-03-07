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
        indices = keys(JuMP.value.(pm.var[:it][pm_it_sym][:nw][nw_id][:qloss]))

        for (l, branch) in _PM.ref(pm,nw_id,:branch)
            key             = (branch["index"], branch["hi_bus"], branch["lo_bus"])
            branch_solution = nw_data["branch"][string(l)]

            branch_solution["gmd_qloss"] = key in indices ? JuMP.value.(pm.var[:it][pm_it_sym][:nw][nw_id][:qloss][key]) : 0.0
        end
    end
end


"SOLUTION: add quasi-dc power flow solutions"
function solution_gmd!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})
    nws_data = haskey(solution["it"][pm_it_name], "nw") ? solution["it"][pm_it_name]["nw"] : nws_data = Dict("0" => solution["it"][pm_it_name])

    # GMD Branch
    for (n, nw_data) in nws_data
        nw_id = parse(Int64, n)
        nws_data["$(nw_id)"]["gmd_branch"] = pm.data["gmd_branch"]
        if haskey(nw_data, "gmd_branch")
            for (i, gmd_branch) in nw_data["gmd_branch"]
                if gmd_branch["br_status"] == 0
                    gmd_branch["gmd_idc"] = 0.0
                else
                    key = (gmd_branch["index"], gmd_branch["f_bus"], gmd_branch["t_bus"])
                    gmd_branch["gmd_idc"] = JuMP.value.(pm.var[:it][pm_it_sym][:nw][nw_id][:dc][key])
                end
            end
        end
    end
end


"SOLUTION: add gmd qloss solution from a decoupled model.

 Decoupled models solve the quasi DC flows first and then the AC flows.  The gmd_qloss is a value that is calculated in between
 the two solves and this solution processor takes the calculated value and places it in the solution vector so that the decoupled solution output appears the same as a single shot optimization
 problem
"
function solution_gmd_qloss_decoupled!(pm::_PM.AbstractPowerModel, solution::Dict{String,Any})
    nws_data = haskey(solution["it"][pm_it_name], "nw") ? solution["it"][pm_it_name]["nw"] : nws_data = Dict("0" => solution["it"][pm_it_name])

    for (n, nw_data) in nws_data
        if !haskey(nw_data, "branch")
            continue
        end

        nw_id = parse(Int64, n)
        for (i, branch) in nw_data["branch"]
            branch["gmd_qloss"] = haskey(_PM.ref(pm,nw_id,:branch, parse(Int64,i)),"gmd_qloss") ? _PM.ref(pm,nw_id,:branch, parse(Int64,i),"gmd_qloss") / _PM.ref(pm,nw_id,:baseMVA) : nothing
        end
    end
end
