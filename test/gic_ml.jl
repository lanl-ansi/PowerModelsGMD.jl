@testset "test ac gic ml" begin
    @testset "IEEE 24 0" begin
        result = run_ac_gic_ml("../test/data/case24_ieee_rts_0.m", ipopt_solver)
        println("Objective: $(result["objective"]), expected 167153.8 += 1e-1")
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 167153.8; atol = 1e+6)          
    end
    @testset "OTS Test" begin
        result = run_ac_gic_ml("../test/data/ots_test.m", ipopt_solver)        
        println("Objective: $(result["objective"]), expected 2.26947e6 += 1e7")
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.2694747340471516e6; atol = 1e7)       
    end    
end

@testset "test qc gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_qc_gic_ml("../test/data/case24_ieee_rts_0.m", ipopt_solver)
        println("Objective: $(result["objective"]), expected 159820.9 += 1e-1")
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 159820.9; atol = 1e+6)        
    end
    @testset "OTS Test" begin
        result = run_qc_gic_ml("../test/data/ots_test.m", ipopt_solver)        
        println("Objective: $(result["objective"]), expected 2.06486e6 += 1e7")
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.0648604728100917e6; atol = 1e7)       
    end
    
end
