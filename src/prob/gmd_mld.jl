##############
# GIC AC-MLD #
##############

# ===   COUPLED MLD   === #


"FUNCTION: solve GMD MLD mitigation with nonlinear ac equations"
function solve_ac_gmd_mld(file, optimizer; kwargs...)
    return solve_gmd_mld(file, _PM.ACPPowerModel, optimizer; kwargs...)
end

"FUNCTION: solve GMD MLD mitigation with second order cone relaxation"
function solve_soc_gmd_mld(file, optimizer; kwargs...)
    return solve_gmd_mld(file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end

"FUNCTION: solve GMD MLD mitigation with nonlinear ac equations"
function solve_qc_gmd_mld(file, optimizer; kwargs...)
    return solve_gmd_mld(file, _PM.QCRMPowerModel , optimizer; kwargs...)
end

function solve_gmd_mld(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_mld;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the ac minimum loadshedding coupled with quasi-dc-pf problem
as a maximum loadability problem with relaxed generator and bus participation"
function build_gmd_mld(pm::_PM.AbstractPowerModel; kwargs...)

# Reference:
#   built problem specification corresponds to the "MLD" specification of  PowerModelsRestoration.jl
#   (https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl)

    _PMR.variable_bus_voltage_indicator(pm, relax=true)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    variable_dc_voltage(pm)
    variable_gic_current(pm)
    variable_dc_line_flow(pm)
    variable_qloss(pm)

    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
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
        constraint_dc_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    _PM.objective_max_loadability(pm)
end
