@testset "test ac gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_ac_gmd_ls("../test/data/case24_ieee_rts_0.m", ipopt_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 167153.8; atol = 1e-1)          
    end
    @testset "OTS Test" begin
        result = run_ac_gmd_ls("../test/data/ots_test.m", ipopt_solver)        
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.2694747340471516e6; atol = 1e-1)       
    end    
end

@testset "test qc gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_qc_gmd_ls("../test/data/case24_ieee_rts_0.m", ipopt_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 159820.9; atol = 1e-1)        
    end
    @testset "OTS Test" begin
        result = run_qc_gmd_ls("../test/data/ots_test.m", ipopt_solver)        
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.0648604728100917e6; atol = 1e-1)       
    end
    
end
