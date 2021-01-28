export run_gmd


"FUNCTION: run GIC current model only"
function run_gmd(data, optimizer; kwargs...)
    return PMs.run_model(data, PMs.ACPPowerModel, optimizer, post_gmd; ref_extensions=[ref_add_core!], solution_builder = solution_gmd!, kwargs...)
end


"FUNCTION: post problem corresponding to the dc gic problem this is a linear constraint satisfaction problem"
function post_gmd(pm::PMs.AbstractPowerModel; kwargs...)

    # -- Variables -- #

    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    # -- Constraints -- #

    # - DC network - #

    for i in PMs.ids(pm, :gmd_bus)
        Memento.debug(LOGGER, "Adding constraits for bus $i")
        constraint_dc_kcl_shunt(pm, i)
    end

    for i in PMs.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end


