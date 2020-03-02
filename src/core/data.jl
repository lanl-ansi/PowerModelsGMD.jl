export make_gmd_mixed_units, adjust_gmd_qloss, top_oil_rise, hotspot_rise, update_top_oil_rise, update_hotspot_rise


# --- GMD Formulation Functions --- #


"FUNCTION: add GMD data"
function add_gmd_data(case::Dict{String,Any}, solution::Dict{String,<:Any}; decoupled=false)

    @assert !InfrastructureModels.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    for (k,bus) in case["bus"]
        j = "$(bus["gmd_bus"])"
        bus["gmd_vdc"] = solution["gmd_bus"][j]["gmd_vdc"]
    end

    for (i,br) in case["branch"]
        br_soln = solution["branch"][i]

        if br["type"] == "line"
            k = "$(br["gmd_br"])"
            br["gmd_idc"] = solution["gmd_branch"][k]["gmd_idc"]/3.0
        
        else # branch is transformer
            if decoupled
                # get the high-side gmd branch
                k = br["dc_brid_hi"]
                # TODO: add calculations from constraint_dc_current_mag
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




# --- General Functions --- #


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
function calc_ac_mag_max(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    
    # ac_mag_max
    branch = PMs.ref(pm, nw, :branch, i)
    f_bus = PMs.ref(pm, nw, :bus, branch["f_bus"])
    t_bus = PMs.ref(pm, nw, :bus, branch["t_bus"])
    ac_max = branch["rate_a"]*branch["tap"] / min(f_bus["vmin"], t_bus["vmin"])

    #println(i, " " , ac_max, " ", branch["rate_a"], " ", pm.ref[:nw][n][:bus][f_bus]["vmin"], " ", pm.ref[:nw][n][:bus][t_bus]["vmin"])

    return ac_max

end


"FUNCTION: compute the maximum DC current on a branch"
function calc_dc_mag_max(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    
    branch = PMs.ref(pm, nw, :branch, i)

    ac_max = -Inf
    for l in PMs.ids(pm, nw, :branch)
        ac_max = max(calc_ac_mag_max(pm, l, nw=nw), ac_max)
    end
    ibase = calc_branch_ibase(pm, i, nw=nw)
    #println(i , " ", 2 * ac_max * ibase, " ", ibase, " ", ac_max)

    return 2 * ac_max * ibase #   branch["ibase"]

end


"FUNCTION: computes the ibase for a branch"
function calc_branch_ibase(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    branch = PMs.ref(pm, nw, :branch, i)
    bus = PMs.ref(pm, nw, :bus, branch["hi_bus"])
    return branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))

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


"FUNCTION: compute the thermal coeffieicents for a branch"
function calc_branch_thermal_coeff(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)

    branch = PMs.ref(pm, nw, :branch, i)
    buses = PMs.ref(pm, nw, :bus)

    if !(branch["type"] == "xfmr")
        return NaN
    end

    # A hack for now.... FIX LATER!
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

    #x0 = 1e3*thermal_cap_x0./calc_branch_ibase(pm, i, nw=nw)  #branch["ibase"]
    x0 = thermal_cap_x0./calc_branch_ibase(pm, i, nw=nw)  #branch["ibase"]
    y0 = thermal_cap_y0./100  # convert to %

    y = calc_ac_mag_max(pm, i, nw=nw) .* y0 # branch["ac_mag_max"] .* y0
    x = x0

    fit = poly_fit(x, y, 2)
    fit = round.(fit.*1e+5)./1e+5
    return fit

end


"FUNCTION: computes the maximum dc voltage difference between buses"
function calc_max_dc_voltage_difference(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return 1e6 # TODO, actually formally calculate
end


"FUNCTION: apply function"
function apply_func(data::Dict{String,Any}, key::String, func)

    if haskey(data, key)
        data[key] = func(data[key])
    end

end


"FUNCTION: adjust GMD Qloss"
function adjust_gmd_qloss(case::Dict{String,Any}, data::Dict{String,Any})

    if !("branch" in keys(data))
        data["branch"] = Dict{String,Any}()
    end

    for (i,br) in case["branch"]
        if !(i in keys(data["branch"]))
            data["branch"][i] = Dict{String,Any}()
            data["branch"][i]["pf"] = 0.0
            data["branch"][i]["pt"] = 0.0
            data["branch"][i]["qf"] = 0.0
            data["branch"][i]["qt"] = 0.0
        end

        br_soln = data["branch"][i]
            

        if "gmd_qloss" in keys(br_soln) 
            if br["f_bus"] == br["hi_bus"]
                br_soln["qf"] += br_soln["gmd_qloss"]
            else
                br_soln["qt"] += br_soln["gmd_qloss"]
            end
        end
    end

end


"FUNCTION: make GMD mixed units"
function make_gmd_mixed_units(data::Dict{String,Any}, mva_base::Real)

    rescale      = x -> x*mva_base
    rescale_dual = x -> x/mva_base

    if haskey(data, "bus")
        for (i, bus) in data["bus"]
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
    if haskey(data, "branch")
        append!(branches, values(data["branch"]))
    end

    dclines =[]
    if haskey(data, "dcline")
        append!(dclines, values(data["dcline"]))
    end

    if haskey(data, "ne_branch")
        append!(branches, values(data["ne_branch"]))
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

    if haskey(data, "gen")
        for (i, gen) in data["gen"]
            apply_func(gen, "pg", rescale)
            apply_func(gen, "qg", rescale)

            apply_func(gen, "pmax", rescale)
            apply_func(gen, "pmin", rescale)

            apply_func(gen, "qmax", rescale)
            apply_func(gen, "qmin", rescale)

            if "model" in keys(gen) && "cost" in keys(gen)
                if gen["model"] != 2
                    Memento.warn(LOGGER, "Skipping generator cost model of type other than 2")
                else
                    degree = length(gen["cost"])
                    for (i, item) in enumerate(gen["cost"])
                        gen["cost"][i] = item/mva_base^(degree-i)
                    end
                end
            end
        end
    end

end


"FUNCTION: compute the maximum DC voltage at a gmd bus "
function calc_max_dc_voltage(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return Inf
end


"FUNCTION: compute the maximum DC voltage at a gmd bus "
function calc_min_dc_voltage(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return -Inf
end


"FUNCTION: compute the minimum absolute value AC current on a branch"
function calc_ac_mag_min(pm::PMs.AbstractPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return 0
end




# --- Decoupled GMD Formulation Functions --- #


"FUNCTION: DC current on gwye-delta transformers"
function dc_current_mag_gwye_delta_xf(branch, case, solution)

    # calculate the current magnitude for each gmd branch

    # find the corresponding gmd branch
    khi = branch["gmd_br_hi"]
    branch["ieff"] = abs(solution["gmd_branch"]["$khi"]["gmd_idc"])

end

"FUNCTION: DC current on gwye-gwye transformers"
function dc_current_mag_gwye_gwye_xf(branch, case, solution)

    # find the corresponding gmd branch
    k = branch["index"]
    khi = branch["gmd_br_hi"]
    klo = branch["gmd_br_lo"]
    println("branch[$k]: hi_branch[$khi], lo_branch[$klo]")
    ihi = solution["gmd_branch"]["$khi"]["gmd_idc"]
    ilo = solution["gmd_branch"]["$klo"]["gmd_idc"]

    jfr = branch["f_bus"]
    jto = branch["t_bus"]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    a = vhi/vlo

    branch["ieff"] = abs((a*ihi + ilo)/a)

end

"DC current on three-winding gwye-gwye-gwye transformers"
function dc_current_mag_3w_xf(branch, case, solution)
    # find the corresponding gmd branch
    k = branch["index"]
    khi = branch["gmd_br_hi"]
    klo = branch["gmd_br_lo"]
    kmed = branch["gmd_br_med"]
    println("branch[$k]: hi_branch[$khi], lo_branch[$klo], med_branch[$kmed]")
    ihi = solution["gmd_branch"]["$khi"]["gmd_idc"]
    ilo = solution["gmd_branch"]["$klo"]["gmd_idc"]
    imed = solution["gmd_branch"]["$kmed"]["gmd_idc"]

    jfr = branch["source_id"][1]
    jto = branch["source_id"][2]
    jmed = branch["source_id"][3]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    vmed = case["bus"]["$jmed"]["base_kv"]

    a = vhi/vlo
    b = vhi/vmed

    # From Boteler '16 eq. 51
    # need to check if we are on the high-side branch
    branch["ieff"] = abs(I1 + Ilo/a + Imed/b)
end

"DC current on gwye-gwye auto transformers"
function dc_current_mag_gwye_gwye_auto_xf(branch, case, solution)

    # find the corresponding gmd branch:
    ks = branch["gmd_br_series"]
    kc = branch["gmd_br_common"]
    is = solution["gmd_branch"]["$ks"]["gmd_idc"]
    ic = solution["gmd_branch"]["$kc"]["gmd_idc"]

    ihi = -is
    ilo = ic + is

    jfr = branch["f_bus"]
    jto = branch["t_bus"]
    vhi = case["bus"]["$jfr"]["base_kv"]
    vlo = case["bus"]["$jto"]["base_kv"]
    a = vhi/vlo

    branch["ieff"] = abs((a*is + ic)/(a + 1.0))

end


"FUNCTION: DC current on normal lines"
function dc_current_mag_line(branch, case, solution)
    branch["ieff"] = 0.0
end


"FUNCTION: DC current on ungrounded transformers"
function dc_current_mag_grounded_xf(branch, case, solution)
    branch["ieff"] = 0.0
end


"FUNCTION: constraints for computing the DC current magnitude"
function dc_current_mag(branch, case, solution)

    # correct equation is ieff = |a*ihi + ilo|/a
    # just use ihi for now

    branch["ieff"] = 0.0

    if branch["type"] != "xfmr"
        dc_current_mag_line(branch, case, solution)
    elseif branch["config"] in ["delta-delta", "delta-wye", "wye-delta", "wye-wye"]
        println("  Ungrounded config, ieff constrained to zero")
        dc_current_mag_grounded_xf(branch, case, solution)
    elseif branch["config"] in ["delta-gwye","gwye-delta"]
        dc_current_mag_gwye_delta_xf(branch, case, solution)
    elseif branch["config"] == "gwye-gwye"
        dc_current_mag_gwye_gwye_xf(branch, case, solution)
    elseif branch["config"] == "gwye-gwye-auto"
        dc_current_mag_gwye_gwye_auto_xf(branch, case, solution)
    elseif branch["config"] == "three-winding" && branch["winding"] == "high"
        dc_current_mag_3w_xf(branch, case, solution)
    end

end


"FUNCTION: convert effective GIC to PowerWorld to-phase convention"
# TODO: do this also for ieff?
function adjust_gmd_phasing(dc_result)
    
    # Function to convert dc currents to be compatible with PowerWorld conventions

    gmd_branches = dc_result["solution"]["gmd_branch"]

    for b in values(gmd_branches)
        b["gmd_idc"] /= 3
    end

    return dc_result

end




# --- Thermal Model Functions --- #


"FUNCTION: calculate top-oil temperature rise"
function delta_topoilrise(branch, result, base_mva, delta_t)

    delta_topoilrise_ss = delta_topoilrise_ss(branch, result, base_mva)
    #delta_topoilrise_ss = 1 #testing for step response
    delta_topoilrise = delta_topoilrise_ss # if 1st iteration, assume it starts from steady-state value

    if ( ("delta_topoilrise" in keys(branch)) && ("delta_topoilrise_ss" in keys(branch)) ) 
        # println("Updating oil temperature")
        delta_topoilrise_prev = branch["delta_topoilrise"]
        delta_topoilrise_ss_prev = branch["delta_topoilrise_ss"] 

        # trapezoidal integration
        tau = 2*(branch["topoil_time_const"]*60)/delta_t
        delta_topoilrise = (delta_topoilrise_ss + delta_topoilrise_ss_prev)/(1 + tau) - delta_topoilrise_prev*(1 - tau)/(1 + tau)
    else
        delta_topoilrise = 0
        # println("Setting initial oil temperature")
    end

   branch["delta_topoilrise_ss"] = delta_topoilrise_ss
   branch["delta_topoilrise"] = delta_topoilrise

end


"FUNCTION: calculate steady-state top-oil temperature rise"
function delta_topoilrise_ss(branch, result, base_mva)
    
    if !(branch["type"] == "transformer" || branch["type"] == "xfmr")
        return 0
    end
        
    i = branch["index"]
    bs = result["solution"]["branch"]["$i"]
    p = bs["pf"]
    q = bs["qf"]
    S = sqrt(p^2 + q^2)
    K = S/(branch["rate_a"] * base_mva) #calculate the loading

    return branch["topoil_rated"]*K^2

end


"FUNCTION: update top-oil temperature rise in the network"
function update_topoilrise(branch, net)

    k = "$(branch["index"])"
    net["branch"][k]["delta_topoilrise"] = branch["delta_topoilrise"]
    net["branch"][k]["delta_topoilrise_ss"] = branch["delta_topoilrise_ss"]

end


"FUNCTION: calculate hotspot temperature rise"
#TODO: FIX function - even though it is written correctly, it errors out when enabled in gmd_opf_ts_decoupled.jl
function delta_hotspotrise(branch, result, Ie_prev, delta_t)
    #determined for the time-extended mitigation problem
    
    delta_hotspotrise = 0
    Ie = branch["ieff"]
    tau = 2*branch["hotspot_rated"]/delta_t

    if Ie_prev === nothing
        delta_hotspotrise = branch["hotspot_coeff"]*Ie
    else
        delta_hotspotrise_prev = branch["delta_hotspotrise"]
        delta_hotspotrise = branch["hotspot_coeff"]*(Ie + Ie_prev)/(1 + tau) - delta_hotspotrise_prev*(1 - tau)/(1 + tau)
    end

    branch["delta_hotspotrise"] = delta_hotspotrise

end


"FUNCTION: calculate steady-state hotspot temperature rise"
function delta_hotspotrise_ss(branch, result)
    #determined for the time-extended  mitigation problem
    
    delta_hotspotrise_ss = 0
    Ie = branch["ieff"]
    delta_hotspotrise_ss = branch["hotspot_coeff"]*Ie
    branch["delta_hotspotrise_ss"] = delta_hotspotrise_ss

end


"FUNCTION: update hotspot temperature rise in the network"
function update_hotspotrise(branch, net)

    k = "$(branch["index"])"
    #net["branch"][k]["delta_hotspotrise"] = branch["delta_hotspotrise"]
    net["branch"][k]["delta_hotspotrise_ss"] = branch["delta_hotspotrise_ss"]
    
end


