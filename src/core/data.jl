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
