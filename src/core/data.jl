export make_gmd_mixed_units, adjust_gmd_qloss, top_oil_rise, hotspot_rise, update_top_oil_rise, update_hotspot_rise


# ===   GENERAL FUNCTIONS   === #


"FUNCTION: calculate Qloss"
function calculate_qloss(branch, case, solution)

    @assert !InfrastructureModels.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    k = "$(branch["index"])"
    i = "$(branch["hi_bus"])"
    j = "$(branch["lo_bus"])"

    br_soln = solution["branch"][k]
    bus = case["bus"][i]
    i_dc_mag = abs(br_soln["gmd_idc"])

    if "gmd_k" in keys(branch)

        ibase = branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
        K = branch["gmd_k"]*data["baseMVA"]/ibase

        # K is per phase
        return K*i_dc_mag/(3.0*branch["baseMVA"])
    end

    return 0.0

end


"FUNCTION: compute maximum AC current on a branch"
function calc_ac_mag_max(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = _PM.ref(pm, nw, :bus, branch["f_bus"])
    t_bus = _PM.ref(pm, nw, :bus, branch["t_bus"])
    ac_max = branch["rate_a"]*branch["tap"] / min(f_bus["vmin"], t_bus["vmin"])

    return ac_max

end


"FUNCTION: compute the maximum DC current on a branch"
function calc_dc_mag_max(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    
    branch = _PM.ref(pm, nw, :branch, i)

    ac_max = -Inf
    for l in _PM.ids(pm, nw, :branch)
        ac_max = max(calc_ac_mag_max(pm, l, nw=nw), ac_max)
    end
    ibase = calc_branch_ibase(pm, i, nw=nw)

    return 2 * ac_max * ibase  # branch["ibase"]

end


"FUNCTION: compute the ibase for a branch"
function calc_branch_ibase(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)
    bus = _PM.ref(pm, nw, :bus, branch["hi_bus"])
    return branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))

end


"FUNCTION: compute the thermal coeffieicents for a branch"
function calc_branch_thermal_coeff(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)
    buses = _PM.ref(pm, nw, :bus)

    if !(branch["type"] == "xfmr" || branch["type"] == "xf" || branch["type"] == "transformer")
        return NaN
    end

    # TODO: FIX LATER!
    thermal_cap_x0 = pm.data["thermal_cap_x0"]
    # since provided values are in [per unit]...

    if isa(thermal_cap_x0, Dict)
        thermal_cap_x0 = []
        for (key, value) in sort(pm.data["thermal_cap_x0"]["1"])
            if key == "index" || key == "source_id"
                continue
            end
            push!(thermal_cap_x0, value)
        end
    end

    thermal_cap_y0 = pm.data["thermal_cap_y0"]
    if isa(thermal_cap_y0, Dict)
        thermal_cap_y0 = []
        for (key, value) in sort(pm.data["thermal_cap_y0"]["1"])
            if key == "index" || key == "source_id"
                continue
            end
            push!(thermal_cap_y0, value)
        end
    end

    x0 = thermal_cap_x0./calc_branch_ibase(pm, i, nw=nw)  #branch["ibase"]
    y0 = thermal_cap_y0./100   # convert to [%]

    y = calc_ac_mag_max(pm, i, nw=nw) .* y0  # branch["ac_mag_max"] .* y0
    x = x0

    fit = poly_fit(x, y, 2)
    fit = round.(fit.*1e+5)./1e+5
    return fit

end


"FUNCTION: POLYFIT"
function poly_fit(x, y, n)

    # Fits a polynomial of degree `n` through a set of points.
    # Taken from CurveFit.jl by Paul Jabardo
    # https://github.com/pjabardo/CurveFit.jl/blob/master/src/linfit.jl
    # Simple algorithm, doesn't use orthogonal polynomials or any such thing
    # and therefore unconditioned matrices are possible. Use it only for low
    # degree polynomials.
    # This function returns a the coefficients of the polynomial.

    nx = length(x)
    A = zeros(eltype(x), nx, n+1)
    A[:,1] .= 1.0
    for i in 1:n
        for k in 1:nx
            A[k,i+1] = A[k,i] * x[k]
        end
    end
    A\y

end


