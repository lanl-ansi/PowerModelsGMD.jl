export run_ac_gmd_opf_blocker_placement
export run_gmd_opf_blocker_placement


"FUNCTION: run basic GMD model with nonlinear ac equations"
function run_ac_gmd_opf_blocker_placement(file, optimizer; kwargs...)
    return run_gmd_opf( file, _PM.ACPPowerModel, optimizer; kwargs...)
end

function run_gmd_opf_blocker_placement(file, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(
        file,
        model_type,
        optimizer,
        build_gmd_opf_blocker_placement;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!,
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd_mls!,
            solution_gmd_blocker!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the ac optimal power flow coupled with quasi-dc power flow problem
as a generator dispatch minimization problem"
function build_gmd_opf_blocker_placement(pm::_PM.AbstractPowerModel; kwargs...)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_blocker_indicator(pm; relax=false)
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
        if i in _PM.ids(pm, :bus_blockers)
            constraint_dc_power_balance_blocker_shunt(pm, i)
        else
            constraint_dc_power_balance_shunt(pm, i)
        end
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_minimize_idc_sum(pm)
    #objective_blocker_placement_cost(pm)
end

