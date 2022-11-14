@testset "TEST DATA AC-OPF" begin


    @testset "B4GIC case" begin

        result = _PM.solve_ac_opf(case_b4gic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 116384.9314; atol=1e2)

    end


    @testset "B4GIC-3W case" begin

        result = _PM.solve_ac_opf(case_b4gic3w, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 1006.3460; atol=1e2)

    end


    @testset "B6GIC-NERC case" begin

        result =_PM.solve_ac_opf(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 977.3898; atol=1e2)

    end


    @testset "EPRI21 case" begin

        result = _PM.solve_ac_opf(case_epri21, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 401802.4215; atol=1e2)

    end


    @testset "IEEE-RTS case" begin

        result = _PM.solve_ac_opf(case24_ieee_rts_0, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 64439.3409; atol=1e2)

    end


    @testset "OTS-TEST case" begin  ## LOCALLY INFEASIBLE

        result = _PM.solve_ac_opf(case_otstest, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 0.0; atol=1e2)

    end


end