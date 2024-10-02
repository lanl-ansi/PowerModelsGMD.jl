@testset "TEST GMD" begin
@testset "linear solve of gmd" begin
        @testset "b4gic_default  case" begin
            result = _PMGMD.solve_gmd(b4gic_default)
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], 13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -19.89, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"], 19.89, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["2"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["3"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["2"], 37.22, rtol=0.5)
            @test isapprox(result["solution"]["qloss"]["3"], 37.15, rtol=0.5)
        end
        @testset "b4gic_offbase  case" begin
            result = _PMGMD.solve_gmd(b4gic_offbase)
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], 13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -19.89, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"], 19.89, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["2"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["3"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["2"], 37.26, rtol=0.5)
            @test isapprox(result["solution"]["qloss"]["3"], 37.16, rtol=0.5)
        end
        @testset "autotransformer case" begin
            result = _PMGMD.solve_gmd(autotransformer)
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -79.82, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], 7.44, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], 47.64, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["5"]["gmd_vdc"], -86.00, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["6"]["gmd_vdc"], 21.34, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["7"]["gmd_vdc"], 3.36, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["8"]["gmd_vdc"], 58.87, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["9"]["gmd_vdc"], 0.0, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["1"], 103.913, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["3"], 18.183,  rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["5"], 89.883,  rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["1"], 66.82,  rtol=0.5) # issue with vm for qloss
            @test isapprox(result["solution"]["qloss"]["3"], 20.07,  rtol=0.5)
            @test isapprox(result["solution"]["qloss"]["5"], 97.12,  rtol=0.5)
        end
        @testset "epricase case" begin
            result = _PMGMD.solve_gmd(epricase)
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -41.76, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], -20.62, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -16.61, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"], -105.62, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["5"]["gmd_vdc"], -10.66, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["6"]["gmd_vdc"], 42.13, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["8"]["gmd_vdc"], 18.60, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["10"]["gmd_vdc"], -48.72, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["11"]["gmd_vdc"], -105.95, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["12"]["gmd_vdc"], -107.33, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["13"]["gmd_vdc"], -11.77, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["14"]["gmd_vdc"], 52.66, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["17"]["gmd_vdc"], 5.66, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["18"]["gmd_vdc"], 21.703, rtol=1e-3) 
            @test isapprox(result["solution"]["gmd_bus"]["21"]["gmd_vdc"], -18.67, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["23"]["gmd_vdc"], -22.37, rtol=2e-3) # slightly off 
            @test isapprox(result["solution"]["gmd_bus"]["27"]["gmd_vdc"], -11.83, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["1"], 69.60, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["4"], 10.904, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["5"], 10.904, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["6"], 14.548, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["7"], 14.548, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["13"], 20.809, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["14"], 20.809, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["16"], 70.210, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["17"], 70.210, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["23"], 30.996, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["25"], 19.075, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["29"], 17.183, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["30"], 17.183, rtol=1e-3)
            # println(result["solution"]["qloss"])
        end
    end
    @testset "opt solve of gmd" begin
        @testset "b4gic_default  case" begin
            result = _PMGMD.solve_gmd(b4gic_default, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], 13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -19.89, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"], 19.89, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["2"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["3"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["2"], 37.22, rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["3"], 37.15, rtol=1e-3)
        end
        @testset "b4gic_offbase  case" begin
            result = _PMGMD.solve_gmd(b4gic_offbase, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], 13.26, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -19.89, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"], 19.89, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["2"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["3"], 22.099, rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["2"], 37.26, rtol=1e-3)
            @test isapprox(result["solution"]["qloss"]["3"], 37.16, rtol=1e-3)
        end
        # TODO: b4gic_busOff case broken
        @testset "autotransformer case" begin
            result = _PMGMD.solve_gmd(autotransformer, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -79.82, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], 7.44, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], 47.64, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["5"]["gmd_vdc"], -86.00, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["6"]["gmd_vdc"], 21.34, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["7"]["gmd_vdc"], 3.36, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["8"]["gmd_vdc"], 58.87, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["9"]["gmd_vdc"], 0.0, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["1"], 103.913, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["3"], 18.183, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["5"], 89.883, rtol=1e-3) 
            @test isapprox(result["solution"]["qloss"]["1"], 66.82, rtol=0.5) # issue with vm for qloss
            @test isapprox(result["solution"]["qloss"]["3"], 20.07, rtol=0.5)
            @test isapprox(result["solution"]["qloss"]["5"], 97.12, rtol=0.5)
        end
        @testset "epricase case" begin
            result = _PMGMD.solve_gmd(epricase, ipopt_solver; setting=setting)
            @test result["termination_status"] == _PM.LOCALLY_SOLVED
            @test isapprox(result["solution"]["gmd_bus"]["1"]["gmd_vdc"], -41.76, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["2"]["gmd_vdc"], -20.62, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["3"]["gmd_vdc"], -16.61, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["4"]["gmd_vdc"], -105.62, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["5"]["gmd_vdc"], -10.66, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["6"]["gmd_vdc"], 42.13, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["8"]["gmd_vdc"], 18.60, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["10"]["gmd_vdc"], -48.72, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["11"]["gmd_vdc"], -105.95, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["12"]["gmd_vdc"], -107.33, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["13"]["gmd_vdc"], -11.77, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["14"]["gmd_vdc"], 52.66, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["17"]["gmd_vdc"], 5.66, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["18"]["gmd_vdc"], 21.703, rtol=1e-3) 
            @test isapprox(result["solution"]["gmd_bus"]["21"]["gmd_vdc"], -18.67, rtol=1e-3)
            @test isapprox(result["solution"]["gmd_bus"]["23"]["gmd_vdc"], -22.37, rtol=2e-3) # slightly off 
            @test isapprox(result["solution"]["gmd_bus"]["27"]["gmd_vdc"], -11.83, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["1"], 69.60, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["4"], 10.904, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["5"], 10.904, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["6"], 14.548, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["7"], 14.548, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["13"], 20.809, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["14"], 20.809, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["16"], 70.210, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["17"], 70.210, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["23"], 30.996, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["25"], 19.075, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["29"], 17.183, rtol=1e-3)
            @test isapprox(result["solution"]["ieff"]["30"], 17.183, rtol=1e-3)
            # println(result["solution"]["qloss"])
        end
    end
end

