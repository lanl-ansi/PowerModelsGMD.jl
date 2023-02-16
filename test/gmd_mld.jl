@testset "TEST AC GMD MINIMUM LOADSHED" begin


    @testset "EPRI21 case" begin

        case_epri21 = _PM.parse_file(data_epri21)


        # ===   DECOUPLED GMD MLD   === #


        # ===   DECOUPLED GMD CASCADE MLD   === #


        # ===   COUPLED GMD MLS   === #


        # ===   COUPLED MLD   === #


        # result = _PMGMD.solve_ac_gmd_mls(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.
        # ["termination_status"] = LOCALLY_INFEASIBLE





    end


    @testset "IEEE-RTS-0 case" begin

        case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)


        # ===   DECOUPLED GMD MLD   === #


        result = _PMGMD.solve_gmd_mld_decoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 108817.4779; atol=1e2)


        # ===   DECOUPLED GMD CASCADE MLD   === #


        result = _PMGMD.solve_gmd_cascade_mld_decoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 108817.4779; atol=1e2)


        # ===   COUPLED GMD MLS   === #


        result = _PMGMD.solve_ac_gmd_mls(case_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 108817.4779; atol=1e2)


        # ===   COUPLED MLD   === #


        result = _PMGMD.solve_ac_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 108817.4779; atol=1e2)


    end


end





@testset "TEST AC GMD MAXIMUM LOADABILITY" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.solve_ac_gmd_mld(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 201417.0020; atol=1e2)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.solve_ac_gmd_mld(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end





@testset "TEST QC GMD MINIMUM LOADSHED" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.solve_qc_gmd_mls(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 110689.1477; atol=1e2)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.solve_qc_gmd_mls(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end





@testset "TEST SOC GMD MINIMUM LOADSHED" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.solve_soc_gmd_mls(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 110656.0578; atol=1e2)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.solve_soc_gmd_mls(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end





@testset "TEST SOC GMD MAXIMUM LOADABILITY" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.solve_soc_gmd_mld(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 200859.4045; atol=1e3)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.solve_soc_gmd_mld(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol=1e2)

        # TODO => FIX ERROR
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end