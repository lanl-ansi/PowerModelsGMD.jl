export solve_ac_gmd_opf_ts
export solve_gmd_opf_ts


"FUNCTION: run multi-time-series GMD model with nonlinear ac equations"
function solve_ac_gmd_opf_ts(file, optimizer; kwargs...)
    return solve_gmd_opf_ts( file, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_gmd_opf_ts(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_opf_ts;
        multinetwork = true,
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!,
            solution_PM!,
            solution_gmd_qloss!,
            solution_gmd_mls!,
            solution_gmd_xfmr_temp!
        ],
        kwargs...,
    )
end


"FUNCTION: build the multi-time-series ac optimal power flow coupled with quasi-dc power flow problem
as a transformer heating minimization problem"
function build_gmd_opf_ts(pm::_PM.AbstractPowerModel; kwargs...)

    for (n, network) in _PM.nws(pm)

        _PM.variable_bus_voltage(pm, nw=n)
        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        variable_dc_voltage(pm, nw=n)
        variable_dc_current_mag(pm, nw=n)
        variable_dc_line_flow(pm, nw=n)
        variable_qloss(pm, nw=n)

        variable_delta_oil_ss(pm, nw=n, bounded=true)
        variable_delta_oil(pm, nw=n, bounded=true)
        variable_delta_hotspot_ss(pm, nw=n, bounded=true)
        variable_delta_hotspot(pm, nw=n, bounded=true)
        variable_hotspot(pm, nw=n, bounded=true)

        _PM.constraint_model_voltage(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_power_balance_gmd(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)

            _PM.constraint_ohms_yt_from(pm, i, nw=n)
            _PM.constraint_ohms_yt_to(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm, i, nw=n)

            _PM.constraint_thermal_limit_from(pm, i, nw=n)
            _PM.constraint_thermal_limit_to(pm, i, nw=n)

            constraint_qloss_vnom(pm, i, nw=n)
            constraint_dc_current_mag(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state(pm, i, nw=n)
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)

        end

        for i in _PM.ids(pm, :gmd_bus, nw=n)
            constraint_dc_power_balance_shunt(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_branch, nw=n)
            constraint_dc_ohms(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

    end

    network_ids = sort(collect(nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PM.ids(pm, :branch, nw=n_1)
        constraint_temperature_state(pm, i, nw=n_1)
    end
    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_temperature_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    objective_gmd_min_transformer_heating(pm)

end

