export run_gmd_blocker_placement


"FUNCTION: run GIC current model"
function run_gmd_blocker_placement(file, optimizer; kwargs...)
    return _PM.run_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd_blocker_placement;
        ref_extensions = [
            ref_add_gmd!,
            #ref_add_gmd_blockers!
        ],
        solution_processors = [
            solution_gmd!,
            solution_gmd_blocker!,
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
            constraint_blocker_dc_power_balance_shunt(pm, i)
        else
            constraint_dc_power_balance_shunt(pm, i)
        end
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    objective_blocker_placement_cost(pm)
end

"Minimize cost of installing GIC blockers"
function objective_blocker_placement_cost(pm::_PM.AbstractPowerModel)
    nw = nw_id_default # TODO: extend to multinetwork
    return JuMP.@objective(pm.model, Min,
        sum( get(_PM.ref(pm, nw, :blocker_buses, i), "blocker_cost", 1.0)*_PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :blocker_buses) )
    )
end

"Minimize GIC"
function objective_minimize_idc_sum(pm::_PM.AbstractPowerModel)
    nw = nw_id_default # TODO: extend to multinetwork
    return JuMP.@objective(pm.model, Min,
        sum( _PM.var(pm, nw, :dc).^2 )
            + 1000*sum( get(_PM.ref(pm, nw, :blocker_buses, i), "blocker_cost", 1.0)
            * _PM.var(pm, nw, :z_blocker, i) for i in _PM.ids(pm, :blocker_buses) 
        )
    )
end


