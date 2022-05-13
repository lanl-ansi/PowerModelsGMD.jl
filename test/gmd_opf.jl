@testset "TEST GMD OPF" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        b4gic_data = _PM.parse_file(case_b4gic)
        result = _PMGMD.run_ac_gmd_opf(b4gic_data, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 139231.9720; atol = 1e2)

        solution = result["solution"]
        adjust_gmd_qloss(b4gic_data, solution)

        # - DC solution - %

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)

        @test isapprox(solution["gmd_branch"]["2"]["gmd_idc"], 106.6935, atol=1e-1)
    
        # - AC solution - %

        @test isapprox(solution["bus"]["1"]["vm"], 1.0967, atol=1e-1)

        @test isapprox(solution["branch"]["3"]["pf"], -10.0554, atol=1e-1)
        @test isapprox(solution["branch"]["3"]["qf"], -4.5913, atol=1e-1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin
        b6gic_nerc_data = _PM.parse_file(case_b6gic_nerc)
        result = _PMGMD.run_ac_gmd_opf(b6gic_nerc_data, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 12312.5633; atol = 1e2)

        solution = result["solution"]
        adjust_gmd_qloss(b6gic_nerc_data, solution)

        # - DC solution - %

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.0222, atol=1e-1)

        @test isapprox(solution["gmd_branch"]["3"]["gmd_idc"], -13.5072, atol=1e-1)

        # - AC solution - %

        @test isapprox(solution["bus"]["2"]["vm"], 1.09126, atol=1e-1)

        @test isapprox(solution["branch"]["4"]["qf"], -0.3772, atol=1e-1)  # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qt"], 0.3201, atol=1e-1)  # T2 gwye-gwye auto

        @test isapprox(solution["branch"]["5"]["pf"], -1.0029, atol=1e-1)  # Branch45
        @test isapprox(solution["branch"]["5"]["pt"], 1.0047, atol=1e-1)  # Branch45
        @test isapprox(solution["branch"]["5"]["qf"], -0.4864, atol=1e-1)  # Branch45
        @test isapprox(solution["branch"]["5"]["qt"], 0.4246, atol=1e-1)  # Branch45

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_ac_gmd_opf(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol = 1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PMGMD.run_ac_gmd_opf(case_uiuc150, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol = 1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end



    # ===   RTS-GMLC-GIC   === #

    @testset "RTS-GMLC-GIC case" begin

        rtsgmlcgic_data = _PM.parse_file(case_rtsgmlcgic)
        result = _PMGMD.run_ac_gmd_opf(rtsgmlcgic_data, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 191245.1403; atol = 1e2)

        solution = result["solution"]
        adjust_gmd_qloss(rtsgmlcgic_data, solution)

        # - DC solution - %

        # NOTE: currently PMsGMD always gives gmd_vdc=0 on the delta side of generator transformers
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.9618, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.6351, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.5894, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.6450, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.9706, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=1e-1)

        @test isapprox(solution["gmd_branch"]["13"]["gmd_idc"], -23.4737, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["38"]["gmd_idc"], 30.5395, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["67"]["gmd_idc"], -0.3426, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["81"]["gmd_idc"], -1.4860, atol=1e-1)

        # - AC solution - %

        @test isapprox(solution["bus"]["211"]["vm"], 1.0218, atol=1e-1)  # Bus211
        @test isapprox(solution["bus"]["313"]["vm"], 1.0231, atol=1e-1)  # Bus313
        @test isapprox(solution["bus"]["1020"]["vm"], 1.1371, atol=1e-1)  # GenBus121=>ID"1020"
        @test isapprox(solution["bus"]["1052"]["vm"], 1.1352, atol=1e-1)  # GenBus218=>ID"1052"
    
        @test isapprox(solution["branch"]["100"]["pf"], 1.6006, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(solution["branch"]["100"]["qf"], 0.1978, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(solution["branch"]["165"]["pt"], 0.9965, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(solution["branch"]["165"]["qt"], -1.4386, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(solution["branch"]["24"]["pt"], 0.8828, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(solution["branch"]["24"]["pf"], -0.8715, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(solution["branch"]["198"]["qt"], -1.5093, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(solution["branch"]["198"]["qf"], -0.9301, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(solution["branch"]["150"]["gmd_qloss"], 0.0062, atol=1e-1)  # Branch213-1042=>ID"150"
        @test isapprox(solution["branch"]["97"]["gmd_qloss"], 0.0163, atol=1e-1)  # Branch309-312=>ID"97"
        @test isapprox(solution["branch"]["44"]["gmd_qloss"], 0.0209, atol=1e-1)  # Branch210-211=>ID"44"

        @test isapprox(solution["gen"]["88"]["pg"], 2.8838, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(solution["gen"]["88"]["qg"], 1.50, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(solution["gen"]["92"]["pg"], 3.2737, atol=1e-1)  # GenBus-221-Bus1053=>ID"92"
        @test isapprox(solution["gen"]["11"]["qg"], 0.8958, atol=1e-1)  # GenBus-107-Bus1009=>ID"11"

    end



end