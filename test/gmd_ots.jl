@testset "TEST AC GMD OTS" begin


    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_ac_gmd_mls_ots(case_epri21, juniper_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # [warn | InfrastructureModels]: model has no results, solution cannot be built
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



    # ===   OTS-TEST   === #

    @testset "OTS-TEST case" begin

        # result = _PMGMD.run_ac_gmd_mls_ots(case_otstest, juniper_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # [warn | InfrastructureModels]: model has no results, solution cannot be built
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end





@testset "TEST QC GMD OTS" begin


    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_qc_gmd_mls_ots(case_epri21, juniper_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # [warn | InfrastructureModels]: model has no results, solution cannot be built
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



    # ===   OTS-TEST   === #

    @testset "OTS-TEST case" begin

        # result = _PMGMD.run_qc_gmd_mls_ots(case_otstest, juniper_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # [warn | InfrastructureModels]: model has no results, solution cannot be built
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end





@testset "TEST SOC GMD OTS" begin


    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_soc_gmd_mls_ots(case_epri21, juniper_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # [warn | InfrastructureModels]: model has no results, solution cannot be built
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



    # ===   OTS-TEST   === #

    @testset "OTS-TEST case" begin

        # result = _PMGMD.run_soc_gmd_mls_ots(case_otstest, juniper_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # [warn | InfrastructureModels]: model has no results, solution cannot be built
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end