export run_gmd_opf_ts, run_ac_gmd_opf_ts


"FUNCTION: convinience function"
function run_gmd_opf_ts(data, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_gmd_opf_ts; ref_extensions=[ref_add_core!], solution_builder = solution_gmd_ts!, multinetwork=true, kwargs...)
end


"FUNCTION: GMD OPF TS problem specification"
function post_gmd_opf_ts(pm::PMs.AbstractPowerModel; kwargs...)

    for (n, network) in PMs.nws(pm)

        # -- Variables -- #

        PMs.variable_bus_voltage(pm, nw=n)
        PMs.variable_gen_power(pm, nw=n)
        PMs.variable_branch_power(pm, nw=n)
        PMs.variable_dcline_power(pm, nw=n)

        variable_dc_voltage(pm, nw=n)
        variable_dc_current_mag(pm, nw=n)
        variable_qloss(pm, nw=n)
        variable_dc_line_flow(pm, nw=n)

        b = true
        variable_delta_oil_ss(pm, nw=n, bounded=b)
        variable_delta_oil(pm, nw=n, bounded=b)
        variable_delta_hotspot_ss(pm, nw=n, bounded=b)
        variable_delta_hotspot(pm, nw=n, bounded=b)
        variable_hotspot(pm, nw=n, bounded=b)

        # -- Constraints -- #

        # - General - #

        PMs.constraint_model_voltage(pm, nw=n)

        for i in PMs.ids(pm, :ref_buses, nw=n)
            PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :bus, nw=n)
            constraint_power_balance_gmd(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :branch, nw=n)
            constraint_dc_current_mag(pm, i, nw=n)
            constraint_qloss_vnom(pm, i, nw=n)

            PMs.constraint_ohms_yt_from(pm, i, nw=n)
            PMs.constraint_ohms_yt_to(pm, i, nw=n)

            PMs.constraint_voltage_angle_difference(pm, i, nw=n)

            PMs.constraint_thermal_limit_from(pm, i, nw=n)
            PMs.constraint_thermal_limit_to(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n) 
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)             
            constraint_hotspot_temperature_state(pm, i, nw=n)                         
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)            
        end

        # - DC network - #

        for i in PMs.ids(pm, :gmd_bus)
            constraint_dc_power_balance_shunt(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :gmd_branch)
            constraint_dc_ohms(pm, i, nw=n)
        end

        for i in PMs.ids(pm, :dcline, nw=n)
            PMs.constraint_dcline(pm, i, nw=n)
        end

    end

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

    objective_gmd_min_transformer_heating(pm)

end


