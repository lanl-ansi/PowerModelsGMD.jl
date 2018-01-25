@testset "test ac data" begin
    @testset "4-bus case ac opf" begin
        result = run_ac_opf("../test/data/b4gic.json", ipopt_solver)
        
        
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 116914; atol = 1e2)
    end

    @testset "6-bus case ac opf" begin
        result = run_ac_opf("../test/data/b6gic_nerc.json", ipopt_solver)
        
        println(result["objective"])
        
        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 980; atol = 1e0)
    end

    @testset "19-bus case ac opf" begin
        result = run_ac_opf("../test/data/epri21.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 401802; atol = 1e2)
    end

    @testset "150-bus case ac opf" begin
        result = run_ac_opf("../test/data/uiuc150.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 893768; atol = 1e2)
    end
end




@testset "test ac gmd" begin
    @testset "4-bus case solution" begin
        result = run_ac_gmd("../test/data/b4gic.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)
    end

    @testset "4-bus case" begin
        casename = "../test/data/b4gic.json"        
        f = open(casename)
        case = JSON.parse(f)
        close(f)

        result = run_ac_gmd("../test/data/b4gic.json", ipopt_solver; setting=setting)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)

        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)       
        @test isapprox(solution["bus"]["1"]["vm"], 0.933660, atol=1e-3)
        @test isapprox(solution["branch"]["3"]["pf"], -1007.680670, atol=1e-3)
        @test isapprox(solution["branch"]["3"]["qf"], -434.504704, atol=1e-3)          
    end

    @testset "6-bus case" begin
        casename = "../test/data/b6gic_nerc.json"
        result = run_ac_gmd(casename, ipopt_solver; setting=setting)

        f = open(casename)
        case = JSON.parse(f)
        close(f)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 11832.5; atol = 1e3)
          
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        adjust_gmd_qloss(case, solution)

        @test isapprox(solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)
        @test isapprox(solution["bus"]["2"]["vm"], 0.92784494, atol=1e-2)
        # check that kcl with qloss is being done correctly
        # br23
        @test isapprox(solution["branch"]["2"]["qf"], -36.478387, atol=5.0)
        @test isapprox(solution["branch"]["2"]["qt"], 49.0899781, atol=5.0)
        # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qf"], -36.402340, atol=5.0)
        @test isapprox(solution["branch"]["4"]["qt"], 36.4783871, atol=5.0)
        # br45
        @test isapprox(solution["branch"]["5"]["pf"], -100.40386, atol=5.0)
        @test isapprox(solution["branch"]["5"]["pt"], 100.648681, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qf"], -49.089978, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qt"], 48.6800005, atol=5.0)
        
        # check that kcl with qloss is being done correctly
        # br23
        @test isapprox(solution["branch"]["2"]["qf"], -36.478387, atol=5.0)
        @test isapprox(solution["branch"]["2"]["qt"], 49.0899781, atol=5.0)
        # T2 gwye-gwye auto
        @test isapprox(solution["branch"]["4"]["qf"], -36.402340, atol=5.0)
        @test isapprox(solution["branch"]["4"]["qt"], 36.4783871, atol=5.0)
        # br45
        @test isapprox(solution["branch"]["5"]["pf"], -100.40386, atol=5.0)
        @test isapprox(solution["branch"]["5"]["pt"], 100.648681, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qf"], -49.089978, atol=5.0)
        @test isapprox(solution["branch"]["5"]["qt"], 48.6800005, atol=5.0)
    end

    @testset "19-bus case" begin
        casename = "../test/data/epri21.json"
        result = run_ac_gmd(casename, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5.08585e5; atol = 1e4)
         
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)
        # adjust_gmd_qloss(case, solution)
        @test isapprox(solution["gmd_bus"]["14"]["gmd_vdc"], 44.31, atol=1e-1) 
        @test isapprox(solution["gmd_bus"]["23"]["gmd_vdc"],  -41.01, atol=1e-1)         
    end

    @testset "150-bus case" begin
        casename = "../test/data/uiuc150.json"
        result = run_ac_gmd(casename, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 9.52847e5; atol = 1e5)
                    
        solution = result["solution"]
        make_gmd_mixed_units(solution, 100.0)

        @test isapprox(solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1) 
        @test isapprox(solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1) 
    end
end





