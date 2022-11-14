@testset "TEST GMD OPF" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        b4gic_data = _PM.parse_file(case_b4gic)
        result = _PMGMD.solve_ac_gmd_opf(b4gic_data, ipopt_solver; setting=setting)
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
        result = _PMGMD.solve_ac_gmd_opf(b6gic_nerc_data, ipopt_solver; setting=setting)
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

        # result = _PMGMD.solve_ac_gmd_opf(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol = 1e2)

        # TODO => FIX ERROR
        # Received Warning Message:
        # DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results.

    end



end