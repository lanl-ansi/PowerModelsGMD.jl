
" Generic algorithm that solves GIC optimization in a decoupled fashion, where first the gic flows are solved and then the ac flows"

function solve_gmd_decoupled(dc_case::Dict{String,Any}, model_constructor, solver, gic_prob_method, ac_prob_method;  return_dc=false, kwargs...)
    return solve_gmd_decoupled(dc_case, model_constructor, solver, solver, gic_prob_method, ac_prob_method; return_dc, kwargs)
end

function solve_gmd_decoupled(dc_case::Dict{String,Any}, model_constructor, solver_ac, solver_dc, gic_prob_method, ac_prob_method;  return_dc=false, kwargs...)
    setting = kwargs[:setting]
    if (solver_dc != None)
        dc_result = gic_prob_method(dc_case, solver_dc)
    else
        dc_result = gic_prob_method(dc_case); # Change to linear result
    end
    dc_solution = dc_result["solution"]
    ac_case = deepcopy(dc_case)

    for branch in values(ac_case["branch"])
        branch["ieff"] = calc_ieff_current_mag(branch, ac_case, dc_solution)
    end
    # Assumes solver_ac valid

    if (solver_ac == None)
        solver_ac = _PM.compute_ac_pf(ac_case)
    else
        ac_result = ac_prob_method(ac_case, model_constructor, solver_ac, setting=setting; solution_processors = [
        solution_gmd_qloss!,
        ],
        )
    end

    for (i, branch) in ac_case["branch"]
        ac_result["solution"]["branch"][i]["gmd_idc_mag"] = branch["ieff"]
    end

    for (asset, indicies) in dc_solution
        if typeof(indicies) != Dict{String,Any}
            continue
        end

        if !haskey(ac_result["solution"], asset)
            ac_result["solution"][asset] = Dict{String,Any}()
        end

        for (i, variables) in indicies
            if !haskey(ac_result["solution"][asset], i)
                ac_result["solution"][asset][i] = Dict{String,Any}()
            end

            if typeof(variables) != Dict{String,Any}
                Memento.warn(_LOGGER, "Variable dc_solution[$asset][$i] isn't a dictionary")
                continue
            end
    

            for (variable, assignment) in variables
                ac_result["solution"][asset][i][variable] = assignment
                # try
                #     ac_result["solution"][asset][i][variable] = assignment
                # catch
                #     println("Error assigning ac_result[\"solution\"][$asset][$i][$variable] = $assignment")
                # end
            end
        end

    end

    if return_dc
        data = Dict()
        data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
        data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
        return data
    end

    return ac_result
    #    ac_solution = ac_result["solution"]
end


"Helper functions for using the decoupled algorithm for the MLD problem"
function solve_soc_gmd_mld_decoupled(case::Dict{String,Any}, solver; kwargs...)
    return solve_gmd_mld_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_ac_gmd_mld_decoupled(case::Dict{String,Any}, solver; kwargs...)
    return solve_gmd_mld_decoupled(case, _PM.ACPPowerModel, solver; kwargs...)
end

function solve_gmd_mld_decoupled(file::String, model_constructor, solver; kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_mld_decoupled(data, model_constructor, solver; kwargs...)
end

function solve_gmd_mld_decoupled(case::Dict{String,Any}, model_constructor, solver; kwargs...)
    return solve_gmd_decoupled(case, model_constructor, solver, _PMGMD.solve_gmd, _PMGMD.solve_gmd_mld_uncoupled; kwargs...)
end


"Helper functions for using the decoupled algorithm for the OPF problem"
function solve_soc_gmd_opf_decoupled(case::Dict{String,Any}, solver; kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_ac_gmd_opf_decoupled(case::Dict{String,Any}, solver; kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.ACPPowerModel, solver; kwargs...)
end

function solve_gmd_opf_decoupled(file::String, model_constructor, solver; kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_opf_decoupled(data, model_constructor, solver; kwargs...)
end

function solve_gmd_opf_decoupled(case::Dict{String,Any}, model_constructor, solver; kwargs...)
    return solve_gmd_decoupled(case, model_constructor, solver, _PMGMD.solve_gmd, _PMGMD.solve_gmd_opf_uncoupled; kwargs...)
end


"Helper functions for using the decoupled algorithm for the PF problem"
function solve_soc_gmd_pf_decoupled(case::Dict{String,Any}, solver; kwargs...)
    return solve_gmd_pf_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_ac_gmd_pf_decoupled(case::Dict{String,Any}, solver; kwargs...)
    return solve_gmd_pf_decoupled(case, _PM.ACPPowerModel, solver; kwargs...)
end

function solve_gmd_pf_decoupled(file::String, model_constructor, solver; kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_pf_decoupled(data, model_constructor, solver; kwargs...)
end

function solve_gmd_pf_decoupled(case::Dict{String,Any}, model_constructor, solver; kwargs...)
    return solve_gmd_decoupled(case, model_constructor, solver, _PMGMD.solve_gmd, _PMGMD.solve_gmd_pf_uncoupled; kwargs...)
end

