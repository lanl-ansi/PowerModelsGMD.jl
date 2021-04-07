@testset "TEST GMD OPF" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PMGMD.run_ac_gmd_opf(case_b4gic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 139231.9720134984; atol = 1e1)

        solution = result["solution"]
        adjust_gmd_qloss(case_b4gic, solution)

        # - DC solution - %

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.008063648310255, atol=1e-1)

        @test isapprox(solution["gmd_branch"]["2"]["gmd_idc"], 106.69354549436753, atol=1e-1)
    
        # - AC solution - %

        @test isapprox(solution["bus"]["1"]["vm"], 1.0966872989905379, atol=1e-1)

        @test isapprox(solution["branch"]["3"]["pf"], -10.055373226267239, atol=1e-1)
        @test isapprox(solution["branch"]["3"]["qf"], -3.9148516171425456, atol=1e-1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result = _PMGMD.run_ac_gmd_opf(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 12312.563267977646; atol = 1e1)

        solution = result["solution"]
        adjust_gmd_qloss(case_b6gic_nerc, solution)

        # - DC solution - %

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.02219289879143, atol=1e-1)

        @test isapprox(solution["gmd_branch"]["3"]["gmd_idc"], -13.50723732066095, atol=1e-1)

        # - AC solution - %

        @test isapprox(solution["bus"]["2"]["vm"], 1.0912584470250826, atol=1e-1)

        @test isapprox(solution["branch"]["4"]["qf"], -0.3772062566440934, atol=1e-1)  # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qt"], 0.3200989125511953, atol=1e-1)  # T2 gwye-gwye auto

        @test isapprox(solution["branch"]["5"]["pf"], -1.0029133070304042, atol=1e-1)  # Branch45
        @test isapprox(solution["branch"]["5"]["pt"], 1.0046889515479422, atol=1e-1)  # Branch45
        @test isapprox(solution["branch"]["5"]["qf"], -0.4863603147738442, atol=1e-1)  # Branch45
        @test isapprox(solution["branch"]["5"]["qt"], 0.4245851300293398, atol=1e-1)  # Branch45

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        # result = _PMGMD.run_ac_gmd_opf(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol = 1e1)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PMGMD.run_ac_gmd_opf(case_uiuc150, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol = 1e1)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end



    # ===   RTS-GMLC-GIC   === #

    @testset "RTS-GMLC-GIC case" begin

        result = _PMGMD.run_ac_gmd_opf(case_rtsgmlcgic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 189428.17746466602; atol = 1e1)

        solution = result["solution"]
        adjust_gmd_qloss(case_rtsgmlcgic, solution)

        # - DC solution - %

        # NOTE: currently PMsGMD always gives gmd_vdc=0 on the delta side of generator transformers
        @test isapprox(solution["gmd_bus"]["68"]["gmd_vdc"], 16.961848248756226, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["84"]["gmd_vdc"], -6.635078362729119, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["96"]["gmd_vdc"], 13.589410136012727, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["121"]["gmd_vdc"], -9.644997725255687, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["122"]["gmd_vdc"], -7.970614159814858, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=1e-1)

        @test isapprox(solution["gmd_branch"]["13"]["gmd_idc"], -23.473682270916658, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["38"]["gmd_idc"], 30.539506985913533, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["67"]["gmd_idc"], -0.3426263327694325, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["81"]["gmd_idc"], -1.486030984306775, atol=1e-1)

        # - AC solution - %

        @test isapprox(solution["bus"]["211"]["vm"], 1.0522044771130519, atol=1e-1)  # Bus211
        @test isapprox(solution["bus"]["313"]["vm"], 1.060865207331152, atol=1e-1)  # Bus313
        @test isapprox(solution["bus"]["1020"]["vm"], 1.15, atol=1e-1)  # GenBus121=>ID"1020"
        @test isapprox(solution["bus"]["1052"]["vm"], 1.1497631788352012, atol=1e-1)  # GenBus218=>ID"1052"
    
        @test isapprox(solution["branch"]["100"]["pf"], 1.5437474856856441, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(solution["branch"]["100"]["qf"], 0.1624499480150917, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(solution["branch"]["165"]["pt"], 1.0046427651625125, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(solution["branch"]["165"]["qt"], -1.75, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(solution["branch"]["24"]["pt"], 0.8760387367854952, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(solution["branch"]["24"]["pf"], -0.8647972686013478, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(solution["branch"]["198"]["qt"], -1.75, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(solution["branch"]["198"]["qf"], -0.9334541797499037, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(solution["branch"]["150"]["gmd_qloss"], 0.00639629432874184, atol=1e-1)  # Branch213-1042=>ID"150"
        @test isapprox(solution["branch"]["97"]["gmd_qloss"], 0.01705461017312502, atol=1e-1)  # Branch309-312=>ID"97"
        @test isapprox(solution["branch"]["44"]["gmd_qloss"], 0.021531154126607683, atol=1e-1)  # Branch210-211=>ID"44"

        @test isapprox(solution["gen"]["88"]["pg"], 3.414180248804262, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(solution["gen"]["88"]["qg"], 1.3638911433581828, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(solution["gen"]["92"]["pg"], 3.198848185427888, atol=1e-1)  # GenBus-221-Bus1053=>ID"92"
        @test isapprox(solution["gen"]["11"]["qg"], 0.8212354656714947, atol=1e-1)  # GenBus-107-Bus1009=>ID"11"

    end



end