"variable: `v_dc[j]` for `j` in `gmd_bus`"
function variable_dc_voltage{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)    
    if bounded
        pm.var[:nw][n][:v_dc] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:gmd_bus])], basename="$(n)_v_dc",
          lowerbound = -Inf,
          upperbound = Inf,
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_bus], i, "v_dc_start")
        )  
    else
        pm.var[:nw][n][:v_dc] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:gmd_bus])], basename="$(n)_v_dc",
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_bus], i, "v_dc_start")
        )
    end    
#    pm.var[:nw][n][:v_dc] = @variable(pm.model, v_dc[i in keys(pm.ref[:nw][n][:gmd_bus])], start = PMs.getstart(pm.ref[:nw][n][:gmd_bus], i, "v_dc_start"))
end

"variable: `v_dc[j]` for `j` in `gmd_bus`"
function variable_dc_voltage_on_off{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)    
    variable_dc_voltage(pm,n;bounded=bounded)
    if bounded
        pm.var[:nw][n][:v_dc_diff] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:gmd_branch])], basename="$(n)_v_dc_diff",
          lowerbound = -calc_max_dc_voltage_difference(pm, i, n),
          upperbound = calc_max_dc_voltage_difference(pm, i, n),
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_branch], i, "v_dc_start_diff")
        )  
    else
        pm.var[:nw][n][:v_dc_diff] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:gmd_branch])], basename="$(n)_v_dc_diff",
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_branch], i, "v_dc_start_diff")
        )
    end
    
    # McCormick variable
    pm.var[:nw][n][:vz] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:gmd_branch])], basename="$(n)_vz",
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_branch], i, "v_vz_start")
    )
    
            
end



"variable: `i_dc_mag[j]` for `j` in `branch`"
function variable_dc_current_mag{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:i_dc_mag] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:branch])], basename="$(n)_i_dc_mag",
          lowerbound = 0,
          upperbound = calc_dc_mag_max(pm,i,n),
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_start")
        )  
    else
        pm.var[:nw][n][:i_dc_mag] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:branch])], basename="$(n)_i_dc_mag",
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_start")
        )
    end    
        
    #pm.var[:nw][n][:i_dc_mag] = @variable(pm.model, i_dc_mag[i in keys(pm.ref[:nw][n][:branch])], start = PMs.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_start"))
end


"variable: `i_dc_mag_sqr[j]` for `j` in `branch`"
function variable_dc_current_mag_sqr{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:i_dc_mag_sqr] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:branch])], basename="$(n)_i_dc_mag_sqr",
          lowerbound = 0,
          upperbound = calc_dc_mag_max(pm,i,n)^2,
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_sqr_start")
        )  
    else
        pm.var[:nw][n][:i_dc_mag_sqr] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:branch])], basename="$(n)_i_dc_mag_sqr",
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_sqr_start")
        )
    end    
        
    #pm.var[:nw][n][:i_dc_mag] = @variable(pm.model, i_dc_mag[i in keys(pm.ref[:nw][n][:branch])], start = PMs.getstart(pm.ref[:nw][n][:branch], i, "i_dc_mag_start"))
end

"variable: `dc[j]` for `j` in `gmd_branch`"
function variable_dc_line_flow{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:dc] = @variable(pm.model, 
          [(l,i,j) in pm.ref[:nw][n][:gmd_arcs]], basename="$(n)_dc",
          lowerbound = -Inf,
          upperbound = Inf,
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_branch], i, "dc_start")
        )  
    else
        pm.var[:nw][n][:dc] = @variable(pm.model, 
          [(l,i,j) in pm.ref[:nw][n][:gmd_arcs]], basename="$(n)_dc",
          start = PowerModels.getstart(pm.ref[:nw][n][:gmd_branch], i, "dc_start")
        )
    end    
  
    #pm.var[:nw][n][:dc] = @variable(pm.model, dc[(l,i,j) in pm.ref[:nw][n][:gmd_arcs]], start = PMs.getstart(pm.ref[:nw][n][:gmd_branch], l, "dc_start"))

    dc_expr = Dict([((l,i,j), -1.0*pm.var[:nw][n][:dc][(l,i,j)]) for (l,i,j) in pm.ref[:nw][n][:gmd_arcs_from]])
    dc_expr = merge(dc_expr, Dict([((l,j,i), 1.0*pm.var[:nw][n][:dc][(l,i,j)]) for (l,i,j) in pm.ref[:nw][n][:gmd_arcs_from]]))

    if !haskey(pm.model.ext, :nw)
        pm.model.ext[:nw] = Dict()  
    end  

    if !haskey(pm.model.ext[:nw], n)
        pm.model.ext[:nw][n] = Dict()  
    end  
              
    pm.model.ext[:nw][n][:dc_expr] = dc_expr
