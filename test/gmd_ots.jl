@testset "Test AC GMD OTS" begin

    @testset "EPRI21 case" begin
        
        #result = run_qc_gmd_ots("../test/data/ots_test.m", cplex_solver)
        result = run_ac_gmd_ots("../test/data/ots_test.m", juniper_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        @test isapprox(result["objective"], 2.46069149389163e6; atol = 1e-1, rtol = 1e-3)

    end

end


