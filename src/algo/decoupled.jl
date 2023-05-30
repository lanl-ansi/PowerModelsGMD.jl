
" Generic algorithm that solves GIC optimization in a decoupled fashion, where first the gic flows are solved and then the ac flows"
function solve_gmd_decoupled(dc_case::Dict{String,Any}, model_constructor, solver, gic_prob_method, ac_prob_method; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = gic_prob_method(dc_case, solver)

    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for branch in values(ac_case["branch"])
        branch["ieff"] = calc_dc_current_mag(branch, ac_case, dc_solution)
    end

    ac_result = ac_prob_method(ac_case, model_constructor, solver, setting=setting; solution_processors = [
        solution_gmd_qloss!,
    ],
    )
    for (i, branch) in ac_case["branch"]
        ac_result["solution"]["branch"][i]["gmd_idc_mag"] = branch["ieff"]
    end

    ac_solution = ac_result["solution"]

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end


"Helper functions for using the decoupled algorithm for the MLD problem"
function solve_soc_gmd_mld_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_mld_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_ac_gmd_mld_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_mld_decoupled(case, _PM.ACPPowerModel, solver; kwargs...)
end

function solve_gmd_mld_decoupled(file::String, model_constructor, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_mld_decoupled(data, model_constructor, solver; kwargs...)
end

function solve_gmd_mld_decoupled(case::Dict{String,Any}, model_constructor, solver; setting=Dict(), kwargs...)
    return solve_gmd_decoupled(case, model_constructor, solver, _PMGMD.solve_gmd, _PMGMD.solve_gmd_mld_uncoupled; kwargs...)
end


"Helper functions for using the decoupled algorithm for the OPF problem"
function solve_soc_gmd_opf_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_ac_gmd_opf_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.ACPPowerModel, solver; kwargs...)
end

function solve_gmd_opf_decoupled(file::String, model_constructor, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_opf_decoupled(data, model_constructor, solver; kwargs...)
end

function solve_gmd_opf_decoupled(case::Dict{String,Any}, model_constructor, solver; setting=Dict(), kwargs...)
    return solve_gmd_decoupled(case, model_constructor, solver, _PMGMD.solve_gmd, _PMGMD.solve_gmd_opf_uncoupled; kwargs...)
end


"Helper functions for using the decoupled algorithm for the PF problem"
function solve_soc_gmd_pf_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_pf_decoupled(case, _PM.SOCWRPowerModel, solver; kwargs...)
end

function solve_ac_gmd_pf_decoupled(case::Dict{String,Any}, solver; setting=Dict(), kwargs...)
    return solve_gmd_pf_decoupled(case, _PM.ACPPowerModel, solver; kwargs...)
end

function solve_gmd_pf_decoupled(file::String, model_constructor, solver; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_pf_decoupled(data, model_constructor, solver; kwargs...)
end

function solve_gmd_pf_decoupled(case::Dict{String,Any}, model_constructor, solver; setting=Dict(), kwargs...)
    return solve_gmd_decoupled(case, model_constructor, solver, _PMGMD.solve_gmd, _PMGMD.solve_gmd_pf_uncoupled; kwargs...)
end
