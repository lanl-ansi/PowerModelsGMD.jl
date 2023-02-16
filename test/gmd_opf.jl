@testset "TEST GMD OPF" begin


    @testset "B4GIC case" begin

        case_b4gic = _PM.parse_file(data_b4gic)


        # ===   DECOUPLED AC-OPF   === #


        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_b4gic, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 116456.6409; atol = 1e2)

        # DC solution:
        dc_solution = result["dc"]["result"]["solution"]
        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 106.6935, atol=1e-1)

        # AC solution:
        ac_solution = result["ac"]["result"]["solution"]
        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0978, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0551, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -4.4491, atol=1e-1)


        # ===   COUPLED AC-OPF   === #


        result = _PMGMD.solve_ac_gmd_opf(case_b4gic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 139231.9720; atol = 1e2)

        solution = result["solution"]
        _PMGMD.adjust_gmd_qloss(case_b4gic, solution)

        # DC solution:
        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["2"]["gmd_idc"], 106.6935, atol=1e-1)
    
        # AC solution:
        @test isapprox(solution["bus"]["1"]["vm"], 1.0967, atol=1e-1)
        @test isapprox(solution["branch"]["3"]["pf"], -10.0554, atol=1e-1)
        @test isapprox(solution["branch"]["3"]["qf"], -4.5913, atol=1e-1)


    end


    @testset "B4GIC-3W case" begin

        mods_b4gic3w = "../test/data/suppl/b4gic3w_mods.json"
        f = open(mods_b4gic3w)
        mods = JSON.parse(f)
        close(f)

        case_b4gic3w = _PM.parse_file(data_b4gic3w)
        _PMGMD.apply_mods!(case_b4gic3w, mods)
        _PMGMD.fix_gmd_indices!(case_b4gic3w)


        # ===   DECOUPLED AC-OPF   === #


        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_b4gic3w, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 1006.35; atol = 1e2)

        # DC solution:
        dc_solution = result["dc"]["result"]["solution"]
        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -35.9637, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], -103.849  , atol=1e-1)

        # AC solution:
        ac_solution = result["ac"]["result"]["solution"]
        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0636, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0000, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -2.0, atol=5e-1)
        @test isapprox(ac_solution["branch"]["4"]["pf"], 0.0000, atol=1e-1)
        @test isapprox(ac_solution["branch"]["4"]["qf"], 1.1453, atol=5e-1)
        @test isapprox(ac_solution["branch"]["5"]["pf"], -10.0546, atol=1e-1)
        @test isapprox(ac_solution["branch"]["5"]["qf"], -2.6997, atol=5e-1)


        # ===   COUPLED AC-OPF   === #


        # NOTE: B4GIC-3W COUPLED tests are disabled due to the missing [baseMVA] values of
        # branches that cause "function calc_branch_ibase" (scr/core/data.jl) to error out

        # result = _PMGMD.solve_ac_gmd_opf(case_b4gic3w, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 139231.9720; atol = 1e2)

        # solution = result["solution"]
        # _PMGMD.adjust_gmd_qloss(case_b4gic3w, solution)

        # # DC solution:
        # @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)
        # @test isapprox(solution["gmd_branch"]["2"]["gmd_idc"], 106.6935, atol=1e-1)
    
        # # AC solution:
        # @test isapprox(solution["bus"]["1"]["vm"], 1.0967, atol=1e-1)
        # @test isapprox(solution["branch"]["3"]["pf"], -10.0554, atol=1e-1)
        # @test isapprox(solution["branch"]["3"]["qf"], -4.5913, atol=1e-1)


    end


    @testset "NERC B6GIC case" begin

        case_b6gic_nerc = _PM.parse_file(data_b6gic_nerc)


        # ===   DECOUPLED AC-OPF   === #


        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 978.3884; atol = 1e2)

        # DC solution:
        dc_solution = result["dc"]["result"]["solution"]
        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.0222, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["3"]["gmd_idc"], -13.5072, atol=1e-1)

        # AC solution:
        ac_solution = result["ac"]["result"]["solution"]
        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.0992, atol=1e-1)
        @test isapprox(ac_solution["branch"]["5"]["pf"], -1.0028, atol=1e-1)
        @test isapprox(ac_solution["branch"]["5"]["pt"], 1.0042, atol=1e-1)
        @test isapprox(ac_solution["branch"]["5"]["qf"], -0.3910, atol=1e-1)
        @test isapprox(ac_solution["branch"]["5"]["qt"], 0.3236, atol=1e-1)


        # ===   COUPLED AC-OPF   === #


        result = _PMGMD.solve_ac_gmd_opf(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 12312.5633; atol = 1e2)

        solution = result["solution"]
        _PMGMD.adjust_gmd_qloss(case_b6gic_nerc, solution)

        # DC solution:
        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.0222, atol=1e-1)
        @test isapprox(solution["gmd_branch"]["3"]["gmd_idc"], -13.5072, atol=1e-1)

        # AC solution:
        @test isapprox(solution["bus"]["2"]["vm"], 1.09126, atol=1e-1)
        @test isapprox(solution["branch"]["5"]["pf"], -1.0029, atol=1e-1)
        @test isapprox(solution["branch"]["5"]["pt"], 1.0047, atol=1e-1)
        @test isapprox(solution["branch"]["5"]["qf"], -0.4864, atol=1e-1)
        @test isapprox(solution["branch"]["5"]["qt"], 0.4246, atol=1e-1)


    end


    @testset "EPRI21 case" begin

        case_epri21 = _PM.parse_file(data_epri21)


        # ===   DECOUPLED AC-OPF   === #


        result = _PMGMD.solve_ac_gmd_opf_decoupled(case_epri21, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 401410.1419; atol = 1e2)

        # DC solution:
        dc_solution = result["dc"]["result"]["solution"]
        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -6.5507, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"], 44.2630, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["17"]["gmd_vdc"], -40.6570, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["5"]["gmd_idc"], 140.6257, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], 53.3282, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["35"]["gmd_idc"], -54.5694, atol=1e-1)

        # AC solution:
        ac_solution = result["ac"]["result"]["solution"]
        @test isapprox(ac_solution["bus"]["5"]["vm"], 1.0627, atol=1e-1)
        @test isapprox(ac_solution["bus"]["13"]["va"], -0.0413, atol=1e-1)
        @test isapprox(ac_solution["gen"]["5"]["pg"], 5.0394, atol=1e-1)
        @test isapprox(ac_solution["gen"]["5"]["qg"], -0.1061, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["pf"], 4.5151, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -0.6707, atol=5e-1)

        @test isapprox(ac_solution["branch"]["24"]["pt"], 8.9500, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["qt"], -0.5656, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["gmd_qloss"], 0.2891, atol=1e-1)
        @test isapprox(ac_solution["branch"]["30"]["gmd_qloss"], 0.1597, atol=1e-1)


        # ===   COUPLED AC-OPF   === #


        # NOTE: EPRI21 COUPLED tests are disabled due to error.
        # INVALID_MODEL termination status. Potentially caused by DC voltage magnitude taking 0 value.

        # result = _PMGMD.solve_ac_gmd_opf(case_epri21, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0; atol = 1e2)

        # solution = result["solution"]
        # _PMGMD.adjust_gmd_qloss(case_epri21, solution)

    end


end