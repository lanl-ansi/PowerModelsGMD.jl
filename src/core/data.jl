export make_gmd_mixed_units, adjust_gmd_qloss

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

""
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
                # get he high-side gmd branch
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

function make_gmd_per_unit!(data::Dict{String,<:Any})
    @assert !InfrastructureModels.ismultinetwork(case)
    @assert !haskey(case, "conductors")

    if !haskey(data, "GMDperUnit") || data["GMDperUnit"] == false
        make_gmd_per_unit!(data["baseMVA"], data)
        data["GMDperUnit"] = true
    end
end

function make_gmd_per_unit!(mva_base::Number, data::Dict{String,<:Any})
    @assert !InfrastructureModels.ismultinetwork(case)
    @assert !haskey(case, "conductors")

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
function calc_ac_mag_max(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    # ac_mag_max
    branch = PMs.ref(pm, nw, :branch, i)
    f_bus = PMs.ref(pm, nw, :bus, branch["f_bus"])
    t_bus = PMs.ref(pm, nw, :bus, branch["t_bus"])
    ac_max = branch["rate_a"]*branch["tap"] / min(f_bus["vmin"], t_bus["vmin"])

    # println(i, " " , ac_max, " ", branch["rate_a"], " ", pm.ref[:nw][n][:bus][f_bus]["vmin"], " ", pm.ref[:nw][n][:bus][t_bus]["vmin"])

    return ac_max
end


"Computes the maximum DC current on a branch"
function calc_dc_mag_max(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = PMs.ref(pm, nw, :branch, i)

    ac_max = -Inf
    for l in PMs.ids(pm, nw, :branch)
        ac_max = max(calc_ac_mag_max(pm, l, nw=nw), ac_max)
    end
    ibase = calc_branch_ibase(pm, i, nw=nw)
    #println(i , " ", 2 * ac_max * ibase, " ", ibase, " ", ac_max)

    return 2 * ac_max * ibase #   branch["ibase"]
end


"Computes the ibase for a branch"
function calc_branch_ibase(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = PMs.ref(pm, nw, :branch, i)
    bus = PMs.ref(pm, nw, :bus, branch["hi_bus"])
    return branch["baseMVA"]*1000.0*sqrt(2.0)/(bus["base_kv"]*sqrt(3.0))
end

"""
Fits a polynomial of degree `n` through a set of points.
Taken from CurveFit.jl by Paul Jabardo
https://github.com/pjabardo/CurveFit.jl/blob/master/src/linfit.jl
Simple algorithm, doesn't use orthogonal polynomials or any such thing
and therefore unconditioned matrices are possible. Use it only for low
degree polynomials.
This function returns a the coefficients of the polynomial.
"""
function poly_fit(x, y, n)

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


"Computes the thermal coeffieicents for a branch"
function calc_branch_thermal_coeff(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = PMs.ref(pm, nw, :branch, i)
    buses = PMs.ref(pm, nw, :bus)

    if !(branch["type"] == "xf")
        return NaN
    end

    # A hack for now....
    thermal_cap_x0 = pm.data["thermal_cap_x0"]
    if isa(thermal_cap_x0, Dict)
        thermal_cap_x0 = []
        for (key, value) in sort(pm.data["thermal_cap_x0"]["1"])
            if key == "index"
                continue
            end
            push!(thermal_cap_x0, value)
        end
    end

    thermal_cap_y0 = pm.data["thermal_cap_y0"]
    if isa(thermal_cap_y0, Dict)
        thermal_cap_y0 = []
        for (key, value) in sort(pm.data["thermal_cap_y0"]["1"])
            if key == "index"
                continue
            end
            push!(thermal_cap_y0, value)
        end
    end

    x0 = thermal_cap_x0./calc_branch_ibase(pm, i, nw=nw)  #branch["ibase"]
    y0 = thermal_cap_y0./100  # convert to %

    y = calc_ac_mag_max(pm, i, nw=nw) .* y0 # branch["ac_mag_max"] .* y0
    x = x0

    fit = poly_fit(x, y, 2)
    fit = round.(fit.*1e+5)./1e+5
    return fit
end


"Computes the maximum dc voltage difference between buses"
function calc_max_dc_voltage_difference(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return 1e6 # TODO, actually formally calculate
end

""
function apply_func(data::Dict{String,Any}, key::String, func)
    if haskey(data, key)
        data[key] = func(data[key])
    end
end

function adjust_gmd_qloss(case::Dict{String,Any}, data::Dict{String,Any})
    for (i,br) in case["branch"]
        br_soln = data["branch"][i]

        if br["f_bus"] == br["hi_bus"]
            br_soln["qf"] += br_soln["gmd_qloss"]
        else
            br_soln["qt"] += br_soln["gmd_qloss"]
        end
    end
end


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

"Computes the maximum DC voltage at a gmd bus "
function calc_max_dc_voltage(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return Inf
end

"Computes the maximum DC voltage at a gmd bus "
function calc_min_dc_voltage(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return -Inf
end

"Computes the minimim absolute value AC current on a branch"
function calc_ac_mag_min(pm::PMs.GenericPowerModel, i; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    return 0
end
