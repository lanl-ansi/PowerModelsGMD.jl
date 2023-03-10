
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
