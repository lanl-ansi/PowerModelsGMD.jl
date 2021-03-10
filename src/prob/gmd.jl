export run_gmd


"FUNCTION: run GIC current model only"
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
            solution_PM!,
            solution_gmd!
        ],
        kwargs...,
    )
end


function build_gmd(pm::_PM.AbstractPowerModel; kwargs...)

    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    for i in _PM.ids(pm, :gmd_bus)
        Memento.debug(_LOGGER, "Adding constraits for bus $i")
        constraint_dc_kcl_shunt(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        Memento.debug(_LOGGER, "Adding constraits for branch $i")
        constraint_dc_ohms(pm, i)
    end

end

