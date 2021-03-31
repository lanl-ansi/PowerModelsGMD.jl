@testset "TEST GMD OPF DECOUPLED" begin


    # ===   B4GIC   === #

    @testset "B4GIC case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_b4gic, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 116456.64090061102; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32.008063648310255, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["2"]["gmd_idc"], 106.69354549436753, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["1"]["vm"], 1.0977680608382536, atol=1e-1)

        @test isapprox(ac_solution["branch"]["3"]["pf"], -10.0551155712465, atol=1e-1)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -3.851701984274371, atol=1e-1)

    end



    # ===   NERC B6GIC   === #

    @testset "NERC B6GIC case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_b6gic_nerc, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 978.3884231039234; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.02219289879143, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["3"]["gmd_idc"], -13.507237320660954, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["2"]["vm"], 1.0991756120094884, atol=1e-1)

        @test isapprox(ac_solution["branch"]["4"]["qf"], -0.3626293539879627, atol=1e-1)  # T2 gwye-gwye auto
        @test isapprox(ac_solution["branch"]["4"]["qt"], 0.30241727363990395, atol=1e-1)  # T2 gwye-gwye auto

        @test isapprox(ac_solution["branch"]["5"]["pf"], -1.0028473574995174, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["pt"], 1.0044948718496285, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["qf"], -0.39098384971754685, atol=1e-1)  # Branch45
        @test isapprox(ac_solution["branch"]["5"]["qt"], 0.3236086193915454, atol=1e-1)  # Branch45

    end



    # ===   EPRI21   === #

    @testset "EPRI21 case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_epri21, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 399393.87778206554; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -6.550702322086242, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"], 44.26301987818915, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["17"]["gmd_vdc"], -40.6570388410749, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["5"]["gmd_idc"], 140.6256703830644, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], 53.32820180462106, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["29"]["gmd_idc"], 177.05207951275656, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["35"]["gmd_idc"], -54.56937304382294, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["5"]["vm"], 1.188009696729532, atol=1e-1)
        @test isapprox(ac_solution["bus"]["13"]["va"], -0.04127494170913014, atol=1e-1)

        @test isapprox(ac_solution["gen"]["5"]["pg"], 5.03935982867538, atol=1e-1)
        @test isapprox(ac_solution["gen"]["5"]["qg"], -0.1061, atol=1e-1)

        @test isapprox(ac_solution["branch"]["13"]["pf"], 4.51513418145402, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["qf"], -0.6706551535472776, atol=1e-1)
        @test isapprox(ac_solution["branch"]["13"]["gmd_qloss"], 3.790257602376662e-40, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["pt"], 8.949999910553688, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["qt"], -0.5656000077047978, atol=1e-1)
        @test isapprox(ac_solution["branch"]["24"]["gmd_qloss"], 0.2891248351366193, atol=1e-1)
        @test isapprox(ac_solution["branch"]["30"]["gmd_qloss"], 0.15972292809209068, atol=1e-1)

    end



    # ===   UIUC150   === #

    @testset "UIUC150 case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_uiuc150, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 1.3447792769590218e6; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["13"]["gmd_vdc"], 0.685118454216281, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["57"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["131"]["gmd_vdc"], 3.804381582513118, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["190"]["gmd_vdc"], 6.9635628849854605, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["197"]["gmd_vdc"], -32.67451206860218, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["7"]["gmd_idc"], 23.94442947211026, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["45"]["gmd_idc"], -6.258858763372976, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["91"]["gmd_idc"], -23.014727979030802, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["5"]["va"], -0.049615317087241304, atol=1e-1)
        @test isapprox(ac_solution["bus"]["55"]["vm"], 1.129193655714393, atol=1e-1)
        @test isapprox(ac_solution["bus"]["115"]["va"], -0.37711577559367043, atol=1e-1)
        @test isapprox(ac_solution["bus"]["115"]["vm"], 1.1544043121435428, atol=1e-1)

        @test isapprox(ac_solution["gen"]["13"]["pg"], 3.136705665730146e-5, atol=1e-1)
        @test isapprox(ac_solution["gen"]["13"]["qg"], -0.21697216684491408, atol=1e-1)
        @test isapprox(ac_solution["gen"]["24"]["pg"], 6.043067353756317, atol=1e-1)
        @test isapprox(ac_solution["gen"]["24"]["qg"], 3.0643962180628286, atol=1e-1)

        @test isapprox(ac_solution["branch"]["73"]["gmd_qloss"], 6.586804365741198e-10, atol=1e-1)
        @test isapprox(ac_solution["branch"]["73"]["pf"], -2.6011560849358117, atol=1e-1)
        @test isapprox(ac_solution["branch"]["131"]["gmd_qloss"], 6.432068782169931e-10, atol=1e-1)
        @test isapprox(ac_solution["branch"]["131"]["pt"], -0.07047236948815457, atol=1e-1)
        @test isapprox(ac_solution["branch"]["131"]["qt"], 1.8066969339885781, atol=1e-1)
        @test isapprox(ac_solution["branch"]["184"]["gmd_qloss"], 0.0350137151647536, atol=1e-1)
        @test isapprox(ac_solution["branch"]["208"]["gmd_qloss"], 0.02935521386675506, atol=1e-1)

    end



    # ===   RTS-GMLC-GIC   === #

    @testset "RTS-GMLC-GIC case" begin

        result = _PMGMD.run_ac_gmd_opf_decoupled(case_rtsgmlcgic, ipopt_solver; setting=setting)
        @test result["ac"]["result"]["termination_status"] == _PM.LOCALLY_SOLVED
        @test isapprox(result["ac"]["result"]["objective"], 87444.34461000546; atol = 1e1)

        # - DC solution - %

        dc_solution = result["dc"]["result"]["solution"]

        # NOTE: currently PMsGMD always gives gmd_vdc=0 on the delta side of generator transformers
        @test isapprox(dc_solution["gmd_bus"]["68"]["gmd_vdc"], 16.961848248756223, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["84"]["gmd_vdc"], -6.635078362729118, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["96"]["gmd_vdc"], 13.589410136012727, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["121"]["gmd_vdc"], -9.644997725255688, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["122"]["gmd_vdc"], -7.970614159814858, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["155"]["gmd_vdc"], 0.0, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["186"]["gmd_vdc"], 0.0, atol=1e-1)

        @test isapprox(dc_solution["gmd_branch"]["13"]["gmd_idc"], -23.473682270916655, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["38"]["gmd_idc"], 30.53950698591353, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["67"]["gmd_idc"], -0.34262633276943266, atol=1e-1)
        @test isapprox(dc_solution["gmd_branch"]["81"]["gmd_idc"], -1.486030984306776, atol=1e-1)

        # - AC solution - %

        ac_solution = result["ac"]["result"]["solution"]

        @test isapprox(ac_solution["bus"]["211"]["vm"], 1.0214524186490679, atol=1e-1)  # Bus211
        @test isapprox(ac_solution["bus"]["313"]["vm"], 1.0235341210691178, atol=1e-1)  # Bus313
        @test isapprox(ac_solution["bus"]["1020"]["vm"], 1.123908465035155, atol=1e-1)  # GenBus121=>ID"1020"
        @test isapprox(ac_solution["bus"]["1052"]["vm"], 1.1281435737232657, atol=1e-1)  # GenBus218=>ID"1052"
    
        @test isapprox(ac_solution["branch"]["100"]["pf"], 1.7369061791519753, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(ac_solution["branch"]["100"]["qf"], 0.21367460548313133, atol=1e-1)  # Branch107-108=>ID"100"
        @test isapprox(ac_solution["branch"]["165"]["pt"], 0.9953194237615702, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(ac_solution["branch"]["165"]["qt"], -1.4393885073353945, atol=1e-1)  # Branch306-310=>ID"165"
        @test isapprox(ac_solution["branch"]["24"]["pt"], 0.8886146656975946, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(ac_solution["branch"]["24"]["pf"], -0.8770964186633984, atol=1e-1)  # Branch106-110=>ID"24"
        @test isapprox(ac_solution["branch"]["198"]["qt"], -1.5080907779173738, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(ac_solution["branch"]["198"]["qf"], -0.930731478790997, atol=1e-1)  # Branch206-210=>ID"198"
        @test isapprox(ac_solution["branch"]["150"]["gmd_qloss"], 0.005926580168629641, atol=1e-1)  # Branch213-1042=>ID"150"
        @test isapprox(ac_solution["branch"]["97"]["gmd_qloss"], 0.012992879217039763, atol=1e-1)  # Branch309-312=>ID"97"
        @test isapprox(ac_solution["branch"]["44"]["gmd_qloss"], 0.015668390295656063, atol=1e-1)  # Branch210-211=>ID"44"

        @test isapprox(ac_solution["gen"]["88"]["pg"], 2.558284378375067, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(ac_solution["gen"]["88"]["qg"], 1.4999999106662838, atol=1e-1)  # GenBus-313-Bus1076=>ID"88"
        @test isapprox(ac_solution["gen"]["92"]["pg"], 3.5499999187610514, atol=1e-1)  # GenBus-221-Bus1053=>ID"92"
        @test isapprox(ac_solution["gen"]["11"]["qg"], 0.9568041347526458, atol=1e-1)  # GenBus-107-Bus1009=>ID"11"

    end



end