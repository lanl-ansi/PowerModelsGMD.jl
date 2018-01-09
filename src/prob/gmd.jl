# Formulations of GMD Problems
export run_gmd, run_ac_gmd

function run_ac_gmd(file, solver; kwargs...)
    #return run_gmd(file, PMs.ACPPowerModel, solver; kwargs...)
    return run_gmd(file, ACPPowerModel, solver; kwargs...)
end

function run_gmd(file::AbstractString, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...)
   # data = PowerModels.parse_file(file)
    #return run_gmd(data, model_constructor, solver; kwargs...)
end

#function run_gmd(data::Dict{String,Any}, model_constructor, solver; kwargs...)
    #println("Data gmd branches:", keys(data["gmd_branch"]))
 #   pm = model_constructor(data; kwargs...)
    #println("Ref gmd branches:", keys(pm.ref[:gmd_branch]))

  #  PowerModelsGMD.add_gmd_ref(pm)
    #println("GMD ref gmd branches:", keys(pm.ref[:gmd_branch]))

   # post_gmd(pm; kwargs...)

    #solution = solve_generic_model(pm, solver; solution_builder = get_gmd_solution)

    #return solution
    # TODO with improvements to PowerModels, see if this function can be replaced by,
    # return PMs.run_generic_model(file, model_constructor, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...) 
#end

function post_gmd{T}(pm::GenericPowerModel{T}; kwargs...)
    
  
    #println("Power Model GMD data")
    #println("----------------------------------")
    PMs.variable_voltage(pm)

    variable_dc_voltage(pm)

    variable_dc_current_mag(pm)
    variable_qloss(pm)

    PMs.variable_generation(pm) 
    PMs.variable_line_flow(pm) 

    variable_dc_line_flow(pm)

    # get the index of the slack bus
#    println("Ref buses:")
 #   println(keys(pm.ref[:ref_buses]))

    #PMs.constraint_theta_ref(pm) 
    # for (i,bus) in pm.ref[:ref_buses]
    #     PMs.constraint_theta_ref(pm, bus)
    # end

    if :setting in keys(Dict(kwargs))
        setting = Dict(Dict(kwargs)[:setting])
    else
        setting = Dict()
    end

    #println("kwargs: ", kwargs)
    #println("setting: ",setting)

    if "objective" in keys(setting)
        objective = setting["objective"]
    else
        objective = "min_fuel"
    end

    if objective == "min_error"
        variable_demand_factor(pm)
    end


    println("objective: ",objective)

    # println("kwargs: ",Dict(kwargs)[:setting])
    # println("kwargs keys: ",keys(Dict(kwargs)[:setting]))

    # if "objective" in setting
    #     println("OBJECTIVE IS SPECIFIED")
    # else
    #     println("OBJECTIVE NOT SPECIFIED")
    # end

    if objective == "min_error"
        println("APPLYING MIN ERROR OBJECTIVE")
        objective_gmd_min_error(pm)
    else
        println("APPLYING MIN FUEL OBJECTIVE")
        objective_gmd_min_fuel(pm)
    end

    for (i,bus) in ref(pm,:bus)
        if objective == "min_error"
            constraint_gmd_kcl_shunt(pm, i, load_shed=true) 
        else
            constraint_gmd_kcl_shunt(pm, i, load_shed=false)
        end
    end

#    println("GMD ref branches:", keys(pm.ref[:gmd_branch]))

    for (i,branch) in ref(pm,:branch)
        @printf "Adding constraints for branch %d\n" i
        constraint_dc_current_mag(pm, i)
        constraint_qloss(pm, i)

        PMs.constraint_ohms_yt_from(pm, i) 
        PMs.constraint_ohms_yt_to(pm, i) 


        if objective == "min_error"
            # println("APPLYING THERMAL LIMIT CONSTRAINT")
            PMs.constraint_thermal_limit_from(pm, i)
            PMs.constraint_thermal_limit_to(pm, i)
            PMs.constraint_voltage(pm) 
            PMs.constraint_voltage_angle_difference(pm, i) 
        else
            # PMs.constraint_thermal_limit_from(pm, branch)
            # PMs.constraint_thermal_limit_to(pm, branch)
            PMs.constraint_voltage(pm) 
            PMs.constraint_voltage_angle_difference(pm, i) 

            # println("DISABLING THERMAL LIMIT CONSTRAINT")
        end

    end

    #println()
    #println("Buses")
    #println("--------------------")

    ### DC network constraints ###
    for (i,bus) in ref(pm,:gmd_bus)
        # println("bus:")
        # println(bus)
        constraint_dc_kcl_shunt(pm, i)
    end

    #println()
    #println("Branches")
    #println("--------------------")

    for (i,branch) in ref(pm,:gmd_branch)
        constraint_dc_ohms(pm, i)
    end

    #println()
end






