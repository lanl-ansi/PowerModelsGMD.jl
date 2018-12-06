#=
# ommit due to not open source
@testset "test qc gmd ots" begin
    @testset "OTS Test" begin
        result = run_qc_gmd_ots("../test/data/ots_test.m", cplex_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.3416780903493064e6; atol = 1e-1, rtol = 1e-3)
    end
end
=#

@testset "test ac gmd ots" begin
    @testset "OTS Test" begin
        result = run_ac_gmd_ots("../test/data/ots_test.m", juniper_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.34180007e6; atol = 1e-1, rtol = 1e-3)
    end
end
















