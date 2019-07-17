export run_gmd_opf_ts, run_ac_gmd_opf_ts


"FUNCTION: run the basic GMD model"
function run_gmd_opf_ts(file, model_constructor, solver; kwargs...)
    return PMs.run_model(file, model_constructor, solver, post_gmd_opf_ts; solution_builder = get_gmd_ts_solution, multinetwork=true, kwargs...)
end


"FUNCTION: run basic GMD with the nonlinear AC equations"
# function run_ac_gmd_opf_ts(file, solver; kwargs...)
#     return run_gmd_opf_ts(file, PMs.ACPPowerModel, solver; kwargs...)
# end


"FUNCTION: GMD OPF TS problem formulation"
# TODO: Stub out quasi dynamic gmd
function post_gmd_opf_ts(pm::PMs.GenericPowerModel)
    for (n, network) in PMs.nws(pm)
        
        # -- Variables -- #
        
        PMs.variable_generation(pm, nw=n)
        PMs.variable_voltage(pm, nw=n)
        PMs.variable_branch_flow(pm, nw=n)
        PMs.variable_dcline_flow(pm, nw=n)
        
        PowerModelsGMD.variable_dc_line_flow(pm, nw=n)
        PowerModelsGMD.variable_dc_voltage(pm, nw=n)
        PowerModelsGMD.variable_dc_current_mag(pm, nw=n)
        PowerModelsGMD.variable_qloss(pm, nw=n)
        
        #PowerModelsGMD.variable_delta_topoilrise(pm, nw=n) #decided not to store value
        PowerModelsGMD.variable_delta_topoilrise_ss(pm, nw=n)
        PowerModelsGMD.variable_delta_hotspotrise_ss(pm, nw=n)
        PowerModelsGMD.variable_actual_hotspot(pm, nw=n)


        # -- Constraints -- #

        # - General - #

        PMs.constraint_model_voltage(pm, nw=n)

        for i in PMs.ids(pm, :ref_buses, nw=n)
            PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :bus, nw=n)
            PowerModelsGMD.constraint_kcl_gmd(pm, i, nw=n)
        end
        
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

        # - DC network - #

        for i in PMs.ids(pm, :gmd_bus)
            PowerModelsGMD.constraint_dc_kcl_shunt(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :gmd_branch)
            PowerModelsGMD.constraint_dc_ohms(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :dcline, nw=n)
            PMs.constraint_dcline(pm, i, nw=n)
        end

        # - Thermal - # 
    
        PowerModelsGMD.constraint_delta_topoilrise(pm, nw=n)
        PowerModelsGMD.constraint_delta_topoilrise_ss(pm, nw=n)
        PowerModelsGMD.constraint_delta_hotspotrise(pm, nw=n)
        PowerModelsGMD.constraint_delta_hotspotrise_ss(pm, nw=n)


        # -- Future improvements -- # 

        #variable_demand_factor(pm) #TODO: add new function
        #objective_min_error(pm) #TODO: add new function
        #constraint_quasi_dynamic_kcl_shunt(pm, bus, load_shed=true) #TODO add new function


    end


    # -- Objective -- #

    PowerModelsGMD.objective_gmd_min_fuel(pm)

end

