export run_gmd_ots_ts, run_ac_gmd_ots_ts


"FUNCTION: convinience function"
function run_gmd_ots_ts(file, model_type::Type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, post_gmd_ots_ts; ref_extensions=[PMs.ref_add_on_off_va_bounds!], solution_builder = solution_gmd_ts!, multinetwork=true, kwargs...)
end


"FUNCTION: GMD OTS TS problem formulation"
function post_gmd_ots_ts(pm::PMs.AbstractPowerModel; kwargs...)

    for (n, network) in nws(pm)

        # -- Variables -- #

        PMs.variable_voltage_on_off(pm, nw=n) # theta_i and V_i, includes constraint 3o
        PMs.variable_generation(pm, nw=n) 
        PMs.variable_branch_flow(pm, nw=n) 
        PMs.variable_dcline_flow(pm, nw=n) 

        # AC switching variables
        PMs.variable_branch_indicator(pm, nw=n) # z_e variable

        variable_dc_current_mag(pm, nw=n)
        variable_dc_current(pm, nw=n)
        variable_dc_line_flow(pm; bounded=false, nw=n)
        variable_dc_voltage_on_off(pm, nw=n)

        variable_qloss(pm, nw=n) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)

        # GMD switching-related variables
		# variable_active_generation_sqr_cost(pm, nw=n)
        # variable_load(pm, nw=n) # l_i^p, l_i^qPG.
        # variable_gen_indicator(pm, nw=n)  # z variables for the generators

        # Thermal variables
        b = true
        variable_delta_oil_ss(pm, nw=n, bounded=b)
        variable_delta_oil(pm, nw=n, bounded=b)
        variable_delta_hotspot_ss(pm, nw=n, bounded=b)
        variable_delta_hotspot(pm, nw=n, bounded=b)
        variable_hotspot(pm, nw=n, bounded=b)

        # -- Constraints -- #

        # - General - #

        PMs.constraint_model_voltage_on_off(pm, nw=n)

        for i in PMs.ids(pm, :ref_buses, nw=n)
            PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :bus, nw=n)
            constraint_kcl_gmd(pm, i, nw=n)
            # constraint_power_balance_shunt(pm, i, nw=n)
        end

	    # for i in PMs.ids(pm, :gen)
	    #    constraint_gen_on_off(pm, i, nw=n) # variation of 3q, 3r
	    #    constraint_gen_ots_on_off(pm, i, nw=n)
	    #    constraint_gen_perspective(pm, i, nw=n)
	    # end

        for i in PMs.ids(pm, :branch, nw=n)
            Pconstraint_dc_current_mag_on_off(pm, i, nw=n)
            # OTS formulation is using constraint_qloss
            constraint_qloss_vnom(pm, i, nw=n)

            PMs.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            PMs.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            PMs.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            PMs.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            PMs.constraint_thermal_limit_to_on_off(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n) 
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)             
            constraint_hotspot_temperature_state(pm, i, nw=n)                         
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)            
        end

        # - DC network - #

        for i in PMs.ids(pm, :gmd_bus)
            constraint_dc_kcl_shunt(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :gmd_branch)
            constraint_dc_ohms_on_off(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :dcline, nw=n)
            PMs.constraint_dcline(pm, i, nw=n)
        end
    end

    # for i in PMs.ids(pm, :branch, nw=1)
    #     constraint_avg_absolute_hotspot_temperature_state(pm, i)
    # end

    network_ids = sort(collect(nw_ids(pm)))

    n_1 = network_ids[1]
    for i in ids(pm, :branch, nw=n_1)
        constraint_temperature_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in ids(pm, :branch, nw=n_2)
            constraint_temperature_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    # -- Objective -- #

    # this has multinetwork built-in
    # objective_gmd_min_ls_on_off(pm)
    PMs.objective_min_fuel_and_flow_cost(pm)

    # objective_gmd_min_fuel(pm)
    # objective_gmd_min_transformer_heating(pm)

end


