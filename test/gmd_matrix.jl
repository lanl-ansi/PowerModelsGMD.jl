@testset "TEST GMD MATRIX" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PMGMD.run_gmd(case_b4gic; setting=setting)
        @test result["status"] == :LocalOptimal

        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], -63.9691, atol=1e-1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result = _PMGMD.run_gmd(case_b6gic_nerc; setting=setting)
        @test result["status"] == :LocalOptimal

        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.0222, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["3"]["gmd_idc"], -13.5072, atol=1e-1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PMGMD.run_gmd(case_epri21; setting=setting)
        @test result["status"] == :LocalOptimal

        # - DC solution - %

        dc_solution = result["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -6.5507, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"], 44.2630, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["17"]["gmd_vdc"], -40.6569, atol=1e-1)
    
        @test isapprox(dc_solution["gmd_branch"]["5"]["gmd_idc"], -51.9651, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], -15.0549, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["29"]["gmd_idc"], 177.0521, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["35"]["gmd_idc"], -54.5694, atol=1e-1)

    end



end