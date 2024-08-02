"CONSTRAINT: calculate qloss assuming constant ac voltage"
function update_qloss_decoupled_vnom!(case::Dict{String,Any})

    for (_, bus) in case["bus"]
        bus["qloss0"] = 0.0
        bus["qloss"] = 0.0
    end

    for (_, branch) in case["branch"]
        branch["qloss0"] = 0.0
        branch["qloss"] = 0.0
    end

    for (k, branch) in case["branch"]
        # qloss is defined in arcs going in both directions

        i = branch["f_bus"]
        j = branch["t_bus"]

        ckt = "  "
        if "ckt" in keys(branch)
            ckt = branch["ckt"]
        end

        if ( !("hi_bus" in keys(branch)) || !("lo_bus" in keys(branch)) || (branch["hi_bus"] == -1) || (branch["lo_bus"] == -1) )
            Memento.warn(_LOGGER, "Branch $k ($i, $j, $ckt) is missing hi bus/lo bus")
            continue
        end

        bus = case["bus"]["$i"]
        i = branch["hi_bus"]
        j = branch["lo_bus"]

        if branch["br_status"] == 0
            # branch is disabled
            continue
        end

        if "gmd_k" in keys(branch)

            ibase = (case["baseMVA"] * 1000.0 * sqrt(2.0)) / (bus["base_kv"] * sqrt(3.0))
            ieff = branch["ieff"] / (3 * ibase)
            qloss = branch["gmd_k"] * ieff

            case["bus"]["$i"]["qloss"] += qloss

            case["branch"][k]["gmd_qloss"] = qloss * case["baseMVA"]

            n = length(case["load"])
            if qloss >= 1e-3
                load = Dict{String, Any}()
                load["source_id"] = ["qloss", branch["index"]]
                load["load_bus"] = i
                load["status"] = 1
                load["pd"] = 0.0
                load["qd"] = qloss
                load["index"] = n + 1
                case["load"]["$(n + 1)"] = load
                load["weight"] = 100.0
            end

        else

            Memento.warn(_LOGGER, "Transformer $k ($i,$j) does not have field gmd_k, skipping")

        end

    end

end


"FUNCTION: POLYFIT"
function poly_fit(x, y, n)
# Fits a polynomial of degree `n` through a set of points.
# Simple algorithm that does not use orthogonal polynomials or any such thing
# and therefore unconditioned matrices are possible. Use it only for low degree
# polynomial. This function returns a the coefficients of the polynomial.
# Reference: https://github.com/pjabardo/CurveFit.jl/blob/master/src/linfit.jl

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


"calculate load shedding cost"
function calc_load_shed_cost(pm::_PM.AbstractPowerModel)
    max_cost = 0
    for (n, nw_ref) in _PM.nws(pm)
        for (i, gen) in nw_ref[:gen]
            if gen["pmax"] != 0
                cost_mw = (
                    get(gen["cost"], 1, 0.0) * gen["pmax"]^2 +
                    get(gen["cost"], 2, 0.0) * gen["pmax"]
                    ) / gen["pmax"] + get(gen["cost"], 3, 0.0)
                max_cost = max(max_cost, cost_mw)
            end
        end
    end
    return max_cost * 2.0
end


# ===   CALCULATIONS FOR THERMAL VARIABLES   === #

"FUNCTION: calculate steady-state hotspot temperature rise"
function calc_delta_hotspotrise_ss(branch, k, result)

    delta_hotspotrise_ss = 0

    Ie = result["solution"]["ieff"][k]
    delta_hotspotrise_ss = get(branch, "hotspot_coeff", 0.63) * Ie

    return delta_hotspotrise_ss
end


"FUNCTION: calculate hotspot temperature rise"
function calc_delta_hotspotrise(branch, result, k, Ie_prev, delta_t)

    delta_hotspotrise = 0

    Ie = result["solution"]["ieff"][k]
    tau = 2 * get(branch, "hotspot_rated", 150.0) / delta_t

    if Ie_prev === nothing
        delta_hotspotrise = get(branch, "hotspot_coeff", 0.63) * Ie
    else
        delta_hotspotrise_prev = branch["delta_hotspotrise"]
        delta_hotspotrise = get(branch, "hotspot_coeff", 0.63) * (Ie + Ie_prev) / (1 + tau) - delta_hotspotrise_prev * (1 - tau) / (1 + tau)
    end

    return delta_hotspotrise

end


"FUNCTION: update hotspot temperature rise in the network"
function update_hotspotrise!(branch, case::Dict{String,Any})

    i = branch["index"]

    case["branch"]["$i"]["delta_hotspotrise_ss"] = branch["delta_hotspotrise_ss"]
    case["branch"]["$i"]["delta_hotspotrise"] = branch["delta_hotspotrise"]

end


"FUNCTION: calculate steady-state top-oil temperature rise"
function calc_delta_topoilrise_ss(branch, result, base_mva)
    delta_topoilrise_ss = 75.0 # rated top-oil temperature

    if ( (branch["type"] == "xfmr") || (branch["type"] == "xf") || (branch["type"] == "transformer") )
        i = branch["index"]

        if !haskey(result["solution"], "branch") || !haskey(result["solution"]["branch"], "$i")
            return delta_topoilrise_ss
        end

        bs = result["solution"]["branch"]["$i"]
        p = bs["pf"]
        q = bs["qf"]

        S = sqrt(p^2 + q^2)
        K = S / (branch["rate_a"] * base_mva)

        delta_topoilrise_ss = get(branch, "topoil_rated", 75.0) * K^2

    end

    return delta_topoilrise_ss

end


"FUNCTION: calculate top-oil temperature rise"
function calc_delta_topoilrise(branch, result, base_mva, delta_t)

    delta_topoilrise_ss = branch["delta_topoilrise_ss"]
    delta_topoilrise = delta_topoilrise_ss

    if ( ("delta_topoilrise" in keys(branch)) && ("delta_topoilrise_ss" in keys(branch)) )

        delta_topoilrise_prev = branch["delta_topoilrise"]
        delta_topoilrise_ss_prev = branch["delta_topoilrise_ss"]

        tau = 2 * (get(branch, "topoil_time_const", 71.0) * 60) / delta_t
        delta_topoilrise = (delta_topoilrise_ss + delta_topoilrise_ss_prev) / (1 + tau) - delta_topoilrise_prev * (1 - tau) / (1 + tau)

    else

        delta_topoilrise = 0

    end

    return delta_topoilrise

end


"FUNCTION: update top-oil temperature rise in the network"
function update_topoilrise!(branch, case::Dict{String,Any})

    i = branch["index"]
    case["branch"]["$i"]["delta_topoilrise_ss"] = branch["delta_topoilrise_ss"]
    case["branch"]["$i"]["delta_topoilrise"] = branch["delta_topoilrise"]

end




"FUNCTION: compute the thermal coeffieicents for a branch"
function calc_branch_thermal_coeff(pm::_PM.AbstractPowerModel, i; nw::Int=pm.cnw)

    branch = _PM.ref(pm, nw, :branch, i)

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

    x0 = thermal_cap_x0 ./ calc_branch_ibase(pm, i, nw=nw)
    y0 = thermal_cap_y0 ./ 100

    x = x0
    y = calc_ac_mag_max(pm, i, nw=nw) .* y0

    fit = poly_fit(x, y, 2)
    fit = round.(fit.*1e+5)./1e+5
    return fit

end
