##################
# Data Functions #
##################

# Tools for working with a PowerModelsGMD data dict structure.


# ===   CALCULATIONS FOR VOLTAGE VARIABLES   === #


"FUNCTION: calculate the minimum dc voltage at a gmd bus "
function calc_min_dc_voltage(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return -1e6
end


"FUNCTION: calculate the maximum dc voltage at a gmd bus "
function calc_max_dc_voltage(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return 1e6
end


"FUNCTION: calculate the maximum dc voltage difference between gmd buses"
function calc_max_dc_voltage_difference(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return 1e6
end

# ===   CALCULATIONS FOR CURRENT VARIABLES   === #


"FUNCTION: calculate the minimum absolute value AC current on a branch"
function calc_ac_mag_min(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return 0
end


"FUNCTION: calculate the maximum absolute value AC current on a branch"
function calc_ac_mag_max(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = _PM.ref(pm, nw, :bus, branch["f_bus"])
    t_bus = _PM.ref(pm, nw, :bus, branch["t_bus"])

    ac_max = branch["rate_a"] * branch["tap"] / min(f_bus["vmin"], t_bus["vmin"])
    return ac_max

end


"FUNCTION: calculate dc current magnitude"
function calc_dc_current_mag(branch, case, solution)

    if branch["transformer"] == 0
        return calc_dc_current_mag_line(branch, case, solution)

    elseif !("config" in keys(branch))
        k = branch["index"]
        Memento.warn(_LOGGER, "No winding configuration for transformer $k, treating as line")
        return calc_dc_current_mag_line(branch, case, solution)

    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        return calc_dc_current_mag_grounded_xf(branch, case, solution)

    elseif branch["config"] in ["delta-gwye", "gwye-delta"]
        return calc_dc_current_mag_gwye_delta_xf(branch, case, solution)

    elseif branch["config"] == "gwye-gwye"
        return calc_dc_current_mag_gwye_gwye_xf(branch, case, solution)

    elseif branch["config"] == "gwye-gwye-auto"
        return calc_dc_current_mag_gwye_gwye_auto_xf(branch, case, solution)

    elseif branch["config"] in ["three-winding", "gwye-gwye-delta", "gwye-gwye-gwye", "gywe-delta-delta"]
         return calc_dc_current_mag_3w_xf(branch, case, solution)

    end

    return 0.0
end


"FUNCTION: dc current on normal lines"
function calc_dc_current_mag_line(branch, case, solution)

    return 0.0

end


"FUNCTION: dc current on grounded transformers"
function calc_dc_current_mag_grounded_xf(branch, case, solution)

    return 0.0

end


"FUNCTION: dc current on ungrounded gwye-delta transformers"
function calc_dc_current_mag_gwye_delta_xf(branch, case, solution)

    k   = branch["index"]
    khi = branch["gmd_br_hi"]

    if khi == -1 || khi === nothing
        Memento.warn(_LOGGER, "khi for gwye-delta transformer $k is -1")
        return 0.0
    else
        return abs(solution["gmd_branch"]["$khi"]["gmd_idc"])
    end

end


"FUNCTION: dc current on ungrounded gwye-gwye transformers"
function calc_dc_current_mag_gwye_gwye_xf(branch, case, solution)

    k = branch["index"]
    khi = branch["gmd_br_hi"]
    klo = branch["gmd_br_lo"]

    ihi = 0.0
    ilo = 0.0

    if khi == -1 || khi === nothing
        Memento.warn(_LOGGER, "khi for gwye-gwye transformer $k is -1")
    else
        ihi = solution["gmd_branch"]["$khi"]["gmd_idc"]
    end

    if klo == -1 || klo === nothing
        Memento.warn(_LOGGER, "klo for gwye-gwye transformer $k is -1")
    else
        ilo = solution["gmd_branch"]["$klo"]["gmd_idc"]
    end

    jfr = branch["f_bus"]
    jto = branch["t_bus"]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    a = vhi/vlo

    return abs( (a * ihi + ilo) / a )

end


"FUNCTION: dc current on ungrounded gwye-gwye auto transformers"
function calc_dc_current_mag_gwye_gwye_auto_xf(branch, case, solution)

    k = branch["index"]
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]

    is = 0.0
    ic = 0.0

    if ks == -1 || ks === nothing
        Memento.warn(_LOGGER, "ks for autotransformer $k is -1")
    else
        is = solution["gmd_branch"]["$ks"]["gmd_idc"]
    end

    if kc == -1 || kc === nothing
        Memento.warn(_LOGGER, "kc for autotransformer $k is -1")
    else
        ic = solution["gmd_branch"]["$kc"]["gmd_idc"]
    end

    ihi = -is
    ilo = ic + is

    jfr = branch["f_bus"]
    jto = branch["t_bus"]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    a = vhi/vlo

    return branch["ieff"] = abs( (a * is + ic) / (a + 1.0) )
end


"FUNCTION: dc current on three-winding transformers"
function calc_dc_current_mag_3w_xf(branch, case, solution)

    k = branch["index"]
    khi = branch["gmd_br_hi"]
    klo = branch["gmd_br_lo"]
    kter = branch["gmd_br_ter"]

    ihi = 0.0
    ilo = 0.0
    iter = 0.0

    if khi == -1 || khi === nothing
        Memento.warn(_LOGGER, "khi for three-winding transformer $k is -1")
    else
        ihi = solution["gmd_branch"]["$khi"]["gmd_idc"]
    end

    if klo == -1 || klo === nothing
        Memento.warn(_LOGGER, "klo for three-winding transformer $k is -1")
    else
        ilo = solution["gmd_branch"]["$klo"]["gmd_idc"]
    end

    if kter == -1 || kter === nothing
        Memento.warn(_LOGGER, "kter for three-winding transformer $k is -1")
    else
        iter = solution["gmd_branch"]["$ter"]["gmd_idc"]
    end

    jfr = branch["source_id"][2]
    jto = branch["source_id"][3]
    jter = branch["source_id"][4]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    vter = case["bus"]["$jter"]["base_kv"]
    a = vhi/vlo
    b = vhi/vter

    # Boteler 2016, Equation (51)
    return abs( ihi + ilo / a + iter / b )

end


"FUNCTION: calculate the maximum DC current on a branch"
function calc_dc_mag_max(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)

    ac_max = -Inf
    for l in _PM.ids(pm, nw, :branch)
        ac_max = max(calc_ac_mag_max(pm, l, nw=nw), ac_max)
    end

    ibase = calc_branch_ibase(pm, i, nw=nw)
    dc_mag_max = 2 * ac_max * ibase

    if dc_mag_max < 0
        Memento.warn(_LOGGER, "DC current max for branch $i has been calculated as < 0. This will cause many things to break")
    end

    return dc_mag_max

end


"FUNCTION: calculate the ibase for a branch"
function calc_branch_ibase(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)
    bus = _PM.ref(pm, nw, :bus, branch["hi_bus"])

    return branch["baseMVA"] * 1000.0 * sqrt(2.0) / (bus["base_kv"] * sqrt(3.0))

end


# ===   CALCULATIONS FOR QLOSS VARIABLES   === #


"FUNCTION: calculate qloss"
function calc_qloss(branch, case::Dict{String,Any}, solution::Dict{String,Any})

    @assert !_IM.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    k = "$(branch["index"])"
    i = "$(branch["hi_bus"])"
    j = "$(branch["lo_bus"])"

    bus = case["bus"][i]

    br_soln = solution["branch"][k]
    i_dc_mag = abs(br_soln["gmd_idc"])

    if "gmd_k" in keys(branch)

        ibase = branch["baseMVA"] * 1000.0 * sqrt(2.0) / (bus["base_kv"] * sqrt(3.0))
        K = branch["gmd_k"] * data["baseMVA"]/ibase
            # K is per phase

        return K * i_dc_mag / (3.0 * branch["baseMVA"])

    end

    return 0.0

end



# ===   GENERAL SETTINGS AND FUNCTIONS   === #


"FUNCTION: apply function"
function _apply_func!(data::Dict{String,Any}, key::String, func)

    if haskey(data, key)
        data[key] = func(data[key])
    end

end


"FUNCTION: apply a JSON file or a dictionary of mods"
function apply_mods!(net, modsfile::AbstractString)

    if modsfile !== nothing

        io = open(modsfile)
        mods = JSON.parse(io)
        close(io)

        apply_mods!(net, mods)

    end

end


"FUNCTION: apply a dictionary of mods"
function apply_mods!(net, mods::AbstractDict{String,Any})

    for (otype, objs) in mods

        if !isa(objs, Dict)
            continue
        end

        if !(otype in keys(net))
            net[otype] = Dict{String,Any}()
        end

    end

    net_by_sid = create_sid_map(net)

    if "mods" in keys(mods)
        mods = mods["mods"]
    elseif "modifications" in keys(mods)
        mods = mods["modifications"]
    end

    for (otype, objs) in mods

        if !isa(objs, Dict)
            continue
        end

        if !(otype in keys(net))
            net[otype] = Dict{String,Any}()
        end

        for (okey, obj) in objs

            key = okey

            if ("source_id" in keys(obj)) && (obj["source_id"] in keys(net_by_sid[otype]))
                key = net_by_sid[otype][obj["source_id"]]
            elseif otype == "branch"
                continue
            end

            if !(key in keys(net[otype]))
                net[otype][key] = Dict{String,Any}()
            end

            for (fname, fval) in obj
                net[otype][key][fname] = fval
            end

        end
    end

end


"FUNCTION: correct parent branches for gmd branches after applying mods"
function fix_gmd_indices!(net)

    branch_map = Dict(map(x -> x["source_id"] => x["index"], values(net["branch"])))

    for (i,gbr) in net["gmd_branch"]

        k = gbr["parent_source_id"]

        if k in keys(branch_map)
            gbr["parent_index"] = branch_map[k]
        end

    end

end


"FUNCTION: index mods dictionary by source id"
function create_sid_map(net)

    net_by_sid = Dict()

    for (otype, objs) in net

        if !isa(objs, Dict)
            continue
        end

        if !(otype in keys(net_by_sid))
            net_by_sid[otype] = Dict()
        end

        for (okey, obj) in objs
            if "source_id" in keys(obj)
                net_by_sid[otype][obj["source_id"]] = okey
            end
        end

    end

    return net_by_sid

end


# ===   UNIT CONVERSION FUNCTIONS   === #


"FUNCTION: convert effective GIC to PowerWorld to-phase convention"
function adjust_gmd_phasing!(result)

    gmd_buses = result["solution"]["gmd_bus"]
    for bus in values(gmd_buses)
        bus["gmd_vdc"] = bus["gmd_vdc"]
    end

    gmd_branches = result["solution"]["gmd_branch"]
    for branch in values(gmd_branches)
        branch["gmd_idc"] = branch["gmd_idc"] / 3
    end

    return result

end


"FUNCTION: add GMD data"
function add_gmd_data!(case::Dict{String,Any}, solution::Dict{String,<:Any}; decoupled=false)

    @assert !_IM.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    for (k, bus) in case["bus"]

        j = "$(bus["gmd_bus"])"
        bus["gmd_vdc"] = solution["gmd_bus"][j]["gmd_vdc"]

    end

    for (i, br) in case["branch"]

        br_soln = solution["branch"][i]

        if br["type"] == "line"
            k = "$(br["gmd_br"])"
            br["gmd_idc"] = solution["gmd_branch"][k]["gmd_idc"]/3.0

        else
            if decoupled  # TODO: add calculations from constraint_dc_current_mag

                k = br["dc_brid_hi"]
                    # high-side gmd branch
                br["gmd_idc"] = 0.0
                br["ieff"] = abs(br["gmd_idc"])
                br["qloss"] = calc_qloss(br, case, solution)

            else

                br["ieff"] = br_soln["gmd_idc_mag"]
                br["qloss"] = br_soln["gmd_qloss"]

            end

            if br["f_bus"] == br["hi_bus"]
                br_soln["qf"] += br_soln["gmd_qloss"]
            else
                br_soln["qt"] += br_soln["gmd_qloss"]
            end

        end

        br["qf"] = br_soln["qf"]
        br["qt"] = br_soln["qt"]
    end

end


"FUNCTION: make GMD mixed units"
function make_gmd_mixed_units!(solution::Dict{String,Any}, mva_base::Real)

    rescale = x -> (x * mva_base)
    rescale_dual = x -> (x / mva_base)

    if haskey(solution, "bus")

        for (i, bus) in solution["bus"]
            _apply_func!(bus, "pd", rescale)
            _apply_func!(bus, "qd", rescale)
            _apply_func!(bus, "gs", rescale)
            _apply_func!(bus, "bs", rescale)
            _apply_func!(bus, "va", rad2deg)
            _apply_func!(bus, "lam_kcl_r", rescale_dual)
            _apply_func!(bus, "lam_kcl_i", rescale_dual)
        end

    end

    branches = []
    if haskey(solution, "branch")
        append!(branches, values(solution["branch"]))
    end
    if haskey(solution, "ne_branch")
        append!(branches, values(solution["ne_branch"]))
    end
    for branch in branches
        _apply_func!(branch, "rate_a", rescale)
        _apply_func!(branch, "rate_b", rescale)
        _apply_func!(branch, "rate_c", rescale)
        _apply_func!(branch, "shift", rad2deg)
        _apply_func!(branch, "angmax", rad2deg)
        _apply_func!(branch, "angmin", rad2deg)
        _apply_func!(branch, "pf", rescale)
        _apply_func!(branch, "pt", rescale)
        _apply_func!(branch, "qf", rescale)
        _apply_func!(branch, "qt", rescale)
        _apply_func!(branch, "mu_sm_fr", rescale_dual)
        _apply_func!(branch, "mu_sm_to", rescale_dual)
    end

    dclines =[]
    if haskey(solution, "dcline")
        append!(dclines, values(solution["dcline"]))
    end
    for dcline in dclines
        _apply_func!(dcline, "loss0", rescale)
        _apply_func!(dcline, "pf", rescale)
        _apply_func!(dcline, "pt", rescale)
        _apply_func!(dcline, "qf", rescale)
        _apply_func!(dcline, "qt", rescale)
        _apply_func!(dcline, "pmaxt", rescale)
        _apply_func!(dcline, "pmint", rescale)
        _apply_func!(dcline, "pmaxf", rescale)
        _apply_func!(dcline, "pminf", rescale)
        _apply_func!(dcline, "qmaxt", rescale)
        _apply_func!(dcline, "qmint", rescale)
        _apply_func!(dcline, "qmaxf", rescale)
        _apply_func!(dcline, "qminf", rescale)
    end

    if haskey(solution, "gen")
        for (i, gen) in solution["gen"]
            _apply_func!(gen, "pg", rescale)
            _apply_func!(gen, "qg", rescale)
            _apply_func!(gen, "pmax", rescale)
            _apply_func!(gen, "pmin", rescale)
            _apply_func!(gen, "qmax", rescale)
            _apply_func!(gen, "qmin", rescale)
            if "model" in keys(gen) && "cost" in keys(gen)
                if gen["model"] != 2
                    Memento.warn(_LOGGER, "Skipping generator cost model of type other than 2")
                else
                    degree = length(gen["cost"])
                    for (i, item) in enumerate(gen["cost"])
                        gen["cost"][i] = item / (mva_base^(degree-i))
                    end
                end
            end
        end
    end

end


"FUNCTION: make GMD per unit"
function make_gmd_per_unit!(data::Dict{String,<:Any})

    @assert !_IM.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    if !haskey(data, "GMDperUnit") || data["GMDperUnit"] == false

        make_gmd_per_unit(data["baseMVA"], data)
        data["GMDperUnit"] = true

    end

end


"FUNCTION: make GMD per unit"
function make_gmd_per_unit!(mva_base::Number, data::Dict{String,<:Any})

    @assert !_IM.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    for bus in data["bus"]

        zb = bus["base_kv"]^2/mva_base
        bus["gmd_gs"] *= zb

    end

end
