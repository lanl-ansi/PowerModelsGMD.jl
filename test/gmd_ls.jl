@testset "Test AC GMD Minimum-Load-Shed" begin

    # -- Case-24 IEEE RTS-0 -- #
    # CASE24 IEEE RTS-0 - 57-bus case

    @testset "CASE24-IEEE-RTS-0 case" begin

        casename = "../test/data/case24_ieee_rts_0.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_ls(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        @test isapprox(result["objective"], 108817.47790523888; atol = 1e+6)
    
    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "OTS-TEST case" begin

        # TODO: fix EPRI21 LOCALLY_INFEASIBLE issue

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        # result = PowerModelsGMD.run_ac_gmd_ls(casename, ipopt_optimizer)

        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        # @test isapprox(result["objective"], 2.2694747340471516e6; atol = 1e7)

    end

end





@testset "Test QC GMD Minimum-Load-Shed" begin

    # -- Case-24 IEEE RTS-0 -- #
    # CASE24 IEEE RTS-0 - 57-bus case

    @testset "CASE24-IEEE-RTS-0 case" begin

        casename = "../test/data/case24_ieee_rts_0.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_qc_gmd_ls(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        @test isapprox(result["objective"], 110689.14782215923; atol = 1e+6)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "OTS-TEST case" begin

        # TODO: fix EPRI21 LOCALLY_INFEASIBLE issue

        casename = "../test/data/epri21.m"
        # case = PowerModels.parse_file(casename)
        # result = PowerModelsGMD.run_qc_gmd_ls(casename, ipopt_optimizer)

        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED || result["termination_status"] == PowerModels.OPTIMAL
        # @test isapprox(result["objective"], 2.0648604728100917e6; atol = 1e7)

    end

end


