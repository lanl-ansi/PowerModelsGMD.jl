""
function add_gmd_data(data)

    for (k,bus) in data["bus"]
        j = "$(bus["gmd_bus"])"
        bus["gmd_vdc"] = data["gmd_bus"][j]["gmd_vdc"]
    end

    for (k,sub) in data["sub"]
        i = "$(sub["gmd_bus"])"
        sub["gmd_vdc"] = data["gmd_bus"][i]["gmd_vdc"]
    end

    for (k,br) in data["branch"]
        if br["hi_bus"] == br["f_bus"]
            br["qf"] += br["gmd_qloss"]
        else
            br["qt"] += br["gmd_qloss"]
        end

        br["ieff"] = br["gmd_idc_mag"]
        br["qloss_from"] = br["gmd_qloss"]

        if br["type"] == "line"
            i = "$(br["gmd_br"])"
            br["gmd_idc"] = data["gmd_branch"][i]["gmd_idc"]
        end
    end

end


# data to be concerned with:
# 1. shunt impedances aij
# 2. equivalent currents Jij?
# 3. transformer loss factor Ki? NO, UNITLESSS
# 4. electric field magnitude?
gmd_not_pu = Set(["gmd_gs","gmd_e_field_mag"])
gmd_not_rad = Set(["gmd_e_field_dir"])

function make_gmd_per_unit!(data::Dict{AbstractString,Any})
    if !haskey(data, "GMDperUnit") || data["GMDperUnit"] == false
        make_gmd_per_unit!(data["baseMVA"], data)
        data["GMDperUnit"] = true
    end
end

function make_gmd_per_unit!(mva_base::Number, data::Dict{AbstractString,Any})
    # vb = 1e3*data["bus"][1]["base_kv"] # not sure h
    # data["gmd_e_field_mag"] /= vb
    # data["gmd_e_field_dir"] *= pi/180.0

    for bus in data["bus"]
        zb = bus["base_kv"]^2/mva_base
        #@printf "bus [%d] zb: %f a(pu): %f\n" bus["index"] zb bus["gmd_gs"]
        bus["gmd_gs"] *= zb
        # @printf " -> a(pu): %f\n" bus["gmd_gs"]
    end
end

"Computes the maximum AC current on a branch"
function calc_ac_mag_max(pm::GenericPowerModel, i, n::Int=pm.cnw)
    # ac_mag_max
    branch = pm.ref[:nw][n][:branch][i]  
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    ac_max = branch["rate_a"]*branch["tap"] / min(pm.ref[:nw][n][:bus][f_bus]["vmin"], pm.ref[:nw][n][:bus][t_bus]["vmin"])
          
          
   # println(i, " " , ac_max, " ", branch["rate_a"], " ", pm.ref[:nw][n][:bus][f_bus]["vmin"], " ", pm.ref[:nw][n][:bus][t_bus]["vmin"])
      
      
    return ac_max
end

"Computes the maximum DC current on a branch"
function calc_dc_mag_max{T}(pm::GenericPowerModel{T}, i, n::Int=pm.cnw)
    branch = pm.ref[:nw][n][:branch][i]  
      
    ac_max = -Inf
    for i in keys(pm.ref[:nw][n][:branch])  
        ac_max = max(calc_ac_mag_max(pm, i, n),ac_max)
    end
    ibase = calc_branch_ibase(pm,i,n)
       #println(i , " ", 2 * ac_max * ibase, " ", ibase, " ", ac_max)  
    
    
    return 2 * ac_max * ibase #   branch["ibase"]
end

"Computes the ibase for a branch"
function calc_branch_ibase{T}(pm::GenericPowerModel{T}, i, n::Int=pm.cnw)
    branch = pm.ref[:nw][n][:branch][i]
    hi = branch["hi_bus"]
    bus = pm.ref[:nw][n][:bus][hi]
    return branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
end

"Computes a load shed cost"
function calc_load_shed_cost{T}(pm::GenericPowerModel{T}, nws=[pm.cnw])
    max_cost = 0
    for n in nws
        for (i,gen) in  pm.ref[:nw][n][:gen]
            if gen["pmax"] != 0
                cost_mw = (gen["cost"][1]*gen["pmax"]^2 + gen["cost"][2]*gen["pmax"]) / gen["pmax"] + gen["cost"][3]
                max_cost = max(max_cost, cost_mw)
            end    
        end
    end
    return max_cost * 2.0
end

"Computes the thermal coeffieicents for a branch"
function calc_branch_thermal_coeff{T}(pm::GenericPowerModel{T}, i, n::Int=pm.cnw)
    branch = pm.ref[:nw][n][:branch][i]
    buses = pm.ref[:nw][n][:bus]

    if !(branch["type"] == "xf")
        return NaN
    end    
      
    x0 = pm.data["thermal_cap_x0"]./calc_branch_ibase(pm,i,n)  #branch["ibase"]
    y0 = pm.data["thermal_cap_y0"]./100  # convert to %

    y = calc_ac_mag_max(pm,i,n) .* y0 # branch["ac_mag_max"] .* y0
    x = x0

    fit = poly_fit(x,y,2)
    fit = round(fit.*1e+5)./1e+5
    return fit
end

"Computes the maximum dc voltage difference between buses"
function calc_max_dc_voltage_difference{T}(pm::GenericPowerModel{T}, i, n::Int=pm.cnw)
    return 1e6 # TODO, actually formally calculate
end
