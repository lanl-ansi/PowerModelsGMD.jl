export run_gmd_opf, run_ac_gmd_opf


"FUNCTION: run basic GMD model"
function run_gmd_opf(data, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_gmd_opf; ref_extensions=[ref_add_core!], solution_builder = solution_gmd!, kwargs...)
end


"FUNCTION: run basic GMD with the nonlinear AC equations"
function run_ac_gmd_opf(data, optimizer; kwargs...)
    return run_gmd_opf(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: Basic GMD Model - Minimizes Generator Dispatch"
function post_gmd_opf(pm::PMs.AbstractPowerModel; kwargs...)

    PMs.variable_voltage(pm)
    variable_dc_voltage(pm)
    variable_dc_current_mag(pm)
    variable_qloss(pm)
    PMs.variable_generation(pm)
    PMs.variable_branch_flow(pm)
    variable_dc_line_flow(pm)

    objective_gmd_min_fuel(pm)

    PMs.constraint_model_voltage(pm)

    for i in PMs.ids(pm, :ref_buses)
        PMs.constraint_theta_ref(pm, i)
    end


    for i in PMs.ids(pm, :bus)
        constraint_kcl_gmd(pm, i)
    end

    for i in PMs.ids(pm, :branch)
        Memento.debug(_LOGGER, "Adding constraints for branch $i \n")
        constraint_dc_current_mag(pm, i)
        constraint_qloss_vnom(pm, i)

        PMs.constraint_ohms_yt_from(pm, i)
        PMs.constraint_ohms_yt_to(pm, i)

        # PMs.constraint_thermal_limit_from(pm, i)
        # PMs.constraint_thermal_limit_to(pm, i)
        PMs.constraint_voltage_angle_difference(pm, i)
    end

    ### DC network constraints ###
    for i in PMs.ids(pm, :gmd_bus)
        constraint_dc_kcl_shunt(pm, i)
    end

    for i in PMs.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end


