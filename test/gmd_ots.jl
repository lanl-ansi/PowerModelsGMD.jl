@testset "Test AC GMD OTS" begin

    @testset "OTS-Test case" begin
        
        #casename = "../test/data/ots_test.m"
        casename = "../test/data/epri21_ots.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_ots(casename, juniper_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        @test isapprox(result["objective"], 2.46069149389163e6; atol = 1e-1, rtol = 1e-3)

    end

end


