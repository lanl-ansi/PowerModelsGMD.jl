@testset "TEST GMD MLD" begin


    @testset "EPRI21 case" begin

        case_epri21 = _PM.parse_file(data_epri21)


        # ===   DECOUPLED GMD MLD   === #


        # result = _PMGMD.solve_soc_gmd_mld_decoupled(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # ===   DECOUPLED GMD CASCADE MLD   === #


        # result = _PMGMD.solve_soc_gmd_cascade_mld_decoupled(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # ===   COUPLED GMD MLS   === #


        # result = _PMGMD.solve_soc_gmd_mls(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # result = _PMGMD.solve_qc_gmd_mls(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # result = _PMGMD.solve_ac_gmd_mls(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # ===   COUPLED MLD   === #


        # result = _PMGMD.solve_soc_gmd_mld(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # result = _PMGMD.solve_ac_gmd_mld(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


    end


    @testset "IEEE-RTS-0 case" begin

        case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)


        # ===   DECOUPLED GMD MLD   === #


        # result = _PMGMD.solve_soc_gmd_mld_decoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # ===   DECOUPLED GMD CASCADE MLD   === #


        # result = _PMGMD.solve_soc_gmd_cascade_mld_decoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # ===   COUPLED GMD MLS   === #


        # result = _PMGMD.solve_soc_gmd_mls(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # result = _PMGMD.solve_qc_gmd_mls(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # result = _PMGMD.solve_ac_gmd_mls(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # ===   COUPLED MLD   === #


        # result = _PMGMD.solve_soc_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


        # result = _PMGMD.solve_ac_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)


    end


end