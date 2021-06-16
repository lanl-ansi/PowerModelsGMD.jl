@testset "TEST AC GMD MINIMUM-LOAD-SHED DECOUPLED" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.run_ac_gmd_mls_decoupled(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 100890.0107; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -39.9558, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["7"]["gmd_vdc"], -24.9516, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 166.0424, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["9"]["gmd_idc"], 159.2888, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["15"]["gmd_idc"], 380.4862, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["11"]["vm"], 0.9614, atol=1e-1)
        @test isapprox(ac_solution["bus"]["17"]["vm"], 0.9554, atol=1e-1)
        @test isapprox(ac_solution["bus"]["23"]["vm"], 0.9671, atol=1e-1)

        @test isapprox(ac_solution["branch"]["13"]["pf"], 0.0901, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -0.2204, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["gmd_qloss"], 0.0, atol=1e-1)
        @test isapprox(ac_solution["branch"]["25"]["pf"], -0.9138, atol=1e-1)
        @test isapprox(ac_solution["branch"]["25"]["qf"], -0.0745, atol=1e-1)
        @test isapprox(ac_solution["branch"]["25"]["gmd_qloss"], 0.0, atol=1e-1)

        @test isapprox(ac_solution["branch"]["37"]["gmd_qloss"], 0.0881, atol=1e-1)
        @test isapprox(ac_solution["branch"]["41"]["gmd_qloss"], 0.0843, atol=1e-1)
        @test isapprox(ac_solution["branch"]["57"]["gmd_qloss"], 0.1459, atol=1e-1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_ac_gmd_mls_decoupled(case_epri21, ipopt_solver; setting=setting)
        # @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["ac"]["result"]["objective"], 0; atol = 1e1)

        # TODO => FIX ERROR
        # Received Warning Message:
        # Ungrounded config, ieff constrained to zero.
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end





@testset "TEST SOC GMD MAXIMUM LOADABILITY" begin


    # ===   CASE-24 IEEE RTS-0   === #

    @testset "CASE24-IEEE-RTS-0 case" begin

        result = _PMGMD.run_soc_gmd_mld_decoupled(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 201417.0020; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -39.9558, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["7"]["gmd_vdc"], -24.9516, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 166.0424, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["9"]["gmd_idc"], 159.2888, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["15"]["gmd_idc"], 380.4862, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["11"]["w"], 0.9535, atol=1e-1) #?
        @test isapprox(ac_solution["bus"]["17"]["w"], 0.9849, atol=1e-1) #?
        @test isapprox(ac_solution["bus"]["23"]["w"], 1.0153, atol=1e-1) #?

        @test isapprox(ac_solution["branch"]["13"]["pf"], -0.0523, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -0.1675, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["gmd_qloss"], 0.0, atol=1e-1)
        @test isapprox(ac_solution["branch"]["25"]["pf"], -0.9574, atol=1e-1)
        @test isapprox(ac_solution["branch"]["25"]["qf"], -0.1272, atol=1e-1)
        @test isapprox(ac_solution["branch"]["25"]["gmd_qloss"], 0.0, atol=1e-1)

        @test isapprox(ac_solution["branch"]["37"]["gmd_qloss"], 0.0881, atol=1e-1)
        @test isapprox(ac_solution["branch"]["41"]["gmd_qloss"], 0.0843, atol=1e-1)
        @test isapprox(ac_solution["branch"]["57"]["gmd_qloss"], 0.1459, atol=1e-1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_soc_gmd_mld_decoupled(case_epri21, ipopt_solver; setting=setting)
        # @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["ac"]["result"]["objective"], 0; atol = 1e1)

        # TODO => FIX ERROR
        # Received Warning Message:
        # Ungrounded config, ieff constrained to zero.
        # ["termination_status"] = LOCALLY_INFEASIBLE

    end



end