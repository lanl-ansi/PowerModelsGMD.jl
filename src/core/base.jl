#####################################
# Collection of Universal Functions #
#####################################


"FUNCTION: check gmd branch parent status"
function check_gmd_branch_parent_status(ref, i, gmd_branch)

    parent_id = gmd_branch["parent_index"]
    status = false

    if parent_id in keys(ref[:branch])
        parent_branch = ref[:branch][parent_id]
        status = parent_branch["br_status"] == 1 && gmd_branch["f_bus"] in keys(ref[:gmd_bus]) && gmd_branch["t_bus"] in keys(ref[:gmd_bus])
    end

    return status

end

