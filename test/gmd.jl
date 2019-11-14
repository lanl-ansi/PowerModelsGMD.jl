@testset "Test GMD" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case solution" begin

        result = run_gmd("../test/data/b4gic.m", ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED

    end

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = run_gmd(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = run_gmd(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = run_gmd(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"], 44.31, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"],  -41.01, atol=1e-1)

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150.m"
        case = PowerModels.parse_file(casename)
        result = run_gmd(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1)

    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = run_gmd(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.66, atol=0.1) # Bus312=>ID"121" - PWvalue
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.59, atol=0.1) # Bus211=>ID"96" - PWvalue
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.63, atol=0.1) # Bus123=>ID"84" - PWvalue
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.99, atol=0.1) # Bus313=>ID"122" - PWvalue
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.96, atol=0.1) # Bus107=>ID"68" - PWvalue
    
        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0, atol=0.1) # GenBus121=>ID"155" - PMGMDvalue
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0, atol=0.1) # GenBus218=>ID"186" - PMGMDvalue

    end

end


