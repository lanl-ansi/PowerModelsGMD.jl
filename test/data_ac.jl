@testset "TEST DATA AC-OPF" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PM.run_ac_opf(case_b4gic, ipopt_solver)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 116384.93144690253; atol=1e1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result =_PM.run_ac_opf(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 977.3898874142521; atol=1e1)

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PM.run_ac_opf(case_epri21, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 401802.42149203905; atol=1e1)

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PM.run_ac_opf(case_uiuc150, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 1.2795010572957678e6; atol=1e1)

    end



    # ===   RTS-GMLC-GIC   === #

    @testset "RTS-GMLC-GIC case" begin

        result = _PM.run_ac_opf(case_rtsgmlcgic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 87437.3715710461; atol=1e1)

    end



end