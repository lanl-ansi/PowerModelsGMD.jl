@testset "Test GMD" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = _PM.parse_file(casename)

        result = _PMGMD.run_gmd(casename, ipopt_solver)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        result = _PMGMD.run_gmd(casename, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.008063648310255, atol=0.1)       

        # result = _PMGMD.run_gmd(case_b4gic, ipopt_solver)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED

        # result = _PMGMD.run_gmd(case_b4gic, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = _PM.parse_file(casename)
        result = _PMGMD.run_gmd(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192898791427, atol=1e-1)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        casename = "../test/data/epri21.m"
        case = _PM.parse_file(casename)
        result = _PMGMD.run_gmd(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)

        @test isapprox(solution["gmd_branch"]["5"]["gmd_idc"], 140.62567038306443, atol=1e1)
        @test isapprox(solution["gmd_branch"]["13"]["gmd_idc"], 53.32820180462105, atol=1e1)
        @test isapprox(solution["gmd_branch"]["22"]["gmd_idc"], 61.9451056028716, atol=1e1)
        @test isapprox(solution["gmd_branch"]["29"]["gmd_idc"], 177.05207951275656, atol=1e1)
        @test isapprox(solution["gmd_branch"]["31"]["gmd_idc"], 67.01671102351894, atol=1e1)
        @test isapprox(solution["gmd_branch"]["35"]["gmd_idc"], -54.56937304382288, atol=1e1)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -6.550702322086242, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"], 44.26301987818915, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["17"]["gmd_vdc"], -40.65703884107489, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"], -40.95101258160489, atol=1e-1)    

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150.m"
        case = _PM.parse_file(casename)
        result = _PMGMD.run_gmd(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)

        @test isapprox(solution["gmd_bus"]["13"]["gmd_vdc"], 0.6851184542162815, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["57"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["131"]["gmd_vdc"], 3.8043815825131175, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 6.963562884985462, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.67451206860218, atol=1e-1)

    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = _PM.parse_file(casename)
        result = _PMGMD.run_gmd(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.644997725255688, atol=0.1) # Bus312=>ID"121" - PWvalue
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.589410136012726, atol=0.1) # Bus211=>ID"96" - PWvalue
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.63507836272912, atol=0.1) # Bus123=>ID"84" - PWvalue
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.9706141598148585, atol=0.1) # Bus313=>ID"122" - PWvalue
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.961848248756223, atol=0.1) # Bus107=>ID"68" - PWvalue
    
        # - NOTE: At the moment _PMGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=0.1) # GenBus121=>ID"155" - _PMGMDvalue
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=0.1) # GenBus218=>ID"186" - _PMGMDvalue

    end

end
