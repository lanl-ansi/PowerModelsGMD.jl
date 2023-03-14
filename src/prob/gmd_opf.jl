##############
# GIC AC-OPF #
##############


"FUNCTION: solve basic GMD model with nonlinear ac polar relaxation"
function solve_ac_gmd_opf(file, optimizer; kwargs...)
    return solve_gmd_opf( file, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_soc_gmd_opf(file, optimizer; kwargs...)
    return solve_gmd_opf( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
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
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the coupled quasi-dc-pf and ac-opf problem
as generator dispatch minimization problem

[1] M. Ryu, H. Nagarajan and R. Bent, Mitigating the Impacts of Uncertain Geomagnetic
Disturbances on Electric Grids: A Distributionally Robust Optimization Approach,
in IEEE Transactions on Power Systems, vol. 37, no. 6, pp. 4258-4269, Nov. 2022,
doi: 10.1109/TPWRS.2022.3147104.

*Note - [1] solves a robust variation of build_gmd_opf and is used as a reference for the
GIC equations
"
function build_gmd_opf(pm::_PM.AbstractPowerModel; kwargs...)

    variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    variable_dc_voltage(pm) # varible v^d in [1]
    variable_gic_current(pm) # variable I_eff in [1]
    variable_dc_line_flow(pm) # variabe I^d in [1]
    variable_qloss(pm) # variable for representing k * v * I_eff of constraint 2e in in [1]

    constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_gmd(pm, i) # constraint 1b of [1]
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)

        constraint_qloss(pm, i) # variation of constraint 2e in [1] - computes a (qloss) value for each edge, e.g. k * v * I_eff, which gets sumed in 1c as the qloss term
        constraint_dc_current_mag(pm, i) # constraint 2d of [1]

    end

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance(pm, i) # constraint 2b of [1]
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i) # variation of constraint 2c of [1] w/o switching variable
    end

    #objective_gmd_min_fuel(pm)
    _PM.objective_min_fuel_cost(pm)

end
