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
