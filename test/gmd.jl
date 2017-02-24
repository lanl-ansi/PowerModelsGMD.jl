

@testset "test ac gmd" begin
    @testset "4-bus case" begin
        # data = PowerModels.parse_file("/home/abarnes/.julia/v0.5/PowerModelsGMD/test/data/b4gic.json")
        data = PowerModels.parse_file("../test/data/b4gic.json")
        data["do_gmd"] = true
        data = PowerModelsGMD.setup_gmd(data)
        pm = PowerModels.ACPPowerModel(data,solver=IpoptSolver())
        pm.setting["output"] = Dict("line_flows" => true)
        PowerModelsGMD.post_gmd(pm)
        status, solve_time = solve(pm)
        result = PowerModels.build_solution(pm, status, solve_time; solution_builder = PowerModelsGMD.get_gmd_solution)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)
    end

    @testset "6-bus case" begin
        # data = PowerModels.parse_file("/home/abarnes/.julia/v0.5/PowerModelsGMD/test/data/b4gic.json")
        data = PowerModels.parse_file("../test/data/b6gic_nerc.json")
        data["do_gmd"] = true
        data = PowerModelsGMD.setup_gmd(data)
        pm = PowerModels.ACPPowerModel(data,solver=IpoptSolver())
        pm.setting["output"] = Dict("line_flows" => true)
        PowerModelsGMD.post_gmd(pm)
        status, solve_time = solve(pm)
        result = PowerModels.build_solution(pm, status, solve_time; solution_builder = PowerModelsGMD.get_gmd_solution)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 11832.5; atol = 1e2)
    end

    @testset "19-bus case" begin
        # data = PowerModels.parse_file("/home/abarnes/.julia/v0.5/PowerModelsGMD/test/data/b4gic.json")
        data = PowerModels.parse_file("../test/data/epri21.json")
        data["do_gmd"] = true
        data = PowerModelsGMD.setup_gmd(data)
        pm = PowerModels.ACPPowerModel(data,solver=IpoptSolver())
        pm.setting["output"] = Dict("line_flows" => true)
        PowerModelsGMD.post_gmd(pm)
        status, solve_time = solve(pm)
        result = PowerModels.build_solution(pm, status, solve_time; solution_builder = PowerModelsGMD.get_gmd_solution)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5.08585e5; atol = 1e2)
    end


    @testset "150-bus case" begin
        # data = PowerModels.parse_file("/home/abarnes/.julia/v0.5/PowerModelsGMD/test/data/b4gic.json")
        data = PowerModels.parse_file("../test/data/uiuc150.json")
        data["do_gmd"] = true
        data = PowerModelsGMD.setup_gmd(data)
        pm = PowerModels.ACPPowerModel(data,solver=IpoptSolver())
        pm.setting["output"] = Dict("line_flows" => true)
        PowerModelsGMD.post_gmd(pm)
        status, solve_time = solve(pm)
        result = PowerModels.build_solution(pm, status, solve_time; solution_builder = PowerModelsGMD.get_gmd_solution)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 9.52847e5; atol = 1e2)
    end
end





