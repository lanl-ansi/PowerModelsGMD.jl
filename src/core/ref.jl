# ===   REFS   === #


"REF: extension to add gmd to ref"
function ref_add_gmd!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    data_it = _IM.ismultiinfrastructure(data) ? data["it"][pm_it_name] : data

    if _IM.ismultinetwork(data_it)
        nws_data = data_it["nw"]
    else
        nws_data = Dict("0" => data_it)
    end

    for (n, nw_data) in nws_data

        nw_id = parse(Int, n)
        nw_ref = ref[:it][pm_it_sym][:nw][nw_id]

        # println(nw_ref[:gmd_bus])
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
        nw_ref[:blocker_buses] = Dict(i=>gmd_bus for (i,gmd_bus) in nw_ref[:gmd_bus] if gmd_bus["blocker"] != 0.0)
    end

end

function ref_add_gmd_blockers!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:it][pm_it_sym][:nw]
        #nw_ref[:blocker_buses] = [(i,gmd_bus) for (i,gmd_bus) in nw_ref[:gmd_bus] if gmd_bus["blocker"] != 0.0]
        nw_ref[:blocker_buses] = Dict(i=>gmd_bus for (i,gmd_bus) in nw_ref[:gmd_bus])
    end
end


# "REF: extension to add load blocks to ref"
# function ref_add_load_blocks!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})

#     ref[:load_blocks] = Dict{Int,Set}(i => block for (i,block) in enumerate(PMD.identify_load_blocks(data)))
#     load_block_map = Dict{Int,Int}()
#     for (l,load) in get(data, "load", Dict())
#         for (b,block) in ref[:load_blocks]
#             if load["load_bus"] in block
#                 load_block_map[parse(Int,l)] = b
#             end
#         end
#     end
#     ref[:load_block_map] = load_block_map

# end