"FUNCTION: computes the maximum dc voltage difference between buses"
function calc_max_dc_voltage_difference(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    # TODO: actually formally calculate
    return 1e6
end


"FUNCTION: apply function"
function apply_func(data::Dict{String,Any}, key::String, func)

    if haskey(data, key)
        data[key] = func(data[key])
    end

end


"FUNCTION: compute the maximum DC voltage at a gmd bus "
function calc_max_dc_voltage(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return Inf
end


"FUNCTION: compute the maximum DC voltage at a gmd bus "
function calc_min_dc_voltage(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return -Inf
end


"FUNCTION: compute the minimum absolute value AC current on a branch"
function calc_ac_mag_min(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)
    return 0
end


"FUNCTION: computing the dc current magnitude"
function dc_current_mag(branch, case, solution)
    k = branch["index"]

    branch["ieff"] = 0.0
    if branch["transformer"] == 0 
        dc_current_mag_line(branch, case, solution)
    elseif !("config" in keys(branch))
        Memento.warn(_LOGGER, "No winding configuration for transformer $k, treating as line")
        dc_current_mag_line(branch, case, solution)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        println("UNGROUNDED CONFIGURATION. Ieff is constrained to ZERO.")
        dc_current_mag_grounded_xf(branch, case, solution)

    elseif branch["config"] in ["delta-gwye", "gwye-delta"]
        dc_current_mag_gwye_delta_xf(branch, case, solution)

    elseif branch["config"] == "gwye-gwye"
        dc_current_mag_gwye_gwye_xf(branch, case, solution)

    elseif branch["config"] == "gwye-gwye-auto"
        dc_current_mag_gwye_gwye_auto_xf(branch, case, solution)

    elseif branch["config"] == "three-winding"
        dc_current_mag_3w_xf(branch, case, solution)

    end

end

"CONSTRAINT: computing qloss assuming ac voltage is 1.0 pu"
function qloss_decoupled_vnom(case)
    for (_, bus) in case["bus"]
        bus["qloss"] = 0.0
    end

    for (k, branch) in case["branch"]
        # using hi/lo bus shouldn't be an issue because qloss is defined in arcs going in both directions

        if !("hi_bus" in keys(branch)) || !("lo_bus" in keys(branch)) || branch["hi_bus"] == -1 || branch["lo_bus"] == -1
            Memento.warn(_LOGGER, "Branch $k is missing hi bus/lo bus")
            return
        end

        i = branch["hi_bus"]
        j = branch["lo_bus"]

        bus = case["bus"]["$i"]

        if branch["br_status"] == 0 
            return
        end

        branch["gmd_qloss"] = 0.0

        if "gmd_k" in keys(branch)
            ibase = (1000.0 * sqrt(2.0) * case["baseMVA"]) / (bus["base_kv"] * sqrt(3.0))
            K = (branch["gmd_k"] * case["baseMVA"]) / (ibase)
            ieff = branch["ieff"]/3.0
            qloss = K * ieff
            branch["gmd_qloss"] = qloss
            bus["qloss"] += qloss/case["baseMVA"]
        end
    end


    for (_, bus) in case["bus"]
        if bus["qloss"] >= 1e-3
            n = length(case["load"])

            load = Dict{String, Any}()
            load["source_id"] = ["qloss", bus["index"]]
            load["load_bus"] = bus["index"]
            load["status"] = 1
            load["pd"] = 0
            load["qd"] = bus["qloss"]
            load["index"] = n + 1
            case["load"]["$(n + 1)"] = load
        end
    end
end

"FUNCTION: dc current on normal lines"
function dc_current_mag_line(branch, case, solution)
    branch["ieff"] = 0.0
end


"FUNCTION: dc current on grounded transformers"
function dc_current_mag_grounded_xf(branch, case, solution)
    branch["ieff"] = 0.0
end


"FUNCTION: dc current on ungrounded gwye-delta transformers"
function dc_current_mag_gwye_delta_xf(branch, case, solution)
    k = branch["index"]

    khi = branch["gmd_br_hi"]

    if khi == -1 || khi === nothing
        Memento.warn(_LOGGER, "khi for gwye-delta transformer $k is -1")
        branch["ieff"] = 0.0
    else
        branch["ieff"] = abs(solution["gmd_branch"]["$khi"]["gmd_idc"])
    end
end


"FUNCTION: dc current on ungrounded gwye-gwye transformers"
function dc_current_mag_gwye_gwye_xf(branch, case, solution)

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

    branch["ieff"] = abs((a*ihi + ilo)/a)

end


"FUNCTION: dc current on ungrounded gwye-gwye auto transformers"
function dc_current_mag_gwye_gwye_auto_xf(branch, case, solution)
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

    branch["ieff"] = abs((a*is + ic)/(a + 1.0))

end


"FUNCTION: dc current on three-winding transformers"
function dc_current_mag_3w_xf(branch, case, solution)

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

    jfr = branch["source_id"][1]
    jto = branch["source_id"][2]
    jter = branch["source_id"][3]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    vter = case["bus"]["$jter"]["base_kv"]
    a = vhi/vlo
    b = vhi/vter

    branch["ieff"] = abs(ihi + ilo/a + iter/b)  # Boteler 2016 => Eq. (51)

end




# ===   THERMAL MODEL FUNCTIONS   === #


"FUNCTION: calculate steady-state top-oil temperature rise"
function delta_topoilrise_ss(branch, result, base_mva)

    delta_topoilrise_ss = 0

    if (branch["type"] == "xfmr" || branch["type"] == "xf" || branch["type"] == "transformer")

        i = branch["index"]
        bs = result["solution"]["branch"]["$i"]
        p = bs["pf"]
        q = bs["qf"]
        S = sqrt(p^2 + q^2)
        K = S / (branch["rate_a"] * base_mva)

        # delta_topoilrise_ss = 1  # ==> STEP response
        delta_topoilrise_ss = branch["topoil_rated"] * K^2

    end

    branch["delta_topoilrise_ss"] = delta_topoilrise_ss

end


"FUNCTION: calculate top-oil temperature rise"
function delta_topoilrise(branch, result, base_mva, delta_t)

    delta_topoilrise_ss = branch["delta_topoilrise_ss"]
    delta_topoilrise = delta_topoilrise_ss

    if (("delta_topoilrise" in keys(branch)) && ("delta_topoilrise_ss" in keys(branch)))

        delta_topoilrise_prev = branch["delta_topoilrise"]
        delta_topoilrise_ss_prev = branch["delta_topoilrise_ss"] 

        tau = 2 * (branch["topoil_time_const"] * 60) / delta_t
        delta_topoilrise = (delta_topoilrise_ss + delta_topoilrise_ss_prev) / (1 + tau) - delta_topoilrise_prev * (1 - tau) / (1 + tau)

    else
        delta_topoilrise = 0
    end

    branch["delta_topoilrise"] = delta_topoilrise

end


"FUNCTION: update top-oil temperature rise in the network"
function update_topoilrise(branch, case)

    i = branch["index"]
    case["branch"]["$i"]["delta_topoilrise_ss"] = branch["delta_topoilrise_ss"]
    case["branch"]["$i"]["delta_topoilrise"] = branch["delta_topoilrise"]

end


"FUNCTION: calculate steady-state hotspot temperature rise"
function delta_hotspotrise_ss(branch, result)

    delta_hotspotrise_ss = 0

    Ie = branch["ieff"]
    delta_hotspotrise_ss = branch["hotspot_coeff"] * Ie

    branch["delta_hotspotrise_ss"] = delta_hotspotrise_ss

end


"FUNCTION: calculate hotspot temperature rise"
function delta_hotspotrise(branch, result, Ie_prev, delta_t)

    delta_hotspotrise = 0

    Ie = branch["ieff"]
    tau = 2 * branch["hotspot_rated"] / delta_t

    if Ie_prev === nothing
        delta_hotspotrise = branch["hotspot_coeff"] * Ie
    else
        delta_hotspotrise_prev = branch["delta_hotspotrise"]
        delta_hotspotrise = branch["hotspot_coeff"] * (Ie + Ie_prev) / (1 + tau) - delta_hotspotrise_prev * (1 - tau) / (1 + tau)
    end

    branch["delta_hotspotrise"] = delta_hotspotrise

end


"FUNCTION: update hotspot temperature rise in the network"
function update_hotspotrise(branch, case)

    i = branch["index"]
    case["branch"]["$i"]["delta_hotspotrise_ss"] = branch["delta_hotspotrise_ss"]
    case["branch"]["$i"]["delta_hotspotrise"] = branch["delta_hotspotrise"]

end



# ===   RESULT ADJUSTMENT FUNCTIONS   === #


"FUNCTION: convert effective GIC to PowerWorld to-phase convention"
function adjust_gmd_phasing(result)

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


"FUNCTION: adjust GMD qloss"
function adjust_gmd_qloss(case::Dict{String,Any}, solution::Dict{String,Any})

    for (i, br) in case["branch"]
        if !(i in keys(solution["branch"]))
            # branch is disabled, skip
            continue
        end

        br_soln = solution["branch"][i]

        if !("gmd_qloss" in keys(br_soln))
            continue
        end

        if br_soln["gmd_qloss"] === nothing
            continue
        end

        if !("hi_bus" in keys(br))
            continue
        end

        if  br["f_bus"] == br["hi_bus"]
            br_soln["qf"] += br_soln["gmd_qloss"]
        else
            br_soln["qt"] += br_soln["gmd_qloss"]
        end
    end

end




# ===   UNIT CONVERSION FUNCTIONS   === #


# NOTE: these functions are unused and require update


"FUNCTION: add GMD data"
function add_gmd_data(case::Dict{String,Any}, solution::Dict{String,<:Any}; decoupled=false)

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
            if decoupled
                # TODO: add calculations from constraint_dc_current_mag
                k = br["dc_brid_hi"]  # high-side gmd branch
                br["gmd_idc"] = 0.0
                br["ieff"] = abs(br["gmd_idc"])
                br["qloss"] = calculate_qloss(br, case, solution)
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
# data to be concerned with:
# 1. shunt impedances aij
# 2. equivalent currents Jij?
# 3. transformer loss factor Ki? NO, UNITLESSS
# 4. electric field magnitude?
gmd_not_pu = Set(["gmd_gs","gmd_e_field_mag"])
gmd_not_rad = Set(["gmd_e_field_dir"])


"FUNCTION: make GMD mixed units"
function make_gmd_mixed_units(solution::Dict{String,Any}, mva_base::Real)

    rescale = x -> (x * mva_base)
    rescale_dual = x -> (x / mva_base)

    if haskey(solution, "bus")
        for (i, bus) in solution["bus"]
            apply_func(bus, "pd", rescale)
            apply_func(bus, "qd", rescale)
            apply_func(bus, "gs", rescale)
            apply_func(bus, "bs", rescale)
            apply_func(bus, "va", rad2deg)
            apply_func(bus, "lam_kcl_r", rescale_dual)
            apply_func(bus, "lam_kcl_i", rescale_dual)
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
        apply_func(branch, "rate_a", rescale)
        apply_func(branch, "rate_b", rescale)
        apply_func(branch, "rate_c", rescale)
        apply_func(branch, "shift", rad2deg)
        apply_func(branch, "angmax", rad2deg)
        apply_func(branch, "angmin", rad2deg)
        apply_func(branch, "pf", rescale)
        apply_func(branch, "pt", rescale)
        apply_func(branch, "qf", rescale)
        apply_func(branch, "qt", rescale)
        apply_func(branch, "mu_sm_fr", rescale_dual)
        apply_func(branch, "mu_sm_to", rescale_dual)
    end

    dclines =[]
    if haskey(solution, "dcline")
        append!(dclines, values(solution["dcline"]))
    end
    for dcline in dclines
        apply_func(dcline, "loss0", rescale)
        apply_func(dcline, "pf", rescale)
        apply_func(dcline, "pt", rescale)
        apply_func(dcline, "qf", rescale)
        apply_func(dcline, "qt", rescale)
        apply_func(dcline, "pmaxt", rescale)
        apply_func(dcline, "pmint", rescale)
        apply_func(dcline, "pmaxf", rescale)
        apply_func(dcline, "pminf", rescale)
        apply_func(dcline, "qmaxt", rescale)
        apply_func(dcline, "qmint", rescale)
        apply_func(dcline, "qmaxf", rescale)
        apply_func(dcline, "qminf", rescale)
    end

    if haskey(solution, "gen")
        for (i, gen) in solution["gen"]
            apply_func(gen, "pg", rescale)
            apply_func(gen, "qg", rescale)
            apply_func(gen, "pmax", rescale)
            apply_func(gen, "pmin", rescale)
            apply_func(gen, "qmax", rescale)
            apply_func(gen, "qmin", rescale)
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

    @assert !InfrastructureModels.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    if !haskey(data, "GMDperUnit") || data["GMDperUnit"] == false
        make_gmd_per_unit(data["baseMVA"], data)
        data["GMDperUnit"] = true
    end

end


"FUNCTION: make GMD per unit"
function make_gmd_per_unit!(mva_base::Number, data::Dict{String,<:Any})

    @assert !InfrastructureModels.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    # vb = 1e3*data["bus"][1]["base_kv"] # not sure h
    # data["gmd_e_field_mag"] /= vb
    # data["gmd_e_field_dir"] *= pi/180.0

    for bus in data["bus"]
        zb = bus["base_kv"]^2/mva_base

        #println("bus: $(bus["index"]), zb: $zb, a(pu): $(bus["gmd_gs"])")
        bus["gmd_gs"] *= zb
        #println("-> a(pu): $(bus["gmd_gs"]) \n")
    end

end


