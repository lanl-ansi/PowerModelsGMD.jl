@testset "Test GMD matrix formulation" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)

        result = PowerModelsGMD.run_gmd(casename)
        @test result["status"] == :LocalOptimal

        result = run_gmd(casename; setting=setting)
        @test result["status"] == :LocalOptimal

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.00805764514661, atol=0.1)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_gmd(casename; setting=setting)

        @test result["status"] == :LocalOptimal
          
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.02218586738402, atol=1e-1)
    
    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_gmd(casename; setting=setting)

        @test result["status"] == :LocalOptimal
         
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_branch"]["5"]["gmd_idc"], -51.96515506370937, atol=1e1)
        @test isapprox(solution["gmd_branch"]["13"]["gmd_idc"], -15.054915297542038, atol=1e1)
        @test isapprox(solution["gmd_branch"]["22"]["gmd_idc"], 61.945159608353606, atol=1e1)
        @test isapprox(solution["gmd_branch"]["29"]["gmd_idc"], 177.05215407959514, atol=1e1)
        @test isapprox(solution["gmd_branch"]["31"]["gmd_idc"], 67.01675478586972, atol=1e1)
        @test isapprox(solution["gmd_branch"]["35"]["gmd_idc"], -54.569317073449675, atol=1e1)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -6.550685565370694, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"], 44.26303851989878, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["17"]["gmd_vdc"], -40.65694867935286, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"], -40.95098155881214, atol=1e-1)
    
    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_gmd(casename; setting=setting)

        @test result["status"] == :LocalOptimal
        
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)

        @test isapprox(solution["gmd_bus"]["13"]["gmd_vdc"], 0.6851187440186839, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["57"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["131"]["gmd_vdc"], 3.8043768279006214, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 6.963558493141958, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.67448029367593, atol=1e-1)
    
    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_gmd(casename; setting=setting)

        @test result["status"] == :LocalOptimal
        
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)

        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.644985082841803, atol=0.1) # Bus312=>ID"121" - PWvalue
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.589394664054526, atol=0.1) # Bus211=>ID"96" - PWvalue
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.635076019874775, atol=0.1) # Bus123=>ID"84" - PWvalue
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.970607595792189, atol=0.1) # Bus313=>ID"122" - PWvalue
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.961827165869536, atol=0.1) # Bus107=>ID"68" - PWvalue
    
        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=0.1) # GenBus121=>ID"155" - PMGMDvalue
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=0.1) # GenBus218=>ID"186" - PMGMDvalue

    end

end


