
# Formulations of GMD Problems
export run_gmd_opf_ts, run_ac_gmd_opf_ts


"Run the basic GMD model"
function run_gmd_opf_ts(file, model_constructor, solver; kwargs...)
    return PMs.run_model(file, model_constructor, solver, post_gmd_opf_ts; solution_builder = get_gmd_solution, multinetwork=true, kwargs...)
end


"Run basic GMD with the nonlinear AC equations"
# function run_ac_gmd_opf_ts(file, solver; kwargs...)
#     return run_gmd_opf_ts(file, PMs.ACPPowerModel, solver; kwargs...)
# end


"Stub out quasi dynamic gmd"
# FUNCTION: problem formulation
function post_gmd_opf_ts(pm::PMs.GenericPowerModel)
    for (n, network) in nws(pm)
        PMs.variable_voltage(pm, nw=n)
        PowerModelsGMD.variable_dc_voltage(pm, nw=n)
        PowerModelsGMD.variable_dc_current_mag(pm, nw=n)
        PowerModelsGMD.variable_qloss(pm, nw=n)
        PMs.variable_generation(pm, nw=n)
        PMs.variable_branch_flow(pm, nw=n)
        PMs.variable_dcline_flow(pm, nw=n)
        PowerModelsGMD.variable_dc_line_flow(pm, nw=n)

        #variable_demand_factor(pm) #TODO: add new function
        #objective_min_error(pm) #TODO: add new function
        #constraint_quasi_dynamic_kcl_shunt(pm, bus, load_shed=true) #TODO add new function
        
        PowerModelsGMD.variable_delta_oil_ss(pm, nw=n)
        PowerModelsGMD.variable_delta_oil(pm, nw=n)

        PMs.constraint_model_voltage(pm, nw=n)

        for i in PMs.ids(pm, :ref_buses, nw=n)
            PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :bus, nw=n)
            PowerModelsGMD.constraint_kcl_gmd(pm, i, nw=n)
        end
        @printf "Adding constraints for branch %d\n" i
        for i in PMs.ids(pm, :branch, nw=n)
            PowerModelsGMD.constraint_dc_current_mag(pm, i, nw=n)
            PowerModelsGMD.constraint_qloss_vnom(pm, i, nw=n)

            PMs.constraint_ohms_yt_from(pm, i, nw=n)
            PMs.constraint_ohms_yt_to(pm, i, nw=n)

            PMs.constraint_voltage_angle_difference(pm, i, nw=n)

            PMs.constraint_thermal_limit_from(pm, i, nw=n)
            PMs.constraint_thermal_limit_to(pm, i, nw=n)

            PowerModelsGMD.constraint_temperature_state_ss(pm, i, nw=n)
        end

        ### DC network constraints ###
        for i in PMs.ids(pm, :gmd_bus)
            PowerModelsGMD.constraint_dc_kcl_shunt(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :gmd_branch)
            PowerModelsGMD.constraint_dc_ohms(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :dcline, nw=n)
            PMs.constraint_dcline(pm, i, nw=n)
        end
    end

    PowerModelsGMD.objective_gmd_min_fuel(pm)
end


