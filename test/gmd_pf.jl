@testset "TEST GMD MLD" begin


    @testset "EPRI21 case" begin

        case_epri21 = _PM.parse_file(data_epri21)

        result = _PMGMD.solve_gmd_pf(case_epri21,  _PM.ACPPowerModel, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

    end

    @testset "B4GIC case" begin

        case_b4gic                   = _PM.parse_file(data_b4gic)
        case_b4gic_verification_data = CSV.File(data_b4gic_verification)

        baseMVA = case_b4gic["baseMVA"]

#        result = _PMGMD.solve_gmd_mld(case_b4gic, _PM.ACPPowerModel, ipopt_solver; setting=setting)
        result = _PMGMD.solve_gmd_pf(case_b4gic, _PM.ACPPowerModel, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED

        println(case_b4gic_verification_data.names)
        println(case_b4gic_verification_data[1])

        for row in case_b4gic_verification_data
            i = row[:BusNum3W]
            j = row[Symbol("BusNum3W:1")]
            k = row[:LineCircuit]
            i_eff = row[:GICXFIEffective1]
            qloss = row[:GICQLosses]

            found = false
            # Line circuit number doesn't get tracked in PowerModels... it uses a unique 1..N index as an equivlent to k.  However, this check is ok
            # because there are no paralell lins.
            for (b, branch) in case_b4gic["branch"]
                if branch["f_bus"] == i && branch["t_bus"] == j
                    @test isapprox(result["solution"]["branch"][b]["gmd_idc_mag"], i_eff, atol=1e-4)
                    @test isapprox(result["solution"]["branch"][b]["gmd_qloss"], qloss / baseMVA, atol=1e-4)
                    found = true
                    continue
                end
            end
            @test found == true
        end
    end


end
