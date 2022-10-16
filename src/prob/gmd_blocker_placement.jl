export run_gmd_blocker_placement


"FUNCTION: run GIC current model"
function run_gmd_blocker_placement(file, optimizer; kwargs...)
    return _PM.run_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd_blocker_placement;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!
        ],
        kwargs...,
    )
end


"FUNCTION: build the quasi-dc power flow problem
as a linear constraint satisfaction problem"
function build_gmd_blocker_placement(pm::_PM.AbstractPowerModel; kwargs...)
    variable_blocker_indicator(pm; relax=true)
    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_blocker_dc_power_balance_shunt(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_blocker_placement_cost(pm)
end

"Cost of installing GIC blockers"
function objective_blocker_placement_cost(pm::_PM.AbstractPowerModel)
    nw = nw_id_default # TODO: extend to multinetwork
    return JuMP.@objective(pm.model, Min,
        sum( get(_PM.ref(pm, nw, :gmd_bus, i), "blocker_cost", 1.0)*_PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :gmd_bus) )
    )
end


