@testset "test ac ml" begin
    @testset "3-bus case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case3.json", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5812; atol = 1e0)
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 79804; atol = 1e0)
    end
end


@testset "test dc ml" begin
    @testset "3-bus case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case3.json", DCPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5695; atol = 1e0)
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", DCPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        println("DC results: $(result["objective"])")
    #    @test isapprox(result["objective"], 79804; atol = 1e0)
    end
end


@testset "test soc ml" begin
    @testset "3-bus case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case3.json", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5735.9; atol = 1e0)
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 70831; atol = 1e0)
    end
end


@testset "test qc ml" begin
    @testset "3-bus case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case3.json", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5742.0; atol = 1e0)
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 77049; atol = 1e0)
    end
end


@testset "test sdp ml" begin
    @testset "3-bus case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case3.json", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 5788.7; atol = 1e0)
    end
    # TODO replace this with smaller case, way too slow for unit testing
    #@testset "24-bus rts case" begin
    #    result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", SDPWRMPowerModel, scs_solver)

    #    @test result["status"] == :Optimal
    #    @test isapprox(result["objective"], 75153; atol = 1e0)
    #end
end
