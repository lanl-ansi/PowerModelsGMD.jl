###################
# Ref Definitions #
###################


"REF: add gmd data to PowerModels.jl ref dict structures"
function ref_add_gmd!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})

    data_it  = _IM.ismultiinfrastructure(data) ? data["it"][pm_it_name] : data
    nws_data = _IM.ismultinetwork(data_it) ? data_it["nw"] : Dict("0" => data_it)

#    if _IM.ismultinetwork(data_it)
#        nws_data = data_it["nw"]
#    else
#        nws_data = Dict("0" => data_it)
#    end

    for (n, nw_data) in nws_data

        nw_id = parse(Int, n)
        nw_ref = ref[:it][pm_it_sym][:nw][nw_id]

        nw_ref[:gmd_bus] = Dict(x for x in nw_ref[:gmd_bus] if x.second["status"] != 0)
        nw_ref[:gmd_branch] = Dict(x for x in nw_ref[:gmd_branch] if x.second["br_status"] != 0)

        nw_ref[:gmd_arcs_from] = [(i,branch["f_bus"],branch["t_bus"]) for (i,branch) in nw_ref[:gmd_branch]]
        nw_ref[:gmd_arcs_to] = [(i,branch["t_bus"],branch["f_bus"]) for (i,branch) in nw_ref[:gmd_branch]]
        nw_ref[:gmd_arcs] = [nw_ref[:gmd_arcs_from]; nw_ref[:gmd_arcs_to]]

        gmd_bus_arcs = Dict([(i, []) for (i,bus) in nw_ref[:gmd_bus]])
        for (l,i,j) in nw_ref[:gmd_arcs]
           push!(gmd_bus_arcs[i], (l,i,j))
        end
        nw_ref[:gmd_bus_arcs] = gmd_bus_arcs

        #nw_ref[:blocker_buses] = Dict(i=>gmd_bus for (i,gmd_bus) in nw_ref[:gmd_bus] if gmd_bus["blocker"] != 0.0)
        #nw_ref[:bus_blockers] = Dict(j=>i for (i,j) in enumerate(keys(nw_ref[:gmd_bus])))
        #nw_ref[:blockers] = [i for (i,j) in enumerate(keys(nw_ref[:gmd_bus]))]

#        nw_ref[:bus_blockers] = Dict()
#        nw_ref[:blocker_buses] = Dict()
#        i = 1

#        for j in sort(collect(keys(nw_ref[:gmd_bus])))
#            gmd_bus = nw_ref[:gmd_bus][j]

#            if get(gmd_bus, "blocker", 0.0) != 0.0
#                nw_ref[:bus_blockers][j] = i
#                nw_ref[:blocker_buses][j] = gmd_bus
#                i += 1
#            end
#        end

    end

end


"REF: add expansion blocker data (ne_blocker) to PowerModels.jl ref dict structures"
function ref_add_ne_blocker!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})

    data_it  = _IM.ismultiinfrastructure(data) ? data["it"][pm_it_name] : data
    nws_data = _IM.ismultinetwork(data_it) ? data_it["nw"] : Dict("0" => data_it)

    for (n, nw_data) in nws_data
        nw_id = parse(Int, n)
        nw_ref = ref[:it][pm_it_sym][:nw][nw_id]

        nw_ref[:gmd_ne_blocker] = Dict(x for x in nw_ref[:gmd_ne_blocker] if (x.second["status"] == 1))

        ### bus connected blocker lookups ###
        gmd_bus_ne_blockers = Dict((i, Int[]) for (i,bus) in nw_ref[:gmd_bus])
        for (i, ne_blocker) in nw_ref[:gmd_ne_blocker]
            push!(gmd_bus_ne_blockers[ne_blocker["gmd_bus"]], i)
        end
        nw_ref[:gmd_bus_ne_blockers] = gmd_bus_ne_blockers
    end

end
