@testset "TEST GMD MLD" begin


    @testset "EPRI21 case" begin


        # ===   DECOUPLED GMD MLD   === #


        # case_epri21 = _PM.parse_file(data_epri21)

        # result = _PMGMD.solve_soc_gmd_mld_decoupled(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)

        # FIXME: add actual fully automated testing for "solve_soc_gmd_mld_decoupled"


        # ===   DECOUPLED GMD CASCADE MLD   === #


        #case_epri21 = _PM.parse_file(data_epri21)

        # result = _PMGMD.solve_soc_gmd_cascade_mld_decoupled(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)

        # FIXME: add actual fully automated testing for "solve_soc_gmd_cascade_mld_decoupled"


        # ===   COUPLED GMD MLS   === #


         case_epri21 = _PM.parse_file(data_epri21)

         result = _PMGMD.solve_soc_gmd_mld(case_epri21, ipopt_solver; setting=setting)
         @test result["termination_status"] == _PM.LOCALLY_SOLVED
         @test isapprox(result["objective"], 490.0; atol=1e-2)


         case_epri21 = _PM.parse_file(data_epri21)

# FIXME: QC model not currently supported in PowerModelsRestoration (breaks on the call to constraint_theta_ref)

#         result = _PMGMD.solve_qc_gmd_mld(case_epri21, ipopt_solver; setting=setting)
#         @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         @test isapprox(result["objective"], 0.0000; atol=1e2)


         case_epri21 = _PM.parse_file(data_epri21)

         result = _PMGMD.solve_ac_gmd_mld(case_epri21, ipopt_solver; setting=setting)
         @test result["termination_status"] == _PM.LOCALLY_SOLVED
         @test isapprox(result["objective"], 490.0; atol=1e2)
    end


    @testset "IEEE-RTS-0 case" begin


        # ===   DECOUPLED GMD MLD   === #


        # case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

        # result = _PMGMD.solve_soc_gmd_mld_decoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)

        # FIXME: add actual fully automated testing for "solve_soc_gmd_mld_decoupled"


        # ===   DECOUPLED GMD CASCADE MLD   === #


        # case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

        # result = _PMGMD.solve_soc_gmd_cascade_mld_decoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0000; atol=1e2)

        # FIXME: add actual fully automated testing for "solve_soc_gmd_cascade_mld_decoupled"


        # ===   COUPLED GMD MLS   === #


        case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

        #FIXME: The lower bound (soc) solution is coming back worse than the AC solution.  Seems to be something wonky going on
        # with the dc constraints

        #result = _PMGMD.solve_soc_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
        #@test result["termination_status"] == _PM.LOCALLY_SOLVED
        #@test isapprox(result["objective"], 0.0; atol=1e-2)


         case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

         # FIXME - requires fix in powermodelsrestoration for qc bug
         #result = _PMGMD.solve_qc_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
         #@test result["termination_status"] == _PM.LOCALLY_SOLVED
         #@test isapprox(result["objective"], 0.0000; atol=1e2)


        case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

        #result = _PMGMD.solve_ac_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
        #@test result["termination_status"] == _PM.LOCALLY_SOLVED
        #@test isapprox(result["objective"], 0.0; atol=1e-2)

    end


end
