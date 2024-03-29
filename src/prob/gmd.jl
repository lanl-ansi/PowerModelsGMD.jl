export run_gmd


"FUNCTION: run GIC current model"
function run_gmd(file, optimizer; kwargs...)
    return _PM.run_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd;
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
function build_gmd(pm::_PM.AbstractPowerModel; kwargs...)

    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance_shunt(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end

