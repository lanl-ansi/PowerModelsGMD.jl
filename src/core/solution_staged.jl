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
