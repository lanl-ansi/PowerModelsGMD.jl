
@testset "test ac gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_ac_gmd_ls("../test/data/case24_ieee_rts_0.json", ipopt_solver)
        @test result["status"] == :LocalOptimal
    end
end

@testset "test qc gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_qc_gmd_ls("../test/data/case24_ieee_rts_0.json", gurobi_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
    end
end





