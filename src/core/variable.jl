
""
function variable_dc_voltage{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:v_dc] = @variable(pm.model, v_dc[i in keys(pm.ref[:nw][n][:gmd_bus])], start = PMs.getstart(pm.ref[:nw][n][:gmd_bus], i, "v_dc_start"))
end
""
function variable_dc_current_mag{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:i_dc_mag] = @variable(pm.model, i_dc_mag[i in keys(pm.ref[:nw][n][:branch])], start = PMs.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_start"))
end

""
function variable_dc_line_flow{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:dc] = @variable(pm.model, dc[(l,i,j) in pm.ref[:nw][n][:gmd_arcs]], start = PMs.getstart(pm.ref[:nw][n][:gmd_branch], l, "dc_start"))

    dc_expr = Dict([((l,i,j), -1.0*dc[(l,i,j)]) for (l,i,j) in pm.ref[:nw][n][:gmd_arcs_from]])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*dc[(l,i,j)]) for (l,i,j) in pm.ref[:nw][n][:gmd_arcs_from]]))

    pm.model.ext[:dc_expr] = dc_expr
end

# define qloss for each branch, it flows into the "to" side of the branch
function variable_qloss{T}(pm::GenericPowerModel{T},n::Int=pm.cnw)
    # TODO: if you want to define qloss only on the "to" side you should define on the set keys(pm.ref[:branch]) or :arcs_to
    pm.var[:nw][n][:qloss] = @variable(pm.model, qloss[(l,i,j) in pm.ref[:nw][n][:arcs]], start = PMs.getstart(pm.ref[:nw][n][:branch], l, "qloss_start"))
end

""
function variable_demand_factor{T}(pm::GenericPowerModel{T},n::Int=pm.cnw)
    pm.var[:nw][n][:z_demand] = @variable(pm.model, 0 <= z_demand[i in keys(pm.ref[:nw][n][:bus])] <= 1, start = PMs.getstart(pm.ref[:nw][n][:bus], i, "z_demand_start", 1.0))
end

""
function variable_shunt_factor{T}(pm::GenericPowerModel{T},n::Int=pm.cnw)
    pm.var[:nw][n][:z_shunt] = @variable(pm.model, 0 <= z_shunt[i in keys(pm.ref[:nw][n][:bus])] <= 1, start = PMs.getstart(pm.ref[:nw][n][:bus], i, "z_shunt_nstart", 1.0))
end
