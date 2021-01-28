@testset "Test AC data" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case AC-OPF" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)
        
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 116384.93144690256; atol = 1e2)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case AC-OPF" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)
                
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 977.3898874142305; atol = 1e0)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case AC-OPF" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 401802.421492039; atol = 1e2)

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case AC-OPF" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 8.0361e5; atol = 1e5)
    
    end

    
    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case AC-OPF" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 87359.2; atol = 1e5)

    end

end





@testset "Test Decoupled GMD -> AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)

        ac_result = run_ac_gmd_opf_decoupled(casename, ipopt_optimizer)["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 116456.64090061095; atol = 1e5)
    
        output = run_ac_gmd_opf_decoupled(casename, ipopt_optimizer; setting=setting)
        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 116456.64090061095; atol = 1e5)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]

        # -- DC solution -- #
        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.008063648310255, atol=0.1)

        # -- AC solution -- #
        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0977680608382538, atol=1e-3)
        @test isapprox(ac_solution["branch"]["3"]["pf"], -1005.5115571246496, atol=1e-3)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -385.17019842743235, atol=1e-3)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_optimizer; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 978.3884231039176; atol = 10)
          
        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        adjust_gmd_qloss(case, ac_solution)

        # -- DC solution -- #
        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192898791427, atol=1e-1)

        # -- AC solution -- #
        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.0991756120094875, atol=1e-2)

        # br23
        @test isapprox(ac_solution["branch"]["2"]["qf"], -30.24172736398555, atol=5e2) 
        @test isapprox(ac_solution["branch"]["2"]["qt"], 39.09838497176122, atol=5e2)
        # T2 gwye-gwye auto
        @test isapprox(ac_solution["branch"]["4"]["qf"], -36.26293539879059, atol=5e2) 
        @test isapprox(ac_solution["branch"]["4"]["qt"], 30.24172736398555, atol=5e2)
        # br45
        @test isapprox(ac_solution["branch"]["5"]["pf"], -100.28473574995158, atol=5e2) 
        @test isapprox(ac_solution["branch"]["5"]["pt"], 100.44948718496272, atol=5e2)
        @test isapprox(ac_solution["branch"]["5"]["qf"], -39.09838497176123, atol=5e2)
        @test isapprox(ac_solution["branch"]["5"]["qt"], 32.36086193916137, atol=5e2)
    
    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        # TODO: fix EPRI21 LOCALLY_INFEASIBLE issue

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_optimizer; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 399393.87778206554; atol = 1e1)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        adjust_gmd_qloss(case, ac_solution)
        
        # -- DC solution -- #
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"], 44.26301987818915, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["23"]["gmd_vdc"], -40.95101258160489, atol=1e-1)

        # -- AC solution -- #

        @test isapprox(ac_solution["bus"]["5"]["vm"], 1.1880096967295355, atol=1e-1)
        @test isapprox(ac_solution["bus"]["5"]["va"], -15.73970594081811, atol=1e-1)
        @test isapprox(ac_solution["bus"]["13"]["vm"], 1.2020987903520657, atol=1e-1)
        @test isapprox(ac_solution["bus"]["13"]["va"], -2.364879959581638, atol=1e-1)

        @test isapprox(ac_solution["gen"]["5"]["pg"], 503.9359828675378, atol=1e1)
        @test isapprox(ac_solution["gen"]["5"]["qg"], -10.61, atol=1e1)

        @test isapprox(ac_solution["branch"]["13"]["pf"], 451.51341814540194, atol=1e1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -67.06551535472963, atol=1e1)
        @test isapprox(ac_solution["branch"]["13"]["gmd_qloss"], 0.0, atol=1e1)
        @test isapprox(ac_solution["branch"]["24"]["pt"], 894.9999910553688, atol=1e1)
        @test isapprox(ac_solution["branch"]["24"]["qt"], -56.56000077047978, atol=1e1)
        @test isapprox(ac_solution["branch"]["24"]["gmd_qloss"], 28.91248351366193, atol=1e1)
        @test isapprox(ac_solution["branch"]["30"]["gmd_qloss"], 15.97229280920908, atol=1e1)

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_optimizer; setting=setting)

        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 866977.4464027887; atol = 1e5)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        make_gmd_mixed_units(dc_solution, 100.0)
        make_gmd_mixed_units(ac_solution, 100.0)

        # -- DC solution -- #
        @test isapprox(dc_solution["gmd_bus"]["13"]["gmd_vdc"], 0.6851184542162815, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["57"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["131"]["gmd_vdc"], 3.8043815825131175, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["190"]["gmd_vdc"], 6.963562884985462, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["197"]["gmd_vdc"], -32.67451206860218, atol=1e-1)

        # -- AC solution -- #
    
        @test isapprox(ac_solution["bus"]["5"]["va"], -139.1965718214805, atol=1e1)
        @test isapprox(ac_solution["bus"]["5"]["vm"], 1.1489154656971272, atol=1e-1)
        @test isapprox(ac_solution["bus"]["55"]["va"], -592.6882846385279, atol=1e1)
        @test isapprox(ac_solution["bus"]["55"]["vm"], 1.0208630971787314, atol=1e-1)
        @test isapprox(ac_solution["bus"]["115"]["va"], -96.56375942211031, atol=1e1)
        @test isapprox(ac_solution["bus"]["115"]["vm"], 1.012137313531014, atol=1e-1)

        @test isapprox(ac_solution["gen"]["13"]["qg"], -2170.0, atol=1e2)
        @test isapprox(ac_solution["gen"]["13"]["pg"], 37675.27055475185, atol=1e2)
        @test isapprox(ac_solution["gen"]["24"]["qg"], 12554.618765982148, atol=1e2)
        @test isapprox(ac_solution["gen"]["24"]["pg"], 37972.33980886782, atol=1e2)

        @test isapprox(ac_solution["branch"]["73"]["gmd_qloss"], 9.98578645162235e-36, atol=1e-1)
        @test isapprox(ac_solution["branch"]["73"]["pf"], -20270.552840166845, atol=1e2)
        @test isapprox(ac_solution["branch"]["73"]["qf"], -5720.002474999622, atol=1e2)
        @test isapprox(ac_solution["branch"]["131"]["gmd_qloss"], 3.1462840983996637e-35, atol=1e-1)
        @test isapprox(ac_solution["branch"]["131"]["pt"], -3213.141392890774, atol=1e2)
        @test isapprox(ac_solution["branch"]["131"]["qt"], -21942.774289904373, atol=1e2)
        @test isapprox(ac_solution["branch"]["175"]["gmd_qloss"], 10.300333557325258, atol=1e-1)
        @test isapprox(ac_solution["branch"]["184"]["gmd_qloss"], 3.5013715182661906, atol=1e-1)
        @test isapprox(ac_solution["branch"]["208"]["gmd_qloss"], 2.935521386862689, atol=1e-1)

    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        output = run_ac_gmd_opf_decoupled(casename, ipopt_optimizer; setting=setting)
        
        ac_result = output["ac"]["result"]
        @test ac_result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 87444.34461000544; atol = 1e5)
        
        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]

        # -- DC solution -- #
        # Bus312=>ID"121"
        @test isapprox(dc_solution["gmd_bus"]["121"]["gmd_vdc"], -9.644997725255688, atol=0.1)
        # Bus123=>ID"84"
        @test isapprox(dc_solution["gmd_bus"]["84"]["gmd_vdc"], -6.63507836272912, atol=0.1)
        # Bus107=>ID"68"
        @test isapprox(dc_solution["gmd_bus"]["68"]["gmd_vdc"], 16.961848248756223, atol=0.1)

        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        # GenBus121=>ID"155"/ID"1020"
        @test isapprox(dc_solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=0.1)
        # GenBus218=>ID"186"/ID"1052"
        @test isapprox(dc_solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=0.1)
        
        # -- AC solution -- #
        # Bus211
        @test isapprox(ac_solution["bus"]["211"]["vm"], 1.0214524186490694, atol=1e-2)
        # Bus123
        @test isapprox(ac_solution["bus"]["123"]["vm"], 1.0852210656590495, atol=1e-2)
        # Bus313
        @test isapprox(ac_solution["bus"]["313"]["vm"], 1.0235341210691185, atol=1e-2)
        # GenBus121=>ID"1020"
        @test isapprox(ac_solution["bus"]["1020"]["vm"], 1.1239084650351585, atol=1e-2)
        # GenBus218=>ID"1052"
        @test isapprox(ac_solution["bus"]["1052"]["vm"], 1.1281435737232675, atol=1e-2)

        # Branch107-108=>ID"100"
        @test isapprox(ac_solution["branch"]["100"]["pf"], 173.69061791519755, atol=1)
        @test isapprox(ac_solution["branch"]["100"]["qf"], 21.36746054831305, atol=1)
        # Branch306-310=>ID"165"
        @test isapprox(ac_solution["branch"]["165"]["pt"], 99.53194237615716, atol=1)
        @test isapprox(ac_solution["branch"]["165"]["qt"], -143.93885073353937, atol=1)
        # Branch106-110=>ID"24"
        @test isapprox(ac_solution["branch"]["24"]["pt"], 88.86146656975956, atol=1)
        @test isapprox(ac_solution["branch"]["24"]["pf"], -87.70964186633992, atol=1)
        # Branch206-210=>ID"198"
        @test isapprox(ac_solution["branch"]["198"]["qt"], -150.80907779173728, atol=1)
        @test isapprox(ac_solution["branch"]["198"]["qf"], -93.07314787909989, atol=1.5)
        # Branch213-1042=>ID"150"
        @test isapprox(ac_solution["branch"]["150"]["gmd_qloss"], 0.5926580168629634, atol=0.5)
        # Branch309-312=>ID"97"
        @test isapprox(ac_solution["branch"]["97"]["gmd_qloss"], 1.2992879217039763, atol=0.5)
        # Branch210-211=>ID"44"
        @test isapprox(ac_solution["branch"]["44"]["gmd_qloss"], 1.5668390295656063, atol=0.5)

        # GenBus-313-Bus1076=>ID"88"
        @test isapprox(ac_solution["gen"]["88"]["pg"], 255.8284378375109, atol=1)
        @test isapprox(ac_solution["gen"]["88"]["qg"], 149.99999106662838, atol=1)
        # GenBus-221-Bus1053=>ID"92"
        @test isapprox(ac_solution["gen"]["92"]["pg"], 354.9999918761051, atol=1)
        # GenBus-107-Bus1009=>ID"11"
        @test isapprox(ac_solution["gen"]["11"]["qg"], 95.68041347526413, atol=1)

    end

end


