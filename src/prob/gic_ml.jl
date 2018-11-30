# Formulations of GMD Mitigation Problems that allow load shedding and generation dispatch
# Reference - "Optimal Transmission Line Switching under Geomagnetic Disturbances", IEEE Transactions on Power Systems
# This corresponds to model C4

export run_gmd_ls, run_ac_gmd_ls, run_qc_gmd_ls

"Run the GMD mitigation with the nonlinear AC equations"
function run_ac_gmd_ls(file, solver; kwargs...)
    return run_gmd_ls(file, ACPPowerModel, solver; kwargs...)
end

"Run the GMD mitigation with the QC AC equations"
function run_qc_gmd_ls(file, solver; kwargs...)
    return run_gmd_ls(file, QCWRTriPowerModel, solver; kwargs...)
end

"Minimize load shedding and fuel costs for GMD mitigation"
function run_gmd_ls(file::AbstractString, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gmd_ls; solution_builder = get_gmd_solution, kwargs...)
end

"GMD Model - Minimizes Generator Dispatch and Load Shedding"
function post_gmd_ls{T}(pm::GenericPowerModel{T}; kwargs...)

    # AC modeling
    PMs.variable_voltage(pm) # theta_i and V_i, includes constraint 3o 
    PMs.variable_branch_flow(pm) # p_ij, q_ij
    PMs.variable_generation(pm) # f^p_i, f^q_i, includes a variation of constraints 3q, 3r 
    variable_load(pm) # l_i^p, l_i^q
    variable_ac_current(pm) # \tilde I^a_e and l_e

    # DC modeling
    variable_dc_voltage(pm) # V^d_i 
    variable_reactive_loss(pm) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)
    variable_dc_current(pm) # \tilde I^d_e - This is the computed dc current on the AC network lines - this is generally treated as bounded variable
    variable_dc_line_flow(pm) # I^d_e - This is the actual dc current on lines in the DC network

    # Minimize load shedding and fuel cost 
    objective_gmd_min_ls(pm) # variation of equation 3a

    PMs.constraint_voltage(pm) # Make this on/off

    for i in ids(pm, :ref_buses)
        PMs.constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_kcl_shunt_gmd_ls(pm, i) # variation of 3b, 3c
    end

    for i in ids(pm, :branch)
        constraint_dc_current_mag(pm, i) # constraints 3u
        constraint_qloss(pm, i) # individual terms of righthand side of constraints 3x
        constraint_thermal_protection(pm, i) # constraints 3w
        constraint_current(pm, i) # constraints 3k and 3l

        PMs.constraint_ohms_yt_from(pm, i) # variation of constraints 3d, 3e
        PMs.constraint_ohms_yt_to(pm, i)   # variation of constraints 3f, 3g

        PMs.constraint_thermal_limit_from(pm, i) # variation of constraints 3m
        PMs.constraint_thermal_limit_to(pm, i)   # variation of constraints 3m
        PMs.constraint_voltage_angle_difference(pm, i) # variation of constraints 3p
    end

    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
       constraint_dc_kcl_shunt(pm, i) # variation of constraint 3s
    end

    for i in ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i) # variation of constraint 3t
    end
end
