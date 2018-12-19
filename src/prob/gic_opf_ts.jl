
# Formulations of GMD Problems
export run_gic_opf_ts, run_ac_gic_opf_ts

"Run basic GMD with the nonlinear AC equations"
function run_ac_gic_opf_ts(file, solver; kwargs...)
    return run_gic_opf_ts(file, ACPPowerModel, solver; kwargs...)
end

"Run the basic GMD model"
function run_gic_opf_ts(file::AbstractString, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gic_opf_ts; solution_builder = get_gmd_solution, kwargs...)
end

"Stub out time-series gic problem"
function post_gic_opf_ts(pm::ACPPowerModel; kwargs...)
    PMs.variable_voltage(pm)
    PMs.variable_generation(pm)
    PMs.variable_line_flow(pm)

    variable_demand_factor(pm)

    objective_min_error(pm) # todo: add new function
    #constraint_quasi_dynamic_kcl_shunt(pm, bus, load_shed=true) # todo: add new function

    PMs.constraint_voltage(pm)

    for i in ids(pm, :branch)
        @printf "Adding constraints for branch %d\n" i
        constraint_dc_current_mag(pm, i)
        constraint_qloss_constant_v(pm, i)

        PMs.constraint_ohms_yt_from(pm, i)
        PMs.constraint_ohms_yt_to(pm, i)

        PMs.constraint_thermal_limit_from(pm,i)
        PMs.constraint_thermal_limit_to(pm, i)
        PMs.constraint_voltage_angle_difference(pm, i)
    end

    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
      constraint_dc_kcl_shunt(pm, i)
    end

    for i in ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end