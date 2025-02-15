"Solve basic GMD OPF model with nonlinear ac polar where the GIC currents are constant"
function solve_ac_gmd_opf_temp(file, optimizer; kwargs...)
    return solve_gmd_opf( file, _PM.ACPPowerModel, optimizer; kwargs...)
end

"Solve basic GMD OPF model with second order cone ac polar relaxation where the GIC currents are constant"
function solve_soc_gmd_opf_temp(file, optimizer; kwargs...)
    return solve_gmd_opf( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end

"Solve basic GMD OPF model where the GIC currents are constant"
function solve_gmd_opf_temp(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_opf;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd_qloss!,
        ],
        kwargs...,
    )
end


"build the coupled quasi-dc-pf and ac-opf problem
as generator dispatch minimization problem and the GIC currents are constant
"
function build_gmd_opf_temp(pm::_PM.AbstractPowerModel; kwargs...)

    variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_qloss(pm)

    #constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss_constant_ieff(pm, i)

    end

    _PM.objective_min_fuel_cost(pm)

end










# ===   DECOUPLED AC-OPF   === #


"Solve basic GMD model with nonlinear ac polar relaxation"
function solve_ac_opf_qloss(file, optimizer; kwargs...)
    return solve_opf_qloss( file, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_ac_opf_qloss_vnom(file, optimizer; kwargs...)
    return solve_opf_qloss_vnom( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


function solve_opf_qloss(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_opf_qloss;
        solution_processors = [
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end

function solve_opf_qloss_vnom(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_opf_qloss_vnom;
        solution_processors = [
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end


"build the sequential quasi-dc-pf and ac-opf problem
as a generator dispatch minimization problem with calculated ieff"
function build_opf_qloss(pm::_PM.AbstractPowerModel; kwargs...)
    use_vnom = false
    build_opf_qloss(pm::_PM.AbstractACPModel, use_vnom; kwargs...)
end

function build_opf_qloss_vnom(pm::_PM.AbstractPowerModel; kwargs...)
    use_vnom = true
    build_opf_qloss(pm::_PM.AbstractACPModel, use_vnom; kwargs...)
end

function build_opf_qloss(pm::_PM.AbstractACPModel, vnom; kwargs...)

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_qloss(pm)

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        if vnom
            constraint_qloss_decoupled_vnom(pm, i)
        else
            constraint_qloss_decoupled(pm, i)
        end

    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    _PM.objective_min_fuel_and_flow_cost(pm)

end

# TODO: move to gmd_opf_ts.jl

"Solve the multi-time-series quasi-dc-pf problem followed by the ac-opf problem with qloss constraints"
function solve_ac_gmd_opf_ts_decoupled(case, optimizer, waveform; setting=Dict{String,Any}(), disable_thermal=true, kwargs...)

    wf_time = waveform["time"]
    wf_waveforms = waveform["waveforms"]

    if disable_thermal == false

        base_mva = case["baseMVA"]
        delta_t = wf_time[2] - wf_time[1]

        Ie_prev = Dict()
        for (i, br) in case["branch"]
            Ie_prev[i] = nothing
        end

    end

    solution = []
    for i in eachindex(wf_time)
        if (waveform !== nothing && waveform["waveforms"] !== nothing)
            for (k, wf) in waveform["waveforms"]

                otype = wf["parent_type"]
                field  = wf["parent_field"]

                case[otype][k][field] = wf["values"][i]

            end
        end

        result = solve_ac_gmd_opf_decoupled(case, optimizer; setting=setting,
        solution_processors = [
            solution_gmd!,
            solution_gmd_qloss_decoupled!
        ])

        result["time_index"] = i
        result["time"] = wf_time[i]

        if !disable_thermal

            xfmr_temp = Dict("Ieff" => 0.0, "delta_topoilrise_ss" => 0.0, "delta_hotspotrise_ss" => 0.0, "actual_hotspot" => 0.0)

            if i > 1
                delta_t = wf_time[i] - wf_time[i-1]
            end

            #for (k, br) in result["ac"]["case"]["branch"]
            for (k, br) in case["branch"]

                if !(br["type"] == "xfmr" || br["type"] == "xf" || br["type"] == "transformer")
                    continue
                else
                    br["delta_topoilrise_ss"] = calc_delta_topoilrise_ss(br, result, base_mva)
                    br["delta_topoilrise"] = calc_delta_topoilrise(br, result, base_mva, delta_t)
                    update_topoilrise!(br, case)

                    br["delta_hotspotrise_ss"] = calc_delta_hotspotrise_ss(br, k, result)
                    br["delta_hotspotrise"] = calc_delta_hotspotrise(br, result, k, Ie_prev[k], delta_t)
                    update_hotspotrise!(br, case)

                    xfmr_temp["Ieff"] = result["solution"]["branch"][k]["gmd_idc_mag"] #br["ieff"]
                    # xfmr_temp["delta_topoilrise"] = br["delta_topoilrise"]
                    xfmr_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
                    # xfmr_temp["delta_hotspotrise"] =  br["delta_hotspotrise"]
                    xfmr_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
                    xfmr_temp["actual_hotspot"] = (br["temperature_ambient"] + br["delta_topoilrise_ss"] + br["delta_hotspotrise_ss"])
                end

                merge!(result["solution"]["branch"]["$k"], xfmr_temp)
            end
        end
        push!(solution, result)
    end
    return solution

end
