"FUNCTION: run GMD mitigation with nonlinear ac equations"
function solve_ac_blocker_placement(file, optimizer; kwargs...)
    return solve_blocker_placement(file, _PM.ACPPowerModel, optimizer; kwargs...)
end

"FUNCTION: run GMD mitigation with second order cone relaxation"
function solve_soc_blocker_placement(file, optimizer; kwargs...)
    return solve_blocker_placement(file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function solve_blocker_placement(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_blocker_placement;
        ref_extensions = [
            ref_add_gmd!
            ref_add_ne_blocker!
        ],
        solution_processors = [
            solution_gmd!,
            solution_gmd_qloss!,
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

    variable_ne_blocker_indicator(pm)
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

        constraint_qloss(pm, i)
        constraint_dc_current_mag(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance_ne_blocker(pm,i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    constraint_load_served(pm)

    objective_blocker_placement_cost(pm)
end
