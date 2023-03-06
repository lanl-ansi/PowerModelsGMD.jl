##############
# GIC AC-OPF #
##############


# ===   DECOUPLED AC-OPF   === #


"FUNCTION: solve basic GMD model with nonlinear ac polar relaxation"
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
            solution_PM!,
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
            solution_PM!,
            solution_gmd_qloss!
        ],
        kwargs...,
    )
end


"FUNCTION: build the sequential quasi-dc-pf and ac-opf problem
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


"FUNCTION: solve the quasi-dc-pf problem followed by the ac-opf problem with qloss constraints"
function solve_ac_gmd_opf_decoupled(file::String, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_ac_gmd_opf_decoupled(data, optimizer; kwargs...)
end

function solve_ac_gmd_opf_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_opf_decoupled(data, model_type, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = solve_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        dc_current_mag(branch, ac_case, dc_solution)
    end

    qloss_decoupled_vnom(ac_case)
    # ac_result = solve_opf_qloss_vnom(ac_case, model_type, optimizer, setting=setting)
    ac_result = _PM.solve_opf(ac_case, model_type, optimizer, setting=setting;
        solution_processors = [
            solution_gmd_qloss_decoupled!
        ])
    ac_solution = ac_result["solution"]

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


# ===   DECOUPLED AC-OPF-TS   === #


"FUNCTION: solve the multi-time-series quasi-dc-pf problem followed by the ac-opf problem with qloss constraints"
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
    for i in 1:length(wf_time)

        if (waveform !== nothing && waveform["waveforms"] !== nothing)
            for (k, wf) in waveform["waveforms"]

                otype = wf["parent_type"]
                field  = wf["parent_field"]

                case[otype][k][field] = wf["values"][i]

            end
        end

        result = solve_ac_gmd_opf_decoupled(case, optimizer; setting=setting)

        result["time_index"] = i
        result["time"] = wf_time[i]

        if disable_thermal == false

            xfmr_temp = Dict("Ieff" => 0.0, "delta_topoilrise_ss" => 0.0, "delta_hotspotrise_ss" => 0.0, "actual_hotspot" => 0.0)

            if i > 1
                delta_t = wf_time[i] - wf_time[i-1]
            end

            for (k, br) in result["ac"]["case"]["branch"]

                ac_result = result["ac"]["result"]

                if !(br["type"] == "xfmr" || br["type"] == "xf" || br["type"] == "transformer")
                    continue
                else

                    delta_topoilrise_ss(br, ac_result, base_mva)
                    delta_topoilrise(br, ac_result, base_mva, delta_t)
                    update_topoilrise(br, case)

                    delta_hotspotrise_ss(br, ac_result)
                    delta_hotspotrise(br, ac_result, Ie_prev[k], delta_t)
                    update_hotspotrise(br, case)

                    xfmr_temp["Ieff"] = br["ieff"]
                    # xfmr_temp["delta_topoilrise"] = br["delta_topoilrise"]
                    xfmr_temp["delta_topoilrise_ss"] = br["delta_topoilrise_ss"]
                    # xfmr_temp["delta_hotspotrise"] =  br["delta_hotspotrise"]
                    xfmr_temp["delta_hotspotrise_ss"] = br["delta_hotspotrise_ss"]
                    xfmr_temp["actual_hotspot"] = (br["temperature_ambient"] + br["delta_topoilrise_ss"] + br["delta_hotspotrise_ss"])

                end

                merge!(ac_result["solution"]["branch"]["$k"], xfmr_temp)

            end

        end
        push!(solution, result)

    end
    return solution

end


# ===   COUPLED AC-OPF   === #


"FUNCTION: solve basic GMD model with nonlinear ac polar relaxation"
function solve_ac_gmd_opf(file, optimizer; kwargs...)
    return solve_gmd_opf( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


function solve_gmd_opf(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_opf;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the coupled quasi-dc-pf and ac-opf problem
as generator dispatch minimization problem"
function build_gmd_opf(pm::_PM.AbstractPowerModel; kwargs...)

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_dc_voltage(pm)
    variable_dc_current_mag(pm)
    variable_dc_line_flow(pm)
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

        constraint_qloss_vnom(pm, i)
        constraint_dc_current_mag(pm, i)

    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_gmd_min_fuel(pm)

end


# ===   COUPLED AC-OPF-TS   === #


"FUNCTION: solve the multi-time-series GMD model with nonlinear ac polar relaxation"
function solve_ac_gmd_opf_ts(file, optimizer; kwargs...)
    return solve_gmd_opf_ts(file, _PM.ACPPowerModel, optimizer; kwargs...)
end


function solve_gmd_opf_ts(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_opf_ts;
        multinetwork = true,
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the multi-time-series coupled quasi-dc-pf and ac-opf problem with qloss constraints
as a transformer heating minimization problem"
function build_gmd_opf_ts(pm::_PM.AbstractPowerModel; kwargs...)

    for (n, network) in _PM.nws(pm)

        _PM.variable_bus_voltage(pm, nw=n)
        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        variable_dc_voltage(pm, nw=n)
        variable_dc_current_mag(pm, nw=n)
        variable_dc_line_flow(pm, nw=n)
        variable_qloss(pm, nw=n)

        variable_delta_oil_ss(pm, nw=n, bounded=true)
        variable_delta_oil(pm, nw=n, bounded=true)
        variable_delta_hotspot_ss(pm, nw=n, bounded=true)
        variable_delta_hotspot(pm, nw=n, bounded=true)
        variable_hotspot(pm, nw=n, bounded=true)

        _PM.constraint_model_voltage(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_power_balance_gmd(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)

            _PM.constraint_ohms_yt_from(pm, i, nw=n)
            _PM.constraint_ohms_yt_to(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm, i, nw=n)

            _PM.constraint_thermal_limit_from(pm, i, nw=n)
            _PM.constraint_thermal_limit_to(pm, i, nw=n)

            constraint_qloss_vnom(pm, i, nw=n)
            constraint_dc_current_mag(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state(pm, i, nw=n)
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)

        end

        for i in _PM.ids(pm, :gmd_bus, nw=n)
            constraint_dc_power_balance(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_branch, nw=n)
            constraint_dc_ohms(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

    end

    network_ids = sort(collect(nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PM.ids(pm, :branch, nw=n_1)
        constraint_temperature_state(pm, i, nw=n_1)
    end
    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_temperature_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    objective_gmd_min_transformer_heating(pm)

end
