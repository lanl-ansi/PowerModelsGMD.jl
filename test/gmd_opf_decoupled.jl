@testset "Test AC Data" begin
    @testset "4-bus case ac opf" begin
        result = PowerModels.PowerModels.run_ac_opf("../test/data/b4gic.m", ipopt_solver)
        
        @test result["termination_status"] == LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance")
        @test isapprox(result["objective"], 116914; atol = 1e2)
    end

    @testset "6-bus case ac opf" begin
        result = PowerModels.run_ac_opf("../test/data/b6gic_nerc.m", ipopt_solver)
                
        @test result["termination_status"] == LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance")
        @test isapprox(result["objective"], 980; atol = 1e0)
    end

    @testset "19-bus case ac opf" begin
        result = PowerModels.PowerModels.run_ac_opf("../test/data/epri21.m", ipopt_solver)

        @test result["termination_status"] == LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance")
        @test isapprox(result["objective"], 401802; atol = 1e2)
    end

    @testset "150-bus case ac opf" begin
        result = PowerModels.run_ac_opf("../test/data/uiuc150.m", ipopt_solver)

        @test result["termination_status"] == LOCALLY_SOLVED
        println("Testing objective $(result["objective"]) within tolerance")
        @test isapprox(result["objective"], 893768; atol = 1e2)
    end
end




@testset "Test decoupled GMD -> AC-OPF" begin
    @testset "4-bus case solution" begin
        ac_result = run_ac_gmd_opf_decoupled("../test/data/b4gic.m", ipopt_solver)["ac"]["result"]
        @test ac_result["termination_status"] == LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance")
        @test isapprox(ac_result["objective"], 1.398e5; atol = 1e5)
    end

    @testset "4-bus case" begin
        casename = "../test/data/b4gic.m"                
        case = PowerModels.parse_file(casename)
        
        settings = Dict{AbstractString,Any}("output" => Dict{AbstractString,Any}("branch_flows" => true))
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=settings)

        # outfile = "/home/abarnes/repos/gic/data/decoupled_gmd_results.json"
        # f = open(outfile, "w")
        # JSON.print(f, output)
        # close(f)

        ac_result = output["ac"]["result"]

        @test ac_result["termination_status"] == LOCALLY_SOLVED
        println("Testing objective $(ac_result["objective"]) within tolerance")
        @test isapprox(ac_result["objective"], 1.398e5; atol = 1e5)

        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]

        @test isapprox(dc_solution["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)       
        @test isapprox(ac_solution["bus"]["1"]["vm"], 0.933660, atol=1e-3)
        @test isapprox(ac_solution["branch"]["3"]["pf"], -1007.680670, atol=1e-3)
        @test isapprox(ac_solution["branch"]["3"]["qf"], -434.504704, atol=1e-3)          
    end

    @testset "6-bus case" begin
        casename = "../test/data/b6gic_nerc.m"
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver; setting=setting)
        ac_result = output["ac"]["result"]
        println("Testing objective $(ac_result["objective"]) within 11832.5 +/- 1e3")

        case = PowerModels.parse_file(casename)
                
        @test ac_result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 11832.5; atol = 1e3)
          
        dc_solution = output["dc"]["result"]["solution"]
        ac_solution = output["ac"]["result"]["solution"]
        #make_gmd_mixed_units(dc_solution, 100.0)
        # make_gmd_mixed_units(ac_solution, 100.0)
        # adjust_gmd_qloss(case, ac_solution)

#        println(solution["bus"]["2"]["vm"])
        
        @test isapprox(dc_solution["gmd_bus"]["5"]["gmd_vdc"], -23.022192, atol=1e-1)
        @test isapprox(ac_solution["bus"]["2"]["vm"], 0.92784494, atol=1e-2)
        # check that kcl with qloss is being done correctly
        # br23
        println("Testing $(ac_solution["branch"]["2"]["qf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["2"]["qf"], -36.478387, atol=5e2)
        println("Testing $(ac_solution["branch"]["2"]["qt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["2"]["qt"], 49.0899781, atol=5e2)
        # T2 gwye-gwye auto
        println("Testing $(ac_solution["branch"]["4"]["qf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["4"]["qf"], -36.402340, atol=5e2)
        println("Testing $(ac_solution["branch"]["4"]["qt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["4"]["qt"], 364.783871, atol=5e2)
        # br45
        println("Testing $(ac_solution["branch"]["5"]["pf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["pf"], -100.40386, atol=5e2)
        println("Testing $(ac_solution["branch"]["5"]["pt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["pt"], 100.648681, atol=5e2)
        println("Testing $(ac_solution["branch"]["5"]["qf"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["qf"], -49.089978, atol=5e2)
        println("Testing $(ac_solution["branch"]["5"]["qt"]) within tolerance")
        @test isapprox(ac_solution["branch"]["5"]["qt"], 48.6800005, atol=5e2)
    end

    @testset "19-bus case" begin
        casename = "../test/data/epri21.m"
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver)
        ac_result = output["ac"]["result"]

        @test ac_result["termination_status"] == LOCALLY_SOLVED

        dc_solution = output["dc"]["result"]["solution"]

        # result before PowerModels v0.8
        println("Testing objective $(ac_result["objective"]) within tolerance")
        #@test isapprox(ac_result["objective"], 5.08585e5; atol = 1e5) 
        #@test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"],  44.31, atol=1e-1)
        #@test isapprox(dc_solution["gmd_bus"]["23"]["gmd_vdc"], -41.01, atol=1e-1)

        # after computing a diff on the generated JuMP models from v0.7 and v0.8
        # only coeffents in constraint_ohms_yt_from and constraint_ohms_yt_to changed slightly
        # most likely ipopt was getting stuck in a local min previously
        @test isapprox(ac_result["objective"], 4.99564e5; atol = 1e4)

        # make_gmd_mixed_units(dc_solution, 100.0)
        # adjust_gmd_qloss(case, solution)
        @test isapprox(dc_solution["gmd_bus"]["14"]["gmd_vdc"],  44.26, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["23"]["gmd_vdc"], -40.95, atol=1e-1)
    end

    @testset "150-bus case" begin
        casename = "../test/data/uiuc150.m"
        output = run_ac_gmd_opf_decoupled(casename, ipopt_solver)
        ac_result = output["ac"]["result"]
        println("Testing objective $(ac_result["objective"]) within tolerance")

        @test ac_result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(ac_result["objective"], 9.52847e5; atol = 1e5)

        dc_solution = output["dc"]["result"]["solution"]
        # make_gmd_mixed_units(dc_solution, 100.0)

        @test isapprox(dc_solution["gmd_bus"]["190"]["gmd_vdc"], 7.00, atol=1e-1)
        @test isapprox(dc_solution["gmd_bus"]["197"]["gmd_vdc"], -32.74, atol=1e-1)
    end
end