end

"variable: `qloss[j]` for `j` in `arcs`"
function variable_qloss{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    if bounded
       pm.var[:nw][n][:qloss] = @variable(pm.model, 
          [(l,i,j) in pm.ref[:nw][n][:arcs]], basename="$(n)_qloss",
          lowerbound = 0.0,
          upperbound = Inf,
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "qloss_start")
        )  
    else
        pm.var[:nw][n][:qloss] = @variable(pm.model, 
          [(l,i,j) in pm.ref[:nw][n][:arcs]], basename="$(n)_qloss",
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "qloss_start")
        )
    end   
    #pm.var[:nw][n][:qloss] = @variable(pm.model, qloss[(l,i,j) in pm.ref[:nw][n][:arcs]], start = PMs.getstart(pm.ref[:nw][n][:branch], l, "qloss_start"))
end

""
function variable_demand_factor{T}(pm::GenericPowerModel{T},n::Int=pm.cnw)
    pm.var[:nw][n][:z_demand] = @variable(pm.model, 0 <= z_demand[i in keys(pm.ref[:nw][n][:bus])] <= 1, start = PMs.getstart(pm.ref[:nw][n][:bus], i, "z_demand_start", 1.0))
end

""
function variable_shunt_factor{T}(pm::GenericPowerModel{T},n::Int=pm.cnw)
    pm.var[:nw][n][:z_shunt] = @variable(pm.model, 0 <= z_shunt[i in keys(pm.ref[:nw][n][:bus])] <= 1, start = PMs.getstart(pm.ref[:nw][n][:bus], i, "z_shunt_nstart", 1.0))
end


"variable: `pd[j]` for `j` in `bus`"
function variable_active_load(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:pd] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:bus])], basename="$(n)_pd",
            lowerbound = min(0,pm.ref[:nw][n][:bus][i]["pd"]),
            upperbound = max(0,pm.ref[:nw][n][:bus][i]["pd"]),
            start = PowerModels.getstart(pm.ref[:nw][n][:bus], i, "pd_start")
        )
    else
        pm.var[:nw][n][:pd] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:bus])], basename="$(n)_pd",
            start = PowerModels.getstart(pm.ref[:nw][n][:bus], i, "pd_start")
        )
    end
end

"variable: `qd[j]` for `j` in `bus`"
function variable_reactive_load(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:qd] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:bus])], basename="$(n)_qd",
            lowerbound = min(0,pm.ref[:nw][n][:bus][i]["qd"]),
            upperbound = max(0,pm.ref[:nw][n][:bus][i]["qd"]),
            start = PowerModels.getstart(pm.ref[:nw][n][:bus], i, "qd_start")
        )
    else
        pm.var[:nw][n][:qd] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:bus])], basename="$(n)_qd",
            start = PowerModels.getstart(pm.ref[:nw][n][:bus], i, "qd_start")
        )
    end
end

"generates variables for both `active` and `reactive` load"
function variable_load(pm::GenericPowerModel, n::Int=pm.cnw; kwargs...)
    variable_active_load(pm, n; kwargs...)
    variable_reactive_load(pm, n; kwargs...)
end

"variable: `i_ac_mag[j]` for `j` in `branch'"
function variable_ac_current_mag{T}(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:i_ac_mag] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:branch])], basename="$(n)_i_ac_mag",
          lowerbound = 0,
          upperbound = calc_ac_mag_max(pm, i, n),
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "i_ac_mag_start")
        )  
    else
        pm.var[:nw][n][:i_ac_mag] = @variable(pm.model, 
          [i in keys(pm.ref[:nw][n][:branch])], basename="$(n)_i_ac_mag",
          start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "i_ac_mag_start")
        )
    end
end

"variable: `iv[j]` for `j` in `arcs`"
function variable_iv{T}(pm::GenericPowerModel{T},n::Int=pm.cnw)
    pm.var[:nw][n][:iv] = @variable(pm.model, 
        [(l,i,j) in pm.ref[:nw][n][:arcs]], basename="$(n)_iv",
        start = PowerModels.getstart(pm.ref[:nw][n][:branch], i, "iv_start")
    )
end

"variable: `0 <= gen_z[i] <= 1` for `i` in `generator`s"
function variable_gen_indicator(pm::GenericPowerModel, n::Int=pm.cnw)
    pm.var[:nw][n][:gen_z] = @variable(pm.model, 
        [i in keys(pm.ref[:nw][n][:gen])], basename="$(n)_gen_z",
        lowerbound = 0,
        upperbound = 1,
        category = :Int,
        start = PowerModels.getstart(pm.ref[:nw][n][:gen], i, "gen_z_start", 1.0)
    )
end
