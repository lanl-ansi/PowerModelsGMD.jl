@testset "TEST GMD" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PMGMD.run_gmd(case_b4gic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.008063648310255, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 106.69354549436753, atol=1e-1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result = _PMGMD.run_gmd(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.02219289879143, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["3"]["gmd_idc"], -13.507237320660954, atol=1e-1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PMGMD.run_gmd(case_epri21, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -6.550702322086242, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"], 44.26301987818915, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["17"]["gmd_vdc"], -40.6570388410749, atol=1e-1)
    
        @test isapprox(dc_solution["gmd_branch"]["5"]["gmd_idc"], 140.6256703830644, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], 53.32820180462106, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["29"]["gmd_idc"], 177.05207951275656, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["35"]["gmd_idc"], -54.56937304382294, atol=1e-1)

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PMGMD.run_gmd(case_uiuc150, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        
        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["13"]["gmd_vdc"], 0.685118454216281, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["57"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["131"]["gmd_vdc"], 3.804381582513118, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["190"]["gmd_vdc"], 6.9635628849854605, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["197"]["gmd_vdc"], -32.67451206860218, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["7"]["gmd_idc"], 23.94442947211026, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["45"]["gmd_idc"], -6.258858763372976, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["91"]["gmd_idc"], -23.014727979030802, atol=1e-1)

    end



    # ===   RTS-GMLC-GIC   === #

    @testset "RTS-GMLC-GIC case" begin

        result = _PMGMD.run_gmd(case_rtsgmlcgic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        # - DC solution - %

        dc_solution = result["solution"]

        # NOTE: currently PMsGMD always gives gmd_vdc=0 on the delta side of generator transformers
        @test isapprox(dc_solution["gmd_bus"]["68"]["gmd_vdc"], 16.961848248756223, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["84"]["gmd_vdc"], -6.635078362729118, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["96"]["gmd_vdc"], 13.589410136012727, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["121"]["gmd_vdc"], -9.644997725255688, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["122"]["gmd_vdc"], -7.970614159814858, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], -23.473682270916655, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["38"]["gmd_idc"], 30.53950698591353, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["67"]["gmd_idc"], -0.34262633276943266, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["81"]["gmd_idc"], -1.486030984306776, atol=1e-1)

    end



end