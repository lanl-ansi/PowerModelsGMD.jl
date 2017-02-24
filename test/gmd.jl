

@testset "test ac gmd" begin
    @testset "4-bus case" begin
        data = PowerModels.parse_file("/home/abarnes/.julia/v0.5/PowerModelsGMD/test/data/b4gic.json")
        data["do_gmd"] = true
        data = PowerModelsGMD.setup_gmd(data)
        # data = PowerModels.parse_file("../test/data/b4gic.json")
        pm = PowerModels.ACPPowerModel(data,solver=IpoptSolver())
        pm.setting["output"] = Dict("line_flows" => true)
        PowerModelsGMD.post_gmd(pm)
        status, solve_time = solve(pm)
        result = PowerModels.build_solution(pm, status, solve_time; solution_builder = PowerModelsGMD.get_gmd_solution)

        if !(result["status"] === :LocalInfeasible)
            data = PowerModelsGMD.merge_result(data,result)
        end
        # result = run_ml("../test/data/case3_ml.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)
    end
end





