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


data = raw"U:\gmd-tools-10k_fix\gmd-tools-10k_fix\epricase_aug2022_v22_fix.m"
case = _PM.parse_file(data)
_PMGMD.add_gmd_3w_branch!(case)
sol = _PMGMD.solve_gmd(case)
sol = _PMGMD.solve_gmd("../test/data/pti/epri.raw", "../test/data/gic/epri.gic", "../test/data/lines/epri.csv") # linear solver
# sol=  _PMGMD.solve_gmd(case, ipopt_solver; setting=setting) # for opt solver

high_error = 1e-2 # abs(value) >= .0001

low_error = 1 # abs(value) < .0001

@testset "solve of gmd" begin
	@testset "dc bus voltage" begin
		@test isapprox(sol["solution"]["gmd_bus"]["1"]["gmd_vdc"], -41.76016235, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["2"]["gmd_vdc"], -20.61961174, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["3"]["gmd_vdc"], -16.61394882, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["4"]["gmd_vdc"], -105.61529541, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["5"]["gmd_vdc"], -10.66483116, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["6"]["gmd_vdc"], 42.12586975, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["7"]["gmd_vdc"], 4.895e-05, rtol=low_error)
		@test isapprox(sol["solution"]["gmd_bus"]["8"]["gmd_vdc"], 18.597332, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["9"]["gmd_vdc"], -41.76016235, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["10"]["gmd_vdc"], -48.72018051, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["11"]["gmd_vdc"], -105.95415497, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["12"]["gmd_vdc"], -107.32854462, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["13"]["gmd_vdc"], -11.76732063, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["14"]["gmd_vdc"], 52.65732574, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["15"]["gmd_vdc"], 42.12586975, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["16"]["gmd_vdc"], 42.12586975, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["17"]["gmd_vdc"], 5.65550375, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["18"]["gmd_vdc"], 21.69688416, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["19"]["gmd_vdc"], 18.597332, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["20"]["gmd_vdc"], 18.597332, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["21"]["gmd_vdc"], -18.67332077, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["22"]["gmd_vdc"], -17.44464493, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["23"]["gmd_vdc"], -22.33791161, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["24"]["gmd_vdc"], -20.61961174, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["25"]["gmd_vdc"], -20.61961174, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["26"]["gmd_vdc"], -10.07757759, rtol=high_error)
		@test isapprox(sol["solution"]["gmd_bus"]["27"]["gmd_vdc"], -11.83242035, rtol=high_error)
	end
	@testset "auto transformers" begin
		@test isapprox(sol["solution"]["qloss"]["6"], 16.72485083628135, rtol=high_error) || isapprox(sol["solution"]["qloss"]["6"], 16.43194119987213, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["6"], 14.5484046900, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["7"], 16.72485083628135, rtol=high_error) || isapprox(sol["solution"]["qloss"]["7"], 16.43194119987213, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["7"], 14.5484046900, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["25"], 21.616121840771303, rtol=high_error) || isapprox(sol["solution"]["qloss"]["25"], 21.627214380700018, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["25"], 19.0752430000, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["26"], 21.616121840771303, rtol=high_error) || isapprox(sol["solution"]["qloss"]["26"], 21.627214380700018, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["26"], 19.0752430000, rtol=high_error)
	end
	@testset "d-y transformers" begin
	end
	@testset "y-d transformers" begin
		@test isapprox(sol["solution"]["qloss"]["16"], 81.09222151723166, rtol=high_error) || isapprox(sol["solution"]["qloss"]["16"], 80.45002139003995, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["16"], 70.2097091700, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["17"], 81.09222151723166, rtol=high_error) || isapprox(sol["solution"]["qloss"]["17"], 80.45002139003995, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["17"], 70.2097091700, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["23"], 35.94087699303985, rtol=high_error) || isapprox(sol["solution"]["qloss"]["23"], 35.799826014121564, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["23"], 30.9955215500, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["24"], 35.94087699303985, rtol=high_error) || isapprox(sol["solution"]["qloss"]["24"], 35.799826014121564, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["24"], 30.9955215500, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["1"], 30.05418849627624, rtol=high_error) || isapprox(sol["solution"]["qloss"]["1"], 30.255195959752367, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["1"], 69.6001815800, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["29"], 7.4694490145589185, rtol=high_error) || isapprox(sol["solution"]["qloss"]["29"], 7.4816038001901966, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["29"], 17.1829986600, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["30"], 7.4694490145589185, rtol=high_error) || isapprox(sol["solution"]["qloss"]["30"], 7.4816038001901966, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["30"], 17.1829986600, rtol=high_error)
	end
	@testset "y-y transformers" begin
		@test isapprox(sol["solution"]["qloss"]["4"], 12.535675603875498, rtol=high_error) || isapprox(sol["solution"]["qloss"]["4"], 12.316132827726499, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["4"], 10.9043769800, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["5"], 12.535675603875498, rtol=high_error) || isapprox(sol["solution"]["qloss"]["5"], 12.316132827726499, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["5"], 10.9043769800, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["13"], 23.87893610338079, rtol=high_error) || isapprox(sol["solution"]["qloss"]["13"], 23.82830041533058, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["13"], 20.8088207200, rtol=high_error)
		@test isapprox(sol["solution"]["qloss"]["14"], 23.87893610338079, rtol=high_error) || isapprox(sol["solution"]["qloss"]["14"], 23.82830041533058, rtol=high_error) 
		@test isapprox(sol["solution"]["ieff"]["14"], 20.8088207200, rtol=high_error)
	end
	@testset "d-d transformers" begin
	end
	@testset "lines" begin
		@test isapprox(sol["solution"]["qloss"]["2"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["2"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["3"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["3"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["8"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["8"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["9"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["9"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["10"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["10"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["11"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["11"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["12"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["12"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["15"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["15"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["18"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["18"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["19"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["19"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["20"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["20"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["21"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["21"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["22"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["22"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["27"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["27"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["28"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["28"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["qloss"]["31"], 0.0, rtol=low_error)
		@test isapprox(sol["solution"]["ieff"]["31"], 0.0, rtol=low_error)
	end
end