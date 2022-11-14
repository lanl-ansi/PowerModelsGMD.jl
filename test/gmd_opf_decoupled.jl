@testset "TEST GMD OPF DECOUPLED" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_b4gic, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 116456.6409; atol = 1e3)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 106.6935, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0978, atol=1e-1)

        @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0897, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -4.3035, atol=5e-1)

    end


    # ===   B4GIC3W   === #

    @testset "B4GIC3W case" begin

        # result = _PMGMD.solve_ac_gmd_opf_decoupled(b4gic3w_data, ipopt_solver; setting=setting)
        # @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["ac"]["result"]["objective"], 1006.35; atol = 100)

        # # - DC solution - %

        # dc_solution = result["dc"]["result"]["solution"]

        # @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -35.9637, atol=1e-1)

        # @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], -103.849  , atol=1e-1)

        # # - AC solution - %

        # ac_solution = result["ac"]["result"]["solution"]

        # @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0636, atol=1e-1)

        # @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0000, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["3"]["qf"], -2.0, atol=5e-1)

        # @test isapprox(ac_solution["branch"]["4"]["pf"], 0.0000, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["4"]["qf"], 1.1453, atol=5e-1)

        # @test isapprox(ac_solution["branch"]["5"]["pf"], -10.0546, atol=1e-1)
        # @test isapprox(ac_solution["branch"]["5"]["qf"], -2.6997, atol=5e-1)


    end


    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 978.3884; atol = 1e2)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.0222, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["3"]["gmd_idc"], -13.5072, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.0992, atol=1e-1)

        @test isapprox(ac_solution["branch"]["4"]["qf"], -0.3528, atol=1e-1)  # T2 gwye-gwye auto
        @test isapprox(ac_solution["branch"]["4"]["qt"], 0.3525, atol=1e-1)  # T2 gwye-gwye auto

        @test isapprox(ac_solution["branch"]["5"]["pf"], -1.0028, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["pt"], 1.0042, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["qf"], -0.3910, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["qt"], 0.3236, atol=1e-1)  # Branch45

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_epri21, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 399393.8778; atol = 1e4)

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

        @test isapprox(ac_solution["bus"]["5"]["vm"], 1.04317, atol=1e-1)
        @test isapprox(ac_solution["bus"]["13"]["va"], -0.0413, atol=1e-1)

        @test isapprox(ac_solution["gen"]["5"]["pg"], 5.0394, atol=1e-1)
        @test isapprox(ac_solution["gen"]["5"]["qg"], -0.1061, atol=1e-1)

        @test isapprox(ac_solution["branch"]["13"]["pf"], 4.5151, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -0.6707, atol=5e-1)
        @test isapprox(ac_case["branch"]["13"]["gmd_qloss"], 0.0, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["pt"], 8.9500, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["qt"], -0.5656, atol=1e-1)
        @test isapprox(ac_case["branch"]["24"]["gmd_qloss"], 28.9125, atol=1e-1)
        @test isapprox(ac_case["branch"]["30"]["gmd_qloss"], 15.9723, atol=1e-1)
    end



end