# Formulations of GMD Problems that solves for the GIC current only
export run_gmd_gic, run_ac_gmd_gic

"Run GIC current model only"
function run_gmd_gic(file, solver; kwargs...)
    return run_generic_model(file, ACPPowerModel, solver, post_gmd_gic; solution_builder = get_gmd_solution, kwargs...)
end

"Post problem corresponding to the dc gic problem this is a linear constraint satisfaction problem"
function post_gmd_gic(pm::GenericPowerModel; kwargs...)
    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
        constraint_dc_kcl_shunt(pm, i)
    end

    for i in ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end
end
