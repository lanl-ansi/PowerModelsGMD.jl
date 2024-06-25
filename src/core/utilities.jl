function gen_g_matrix(network::Dict{String, Any})
    num_bus = length(network["gmd_bus"])
    matrix = zeros(Float64, (num_bus, num_bus))
    for bus_id_from in sort(collect(keys(network["gmd_bus"])))
        bus_id_from = parse(Int, bus_id_from)
        for bus_id_to in sort(collect(keys(network["gmd_bus"])))
            bus_id_to = parse(Int, bus_id_to)
            if (bus_id_from == bus_id_to)
                matrix[bus_id_from, bus_id_to] = gen_diagonal_g(bus_id_from, network)
            else
                matrix[bus_id_from, bus_id_to] = -1 * branch_conductance(bus_id_from, bus_id_to, network)
            end            
        end
    end

    return matrix
end

function branch_conductance(bus_from::Int, bus_to::Int, network::Dict{String, Any})
    for branch in values(network["gmd_branch"])
        if (branch["f_bus"] == bus_from && branch["t_bus"] == bus_to) || (branch["f_bus"] == bus_to && branch["t_bus"] == bus_from)
            return 1 / branch["br_r"]
        end         
    end

    return 0
end

function gen_diagonal_g(bus_from::Int, network::Dict{String, Any})
    g_value = network["gmd_bus"]["$bus_from"]["g_gnd"]
    for bus_id in keys(network["gmd_bus"])
        g_value += branch_conductance(bus_from, parse(Int, bus_id), network)
    end

    return g_value
end