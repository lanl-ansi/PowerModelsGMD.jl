@testset "TEST GMD OPF DECOUPLED" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_b4gic, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 116456.6409; atol = 1e3)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 106.6935, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0978, atol=1e-1)

        @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0551, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -16.0624, atol=1e-1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 978.3884; atol = 1e2)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.0222, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["3"]["gmd_idc"], -13.5072, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.0992, atol=1e-1)

        @test isapprox(ac_solution["branch"]["4"]["qf"], -0.3626, atol=1e-1)  # T2 gwye-gwye auto
        @test isapprox(ac_solution["branch"]["4"]["qt"], 0.3024, atol=1e-1)  # T2 gwye-gwye auto

        @test isapprox(ac_solution["branch"]["5"]["pf"], -1.0028, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["pt"], 1.0042, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["qf"], -0.3910, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["qt"], 0.3236, atol=1e-1)  # Branch45

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_epri21, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 399288.91189; atol = 1e3)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -6.5507, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"], 44.2630, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["17"]["gmd_vdc"], -40.6570, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["5"]["gmd_idc"], 140.6257, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], 53.3282, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["29"]["gmd_idc"], 177.0521, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["35"]["gmd_idc"], -54.5694, atol=1e-1)

        # - AC solution - %

        ac_case = result["ac"]["case"]
        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["5"]["vm"], 1.3000, atol=1e-1)
        @test isapprox(ac_solution["bus"]["13"]["va"], -0.0413, atol=1e-1)

        @test isapprox(ac_solution["gen"]["5"]["pg"], 5.0394, atol=1e-1)
        @test isapprox(ac_solution["gen"]["5"]["qg"], -0.1061, atol=1e-1)

        @test isapprox(ac_solution["branch"]["13"]["pf"], 4.5151, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -2.7510, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["13"]["gmd_qloss"], 0.0, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["pt"], 8.9500, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["qt"], -0.1363, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["24"]["gmd_qloss"], 0.2891, atol=1e-1)
        @test isapprox(ac_case["load"]["8"]["qd"], 40.1562, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["30"]["gmd_qloss"], 0.1597, atol=1e-1)
        @test isapprox(ac_case["load"]["11"]["qd"], 11.8122, atol=1e-1)

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_uiuc150, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 895102.8865; atol = 1e3)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["13"]["gmd_vdc"], 0.6851, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["57"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["131"]["gmd_vdc"], 3.8044, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["190"]["gmd_vdc"], 6.9636, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["197"]["gmd_vdc"], -32.6745, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["7"]["gmd_idc"], 23.9444, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["45"]["gmd_idc"], -6.2589, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["91"]["gmd_idc"], -23.0147, atol=1e-1)

        # - AC solution - %

        ac_case = result["ac"]["case"]
        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["5"]["va"], -0.0496, atol=1e-1)
        @test isapprox(ac_solution["bus"]["55"]["vm"], 1.1292, atol=1e-1)
        @test isapprox(ac_solution["bus"]["115"]["va"], -0.0441, atol=1e-1)
        @test isapprox(ac_solution["bus"]["115"]["vm"], 1.0219, atol=2e-1)

        @test isapprox(ac_solution["gen"]["13"]["pg"], 2.4228, atol=1e-1)
        @test isapprox(ac_solution["gen"]["13"]["qg"], 1.7062, atol=1e-1)
        @test isapprox(ac_solution["gen"]["24"]["pg"], 3.8719, atol=1e-1)
        @test isapprox(ac_solution["gen"]["24"]["qg"], 2.9339, atol=2e-1)

        # @test isapprox(ac_solution["branch"]["73"]["gmd_qloss"], 0, atol=1e-1)
        @test isapprox(ac_solution["branch"]["73"]["pf"], -2.4127, atol=2e-1)
        # @test isapprox(ac_solution["branch"]["131"]["gmd_qloss"], 0.0, atol=1e-1)
        @test isapprox(ac_solution["branch"]["131"]["pt"], 5.0864, atol=1e-1)
        @test isapprox(ac_solution["branch"]["131"]["qt"], -0.3272, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["184"]["gmd_qloss"], 0.0350, atol=1e-1)
        @test isapprox(ac_case["load"]["97"]["qd"], 43.1620, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["208"]["gmd_qloss"], 0.0294, atol=1e-1)
        @test isapprox(ac_case["load"]["100"]["qd"], 11.8901, atol=1e-1)

    end



    # ===   RTS-GMLC-GIC   === #

    @testset "RTS-GMLC-GIC case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_rtsgmlcgic, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 83948.9454; atol = 1e3)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        # NOTE: currently PMsGMD always gives gmd_vdc=0 on the delta side of generator transformers
        @test isapprox(dc_solution["gmd_bus"]["68"]["gmd_vdc"], 16.9618, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["84"]["gmd_vdc"], -6.6351, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["96"]["gmd_vdc"], 13.5894, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["121"]["gmd_vdc"], -9.6450, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["122"]["gmd_vdc"], -7.9706, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], -23.4737, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["38"]["gmd_idc"], 30.5395, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["67"]["gmd_idc"], -0.3426, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["81"]["gmd_idc"], -1.4860, atol=1e-1)

        # - AC solution - %
        
        ac_case = result["ac"]["case"]
        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["211"]["vm"], 1.0214, atol=1e-1)  # Bus211
        @test isapprox(ac_solution["bus"]["313"]["vm"], 1.0235, atol=1e-1)  # Bus313
        @test isapprox(ac_solution["bus"]["1020"]["vm"], 1.1239, atol=1e-1)  # GenBus121=>ID"1020"
        @test isapprox(ac_solution["bus"]["1052"]["vm"], 1.1281, atol=1e-1)  # GenBus218=>ID"1052"
    
        @test isapprox(ac_solution["branch"]["100"]["pf"], 1.7369, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(ac_solution["branch"]["100"]["qf"], -0.1573, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(ac_solution["branch"]["165"]["pt"], 0.1947, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(ac_solution["branch"]["165"]["qt"], -1.7391, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(ac_solution["branch"]["24"]["pt"], 0.3215, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(ac_solution["branch"]["24"]["pf"], -0.8771, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(ac_solution["branch"]["198"]["qt"], -1.7293, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(ac_solution["branch"]["198"]["qf"], -1.4273, atol=1e-1)  # Branch206-210=>ID"198"
        # @test isapprox(ac_solution["branch"]["150"]["gmd_qloss"], 0.0059, atol=1e-1)  # Branch213-1042=>ID"150"
        @test isapprox(ac_case["load"]["58"]["qd"], 46.9801, atol=1e-1)  # Branch213-1042=>ID"150"
        # @test isapprox(ac_solution["branch"]["97"]["gmd_qloss"], 0.0130, atol=1e-1)  # Branch309-312=>ID"97"
        @test isapprox(ac_case["load"]["86"]["qd"], 16.8225, atol=1e-1)  # Branch309-312=>ID"97"
        # @test isapprox(ac_solution["branch"]["44"]["gmd_qloss"], 0.0157, atol=1e-1)  # Branch210-211=>ID"44"
        @test isapprox(ac_case["load"]["87"]["qd"], 19.3985, atol=1e-1)  # Branch210-211=>ID"44"


        @test isapprox(ac_solution["gen"]["88"]["pg"], 3.5500, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(ac_solution["gen"]["88"]["qg"], 1.5000, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(ac_solution["gen"]["92"]["pg"], 3.2837, atol=1e-1)  # GenBus-221-Bus1053=>ID"92"
        @test isapprox(ac_solution["gen"]["11"]["qg"], 1.5000, atol=1e-1)  # GenBus-107-Bus1009=>ID"11"

    end



end