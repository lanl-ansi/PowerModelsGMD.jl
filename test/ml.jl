### Basic Max Loading Tests

@testset "test ac ml" begin
    @testset "3-bus case" begin
        result = run_ml("../test/data/case3_ml.m", ACPPowerModel, ipopt_solver)

        #println(result)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.93675; atol = 1e-2)
    end
    @testset "3-bus uc case" begin
        result = run_ml("../test/data/case3_mluc.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalInfeasible
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", ACPPowerModel, ipopt_solver)

        #println(result)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 34.29; atol = 1e-2)
    end
end


@testset "test dc ml" begin
    @testset "3-bus case" begin
        result = run_ml("../test/data/case3_ml.m", DCPPowerModel, ipopt_solver)

        #println(result)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.25822; atol = 1e-2)
    end
    @testset "3-bus uc case" begin
        result = run_ml("../test/data/case3_mluc.m", DCPPowerModel, ipopt_solver)

        #println(result)
        @test result["status"] == :LocalInfeasible
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", DCPPowerModel, ipopt_solver)

        #println(result)
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 28.45; atol = 1e-2)
    end
end


@testset "test soc ml" begin
    @testset "3-bus case" begin
        result = run_ml("../test/data/case3_ml.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 2.08558; atol = 1e-2)
    end
    @testset "3-bus case uc" begin
        result = run_ml("../test/data/case3_mluc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalInfeasible
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 34.29; atol = 1e-2)
    end
end


@testset "test qc ml" begin
    @testset "3-bus case" begin
        result = run_ml("../test/data/case3_ml.m", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 2.00895; atol = 1e-2)
    end
    @testset "3-bus uc case" begin
        result = run_ml("../test/data/case3_mluc.m", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalInfeasible
    end
    @testset "24-bus rts case" begin
        result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 34.29; atol = 1e-2)
    end
end


@testset "test sdp ml" begin
    @testset "3-bus case" begin
        result = run_ml("../test/data/case3_ml.m", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 1.93621; atol = 1e-1)
    end
    @testset "3-bus uc case" begin
        result = run_ml("../test/data/case3_mluc.m", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Infeasible
    end
    # TODO replace this with smaller case, way too slow for unit testing
    #@testset "24-bus rts case" begin
    #    result = run_ml("$(Pkg.dir("PowerModels"))/test/data/case24.json", SDPWRMPowerModel, scs_solver)

    #    @test result["status"] == :Optimal
    #    @test isapprox(result["objective"], 34.29; atol = 1e-2)
    #end
end

