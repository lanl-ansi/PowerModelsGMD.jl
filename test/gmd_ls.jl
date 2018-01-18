
@testset "test ac gmd ls" begin
    @testset "IEEE 24 0" begin
        result = run_ac_gmd_ls("../test/data/case24_ieee_rts_0.json", ipopt_solver)
        @test result["status"] == :LocalOptimal
    end
end





