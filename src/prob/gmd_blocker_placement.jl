"FUNCTION: run GMD mitigation with nonlinear ac equations"
function solve_ac_blocker_placement(file::String, optimizer; kwargs...)
    case = _PM.parse_file(file)
    return solve_blocker_placement(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_ac_blocker_placement(case::Dict{String,Any}, optimizer; kwargs...)
    return solve_blocker_placement(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

"FUNCTION: run GMD mitigation with second order cone relaxation"
function solve_soc_blocker_placement(file::String, optimizer; kwargs...)
    case = _PM.parse_file(file)
    return solve_blocker_placement(case, _PM.SOCWRPowerModel, optimizer; kwargs...)
end

function solve_soc_blocker_placement(case::Dict{String,Any}, optimizer; kwargs...)
    return solve_blocker_placement(case, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function solve_blocker_placement(case, model_type::Type, optimizer; kwargs...)
    _case = deepcopy(case)
    components = get_connected_components(_case)
    
    _case["connected_components"] = components
    
    filter_gmd_ne_blockers!(_case)

    return _PM.solve_model(
        _case,
        model_type,
        optimizer,
        build_blocker_placement;
        ref_extensions = [
            ref_add_gmd!,
            ref_add_ne_blocker!,
            ref_add_gmd_connections!,
        ],
        solution_processors = [
            solution_gmd!,
            # solution_gmd_qloss!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the ac minimum loadshed coupled with quasi-dc power flow problem
as a maximum loadability problem with relaxed generator and bus participation"
function build_blocker_placement(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built maximum loadability problem specification corresponds to the "MLD" specification of
#   PowerModelsRestoration.jl (https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl)

    blocker_relax = get(pm.setting,"blocker_relax",false)
    variable_ne_blocker_indicator(pm, relax=blocker_relax)
    variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd_shunt_ls(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss_pu(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_kcl_ne_blocker(pm,i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    for i in _PM.ids(pm, :gmd_connections)
        constraint_gmd_connections(pm, i)
    end

    constraint_load_served(pm)

    objective_blocker_placement_cost(pm)
end


"FUNCTION: build the multi-time-series coupled quasi-dc-pf and ac-ots with ac-mls problem
as a generator dispatch minimization problem"
function build_blocker_placement_ts(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built minimum loadshedding problem specification corresponds to the "Model C4" of
#   Mowen et al., "Optimal Transmission Line Switching under Geomagnetic Disturbances", 2018.


    for (n, network) in _PM.nws(pm)
        _PMR.variable_bus_voltage_on_off(pm, nw=n)
        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, relax=true)
        _PM.variable_shunt_admittance_factor(pm, relax=true)

        variable_dc_voltage_on_off(pm, nw=n)
        variable_dc_line_flow(pm, nw=n, bounded=false)
        variable_dc_current_mag(pm, nw=n)
        variable_qloss(pm, nw=n)

        variable_delta_oil_ss(pm, nw=n, bounded=true)
        variable_delta_oil(pm, nw=n, bounded=true)
        variable_delta_hotspot_ss(pm, nw=n, bounded=true)
        variable_delta_hotspot(pm, nw=n, bounded=true)
        variable_hotspot(pm, nw=n, bounded=true)

        _PM.constraint_model_voltage_on_off(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_power_balance_gmd_shunt_ls(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            _PM.constraint_gen_power_on_off(pm, i, nw=n)
            constraint_gen_ots_on_off(pm, i, nw=n)
            constraint_gen_perspective(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)

            _PM.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            _PM.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            _PM.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            _PM.constraint_thermal_limit_to_on_off(pm, i, nw=n)

            constraint_qloss_vnom(pm, i, nw=n)
            constraint_dc_current_mag(pm, i, nw=n)
            constraint_dc_current_mag_on_off(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state(pm, i, nw=n)
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)

        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_bus, nw=n)
            constraint_dc_kcl(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_branch, nw=n)
            constraint_dc_ohms_on_off(pm, i, nw=n)
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

    _PM.objective_min_fuel_and_flow_cost(pm)
end


