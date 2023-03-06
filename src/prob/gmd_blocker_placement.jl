export solve_gmd_blocker_placement


"FUNCTION: run GIC current model"
function solve_gmd_blocker_placement(file, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd_blocker_placement;
        ref_extensions = [
            ref_add_gmd!
            #ref_add_gmd_blockers!
        ],
        solution_processors = [
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the quasi-dc power flow problem
as a linear constraint satisfaction problem"
function build_gmd_blocker_placement(pm::_PM.AbstractPowerModel; kwargs...)

    variable_blocker_indicator(pm)
    variable_dc_voltage(pm; bounded=true)
    variable_dc_line_flow(pm; bounded=true)

    for i in _PM.ids(pm, :gmd_bus)
        if i in _PM.ids(pm, :bus_blockers)
            constraint_dc_power_balance_blocker(pm, i)
        else
            constraint_dc_power_balance(pm, i)
        end
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_blocker_placement_cost(pm)

end
