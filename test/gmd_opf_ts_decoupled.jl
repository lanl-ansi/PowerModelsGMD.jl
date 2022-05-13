@testset "TEST GMD TS DECOUPLED" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        wf_path = "../test/data/waveforms/b4gic-gmd-wf.json"
        h = open(wf_path)
        wf_data = JSON.parse(h)
        close(h)

        b4gic_data = _PM.parse_file(case_b4gic)

        result = _PMGMD.run_ac_gmd_opf_ts_decoupled(b4gic_data, ipopt_solver, wf_data; setting=setting, disable_thermal=true)
        for period in 1:length(wf_data["time"])
            # @test result[period]["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        end

        # - DC solution - %

        dc_solution = result[5]["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -63.5514, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 211.8379, atol=1e-1)

        dc_solution = result[13]["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -63.5514, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 211.8379, atol=1e-1)

        # - AC solution - %

        @test isapprox(result[1]["ac"]["result"]["objective"], 117618.3233; atol = 1e1)
        @test isapprox(result[5]["ac"]["result"]["objective"], 116978.9911; atol = 1e1)
        @test isapprox(result[9]["ac"]["result"]["objective"], 19254.20179; atol = 1e1)

        ac_solution = result[13]["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0677, atol=1e-1)
        @test isapprox(ac_solution["bus"]["1"]["va"], -0.1124, atol=1e-1)
        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.1199, atol=1e-1)
        @test isapprox(ac_solution["bus"]["2"]["va"], -0.0306, atol=1e-1)

        # @test isapprox(ac_solution["branch"]["1"]["gmd_qloss"], 2.2877, atol=1e-1)
        # @test isapprox(ac_case["load"]["2"]["qd"], 2.2877, atol=1e-1)
        @test isapprox(ac_solution["branch"]["2"]["pf"], -3.9255, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["pf"], -3.9322, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -19.6096, atol=1e-1)        
        # @test isapprox(ac_solution["branch"]["3"]["gmd_qloss"], 2.2877, atol=1e-1)
        # @test isapprox(ac_case["load"]["3"]["qd"], 2.2877, atol=1e-1)


        @test isapprox(ac_solution["gen"]["1"]["pg"], 3.96250, atol=1e-1)
        @test isapprox(ac_solution["gen"]["1"]["qg"], 19.6035, atol=1e-1)

        # - Thermal solution - %

        result = _PMGMD.run_ac_gmd_opf_ts_decoupled(b4gic_data, ipopt_solver, wf_data; setting=setting, disable_thermal=false)
        for period in 1:length(wf_data["time"])
            # @test result[period]["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        end

        ac_solution = result[13]["ac"]["result"]["solution"]

        @test isapprox(ac_solution["branch"]["3"]["Ieff"], 408.5467, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["delta_topoilrise_ss"], 0.0025, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["delta_hotspotrise_ss"], 257.3844, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["actual_hotspot"], 282.3869, atol=1e-1)

    end



end