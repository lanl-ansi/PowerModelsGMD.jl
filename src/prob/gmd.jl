##########
# GIC DC #
##########


# ===   WITH OPTIMIZER   === #


"FUNCTION: solve GIC current model"
function solve_gmd(file, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd;
        ref_extensions = [
            ref_add_gmd!,
        ],
        solution_processors = [
            solution_gmd!
        ],
        kwargs...,
    )
end


"FUNCTION: build the quasi-dc-pf problem
as a linear constraint satisfaction problem"
function build_gmd(pm::_PM.AbstractPowerModel; kwargs...)

    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_kcl(pm, i) # constraint_gic_current_balance(
        
    end

    for i in _PM.ids(pm, :branch)
        constraint_qloss_gmd(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end


# ===   WITH MATRIX SOLVE   === #


"FUNCTION: solve GIC matrix solve"
function solve_gmd(file::String; kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd(data; kwargs...)
end

function solve_gmd(case::Dict{String,Any}; kwargs...)
    diag_y = Dict{Int64,Float64}()
    inject_i = Dict{Int64,Float64}()
    for (i, bus) in case["gmd_bus"]
        if bus["status"] == 1
            bus["g_gnd"] != 0.0 ? diag_y[bus["index"]] = bus["g_gnd"] : diag_y[bus["index"]] = 0.0
            inject_i[bus["index"]] = 0.0
        end
    end
    offDiag_y = Dict{Int64,Any}()
    offDiag_counter = 0
    for (i, branch) in case["gmd_branch"]
        if branch["br_status"] == 1
            m = branch["f_bus"]
            n = branch["t_bus"]
            if !haskey(offDiag_y, m)
                offDiag_y[m] = Dict{Int64,Any}() 
                offDiag_y[m][n] = 0.0
                offDiag_counter += 1
            end
            if !haskey(offDiag_y, n)
                offDiag_y[n] = Dict{Int64,Any}() 
                offDiag_y[n][m] = 0.0
                offDiag_counter += 1
            end
            if haskey(offDiag_y[m], n)
                offDiag_y[m][n] -= 1/branch["br_r"] 
            else
                offDiag_y[m][n] = -1/branch["br_r"]
                offDiag_counter += 1
            end
            if haskey(offDiag_y[n], m) 
                offDiag_y[n][m] -= 1/branch["br_r"] 
            else
                offDiag_y[n][m] = -1/branch["br_r"]
                offDiag_counter += 1
            end
            haskey(diag_y, m) ? diag_y[m] += 1/branch["br_r"] : nothing
            haskey(diag_y, n) ? diag_y[n] += 1/branch["br_r"] : nothing
            haskey(inject_i, m) ? inject_i[m] -= branch["br_v"]/branch["br_r"] : nothing
            haskey(inject_i, n) ? inject_i[n] += branch["br_v"]/branch["br_r"] : nothing
        end
    end

    # create bus map to eliminate zero rows and columns to help y^-1 could remove but for now just setting diagonal to 1
    for (i, val) in diag_y
        if val == 0.0
            diag_y[i] = 1
        end
    end

    rows = zeros(Int64, length(keys(diag_y)) + offDiag_counter)
    columns = zeros(Int64, length(keys(diag_y)) + offDiag_counter)
    values = zeros(Float64, length(keys(diag_y)) + offDiag_counter)
    n = 1
    for (i, val) in diag_y
        rows[n] = i
        columns[n] = i
        values[n] = val
        n += 1
    end
    for (i, ent) in offDiag_y
        for (j, val) in ent
            rows[n] = i
            columns[n] = j
            values[n] = val
            n += 1
        end
    end
    y = SparseArrays.sparse(rows, columns, values)
    i_inj = zeros(Float64, length(keys(inject_i)))
    for (i, val) in inject_i
        i_inj[i] = val
    end
    
    v = y\i_inj
    
    return solution_gmd(v, case)
end
