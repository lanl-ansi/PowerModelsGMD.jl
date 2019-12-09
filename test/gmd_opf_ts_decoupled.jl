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


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        casename = "../test/data/rts_gmlc_gic.m"
        case = PowerModels.parse_file(casename)
        result = PowerModels.run_ac_opf(casename, ipopt_optimizer)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 87437.37157104613; atol = 1e2)

    end

end





@testset "Test Decoupled GMD -> AC-OPF" begin

    # -- B4GIC -- #
    # B4GIC - 4-bus case

    @testset "B4GIC case" begin

        # Load waveform data
        wf_path = "../test/data/waveforms/b4gic-gmd-wf.json"
        h = open(wf_path)
        wf_data = JSON.parse(h)
        close(h)

        timesteps = wf_data["time"]
        n = length(timesteps)

        waveforms = wf_data["waveforms"]

        # Load case data
        casename = "../test/data/b4gic.m"
        case = PowerModels.parse_file(casename)
        base_mva = case["baseMVA"]

        result = PowerModelsGMD.run_ac_gmd_opf_ts_decoupled(case, ipopt_optimizer, wf_data, setting)

        for period in 1:n
            @test result[period]["ac"]["result"]["termination_status"] == PowerModels.LOCALLY_SOLVED
        end

        @test isapprox(result[1]["ac"]["result"]["objective"], 116408.30982879689; atol = 1e2)
        @test isapprox(result[5]["ac"]["result"]["objective"], 116445.28731332484; atol = 1e2)
        @test isapprox(result[9]["ac"]["result"]["objective"], 116515.86700885602; atol = 1e2)

        solution = result[13]["ac"]["result"]["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)
        @test isapprox(solution["gen"]["1"]["pg"], 1.00773e5, atol=1e2)
        @test isapprox(solution["gen"]["1"]["qg"], 85438.1, atol=1e2)

        @test isapprox(solution["bus"]["2"]["vm"], 1.11993, atol=1e2)
        @test isapprox(solution["bus"]["2"]["va"], -100.583, atol=1)
        @test isapprox(solution["bus"]["4"]["vm"], 1.15, atol=1e2)
        @test isapprox(solution["bus"]["4"]["va"], 7.11649e-32, atol=1)

        @test isapprox(solution["branch"]["1"]["gmd_qloss"], 228.775, atol=1)
        @test isapprox(solution["branch"]["2"]["pf"], -1.00093e5, atol=1e2)
        @test isapprox(solution["branch"]["3"]["gmd_qloss"], 228.775, atol=1)

    end


    # -- RTS-GMLC-GIC -- #
    # RTS-GMLC-GIC - 169-bus case

    @testset "RTS-GMLC-GIC case" begin

        # TODO: add waveform data for test

        # Load case data
        # casename = "../test/data/rts_gmlc_gic.m"
        # case = PowerModels.parse_file(casename)
        # base_mva = case["baseMVA"]
        # PowerModels.make_per_unit!(case)

        # Load waveform data
        # wf_path = "../test/data/waveforms/rts_gmlc_gic-gmd-wf.json"

    end

end


