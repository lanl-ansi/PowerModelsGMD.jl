"FUNCTION: solve the quasi-dc-pf problem followed by the ac-opf problem with qloss constraints"
function solve_ac_gmd_opf_decoupled(file::String, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_ac_gmd_opf_decoupled(data, optimizer; kwargs...)
end

function solve_ac_gmd_opf_decoupled(case::Dict{String,Any}, optimizer; setting=Dict(), kwargs...)
    return solve_gmd_opf_decoupled(case, _PM.ACPPowerModel, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(file::String, model_type, optimizer; setting=Dict(), kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd_opf_decoupled(data, model_type, optimizer; kwargs...)
end

function solve_gmd_opf_decoupled(dc_case::Dict{String,Any}, model_type, optimizer; setting=Dict{String,Any}(), kwargs...)

    branch_setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
    merge!(setting, branch_setting)

    dc_result = solve_gmd(dc_case, optimizer)
    dc_solution = dc_result["solution"]

    ac_case = deepcopy(dc_case)
    for (k, branch) in ac_case["branch"]
        branch["ieff"] = calc_dc_current_mag(branch, ac_case, dc_solution)
    end

    update_qloss_decoupled_vnom!(ac_case)
    ac_result = _PM.solve_opf(ac_case, model_type, optimizer, setting=setting;
        solution_processors = [
            solution_gmd_qloss_decoupled!
        ])
    ac_solution = ac_result["solution"]

    data = Dict()
    data["ac"] = Dict("case"=>ac_case, "result"=>ac_result)
    data["dc"] = Dict("case"=>dc_case, "result"=>dc_result)
    return data

end
