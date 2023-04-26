@testset "TEST GIC BLOCKER" begin

    @testset "NE BLOCKER DATA" begin

        case_b4gic = _PM.parse_file(data_b4gic_ne_blocker)
        pm = _PM.instantiate_model(case_b4gic, _PM.ACPPowerModel, _PMGMD.build_blocker_placement; ref_extensions = [
            _PMGMD.ref_add_gmd!
            _PMGMD.ref_add_ne_blocker!
        ])

        @test length(_PM.ref(pm,:gmd_ne_blocker))                      ==  6
        @test _PM.ref(pm,:gmd_ne_blocker,6)["construction_cost"]       ==  100.0
        @test _PM.ref(pm,:gmd_bus_ne_blockers,1)[1]                    ==  1
        @test _PM.ref(pm, :load_served_ratio)                          ==  1.0

    end

    @testset "B4GIC case" begin

        case_b4gic = _PM.parse_file(data_b4gic_ne_blocker)

        result = _PMGMD.solve_ac_blocker_placement(case_b4gic, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        @test isapprox(result["solution"]["gmd_ne_blocker"]["1"]["blocker_placed"], 0.0; atol=1e-6)

        result = _PMGMD.solve_soc_blocker_placement(case_b4gic, juniper_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.0; atol = 1e-1)
        @test isapprox(result["solution"]["gmd_ne_blocker"]["1"]["blocker_placed"], 0.0; atol=1e-6)

    end

end
