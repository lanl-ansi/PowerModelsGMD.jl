export run_gmd_ls, run_ac_gmd_ls, run_qc_gmd_ls

"FUNCTION: run the GMD mitigation with the nonlinear AC equations"
function run_ac_gmd_ls(data, optimizer; kwargs...)
    return run_gmd_ls(data, PMs.ACPPowerModel, optimizer; kwargs...)
end


"FUNCTION: run the GMD mitigation with the QC AC equations"
function run_qc_gmd_ls(data, optimizer; kwargs...)
    return run_gmd_ls(data, PMs.QCLSPowerModel, optimizer; kwargs...)
end


"FUNCTION: minimize load shedding and fuel costs for GMD mitigation"
function run_gmd_ls(data::String, model_type::Type, optimizer; kwargs...)
    return PMs.run_model(data, model_type, optimizer, post_gmd_ls; ref_extensions=[ref_add_core!], solution_builder = solution_gmd!, kwargs...)
end


"FUNCTION: GMD Model - Minimizes Generator Dispatch and Load Shedding"
function post_gmd_ls(pm::PMs.AbstractPowerModel; kwargs...)

    # Reference - "Optimal Transmission Line Switching under Geomagnetic Disturbances"
    # this corresponds to model C4

    # AC modeling
    PMs.variable_bus_voltage(pm) # theta_i and V_i, includes constraint 3o
    PMs.variable_branch_power(pm) # p_ij, q_ij
    PMs.variable_gen_power(pm) # f^p_i, f^q_i, includes a variation of constraints 3q, 3r
    variable_load(pm) # l_i^p, l_i^q
    variable_ac_current(pm) # \tilde I^a_e and l_e

    # DC modeling
    variable_dc_voltage(pm) # V^d_i
    variable_reactive_loss(pm) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)
    variable_dc_current(pm) # \tilde I^d_e - This is the computed dc current on the AC network lines - this is generally treated as bounded variable
    variable_dc_line_flow(pm) # I^d_e - This is the actual dc current on lines in the DC network


    # Minimize load shedding and fuel cost
    objective_gmd_min_ls(pm) # variation of equation 3a

    PMs.constraint_model_voltage(pm) # Make this on/off

    for i in PMs.ids(pm, :ref_buses)
        PMs.constraint_theta_ref(pm, i)
    end


    for i in PMs.ids(pm, :bus)
        constraint_power_balance_shunt_gmd_ls(pm, i) # variation of 3b, 3c
    end

    for i in PMs.ids(pm, :branch)
        constraint_dc_current_mag(pm, i) # constraints 3u
        constraint_qloss_vnom(pm, i) # individual terms of righthand side of constraints 3x
        constraint_thermal_protection(pm, i) # constraints 3w
        constraint_current(pm, i) # constraints 3k and 3l

        PMs.constraint_ohms_yt_from(pm, i) # variation of constraints 3d, 3e
        PMs.constraint_ohms_yt_to(pm, i)   # variation of constraints 3f, 3g

        PMs.constraint_thermal_limit_from(pm, i) # variation of constraints 3m
        PMs.constraint_thermal_limit_to(pm, i)   # variation of constraints 3m
        PMs.constraint_voltage_angle_difference(pm, i) # variation of constraints 3p
    end

    ### DC network constraints ###
    for i in PMs.ids(pm, :gmd_bus)
        constraint_dc_power_balance_shunt(pm, i) # variation of constraint 3s
    end

    for i in PMs.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i) # variation of constraint 3t
    end
end


