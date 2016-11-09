# Formulations of Various Maximum Loadability Problems
export run_ml, run_mluc

PMs = PowerModels

# Maximum loadability with generator participation fixed
function run_ml(file, model_constructor, solver; kwargs...)
    return PMs.run_generic_model(file, model_constructor, solver, post_ml; kwargs...) 
end

function post_ml{T}(pm::GenericPowerModel{T})
    PMs.variable_complex_voltage(pm)

    PMs.variable_active_generation(pm)
    PMs.variable_reactive_generation(pm)

    PMs.variable_active_line_flow(pm)
    PMs.variable_reactive_line_flow(pm)

    variable_loading_factor(pm)

    objective_max_loadability(pm)

    PMs.constraint_theta_ref(pm)
    PMs.constraint_complex_voltage(pm)

    for (i,bus) in pm.set.buses
        constraint_active_kcl_shunt_lf(pm, bus)
        constraint_reactive_kcl_shunt_lf(pm, bus)
    end

    for (i,branch) in pm.set.branches
        PMs.constraint_active_ohms_yt(pm, branch)
        PMs.constraint_reactive_ohms_yt(pm, branch)

        PMs.constraint_phase_angle_difference(pm, branch)

        PMs.constraint_thermal_limit_from(pm, branch)
        PMs.constraint_thermal_limit_to(pm, branch)
    end
end


# Maximum loadability with flexible generator participation fixed
function run_mluc(file, model_constructor, solver; kwargs...)
    return PMs.run_generic_model(file, model_constructor, solver, post_mluc; kwargs...) 
end

function post_mluc{T}(pm::GenericPowerModel{T})
    PMs.variable_complex_voltage(pm)

    variable_generation_indicator(pm)
    PMs.variable_active_generation(pm)
    PMs.variable_reactive_generation(pm)

    PMs.variable_active_line_flow(pm)
    PMs.variable_reactive_line_flow(pm)

    variable_loading_factor(pm)

    objective_max_loadability(pm)


    PMs.constraint_theta_ref(pm)
    PMs.constraint_complex_voltage(pm)

    for (i,gen) in pm.set.gens
        constraint_generation_active_on_off(pm, gen)
        constraint_generation_reactive_on_off(pm, gen)
    end

    for (i,bus) in pm.set.buses
        constraint_active_kcl_shunt_lf(pm, bus)
        constraint_reactive_kcl_shunt_lf(pm, bus)
    end

    for (i,branch) in pm.set.branches
        PMs.constraint_active_ohms_yt(pm, branch)
        PMs.constraint_reactive_ohms_yt(pm, branch)

        PMs.constraint_phase_angle_difference(pm, branch)

        PMs.constraint_thermal_limit_from(pm, branch)
        PMs.constraint_thermal_limit_to(pm, branch)
    end
end
