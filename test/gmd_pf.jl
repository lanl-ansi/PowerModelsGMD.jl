@testset "TEST GMD MLD" begin


    @testset "EPRI21 case" begin

        case_epri21 = _PM.parse_file(data_epri21)

        result = _PMGMD.solve_gmd_pf(case_epri21,  _PM.ACPPowerModel, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

    end

    @testset "B4GIC case" begin

        case_b4gic = _PM.parse_file(data_b4gic)

        result = _PMGMD.solve_gmd_pf(case_b4gic, _PM.ACPPowerModel, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

    end


end
