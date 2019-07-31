@testset "Test AC data" begin

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





@testset "Test Coupled GMD + AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case GMD+AC-OPF solution" begin

        result = run_ac_gmd_opf("../test/data/b4gic.m", ipopt_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance")
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)

    end

    @testset "B4GIC case GMD+AC-OPF" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_opf(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)
        @test isapprox(solution["bus"]["1"]["vm"], 0.933660, atol=1e-3)
        @test isapprox(solution["branch"]["3"]["pf"], -1007.680670, atol=0.1)
        @test isapprox(solution["branch"]["3"]["qf"], -430.0362648, atol=0.1)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case GMD+AC-OPF" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_opf(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 11832.5; atol = 1e3)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)
        @test isapprox(solution["bus"]["2"]["vm"], 0.92784494, atol=1e-2)

        # br23
        @test isapprox(solution["branch"]["2"]["qf"], -36.478387, atol=5.0)
        @test isapprox(solution["branch"]["2"]["qt"], 49.0899781, atol=5.0)
        # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qf"], -36.402340, atol=5.0)
        @test isapprox(solution["branch"]["4"]["qt"], 36.4783871, atol=5.0)
        # br45
        @test isapprox(solution["branch"]["5"]["pf"], -100.40386, atol=5.0)
        @test isapprox(solution["branch"]["5"]["pt"], 100.648681, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qf"], -49.089978, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qt"], 48.6800005, atol=5.0)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case GMD+AC-OPF" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_opf(casename, ipopt_solver; setting=setting)

        # TODO: check why this is showing as infeasible
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED

        # result before PowerModels v0.8
        println("Testing objective $(result["objective"]) within tolerance")
        #@test isapprox(result["objective"], 5.08585e5; atol = 1e4)
        #@test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"],  44.31, atol=1e-1)
        #@test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"], -41.01, atol=1e-1)

        # after computing a diff on the generated JuMP models from v0.7 and v0.8
        # only coeffents in constraint_ohms_yt_from and constraint_ohms_yt_to changed slightly
        # most likely ipopt was getting stuck in a local min previously
        @test isapprox(result["objective"], 4.99564e5; atol = 1e4)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        # adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"],  44.26, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"], -40.95, atol=1e-1)

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case GMD+AC-OPF" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_opf(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 8.16591e5; atol = 1e5)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1)

    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case GMD+AC-OPF" begin

        casename = "../test/data/rts_gmlc_gic.m"        
        case = PowerModels.parse_file(casename)
        result = run_ac_gmd_opf(casename, ipopt_solver; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance for $casename")
        @test isapprox(result["objective"], 99176.9; atol = 1e5)

        solution = result["solution"]
        #make_gmd_mixed_units(solution, 100.0)
        #adjust_gmd_qloss(case, solution)


        # Bus 312 => ID "121"
        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.66, atol=0.1)
            # PowerModelsGMD: -9.645        # PowerWorld: -9.66
        @test isapprox(solution["bus"]["312"]["vm"], 1.03206, atol=1e-3)
            # PowerModelsGMD: 1.03206       # PowerWorld: 1.0190

        # Bus 211 => ID "96"
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.59, atol=0.1)
            # PowerModelsGMD: 13.5894       # PowerWorld: 13.59
        @test isapprox(solution["bus"]["211"]["vm"], 1.05119, atol=1e-3)
            # PowerModelsGMD: 1.05119       # PowerWorld: 1.02735
        
        # Bus 123 => ID "84"
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.63, atol=0.1)
            # PowerModelsGMD: -6.63508      # PowerWorld: -6.63
        @test isapprox(solution["bus"]["123"]["vm"], 1.10724, atol=1e-3)
            # PowerModelsGMD: 1.10724       # PowerWorld: 1.0500
        
        # Bus 313 => ID "122"
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.99, atol=0.1)
            # PowerModelsGMD: -7.97061      # PowerWorld: -7.99
        @test isapprox(solution["bus"]["313"]["vm"], 1.05779, atol=1e-3)
            # PowerModelsGMD: 1.05779       # PowerWorld: 1.03802
        
        # Bus 107 => ID "68"
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.96, atol=0.1)
            # PowerModelsGMD: 16.9618       # PowerWorld: 16.96
        @test isapprox(solution["bus"]["107"]["vm"], 1.05175, atol=1e-3)
            # PowerModelsGMD: 1.05175       # PowerWorld: 1.03745

        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #

        # Gen Bus 121 => ID "155" / ID "1020"
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0, atol=0.1)
            # PowerModelsGMD: 0             # PowerWorld: -13.09
        @test isapprox(solution["bus"]["1020"]["vm"], 1.14254, atol=1e-3)
            # PowerModelsGMD: 1.14254       # PowerWorld: 1.0500
        
        # Gen Bus 218 => ID "186" / ID "1052"
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0, atol=0.1)
            # PowerModelsGMD: 0             # PowerWorld: -4.88
        @test isapprox(solution["bus"]["1052"]["vm"], 1.14107, atol=1e-3)
            # PowerModelsGMD: 1.14107       # PowerWorld: 1.0500


        # Branch 107-108 => ID "100"
        @test isapprox(solution["branch"]["100"]["pf"], (1.74835), atol=0.1)
            # PowerModelsGMD: 1.74835       # PowerWorld: 174.1
        @test isapprox(solution["branch"]["100"]["qf"], (0.205857), atol=0.1)
            # PowerModelsGMD: 0.205857      # PowerWorld: 24.1
        @test isapprox(solution["branch"]["100"]["pt"], (-1.70347), atol=0.1)
            # PowerModelsGMD: -1.70347      # PowerWorld: -169.6
        @test isapprox(solution["branch"]["100"]["qt"], (-0.0529384), atol=0.1)
            # PowerModelsGMD: -0.0529384    # PowerWorld: -8.8
        
        # Branch 306-310 => ID "165"
        @test isapprox(solution["branch"]["165"]["pt"], (1.00549), atol=0.1)
            # PowerModelsGMD: 1.00549       # PowerWorld: 97.4
        @test isapprox(solution["branch"]["165"]["qt"], (-1.75), atol=0.1)
            # PowerModelsGMD: -1.75         # PowerWorld: -128.7
        
        # Branch 106-110 => ID "24"
        @test isapprox(solution["branch"]["24"]["pt"], (0.881669), atol=0.1)
            # PowerModelsGMD: 0.881669      # PowerWorld: 85.3
        @test isapprox(solution["branch"]["24"]["pf"], (-0.870245), atol=0.1)
            # PowerModelsGMD: -0.870245     # PowerWorld: -84.3
        
        # Branch 206-210 => ID "198"
        @test isapprox(solution["branch"]["198"]["pf"], (-0.870808), atol=0.1)
            # PowerModelsGMD: -0.870808     # PowerWorld: -84.3
        @test isapprox(solution["branch"]["198"]["qf"], (-0.930951), atol=0.1)
            # PowerModelsGMD: -0.930951     # PowerWorld: -128.6
        
        # Branch 213-1042 => ID "150"
        @test isapprox(solution["branch"]["150"]["gmd_qloss"], 0.639932, atol=0.5) 
            # PowerModelsGMD: 0.639932      # PowerWorld: 0.62
        @test isapprox(solution["branch"]["150"]["pf"], (-3.53843), atol=0.1)
            # PowerModelsGMD: -3.53843      # PowerWorld: -353.7
        @test isapprox(solution["branch"]["150"]["qf"], (-0.825305), atol=0.1)
            # PowerModelsGMD: -0.825305     # PowerWorld: -110.5
        
        # Branch 309-312 => ID "97"
        @test isapprox(solution["branch"]["97"]["gmd_qloss"], 1.70245, atol=0.5)
            # PowerModelsGMD: 1.70245       # PowerWorld: 1.33
        @test isapprox(solution["branch"]["97"]["pt"], (1.65688), atol=0.1)
            # PowerModelsGMD: 1.65688       # PowerWorld: 166.6
        @test isapprox(solution["branch"]["97"]["qt"], (0.586717), atol=0.1)
            # PowerModelsGMD: 0.586717      # PowerWorld: 41.3
        
        # Branch 210-211 => ID "44"
        @test isapprox(solution["branch"]["44"]["gmd_qloss"], 2.15103, atol=0.5)
            # PowerModelsGMD: 2.15103       # PowerWorld: 1.67
        @test isapprox(solution["branch"]["44"]["qt"], (0.113712), atol=0.1)
            # PowerModelsGMD: 0.113712      # PowerWorld: 14.1
        @test isapprox(solution["branch"]["44"]["qf"], (0.108688), atol=0.1)
            # PowerModelsGMD: 0.108688      # PowerWorld: 10.3

    end

end


