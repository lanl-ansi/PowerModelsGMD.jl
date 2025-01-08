@testset "TEST GIC BLOCKER" begin
    @testset "Steady-state placement" begin
        @testset "NE BLOCKER DATA" begin
            case_b4gic = _PM.parse_file(data_b4gic_ne_blocker)
            _PMGMD.add_connected_components!(case_b4gic)
            pm = _PM.instantiate_model(case_b4gic, _PM.ACPPowerModel, _PMGMD.build_blocker_placement; ref_extensions = [
                _PMGMD.ref_add_gmd!,
                _PMGMD.ref_add_ne_blocker!,
                _PMGMD.ref_add_gmd_connections!,
            ])

            @test length(_PM.ref(pm,:gmd_ne_blocker))                      ==  6
            @test _PM.ref(pm,:gmd_ne_blocker,6)["construction_cost"]       ==  100.0
            @test _PM.ref(pm,:gmd_bus_ne_blockers,1)[1]                    ==  1
            @test _PM.ref(pm, :load_served_ratio)                          ==  1.0
        end

        @testset "Existing blocker test" begin
            blocker_test = _PM.parse_file(data_blocker_test)

            result = _PMGMD.solve_ac_gmd_mld(blocker_test, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 10.0; atol = 1e-1)

            result = _PMGMD.solve_soc_gmd_mld(blocker_test, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 10.0; atol = 1e-1)

            # check what happens when the blockers are removed
            for (i,blocker) in blocker_test["gmd_blocker"]
                blocker["status"] = 0
            end

            result = _PMGMD.solve_ac_gmd_mld(blocker_test, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_INFEASIBLE

            result = _PMGMD.solve_soc_gmd_mld(blocker_test, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_INFEASIBLE
        end

        @testset "B4GIC base ne case" begin
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

        @testset "EPRI 21 contrived ne case" begin
            case_epri21 = _PM.parse_file(data_epri21_ne_blocker)

            case_epri21["branch"]["4"]["rate_a"] = 3.7

            for (i, gmd_bus) in case_epri21["gmd_bus"]
                gmd_bus["g_gnd"] = gmd_bus["g_gnd"] * 1000.0
            end

            result = _PMGMD.solve_ac_blocker_placement(case_epri21, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 2.0; atol = 1e-1)
            @test isapprox(result["solution"]["gmd_ne_blocker"]["3"]["blocker_placed"], 0.0; atol=1e-6)

            case_epri21["branch"]["4"]["rate_a"] = .09925

            result = _PMGMD.solve_soc_blocker_placement(case_epri21, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
            @test isapprox(result["solution"]["gmd_ne_blocker"]["3"]["blocker_placed"], 0.0; atol=1e-6)
        end

        @testset "B4GIC contigency ne case" begin
            case_b4gic = _PM.parse_file(data_b4gic_15kvm_contingency)

            result = _PMGMD.solve_ac_blocker_placement(case_b4gic, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 1.0; atol = 1e-1)
            @test isapprox(result["solution"]["gmd_ne_blocker"]["1"]["blocker_placed"], 1.0; atol=1e-6)

            result = _PMGMD.solve_soc_blocker_placement(case_b4gic, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 1.0; atol = 1e-1)
            @test isapprox(result["solution"]["gmd_ne_blocker"]["2"]["blocker_placed"], 1.0; atol=1e-6)
        end

        @testset "EPRI 21 contigency ne case" begin
            case_epri21_15kvm_contingency = _PM.parse_file(data_epri21_15kvm_contingency)

            result = _PMGMD.solve_ac_blocker_placement(case_epri21_15kvm_contingency, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
            @test isapprox(result["solution"]["gmd_ne_blocker"]["2"]["blocker_placed"], 0.0; atol=1e-6)

            result = _PMGMD.solve_soc_blocker_placement(case_epri21_15kvm_contingency, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
            @test isapprox(result["solution"]["gmd_ne_blocker"]["2"]["blocker_placed"], 0.0; atol=1e-6)
        end
    end

    #@testset "Multi-scenario placement"
    #end

    @testset "Time-extended blocker placement" begin
        @testset "b4gic case" begin
            ts_setting = deepcopy(setting) 
            ts_setting["ts"] = false        
            
            net = PowerModels.parse_file(data_b4gic)
            net["load_served_ratio"] = 0.90
            _PMGMD.add_connected_components!(net)
            _PMGMD.add_blockers!(net)
            _PMGMD.filter_gmd_ne_blockers!(net)   # doesn't work for time-series extended. Run this before calling PowerModels.replicate?

            io = open(data_b4gic_wf)
            waveform = JSON.parse(io)
            close(io)
            
            n = 2
            ts_net = _PM.replicate(net, n)
            
            wf_ids = [1, 27]
            wf_time = waveform["time"]
            wf_waveforms = waveform["waveforms"]
            
            base_mva = net["baseMVA"]
            δ_t = wf_time[2] - wf_time[1]
                        
            # TODO: move this to a function 
            ts_net = _PMGMD.create_ts_net(net, waveform, ids=wf_ids, scaling=10.0)            
            result = _PMGMD.solve_ac_blocker_placement_multi_scenario(ts_net, juniper_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["objective"], 1.0; atol = 1e-1)
        end
    end
end
