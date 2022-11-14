@testset "TEST DATA AC-OPF" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PM.run_ac_opf(case_b4gic, ipopt_solver)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 116384.9314; atol=1e2)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result =_PM.run_ac_opf(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 977.3899; atol=1e2)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PM.run_ac_opf(case_epri21, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 401802.4215; atol=1e2)

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PM.run_ac_opf(case_uiuc150, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 803609.8084; atol=1e2)

    end



end