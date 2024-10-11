@testset "TEST GMD MLD" begin


#     @testset "EPRI21 case" begin


#         # ===   DECOUPLED GMD MLD   === #


#         case_epri21 = _PM.parse_file(data_epri21)

#         result = _PMGMD.solve_gmd_mld_decoupled(case_epri21, _PM.ACPPowerModel, ipopt_solver; setting=setting)
#         @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         @test isapprox(result["objective"], 490.0; atol=1e-2)

#         # FIXME: add actual fully automated testing for "solve_soc_gmd_mld_uncoupled"


#         # ===   DECOUPLED GMD CASCADE MLD   === #


#         #case_epri21 = _PM.parse_file(data_epri21)

#         # result = _PMGMD.solve_soc_gmd_cascade_mld_uncoupled(case_epri21, ipopt_solver; setting=setting)
#         # @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         # @test isapprox(result["objective"], 0.0000; atol=1e2)

#         # FIXME: add actual fully automated testing for "solve_soc_gmd_cascade_mld_uncoupled"


#         # ===   COUPLED GMD MLS   === #


#          case_epri21 = _PM.parse_file(data_epri21)

#          result = _PMGMD.solve_soc_gmd_mld(case_epri21, ipopt_solver; setting=setting)
#          @test result["termination_status"] == _PM.LOCALLY_SOLVED
#          @test isapprox(result["objective"], 490.0; atol=1e-2)


#          case_epri21 = _PM.parse_file(data_epri21)

# # FIXME: QC model not currently supported in PowerModelsRestoration (breaks on the call to constraint_theta_ref)

# #         result = _PMGMD.solve_qc_gmd_mld(case_epri21, ipopt_solver; setting=setting)
# #         @test result["termination_status"] == _PM.LOCALLY_SOLVED
# #         @test isapprox(result["objective"], 0.0000; atol=1e2)


#          case_epri21 = _PM.parse_file(data_epri21)

#          result = _PMGMD.solve_ac_gmd_mld(case_epri21, ipopt_solver; setting=setting)
#          @test result["termination_status"] == _PM.LOCALLY_SOLVED
#          @test isapprox(result["objective"], 490.0; atol=1e-2)
#     end


#     @testset "IEEE-RTS-0 case" begin


#         # ===   DECOUPLED GMD MLD   === #


#         # case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

#         # result = _PMGMD.solve_soc_gmd_mld_uncoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
#         # @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         # @test isapprox(result["objective"], 0.0000; atol=1e2)

#         # FIXME: add actual fully automated testing for "solve_soc_gmd_mld_uncoupled"


#         # ===   DECOUPLED GMD CASCADE MLD   === #


#         # case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)

#         # result = _PMGMD.solve_soc_gmd_cascade_mld_uncoupled(case_ieee_rts_0, ipopt_solver; setting=setting)
#         # @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         # @test isapprox(result["objective"], 0.0000; atol=1e2)

#         # FIXME: add actual fully automated testing for "solve_soc_gmd_cascade_mld_uncoupled"


#         # ===   COUPLED GMD MLS   === #

#         case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)
#         result = _PMGMD.solve_soc_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
#         @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         @test isapprox(result["objective"], 275.427; atol=1e-2)

#         case_ieee_rts_0 = _PM.parse_file(data_ieee_rts_0)
#         result = _PMGMD.solve_ac_gmd_mld(case_ieee_rts_0, ipopt_solver; setting=setting)
#         @test result["termination_status"] == _PM.LOCALLY_SOLVED
#         @test isapprox(result["objective"], 273.819, atol=1e-2)

#     end



    @testset "B4GIC case" begin

        case_b4gic = _PM.parse_file(data_b4gic)

        result = _PMGMD.solve_ac_gmd_mld_decoupled(case_b4gic, ipopt_solver; setting=setting)
        @test result["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["objective"], 100.0; atol = 1e-1)

        # DC solution:
        @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)
        @test isapprox(result["solution"]["gmd_branch"]["2"]["dcf"], -106.6935, atol=1e-1) # total current

        # AC solution:
        # @test isapprox(result["solution"]["bus"]["1"]["vm"], 0.941, atol=1e-1)
        # @test isapprox(result["solution"]["branch"]["3"]["pf"], -10.0551, atol=1e-1)
        # @test isapprox(result["solution"]["branch"]["3"]["qf"], -4.7661, atol=1e-1)
        # @test isapprox(result["solution"]["branch"]["3"]["gmd_qloss"], 0.6159, atol=1e-1)
        # @test isapprox(result["solution"]["branch"]["1"]["gmd_qloss"], 0.5902, atol=1e-1)
        # @test isapprox(result["solution"]["branch"]["2"]["gmd_qloss"], 0.0, atol=1e-1)



