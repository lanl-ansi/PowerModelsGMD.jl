##############
# GIC AC-OTS #
##############


# ===   COUPLED AC-MLS-OTS   === #




# ===   COUPLED AC-MLS-OTS-TS   === #


"FUNCTION: solve the multi-time-series GMD model with nonlinear ac polar relaxation"
function solve_ac_gmd_mls_ots_ts(file, optimizer; kwargs...)
    return solve_gmd_mls_ots_ts( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: solve the multi-time-series GMD model with second order cone relaxation"
function solve_soc_gmd_mls_ots_ts(file, optimizer; kwargs...)
    return solve_gmd_mls_ots_ts( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


function solve_gmd_mls_ots_ts(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_mls_ots_ts;
        multinetwork = true,
        ref_extensions = [
            ref_add_gmd!,
            _PM.ref_add_on_off_va_bounds!
        ],
        solution_processors = [
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end


"FUNCTION: build the multi-time-series coupled quasi-dc-pf and ac-ots with ac-mls problem
as a generator dispatch minimization problem"
function build_gmd_mls_ots_ts(pm::_PM.AbstractPowerModel; kwargs...)
# Reference:
#   built minimum loadshedding problem specification corresponds to the "Model C4" of
#   Mowen et al., "Optimal Transmission Line Switching under Geomagnetic Disturbances", 2018.



    for (n, network) in _PM.nws(pm)

        _PMR.variable_bus_voltage_on_off(pm, nw=n)
        _PM.variable_gen_indicator(pm, nw=n)
        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_branch_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, relax=true)
        _PM.variable_shunt_admittance_factor(pm, relax=true)

        variable_dc_voltage_on_off(pm, nw=n)
        variable_dc_line_flow(pm, nw=n, bounded=false)
        variable_dc_current_mag(pm, nw=n)
        variable_qloss(pm, nw=n)

        variable_delta_oil_ss(pm, nw=n, bounded=true)
        variable_delta_oil(pm, nw=n, bounded=true)
        variable_delta_hotspot_ss(pm, nw=n, bounded=true)
        variable_delta_hotspot(pm, nw=n, bounded=true)
        variable_hotspot(pm, nw=n, bounded=true)

        _PM.constraint_model_voltage_on_off(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_power_balance_gmd_shunt_ls(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            _PM.constraint_gen_power_on_off(pm, i, nw=n)
            constraint_gen_ots_on_off(pm, i, nw=n)
            constraint_gen_perspective(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)

            _PM.constraint_ohms_yt_from_on_off(pm, i, nw=n)
            _PM.constraint_ohms_yt_to_on_off(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

            _PM.constraint_thermal_limit_from_on_off(pm, i, nw=n)
            _PM.constraint_thermal_limit_to_on_off(pm, i, nw=n)

            constraint_qloss_vnom(pm, i, nw=n)
            constraint_dc_current_mag(pm, i, nw=n)
            constraint_dc_current_mag_on_off(pm, i, nw=n)

            constraint_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state_ss(pm, i, nw=n)
            constraint_hotspot_temperature_state(pm, i, nw=n)
            constraint_absolute_hotspot_temperature_state(pm, i, nw=n)

        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_bus, nw=n)
            constraint_dc_kcl(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gmd_branch, nw=n)
            constraint_dc_ohms_on_off(pm, i, nw=n)
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

    _PM.objective_min_fuel_and_flow_cost(pm)

end


"FUNCTION: build coupled quasi-dc-pf and ac-ots with ac-mls problem
as a generator dispatch minimization and load shedding problem

Based on the model described in

[1] M. Lu, H. Nagarajan, E. Yamangil, R. Bent, S. Backhaus and A. Barnes,
\"Optimal Transmission Line Switching Under Geomagnetic Disturbances,\"
in IEEE Transactions on Power Systems, vol. 33, no. 3, pp. 2539-2550, May 2018,
doi: 10.1109/TPWRS.2017.2761178.

but modified so that generator on/off variables are explict.  Reference 1 did
and internal transformation assuming there was a switchable line that was used to
turn a generator on or off

"
function build_gmd_ots(pm::_PM.AbstractPowerModel; kwargs...)

    variable_bus_voltage_on_off(pm) # Variables V and \theta from [1]
    _PM.variable_gen_indicator(pm) # Variable z for generators
    _PM.variable_gen_power(pm) # variable f^p and f^q from [1]
    _PM.variable_branch_indicator(pm) # Variable z for lines from [1]
    _PM.variable_branch_power(pm) # variables p and q from [1]
    _PM.variable_dcline_power(pm) # variable for power on dc lines

    variable_ac_positive_current(pm) # variable I^a and l^a (when necessary) from [1]

#    variable_active_generation_sqr_cost(pm)

    _PM.variable_load_power_factor(pm, relax=true) # variable l^p and l^q from [1], formulated as a 0-1 factor
    _PM.variable_shunt_admittance_factor(pm, relax=true) # variable to allow for variable shunt factors

    variable_dc_voltage_on_off(pm) # variable V^d and V&d-V^d from [1]
    variable_qloss(pm) # variable Qloss form [1]
    variable_gic_current(pm) # tilde(I)^d from [1]
    variable_dc_line_flow(pm, bounded=false) # I^d from [1]

#    constraint_model_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
#        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
#        constraint_power_balance_gmd_shunt_ls(pm, i)
    end

    for i in _PM.ids(pm, :gen)
#        _PM.constraint_gen_power_on_off(pm, i)
#        constraint_gen_ots_on_off(pm, i)
    #    constraint_gen_perspective(pm, i)
    end

    for i in _PM.ids(pm, :branch)

#        _PM.constraint_ohms_yt_from_on_off(pm, i)
#        _PM.constraint_ohms_yt_to_on_off(pm, i)

#        _PM.constraint_voltage_angle_difference_on_off(pm, i)

#        _PM.constraint_thermal_limit_from_on_off(pm, i)
#        _PM.constraint_thermal_limit_to_on_off(pm, i)

#        constraint_qloss(pm, i)
#        constraint_current_on_off(pm, i) - this will need to be added back in
#        constraint_dc_current_mag(pm, i)
#        constraint_dc_current_mag_on_off(pm, i)

#        constraint_thermal_protection(pm, i) - needs to be added back in

    end

    for i in _PM.ids(pm, :dcline)
#        _PM.constraint_dcline_power_losses(pm, i)
    end

    for i in _PM.ids(pm, :gmd_bus)
#        constraint_dc_kcl(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
#        constraint_dc_ohms_on_off(pm, i)
    end

    #objective_gmd_mls_on_off(pm) - needs to be added back in

end
