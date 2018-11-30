# Formulations of GMD Mitigation Problems that allow load shedding and generation dispatch and optimal transmission switching
# Reference - "Optimal Transmission Line Switching under Geomagnetic Disturbances", IEEE Transactions on Power Systems
# This corresponds to model C1
# No longer treating generator transformers as resistance-less edges anymore

export run_gic_ots, run_ac_gic_ots, run_qc_gic_ots

"Run the GMD mitigation with the nonlinear AC equations"
function run_ac_gic_ots(file, solver; kwargs...)
    return run_gic_ots(file, ACPPowerModel, solver; kwargs...)
end

"Run the GMD mitigation with the QC AC equations"
function run_qc_gic_ots(file, solver; kwargs...)
    return run_gic_ots(file, QCWRTriPowerModel, solver; kwargs...)
end

"Minimize load shedding and fuel costs for GMD mitigation"
function run_gic_ots(file::AbstractString, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gic_ots; solution_builder = get_gmd_solution, kwargs...)
end

"GMD Model - Minimizes Generator Dispatch and Load Shedding"
function post_gic_ots{T}(pm::GenericPowerModel{T}; kwargs...)

    # AC modeling
    PMs.variable_voltage_on_off(pm) # theta_i and V_i, includes constraint 3o 
    PMs.variable_active_branch_flow(pm) # p_ij 
    PMs.variable_reactive_branch_flow(pm) # q_ij
    # no bounds because of the on/off constraints
    PMs.variable_generation(pm, bounded=false) # f^p_i, f^q_i, includes a variation of constraints 3q, 3r
    variable_active_generation_sqr_cost(pm)
    PMs.variable_branch_indicator(pm) # z_e variable 
    variable_load(pm) # l_i^p, l_i^q
    variable_ac_current_on_off(pm) # \tilde I^a_e and l_e
    variable_gen_indicator(pm) # z variables for the generators
    
    # DC modeling
    variable_dc_voltage_on_off(pm) # V^d_i 
    variable_reactive_loss(pm) # Q_e^loss for each edge (used to compute  Q_i^loss for each node)
    variable_dc_current(pm) # \tilde I^d_e
    variable_dc_line_flow(pm;bounded=false) # I^d_e

    # Minimize load shedding and fuel cost 
    objective_gic_min_ls_on_off(pm) # variation of equation 3a

    PMs.constraint_voltage_on_off(pm) 

    for i in ids(pm, :ref_buses)
        PMs.constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_kcl_shunt_gic_ls(pm, i) # variation of 3b, 3c 
    end
    
    for i in ids(pm, :gen)
        constraint_gen_on_off(pm, i) # variation of 3q, 3r 
        constraint_gen_ots_on_off(pm, i)
        constraint_gen_perspective(pm, i)
    end
    
    for i in ids(pm, :branch)
        constraint_dc_current_mag(pm, i) # constraints 3u
        constraint_dc_current_mag_on_off(pm, i) # helper constraint to force the "psuedo" DC current 0 when line is turned off
        
        constraint_qloss(pm, i) # individual terms of righthand side of constraints 3x
        constraint_thermal_protection(pm, i) # constraints 3w
        constraint_current_on_off(pm, i) # constraints 3k, 3l, and 3n

        PMs.constraint_ohms_yt_from_on_off(pm, i) # constraints 3d, 3e
        PMs.constraint_ohms_yt_to_on_off(pm, i)   # constraints 3f, 3g
              
        PMs.constraint_thermal_limit_from_on_off(pm, i) # constraints 3m
        PMs.constraint_thermal_limit_to_on_off(pm, i)   # constraints 3m
        PMs.constraint_voltage_angle_difference_on_off(pm, i) # constraints 3p
    end
 
    ### DC network constraints ###
    for i in ids(pm, :gmd_bus)
       constraint_dc_kcl_shunt(pm, i) # constraint 3s
    end

    for i in ids(pm, :gmd_branch)
        constraint_dc_ohms_on_off(pm, i) # constraint 3t
    end   
end
