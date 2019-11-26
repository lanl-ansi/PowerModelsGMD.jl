@testset "Test AC data" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 116914; atol = 1e2)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 980; atol = 1e0)
    
    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 401802; atol = 1e2)
    
    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 8.0361e5; atol = 1e5)

    end

    
    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 87359.2; atol = 1e5)

    end

end





@testset "Test Coupled GMD + AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case solution" begin

        result = PowerModelsGMD.run_ac_gmd_opf("../test/data/b4gic.m", ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance")
        @test isapprox(result["objective"], 139793.03139612713; atol = 1e2)

    end

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 139793.03139612713; atol = 1e2)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.008, atol=0.1)
        @test isapprox(solution["bus"]["1"]["vm"], 0.93436, atol=1e-3)
        @test isapprox(solution["branch"]["3"]["pf"], -1007.65, atol=0.1)
        @test isapprox(solution["branch"]["3"]["qf"], -430.036, atol=0.1)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 12315.90471675542; atol = 1e3)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)
        @test isapprox(solution["bus"]["2"]["vm"], 0.9282525697994615, atol=1e-2)

        # br23
        @test isapprox(solution["branch"]["2"]["qf"], -35.27, atol=5.0)
        @test isapprox(solution["branch"]["2"]["qt"], 49.732, atol=5.0)
        # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qf"], -35.2598, atol=5.0)
        @test isapprox(solution["branch"]["4"]["qt"], 35.27, atol=5.0)
        # br45
        @test isapprox(solution["branch"]["5"]["pf"], -100.401, atol=5.0) 
        @test isapprox(solution["branch"]["5"]["pt"], 100.647, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qf"], -49.731, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qt"], 49.3804, atol=5.0)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        # TODO: check why EPRI21 is LOCALLY_INFEASIBLE

        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        # println("Testing objective $(result["objective"]) within tolerance $casename")
        # @test isapprox(result["objective"], 401802.421492039; atol = 1e4)

        # solution = result["solution"]
        # make_gmd_mixed_units(solution, 100.0)
        # # adjust_gmd_qloss(case, solution)

        # @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"],  44.26, atol=1e-1)
        # @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"], -40.95, atol=1e-1)

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        # TODO: check why UIUC150 is LOCALLY_INFEASIBLE
        
        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        # println("Testing objective $(result["objective"]) within tolerance for $casename")
        # @test isapprox(result["objective"], 8.16591e5; atol = 1e5)

        # solution = result["solution"]
        # make_gmd_mixed_units(solution, 100.0)
        # #adjust_gmd_qloss(case, solution)

        # @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1)
        # @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1)

    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 189417.78810575214; atol = 1e5)

        solution = result["solution"]
        #make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        # Bus312=>ID"121" - PWvalue
        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.64, atol=0.1)
        @test isapprox(solution["bus"]["312"]["vm"], 1.03258, atol=1e-3)
        # Bus211=>ID"96" - PWvalue
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.59, atol=0.1)
        @test isapprox(solution["bus"]["211"]["vm"], 1.052051, atol=1e-3)
        # Bus123=>ID"84" - PWvalue
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.63, atol=0.1)
        @test isapprox(solution["bus"]["123"]["vm"], 1.1111, atol=1e-3)
        # Bus313=>ID"122" - PWvalue
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.99, atol=0.1)
        @test isapprox(solution["bus"]["313"]["vm"], 1.05779, atol=1e-3)
        # Bus107=>ID"68" - PWvalue
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.96, atol=0.1)
        @test isapprox(solution["bus"]["107"]["vm"], 1.042, atol=1e-3)

        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0, atol=0.1)
        @test isapprox(solution["bus"]["1020"]["vm"], 1.153, atol=1e-3)
        # GenBus218=>ID"186"/ID"1052" - PMGMDvalue
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0, atol=0.1)
        @test isapprox(solution["bus"]["1052"]["vm"], 1.151, atol=1e-3)

        # Branch107-108=>ID"100" - PMGMDvalue
        @test isapprox(solution["branch"]["100"]["pf"], (1.543), atol=0.1)
        @test isapprox(solution["branch"]["100"]["qf"], (0.153), atol=0.1)
        @test isapprox(solution["branch"]["100"]["pt"], (-1.507), atol=0.1)
        @test isapprox(solution["branch"]["100"]["qt"], (-0.036), atol=0.1)
        # Branch306-310=>ID"165" - PMGMDvalue
        @test isapprox(solution["branch"]["165"]["pt"], (1.003), atol=0.1)
        @test isapprox(solution["branch"]["165"]["qt"], (-1.75), atol=0.1)
        # Branch106-110=>ID"24" - PMGMDvalue
        @test isapprox(solution["branch"]["24"]["pt"], (0.876), atol=0.1)
        @test isapprox(solution["branch"]["24"]["pf"], (-0.864), atol=0.1)
        # Branch206-210=>ID"198" - PMGMDvalue
        @test isapprox(solution["branch"]["198"]["pf"], (-0.869), atol=0.1)
        @test isapprox(solution["branch"]["198"]["qf"], (-0.933), atol=0.1)
        # Branch213-1042=>ID"150" - PMGMDvalue
        @test isapprox(solution["branch"]["150"]["gmd_qloss"], (0.6393), atol=0.5) 
        @test isapprox(solution["branch"]["150"]["pf"], (-3.298), atol=0.1)
        @test isapprox(solution["branch"]["150"]["qf"], (-0.775), atol=0.1)
        # Branch309-312=>ID"97" - PMGMDvalue
        @test isapprox(solution["branch"]["97"]["gmd_qloss"], 1.70331, atol=0.5)
        @test isapprox(solution["branch"]["97"]["pt"], (1.640), atol=0.1)
        @test isapprox(solution["branch"]["97"]["qt"], (0.589), atol=0.1)
        # Branch210-211=>ID"44" - PMGMDvalue
        @test isapprox(solution["branch"]["44"]["gmd_qloss"], (2.1528), atol=0.5)
        @test isapprox(solution["branch"]["44"]["qt"], (0.121), atol=0.1)
        @test isapprox(solution["branch"]["44"]["qf"], (0.106), atol=0.1)

        # GenBus-313-Bus1076=>ID"88" - PMGMDvalue
        @test isapprox(solution["gen"]["88"]["pg"], (3.41), atol=0.1)
        @test isapprox(solution["gen"]["88"]["qg"], (1.266), atol=0.1)
        # GenBus-221-Bus1053=>ID"92" - PMGMDvalue
        @test isapprox(solution["gen"]["92"]["pg"], (3.199), atol=0.1)
        @test isapprox(solution["gen"]["92"]["qg"], (0.912), atol=0.1)
        #GenBus-107-Bus1009=>ID"11" - PMGMDvalue
        @test isapprox(solution["gen"]["11"]["pg"], (3.235), atol=0.1)
        @test isapprox(solution["gen"]["11"]["qg"], (0.800), atol=0.1)

    end

end


