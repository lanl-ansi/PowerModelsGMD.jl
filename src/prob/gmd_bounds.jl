
function solve_soc_bound_gmd_bus_v(case, optimizer; kwargs...)
    return return solve_bound_gmd_bus_v(case, _PM.SOCWRPowerModel, optimizer; kwargs...)
end

function solve_ac_bound_gmd_bus_v(case, optimizer; kwargs...)
    return return solve_bound_gmd_bus_v(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

"solves for the dv voltage bounds at substations"
function solve_bound_gmd_bus_v(case, model_type::Type, optimizer; kwargs...)
    _case = deepcopy(case)

    components = get_connected_components(_case)

    _case["connected_components"] = components

    filter_gmd_ne_blockers!(_case)

    results = Dict{String,Any}()

    for (_,conn) in enumerate(_case["connected_components"])
        if length(conn) > 1
            t = time()
            for i in conn
                bus = _case["gmd_bus"]["$i"]
                if bus["sub"] == -1
                    kwargs[:setting]["gmd_bus"] = bus["index"]
                    kwargs[:setting]["max"] = true
                    result_max = _PM.solve_model(
                        _case,
                        model_type,
                        optimizer,
                        build_bound_gmd_bus_v;
                        ref_extensions = [
                            ref_add_gmd!,
                            ref_add_ne_blocker!,
                            ref_add_gmd_connections!,
                        ],
                        solution_processors = [],
                        kwargs...,
                    )
                    kwargs[:setting]["max"] = false
                    result_min = _PM.solve_model(
                        _case,
                        model_type,
                        optimizer,
                        build_bound_gmd_bus_v;
                        ref_extensions = [
                            ref_add_gmd!,
                            ref_add_ne_blocker!,
                            ref_add_gmd_connections!,
                        ],
                        solution_processors = [],
                        kwargs...,
                    )
                    results["$i"] = Dict{String,Any}(
                        "max" => result_max,
                        "min" => result_min,
                    )
                end
            end
        end
    end
    if kwargs[:setting]["add2case"]
        solution_add_gmd_bus_v_bounds_case!(case, results)
        return case
    else
        return solution_get_gmd_bus_v_bounds(case, results)
    end
end


function build_bound_gmd_bus_v(pm::_PM.AbstractPowerModel; kwargs...)
    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)

    blocker_relax = get(pm.setting,"blocker_relax",false)
    variable_ne_blocker_indicator(pm, relax=blocker_relax)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_kcl_ne_blocker(pm, i)
    end
    
    for i in _PM.ids(pm, :branch)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    for i in _PM.ids(pm, :gmd_connections)
        constraint_gmd_connections(pm, i)
    end

    objective_bound_gmd_bus_v(pm)
end


function solve_soc_bound_qloss(case, optimizer; kwargs...)
    return return solve_bound_qloss(case, _PM.SOCWRPowerModel, optimizer; kwargs...)
end

function solve_ac_bound_qloss(case, optimizer; kwargs...)
    return return solve_bound_qloss(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

"solve for max q at ac buses"
function solve_bound_qloss(case, model_type::Type, optimizer; kwargs...)
    _case = deepcopy(case)

    components = _PMGMD.get_connected_components(_case)

    _case["connected_components"] = components

    results = Dict{String,Any}()

    for (i, branch) in _case["branch"]
        if branch["type"] == "xfmr"
            kwargs[:setting]["qloss_branch"] = branch["index"]
            result_max = _PM.solve_model(
                    _case,
                    model_type,
                    optimizer,
                    build_bound_qloss;
                    ref_extensions = [
                        ref_add_gmd!,
                        ref_add_ne_blocker!,
                        ref_add_gmd_connections!,
                    ],
                    solution_processors = [
                        solution_gmd_qloss_max!,
                    ],
                    kwargs...,
            )
            results[i] = Dict{String,Any}(
                "max" => result_max,
            )
        end
    end
    if kwargs[:setting]["add2case"]
        solution_add_qloss_bound_case!(case, results)
        return case
    else
        return solution_get_qloss_bound(case, results)
    end
end


function build_bound_qloss(pm)
    variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

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
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    constraint_load_served(pm)

    objective_max_qloss(pm)
end