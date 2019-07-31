@testset "Test AC Data" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case AC-OPF" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_solver)
        
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 116914; atol = 1e2)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case AC-OPF" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_solver)
                
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 980; atol = 1e0)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case AC-OPF" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 401802; atol = 1e2)
    
    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case AC-OPF" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 8.0361e5; atol = 1e5)
    
    end

    
    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case AC-OPF" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 87359.2; atol = 1e5)

    end

end





@testset "Test Decoupled GMD -> AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case GMD->AC-OPF solution" begin

        ac_result = run_ac_gmd_opf_decoupled("../test/data/b4gic.m", ipopt_solver)["ac"]["result"]

        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance")
        @test isapprox(ac_result["objective"], 1.398e5; atol = 1e5)
    
    end

    @testset "B4GIC case GMD->AC-OPF" begin

        casename = "../test/data/b4gic.m"                
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance for $casename")
        @test isapprox(ac_result["objective"], 1.398e5; atol = 1e5)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        #make_gmd_mixed_units(dc_solution, 100.0)
        #make_gmd_mixed_units(ac_solution, 100.0)
        #adjust_gmd_qloss(case, ac_solution)


        # -- DC solution -- #

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)  


        # -- AC solution -- #
        
        @test isapprox(ac_solution["bus"]["1"]["vm"], 0.933660, atol=1e-3)
        @test isapprox(ac_solution["branch"]["3"]["pf"], -1007.680670, atol=1e-3)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -434.504704, atol=1e-3)     

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case GMD->AC-OPF" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance for $casename")
        @test isapprox(ac_result["objective"], 980; atol = 10)
          
        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        #make_gmd_mixed_units(dc_solution, 100.0)
        #make_gmd_mixed_units(ac_solution, 100.0)
        #adjust_gmd_qloss(case, ac_solution)


        # -- DC solution -- #
    
        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)


        # -- AC solution -- #

        @test isapprox(ac_solution["bus"]["2"]["vm"], 0.92784494, atol=1e-2)

        # br23
        println("Testing $(ac_solution["branch"]["2"]["qf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["2"]["qf"], -36.478387, atol=5e2)
        println("Testing $(ac_solution["branch"]["2"]["qt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["2"]["qt"], 49.0899781, atol=5e2)
        # T2 gwye-gwye auto
        println("Testing $(ac_solution["branch"]["4"]["qf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["4"]["qf"], -36.402340, atol=5e2)
        println("Testing $(ac_solution["branch"]["4"]["qt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["4"]["qt"], 364.783871, atol=5e2)
        # br45
        println("Testing $(ac_solution["branch"]["5"]["pf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["pf"], -100.40386, atol=5e2)
        println("Testing $(ac_solution["branch"]["5"]["pt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["pt"], 100.648681, atol=5e2)
        println("Testing $(ac_solution["branch"]["5"]["qf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["qf"], -49.089978, atol=5e2)
        println("Testing $(ac_solution["branch"]["5"]["qt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["qt"], 48.6800005, atol=5e2)
    
    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case GMD->AC-OPF" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance for $casename")
        @test isapprox(ac_result["objective"], 4.01802e5; atol = 1e4)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        #make_gmd_mixed_units(dc_solution, 100.0)
        #make_gmd_mixed_units(ac_solution, 100.0)
        #adjust_gmd_qloss(case, ac_solution)
        

        # -- DC solution -- #

        #@test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"],  44.31, atol=1e-1)
        #@test isapprox(dc_solution["gmd_bus"]["23"]["gmd_vdc"], -41.01, atol=1e-1)

        #@test isapprox(ac_result["objective"], 5.08585e5; atol = 1e5) 

        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"],  44.26, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["23"]["gmd_vdc"], -40.95, atol=1e-1)


        # -- AC solution -- #
    

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case GMD->AC-OPF" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance for $casename")
        @test isapprox(ac_result["objective"], 8.16591e5; atol = 1e5)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        make_gmd_mixed_units(dc_solution, 100.0)
        make_gmd_mixed_units(ac_solution, 100.0)
        #adjust_gmd_qloss(case, ac_solution)       


        # -- DC solution -- #

        @test isapprox(dc_solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1)
    

        # -- AC solution -- #
    
    
    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case GMD->AC-OPF" begin

        casename = "../test/data/rts_gmlc_gic.m"        
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=setting)
        
        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(ac_result["objective"], 87361.0; atol = 1e5)
        
        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        #make_gmd_mixed_units(dc_solution, 100.0)
        #make_gmd_mixed_units(ac_solution, 100.0)
        #adjust_gmd_qloss(case, ac_solution)
        

        # -- DC solution -- #
        
        # Bus 312 => ID "121"
        @test isapprox(dc_solution["gmd_bus"]["121"]["gmd_vdc"], -9.66, atol=0.1)
            # PowerModelsGMD: -9.645        # PowerWorld: -9.66
                    
        # Bus 211 => ID "96"
        @test isapprox(dc_solution["gmd_bus"]["96"]["gmd_vdc"], 13.59, atol=0.1)
            # PowerModelsGMD: 13.5894       # PowerWorld: 13.59
                
        # Bus 123 => ID "84"
        @test isapprox(dc_solution["gmd_bus"]["84"]["gmd_vdc"], -6.63, atol=0.1)
            # PowerModelsGMD: -6.63508      # PowerWorld: -6.63
                        
        # Bus 313 => ID "122"
        @test isapprox(dc_solution["gmd_bus"]["122"]["gmd_vdc"], -7.99, atol=0.1)
            # PowerModelsGMD: -7.97061      # PowerWorld: -7.99
                
        # Bus 107 => ID "68"
        @test isapprox(dc_solution["gmd_bus"]["68"]["gmd_vdc"], 16.96, atol=0.1)
            # PowerModelsGMD: 16.9618       # PowerWorld: 16.96
        
        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        
        # Gen Bus 121 => ID "155" / ID "1020"
        @test isapprox(dc_solution["gmd_bus"]["155"]["gmd_vdc"], 0, atol=0.1)
            # PowerModelsGMD: 0             # PowerWorld: -13.09
            
        # Gen Bus 218 => ID "186" / ID "1052"
        @test isapprox(dc_solution["gmd_bus"]["186"]["gmd_vdc"], 0, atol=0.1)
            # PowerModelsGMD: 0             # PowerWorld: -4.88
        
        
        # -- AC solution -- #
        
        # Bus 312
        @test isapprox(ac_solution["bus"]["312"]["vm"], 0.987139, atol=1e-3)
            # PowerModelsGMD: 0.987139      # PowerWorld: 1.0190
        
        # Bus 211
        @test isapprox(ac_solution["bus"]["211"]["vm"], 1.02158, atol=1e-3)
            # PowerModelsGMD: 1.02158       # PowerWorld: 1.02735
                
        # Bus 123
        @test isapprox(ac_solution["bus"]["123"]["vm"], 1.08246, atol=1e-3)
            # PowerModelsGMD: 1.08246       # PowerWorld: 1.0500
                
        # Bus 313
        @test isapprox(ac_solution["bus"]["313"]["vm"], 1.02146, atol=1e-3)
            # PowerModelsGMD: 1.02146       # PowerWorld: 1.03802
                
        # Bus 107
        @test isapprox(ac_solution["bus"]["107"]["vm"], 1.01247, atol=1e-3)
            # PowerModelsGMD: 1.01247       # PowerWorld: 1.03745
        
        # Gen Bus 121 => ID "1020"
        @test isapprox(ac_solution["bus"]["1020"]["vm"], 1.12287, atol=1e-3)
            # PowerModelsGMD: 1.12287       # PowerWorld: 1.0500
                
        # Gen Bus 218 => ID "1052"
        @test isapprox(ac_solution["bus"]["1052"]["vm"], 1.12191, atol=1e-3)
            # PowerModelsGMD: 1.12191       # PowerWorld: 1.0500
        
        
        # Branch 107-108 => ID "100"
        @test isapprox(ac_solution["branch"]["100"]["pf"], (173.373), atol=0.1)
            # PowerModelsGMD: 173.373       # PowerWorld: 174.1
        @test isapprox(ac_solution["branch"]["100"]["qf"], (23.8099), atol=0.1)
            # PowerModelsGMD: 23.8099       # PowerWorld: 24.1
        @test isapprox(ac_solution["branch"]["100"]["pt"], (-168.586), atol=0.1)
            # PowerModelsGMD: -168.586      # PowerWorld: -169.6
        @test isapprox(ac_solution["branch"]["100"]["qt"], (-7.24075), atol=0.1)
            # PowerModelsGMD: -7.24075      # PowerWorld: -8.8
                
        # Branch 306-310 => ID "165"
        @test isapprox(ac_solution["branch"]["165"]["pt"], (100.765), atol=0.1)
            # PowerModelsGMD: 100.765       # PowerWorld: 97.4
        @test isapprox(ac_solution["branch"]["165"]["qt"], (-143.079), atol=0.1)
            # PowerModelsGMD: -143.079      # PowerWorld: -128.7
                
        # Branch 106-110 => ID "24"
        @test isapprox(ac_solution["branch"]["24"]["pt"], (88.3524), atol=0.1)
            # PowerModelsGMD: 88.3524       # PowerWorld: 85.3
        @test isapprox(ac_solution["branch"]["24"]["pf"], (-87.2082), atol=0.1)
            # PowerModelsGMD: -87.2082      # PowerWorld: -84.3
                
        # Branch 206-210 => ID "198"
        @test isapprox(ac_solution["branch"]["198"]["pf"], (-87.5146), atol=0.1)
            # PowerModelsGMD: -87.5146      # PowerWorld: -84.3
        @test isapprox(ac_solution["branch"]["198"]["qf"], (-93.1864), atol=0.1)
            # PowerModelsGMD: -93.1864      # PowerWorld: -128.6
                
        # Branch 213-1042 => ID "150"
        @test isapprox(ac_solution["branch"]["150"]["gmd_qloss"], 0.592658, atol=0.5) 
            # PowerModelsGMD: 0.592658      # PowerWorld: 0.62
        @test isapprox(ac_solution["branch"]["150"]["pf"], (-353.741), atol=0.1)
            # PowerModelsGMD: -353.741      # PowerWorld: -353.7
        @test isapprox(ac_solution["branch"]["150"]["qf"], (-111.628), atol=0.1)
            # PowerModelsGMD: -111.628      # PowerWorld: -110.5
                
        # Branch 309-312 => ID "97"
        @test isapprox(ac_solution["branch"]["97"]["gmd_qloss"], 1.29929, atol=0.5)
            # PowerModelsGMD: 1.29929       # PowerWorld: 1.33
        @test isapprox(ac_solution["branch"]["97"]["pt"], (166.114), atol=0.1)
            # PowerModelsGMD: 166.114       # PowerWorld: 166.6
        @test isapprox(ac_solution["branch"]["97"]["qt"], (68.9342), atol=0.1)
            # PowerModelsGMD: 68.9342       # PowerWorld: 41.3
                
        # Branch 210-211 => ID "44"
        @test isapprox(ac_solution["branch"]["44"]["gmd_qloss"], 1.56684, atol=0.5)
            # PowerModelsGMD: 1.56684       # PowerWorld: 1.67
        @test isapprox(ac_solution["branch"]["44"]["qt"], (30.9704), atol=0.1)
            # PowerModelsGMD: 30.9704       # PowerWorld: 14.1
        @test isapprox(ac_solution["branch"]["44"]["qf"], (-4.95743), atol=0.1)
            # PowerModelsGMD: -4.95743      # PowerWorld: 10.3

    end

end


