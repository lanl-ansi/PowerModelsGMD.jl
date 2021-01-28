@testset "Test AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 116384.93144690256; atol = 1e2)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 977.3898874142305; atol = 1e0)
    
    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        casename = "../test/data/epri21.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 401802.421492039; atol = 1e2)
    
    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        casename = "../test/data/uiuc150_95pct_loading.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 803609.808470568; atol = 1e5)

    end

    
    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 87359.2; atol = 1e5)

    end

end





@testset "Test Coupled GMD + AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)

        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer)
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 139231.97201349837; atol = 1e2)

        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 139231.97201349837; atol = 1e2)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.008063648310255, atol=0.1)
        @test isapprox(solution["bus"]["1"]["vm"], 1.0966872989905379, atol=1e-3)
        @test isapprox(solution["branch"]["3"]["pf"], -1005.5373226267237, atol=0.1)
        @test isapprox(solution["branch"]["3"]["qf"], -391.4851617142545, atol=0.1)

    end


    # -- B6GIC -- #
    # NERC B6GIC - 6-bus case

    @testset "NERC B6GIC case" begin

        casename = "../test/data/b6gic_nerc.m"
        case = PowerModels.parse_file(casename)
        result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 12312.563267977643; atol = 1e3)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.02219289879143, atol=1e-1)
        @test isapprox(solution["bus"]["2"]["vm"], 1.0912584470250988, atol=1e-2)

        # br23
        @test isapprox(solution["branch"]["2"]["qf"], -32.009891255113644, atol=5.0)
        @test isapprox(solution["branch"]["2"]["qt"], 48.63603205292917, atol=5.0)
        # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qf"], -37.7206256644039, atol=5.0)
        @test isapprox(solution["branch"]["4"]["qt"], 32.009891255113644, atol=5.0)
        # br45
        @test isapprox(solution["branch"]["5"]["pf"], -100.29133070304006, atol=5.0) 
        @test isapprox(solution["branch"]["5"]["pt"], 100.46889515479384, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qf"], -48.63603147736731, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qt"], 42.458513002915325, atol=5.0)

    end


    # --EPRI21 -- #
    # EPRI21 - 19-bus case

    @testset "EPRI21 case" begin

        # TODO: fix EPRI21 LOCALLY_INFEASIBLE issue

        casename = "../test/data/epri21.m"
        # case = PowerModels.parse_file(casename)
        # result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 401802.421492039; atol = 1e4)

        # solution = result["solution"]
        # make_gmd_mixed_units(solution, 100.0)

        # @test isapprox(solution["gmd_branch"]["5"]["gmd_idc"], -51.96515506370937, atol=1e1)
        # @test isapprox(solution["gmd_branch"]["13"]["gmd_idc"], -15.054915297542038, atol=1e1)
        # @test isapprox(solution["gmd_branch"]["22"]["gmd_idc"], 61.945159608353606, atol=1e1)
        # @test isapprox(solution["gmd_branch"]["29"]["gmd_idc"], 177.05215407959514, atol=1e1)
        # @test isapprox(solution["gmd_branch"]["31"]["gmd_idc"], 67.01675478586972, atol=1e1)
        # @test isapprox(solution["gmd_branch"]["35"]["gmd_idc"], -54.569317073449675, atol=1e1)

        # @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -6.550685565370694, atol=1e-1)
        # @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"], 44.26303851989878, atol=1e-1)
        # @test isapprox(solution["gmd_bus"]["17"]["gmd_vdc"], -40.65694867935286, atol=1e-1)
        # @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"],  -40.95098155881214, atol=1e-1)

    end


    # -- UIUC150 -- #
    # UIUC150 - 150-bus case

    @testset "UIUC150 case" begin

        # TODO: fix UIUC150 LOCALLY_INFEASIBLE issue

        # casename = "../test/data/uiuc150_95pct_loading.m"
        # case = PowerModels.parse_file(casename)
        # result = PowerModelsGMD.run_ac_gmd_opf(casename, ipopt_optimizer; setting=setting)

        # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 8.16591e5; atol = 1e5)

        # solution = result["solution"]
        # make_gmd_mixed_units(solution, 100.0)

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
        @test isapprox(result["objective"], 189428.17750557818; atol = 1e5)

        solution = result["solution"]

        # Bus312=>ID"121" - PWvalue
        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.644997725255688, atol=0.1)
        @test isapprox(solution["bus"]["312"]["vm"], 1.033888658284465, atol=1e-3)
        # Bus211=>ID"96" - PWvalue
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.589410136012726, atol=0.1)
        @test isapprox(solution["bus"]["211"]["vm"], 1.052204473566435, atol=1e-3)
        # Bus313=>ID"122" - PWvalue
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.97061415981486, atol=0.1)
        @test isapprox(solution["bus"]["313"]["vm"], 1.0608652027769157, atol=1e-3)

        # - NOTE: At the moment PowerModelsGMD always gives gmd_vdc=0 on the delta side of generator transformers! - #
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=0.1)
        @test isapprox(solution["bus"]["1020"]["vm"], 1.15, atol=1e-3)
        # GenBus218=>ID"186"/ID"1052" - PMGMDvalue
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=0.1)
        @test isapprox(solution["bus"]["1052"]["vm"], 1.1497631769385899, atol=1e-3)

        # Branch107-108=>ID"100" - PMGMDvalue
        @test isapprox(solution["branch"]["100"]["pf"], 1.5437474846723456, atol=0.1)
        @test isapprox(solution["branch"]["100"]["qf"], 0.16244993990518744, atol=0.1)
        @test isapprox(solution["branch"]["100"]["pt"], -1.5083021714930598, atol=0.1)
        @test isapprox(solution["branch"]["100"]["qt"], -0.04530570917000658, atol=0.1)
        # Branch213-1042=>ID"150" - PMGMDvalue
        @test isapprox(solution["branch"]["150"]["gmd_qloss"], 0.6396294305447163, atol=0.5) 
        @test isapprox(solution["branch"]["150"]["pf"], -3.298504426279793, atol=0.1)
        @test isapprox(solution["branch"]["150"]["qf"], -0.8070697110667789, atol=0.1)
        # Branch309-312=>ID"97" - PMGMDvalue
        @test isapprox(solution["branch"]["97"]["gmd_qloss"], 1.7054610107592145, atol=0.5)
        @test isapprox(solution["branch"]["97"]["pt"], 1.6443931120474657, atol=0.1)
        @test isapprox(solution["branch"]["97"]["qt"], 0.6022406318658631, atol=0.1)
        # Branch210-211=>ID"44" - PMGMDvalue
        @test isapprox(solution["branch"]["44"]["gmd_qloss"], 2.1531154054047557, atol=0.5)

        # GenBus-313-Bus1076=>ID"88" - PMGMDvalue
        @test isapprox(solution["gen"]["88"]["pg"], 3.414180249735178, atol=0.1)
        @test isapprox(solution["gen"]["88"]["qg"], 1.3638911050678877, atol=0.1)
        # GenBus-221-Bus1053=>ID"92" - PMGMDvalue
        @test isapprox(solution["gen"]["92"]["pg"], 3.1988481860673548, atol=0.1)
        @test isapprox(solution["gen"]["92"]["qg"], 0.9535597247154375, atol=0.1)
        #GenBus-107-Bus1009=>ID"11" - PMGMDvalue
        @test isapprox(solution["gen"]["11"]["pg"], 3.236238703965149, atol=0.1)
        @test isapprox(solution["gen"]["11"]["qg"], 0.8212354493234951, atol=0.1)

    end

end


