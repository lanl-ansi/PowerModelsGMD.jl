
### UC Max Loading Tests

if (Pkg.installed("AmplNLWriter") != nothing && Pkg.installed("CoinOptServices") != nothing)

    @testset "test ac ml uc" begin
        @testset "3-bus case" begin
            result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case3.json", ACPPowerModel, BonminNLSolver(["bonmin.bb_log_level=0", "bonmin.nlp_log_level=0"]))

            @test result["status"] == :LocalOptimal
            @test isapprox(result["objective"], 4.44; atol = 1e-2)
        end
        @testset "24-bus rts case" begin
            result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case24.json", ACPPowerModel, BonminNLSolver(["bonmin.bb_log_level=0", "bonmin.nlp_log_level=0"]))

            @test result["status"] == :LocalOptimal
            @test isapprox(result["objective"], 34.29; atol = 1e-2)
        end
    end

end

@testset "test dc ml uc" begin
    @testset "3-bus case" begin
        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case3.json", DCPPowerModel, GLPKSolverMIP())

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 3.15; atol = 1e-2)
    end
    @testset "24-bus rts case" begin
        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case24.json", DCPPowerModel, GLPKSolverMIP())

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 28.46; atol = 1e-2)
    end
end


# these tests were commented out in the old code
@testset "test soc ml uc" begin
    @testset "3-bus case" begin
        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case3.json", SOCWRPowerModel, pajarito_solver)

        @test result["status"] == :Suboptimal
        @test isapprox(result["objective"], 4.44; atol = 1e-2)
    end
    @testset "24-bus rts case" begin
        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case24.json", SOCWRPowerModel, pajarito_solver)

        @test result["status"] == :Suboptimal
        @test isapprox(result["objective"], 34.29; atol = 1e-2)
    end
end


@testset "test qc ml uc" begin
    @testset "3-bus case" begin
        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case3.json", QCWRPowerModel, pajarito_solver)

        @test result["status"] == :Suboptimal
        @test isapprox(result["objective"], 4.44; atol = 1e-2)
    end
    @testset "24-bus rts case" begin
        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case24.json", QCWRPowerModel, pajarito_solver)

        @test result["status"] == :Suboptimal
        @test isapprox(result["objective"], 34.29; atol = 1e-2)
    end
end


# these tests were not tested in the old code
#@testset "test sdp ml uc" begin
#    @testset "3-bus case" begin
#        result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case3.json", SDPWRMPowerModel, pajarito_sdp_solver)

#        @test result["status"] == :Optimal
#        @test isapprox(result["objective"], 4.4; atol = 1e-1)
#    end
    # TODO replace this with smaller case, way too slow for unit testing
    #@testset "24-bus rts case" begin
    #    result = run_mluc("$(Pkg.dir("PowerModels"))/test/data/case24.json", SDPWRMPowerModel, scs_solver)

    #    @test result["status"] == :Optimal
    #    @test isapprox(result["objective"], 75153; atol = 1e0)
    #end
#end