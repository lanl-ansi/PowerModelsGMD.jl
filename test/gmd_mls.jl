@testset "TEST AC GMD MINIMUM-LOAD-SHED" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.run_ac_gmd_mls(case24_ieee_rts_0, ipopt_solver)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 108817.4779; atol=1e1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_ac_gmd_mls(case_epri21, ipopt_solver)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e1)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end

end





@testset "TEST QC GMD MINIMUM-LOAD-SHED" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.run_qc_gmd_mls(case24_ieee_rts_0, ipopt_solver)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 110689.1518; atol=1e1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_qc_gmd_mls(case_epri21, ipopt_solver)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e1)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end



end