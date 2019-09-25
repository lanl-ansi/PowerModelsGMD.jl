export run_gmd_ots_ts, run_ac_gmd_ots_ts

# FIX THIS ...

"FUNCTION: ..."




# Formulations of GMD Problems


"Run basic GMD with the nonlinear AC equations"
function run_ac_gic_ots_ts(file, solver; kwargs...)
    return run_gmd(file, ACPPowerModel, solver; kwargs...)
end

"Run the basic GMD model"
function run_gic_ots_ts(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gic_opf; solution_builder = get_gmd_solution, kwargs...)
end

"Basic GMD Model - Minimizes Generator Dispatch"
function post_gic_ts(pm::GenericPowerModel; kwargs...)

    PMs.variable_voltage(pm)

    variable_dc_voltage(pm)

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_generation(pm)
    PMs.variable_branch_flow(pm)

    variable_dc_line_flow(pm)

    objective_gmd_min_fuel(pm)

    PMs.constraint_voltage(pm)

    for i in ids(pm, :ref_buses)
        PMs.constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_kcl_gic(pm, i)
    end

    for i in ids(pm, :branch)
        debug(LOGGER, @sprintf "Adding constraints for branch %d\n" i)
        constraint_dc_current_mag(pm, i)
        constraint_qloss_constant_v(pm, i)

        PMs.constraint_ohms_yt_from(pm, i) 
        PMs.constraint_ohms_yt_to(pm, i) 

        PMs.constraint_thermal_limit_from(pm, i)
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






