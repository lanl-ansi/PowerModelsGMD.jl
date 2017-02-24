

@testset "test ac gmd" begin
    @testset "4-bus case" begin
        result = run_ac_opf("../test/data/b4gic.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 139800.45613240905; atol = 1e3)
    end
end





