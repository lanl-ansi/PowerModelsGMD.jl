@testset "Test AC GMD OTS" begin

    @testset "OTS-Test case" begin

        # TODO: KeyError: key 12 not fount => 'branch_z' error (branch 12 not recognized as gmd branch)

        # #casename = "../test/data/ots_test.m"
        # casename = "../test/data/epri21_ots.m"
        # case = PowerModels.parse_file(casename)
        # result = PowerModelsGMD.run_ac_gmd_ots(casename, juniper_optimizer)

        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        # @test isapprox(result["objective"], 2.46069149389163e6; atol = 1e-1, rtol = 1e-3)

    end

end