#        case_b4gic = _PM.parse_file(data_b4gic)

#        wf_path = "../test/data/suppl/b4gic-gmd-waveform.json"
#        h = open(wf_path)
#        wf_data = JSON.parse(h)
#        close(h)

#        result = _PMGMD.solve_ac_gmd_mld_ts_uncoupled(case_b4gic, ipopt_solver, wf_data; setting=setting, disable_thermal=true)
#        for period in 1:length(wf_data["time"])
#            @test result[period]["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
#        end

        # DC solution:
#        dc_solution = result[5]["dc"]["result"]["solution"]
#        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -27.3598, atol=1e-1)
#        @test isapprox(dc_solution["gmd_branch"]["2"]["dcf"], 91.1995, atol=1e-1)

#        dc_solution = result[13]["dc"]["result"]["solution"]
#        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -122.5639, atol=1e-1)
#        @test isapprox(dc_solution["gmd_branch"]["2"]["dcf"], 408.54665, atol=1e-1)

        # AC solution:
#        @test isapprox(result[1]["ac"]["result"]["objective"], 116408.3098; atol = 1e4)
#        @test isapprox(result[9]["ac"]["result"]["objective"], 116536.1993; atol = 1e4)

#        ac_solution = result[13]["ac"]["result"]["solution"]
#        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0677, atol=1e-1)
#        @test isapprox(ac_solution["bus"]["1"]["va"], -0.1124, atol=1e-1)
#        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.1199, atol=1e-1)
#        @test isapprox(ac_solution["bus"]["2"]["va"], -0.0306, atol=1e-1)
#        @test isapprox(ac_solution["branch"]["2"]["pf"], -10.0093, atol=1e-1)
#        @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0641, atol=1e-1)
#        @test isapprox(ac_solution["branch"]["3"]["qf"], -8.0159, atol=1e-1)
#        @test isapprox(ac_solution["gen"]["1"]["pg"], 10.0773, atol=1e-1)
#        @test isapprox(ac_solution["gen"]["1"]["qg"], 8.5438, atol=1e-1)

        # THERMAL solution:

#        result = _PMGMD.solve_ac_gmd_mld_ts_uncoupled(case_b4gic, ipopt_solver, wf_data; setting=setting, disable_thermal=false)
#        for period in 1:length(wf_data["time"])
#            @test result[period]["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
#        end

#        ac_solution = result[13]["ac"]["result"]["solution"]
#        @test isapprox(ac_solution["branch"]["3"]["Ieff"], 408.5467, atol=1e-1)
#        @test isapprox(ac_solution["branch"]["3"]["delta_topoilrise_ss"], 0.0025, atol=1e-1)
#        @test isapprox(ac_solution["branch"]["3"]["delta_hotspotrise_ss"], 257.3844, atol=1e-1)
#        @test isapprox(ac_solution["branch"]["3"]["actual_hotspot"], 282.3869, atol=1e-1)


        case_b4gic = _PM.parse_file(data_b4gic)

        result = _PMGMD.solve_ac_gmd_mld(case_b4gic, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 100.0; atol = 1e2)

        # solution = result["solution"]

        # # DC solution:
        # @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32.0081, atol=1e-1)
        # @test isapprox(solution["gmd_branch"]["2"]["dcf"], 106.6935, atol=1e-1)

        # # AC solution:
        # @test isapprox(solution["bus"]["1"]["vm"], 0.9851, atol=1e-1)
        # @test isapprox(solution["branch"]["3"]["pf"], -10.0554, atol=1e-1)
        # @test isapprox(solution["branch"]["3"]["qf"], -4.7661, atol=1e-1)
        # @test isapprox(solution["load"]["1"]["status"], 1.0, atol=1e-1)
        # @test isapprox(solution["load"]["1"]["pd"], 10.0, atol=1e-1)


        # result = _PMGMD.solve_soc_gmd_mld(case_b4gic, ipopt_solver; setting=setting)
        # @test result["termination_status"] == _PM.LOCALLY_SOLVED
        # @test isapprox(result["objective"], 100.0; atol = 1e-1)



    end


end
