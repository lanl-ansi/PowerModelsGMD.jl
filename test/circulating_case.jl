using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import InfrastructureModels
const _IM = InfrastructureModels

import PowerModels
const _PM = PowerModels

import JSON
import JuMP
import Ipopt
import Juniper
import LinearAlgebra
import SparseArrays
using Test
import Memento
Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
Memento.setlevel!(Memento.getlogger(_IM), "error")
Memento.setlevel!(Memento.getlogger(_PM), "error")

_PMGMD.logger_config!("error")
const TESTLOG = Memento.getlogger(_PMGMD)
Memento.setlevel!(TESTLOG, "error")

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes")
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => _PM.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes"), "log_levels" => [])
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))


gic_file = "../test/data/gic/circulating_case.gic"
raw_file = "../test/data/pti/circulating_case.raw"
data = _PMGMD.parse_files(gic_file, raw_file)
case = _PMGMD.generate_dc_data(data["nw"]["1"], data["nw"]["2"])

_PMGMD.add_coupled_voltages!("data/lines/circulating_case.csv", case)
_PMGMD.add_gmd_3w_branch!(case)
sol= _PMGMD.solve_gmd(case) # linear solver
# sol=  _PMGMD.solve_gmd(case, ipopt_solver; setting=setting) # for opt solver
_PMGMD.source_id_keys!(sol, case)

high_error = 1e-2 # abs(value) >= .0001

low_error = 1 # abs(value) < .0001

@testset "solve of gmd" begin
	@testset "dc bus voltage" begin
		@test isapprox(sol["solution"]["gmd_bus"][["substation", 1]]["gmd_vdc"], 156.01222229, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["substation", 2]]["gmd_vdc"], -16.20303726, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["substation", 3]]["gmd_vdc"], 4.83526468, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["substation", 4]]["gmd_vdc"], -144.64445496, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 1]]["gmd_vdc"], 172.22134399, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 3]]["gmd_vdc"], -17.97561646, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 4]]["gmd_vdc"], -14.42943668, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 5]]["gmd_vdc"], 1.81808984, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 6]]["gmd_vdc"], 5.36423969, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 7]]["gmd_vdc"], 156.01222229, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 8]]["gmd_vdc"], -16.20303726, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 9]]["gmd_vdc"], 4.83526468, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 12]]["gmd_vdc"], 199.57223511, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 13]]["gmd_vdc"], -171.9956665, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 14]]["gmd_vdc"], -151.42312622, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"][["bus", 15]]["gmd_vdc"], -144.64445496, rtol=high_error)
	end
	@testset "auto transformers" begin
		@test isapprox(sol["solution"]["qloss"][["transformer", 5, 6, 0, "1 ", 0]], 0.58632, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 5, 6, 0, "1 ", 0]], 0.58632, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 5, 6, 0, "1 ", 0]], 0.9250786300, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"][["transformer", 3, 4, 0, "1 ", 0]], 0.188997, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 4, 3, 0, "1 ", 0]], 0.188997, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 3, 4, 0, "1 ", 0]], 0.2981931000, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"][["transformer", 1, 12, 0, "1 ", 0]], 13.205410499999997, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 12, 1, 0, "1 ", 0]], 13.205410499999997, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 1, 12, 0, "1 ", 0]], 20.8351154300, rtol=high_error)
	end
	@testset "d-y transformers" begin
	end
	@testset "y-d transformers" begin
		@test isapprox(sol["solution"]["qloss"][["transformer", 1, 7, 0, "1 ", 0]], 14.3855355, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 1, 7, 0, "1 ", 0]], 14.3855355, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 1, 7, 0, "1 ", 0]], 56.7427063000, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"][["transformer", 6, 9, 0, "1 ", 0]], 0.469464, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 6, 9, 0, "1 ", 0]], 0.469464, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 6, 9, 0, "1 ", 0]], 1.8517643200, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"][["transformer", 14, 15, 0, "1 ", 0]], 7.219255499999999, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 14, 15, 0, "1 ", 0]], 7.219255499999999, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 14, 15, 0, "1 ", 0]], 28.4758319900, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"][["transformer", 8, 3, 0, "1 ", 0]], 1.5731580000000003, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 3, 8, 0, "1 ", 0]], 1.5731580000000003, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 8, 3, 0, "1 ", 0]], 6.2052059200, rtol=high_error)
	end
	@testset "y-y transformers" begin
		@test isapprox(sol["solution"]["qloss"][["transformer", 13, 14, 0, "1 ", 0]], 18.870821999999997, rtol=high_error) || isapprox(sol["solution"]["qloss"][["transformer", 13, 14, 0, "1 ", 0]], 18.870821999999997, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"][["transformer", 13, 14, 0, "1 ", 0]], 29.7738399500, rtol=high_error)
	end
	@testset "d-d transformers" begin
	end
	@testset "lines" begin
		@test isapprox(sol["solution"]["qloss"][["branch", 1, 3, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"][["branch", 1, 3, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"][["branch", 1, 6, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"][["branch", 1, 6, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"][["branch", 4, 5, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"][["branch", 4, 5, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"][["branch", 14, 6, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"][["branch", 14, 6, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"][["branch", 12, 13, "1 "]], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"][["branch", 12, 13, "1 "]], 0.0, rtol=low_error)
	end
end