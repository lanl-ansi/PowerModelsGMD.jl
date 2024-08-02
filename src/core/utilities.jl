function generate_g_i_matrix(network::Dict{String, Any})
    diag_g = Dict{Int64, Float64}()
    inject_i = Dict{Int64, Float64}()

    for bus in values(network["gmd_bus"])
        if bus["status"] == 1
            diag_g[bus["index"]] = bus["g_gnd"]
            inject_i[bus["index"]] = 0
        end
    end

    offDiag_g = Dict{Int64, Dict}()
    offDiag_counter = 0
    for branch in values(network["gmd_branch"])
        if branch["br_status"] != 1
            continue
        end

        bus_from = branch["f_bus"]
        bus_to = branch["t_bus"]

        if !haskey(diag_g, bus_from) || !haskey(diag_g, bus_to)
            continue
        end

        if !haskey(offDiag_g, bus_from)
            offDiag_g[bus_from] = Dict{Int64, Float64}()
        end
        if !haskey(offDiag_g, bus_to)
            offDiag_g[bus_to] = Dict{Int64, Float64}()
        end

        if !haskey(offDiag_g[bus_from], bus_to)
            offDiag_g[bus_from][bus_to] = 0.0
            offDiag_counter += 1
        end
        if !haskey(offDiag_g[bus_to], bus_from)
            offDiag_g[bus_to][bus_from] = 0.0
            offDiag_counter += 1
        end

        offDiag_g[bus_from][bus_to] -= 1/branch["br_r"]
        offDiag_g[bus_to][bus_from] -= 1/branch["br_r"]

        # TODO: What would happen if these didn't exist?
        # Art: added dictionary get function to specify defaults
        # TODO: consider printing a warning if br_r or br_v don't exist and using defaults
        diag_g[bus_from] += 1.0/get(branch, "br_r", 1e6)
        diag_g[bus_to] += 1.0/get(branch, "br_r", 1e6)
        
        inject_i[bus_from] -= (get(branch, "br_v", 0.0) == 0.0 ? 0.0 : branch["br_v"]/branch["br_r"])
        inject_i[bus_to] += (get(branch, "br_v", 0.0) == 0.0 ? 0.0 : branch["br_v"]/branch["br_r"])
    end

    for (i, val) in diag_g
        if val == 0.0
            diag_g[i] = 1
        end
    end

    rows = zeros(Int64, length(keys(diag_g)) + offDiag_counter)
    columns = zeros(Int64, length(keys(diag_g)) + offDiag_counter)
    content = zeros(Float64, length(keys(diag_g)) + offDiag_counter)
    n = 1
    for (i, val) in diag_g
        rows[n] = i
        columns[n] = i
        content[n] = val
        n += 1
    end
    for (i, ent) in offDiag_g
        for (j, val) in ent
            rows[n] = i
            columns[n] = j
            content[n] = val
            n += 1
        end
    end
    g = SparseArrays.sparse(rows, columns, content)

    i_inj = zeros(Float64, length(keys(inject_i)))
    for (i, val) in inject_i
        i_inj[i] = val
    end
    return [g, i_inj]
end
