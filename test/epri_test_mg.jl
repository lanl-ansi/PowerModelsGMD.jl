
using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import InfrastructureModels
const _IM = InfrastructureModels
import PowerModels
const _PM = PowerModels

import JSON
import JuMP
import Memento

import HSL_jll

#ENV["SCIPOPTDIR"] = "/usr/local"  # or path to where SCIP was installed
# Pkg.build("SCIP")

# Suppressing warning messages:
Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
Memento.setlevel!(Memento.getlogger(_IM), "error")
Memento.setlevel!(Memento.getlogger(_PM), "error")

_PMGMD.logger_config!("error")
const TESTLOG = Memento.getlogger(_PMGMD)
Memento.setlevel!(TESTLOG, "error")

import Ipopt
import Juniper
# import SCIP
import Gurobi
import SCIP
import SCIP_jll

import MathOptInterface
const MOI = MathOptInterface
# MOI.set(model, SCIP.StringParameter("lp_solver"), "ma27")
scip_solver = JuMP.optimizer_with_attributes(SCIP.Optimizer, "display/verblevel"=> 5, "nlpi/ipopt/linear_solver" => "ma27", "nlpi/ipopt/optfile"=> "\"hsllib\"=>HSL_jll.libhsl_path, \"linear_solver\"=>\"ma27\", \"print_level\" => 5")
# Setup default optimizers:
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 5, "sb" => "yes", "hsllib"=>HSL_jll.libhsl_path, "linear_solver"=>"ma27")
# scip_solver = JuMP.optimizer_with_attributes(SCIP.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes")
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => _PM.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes"), "log_levels" => [], "time_limit"=>600)

# const GRB_ENV = Gurobi.Env()
gurobi_solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 0)

# juniper_solver2 = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => _PM.optimizer_with_attributes(SCIP.Optimizer))
# look for dual 
setting = Dict{String,Any}(
    "output" => Dict{String,Any}("branch_flows" => true),
    "blocker_relax" => true,
    "add2case" => false,
)

file = "../test/data/matpower/epricase_aug2022_v22_fix_10.m"#fixed epri case 10 volts per km
case = _PM.parse_file(file)
highest_vm = "../test/data/matpower/epricase_aug2022_v22_fix_10.m"
case_hi = _PM.parse_file(highest_vm)

# case["max_blockers"]=1

sol = _PMGMD.solve_gmd(case, ipopt_solver)

#reduce qmax to get a test case that fails
m = 14
gain = 0.05
for (i, gen) in case["gen"]
    gen["qmax"] = case["gen"][i]["qmax"] * (1 - gain*m)
    # gen["pmin"] = 0.0
end


t = @elapsed begin
    soc_qloss =  _PMGMD.solve_soc_bound_qloss(case, juniper_solver; setting=setting)
end
println("Time to complete qloss-bounds $t") 

for (i, bounds) in soc_qloss["qloss"]
    case["branch"][i]["qloss_max"] = bounds["qloss_max"]
end


t = @elapsed begin
    soc_v_bounds = _PMGMD.solve_soc_bound_gmd_bus_v(case_hi, juniper_solver; setting=setting)
end
println("Time to complete v-bounds $t") 

for (i, bounds) in soc_v_bounds["gmd_bus"]
    case["gmd_bus"][i]["vmax"] = bounds["vmax"]
    case["gmd_bus"][i]["vmin"] = bounds["vmin"]
end

_PMGMD.update_cost_multiplier!(case)





# #problem formulations start below
# setting["blocker_relax"] = false
# t = @elapsed begin
#     soc_binary = _PMGMD.solve_soc_blocker_placement(case, juniper_solver; setting=setting)
# end
# solved = false
# opt = 99999999
# blockers = []
# if soc_binary["termination_status"] == _PM.LOCALLY_SOLVED 
#     solved = true
#     opt = soc_binary["objective"]
#     for (idx, blocker) in soc_binary["solution"]["gmd_ne_blocker"]
#         if blocker["blocker_placed"] == 1
#             global blockers
#             push!(blockers, idx)
#         end
#     end
# end
# println("Time to complete SOC binary $t Solved: $solved Opt: $opt Blockers: $blockers")




# t = @elapsed begin
#     soc_binary = _PMGMD.solve_soc_blocker_placement(case, gurobi_solver; setting=setting)
# end
# solved = false
# opt = 99999999
# blockers = []
# if soc_binary["termination_status"] == _PM.OPTIMAL
#     solved = true
#     opt = soc_binary["objective"]
#     for (idx, blocker) in soc_binary["solution"]["gmd_ne_blocker"]
#         if blocker["blocker_placed"] == 1
#             global blockers
#             push!(blockers, idx)
#         end
#     end
# end
# println("Time to complete Gurobi SOC binary $t Solved: $solved Opt: $opt Blockers: $blockers")




# setting["blocker_relax"] = true
# t = @elapsed begin
#     ac_relax = _PMGMD.solve_ac_blocker_placement(case, ipopt_solver; setting=setting)
# end
# solved = false
# opt = 99999999
# if ac_relax["termination_status"] == _PM.LOCALLY_SOLVED 
#     solved = true
#     opt = ac_relax["objective"]
# end
# println("Time to complete AC relax binary $t Solved: $solved Opt: $opt")



setting["blocker_relax"] = false
t = @elapsed begin
    mld_ac_binary = _PMGMD.solve_ac_blocker_placement(case, juniper_solver; setting=setting)
end
solved = false
opt = 99999999
blockers = []
if mld_ac_binary["termination_status"] == _PM.LOCALLY_SOLVED
    solved = true
    opt = mld_ac_binary["objective"]
    for (idx, blocker) in mld_ac_binary["solution"]["gmd_ne_blocker"]
        if blocker["blocker_placed"] == 1
            global blockers
            push!(blockers, idx)
        end
    end
end
println("Time to complete AC binary $t Solved: $solved Opt: $opt Blockers: $blockers")



setting["blocker_relax"] = false
gurobi_solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer,"OutputFlag" => 1, "NonConvex"=>2)
t = @elapsed begin
    mld_acr_binary = _PMGMD.solve_acr_blocker_placement(case, gurobi_solver; setting=setting)
end
solved = false
opt = 99999999
blockers = []
if mld_acr_binary["termination_status"] == _PM.LOCALLY_SOLVED
    solved = true
    opt = mld_acr_binary["objective"]
    for (idx, blocker) in mld_acr_binary["solution"]["gmd_ne_blocker"]
        if blocker["blocker_placed"] == 1
            global blockers
            push!(blockers, idx)
        end
    end
end
println("Time to complete ACR binary $t Solved: $solved Opt: $opt Blockers: $blockers")





# setting["blocker_relax"] = false
# setting["fix_placements"] = false
# t = @elapsed begin
#     mld_qc_binary = _PMGMD.solve_qc_blocker_placement(case, gurobi_solver; setting=setting)
# end
# solved = false
# opt = 99999999
# blockers = []
# if mld_qc_binary["termination_status"] == _PM.OPTIMAL
#     solved = true
#     opt = mld_qc_binary["objective"]
#     for (idx, blocker) in mld_qc_binary["solution"]["gmd_ne_blocker"]
#         if blocker["blocker_placed"] == 1
#             global blockers
#             push!(blockers, idx)
#         end
#     end
# end
# println("Time to complete QC binary $t Solved: $solved Opt: $opt Blockers: $blockers")



# setting["blocker_relax"] = false
# setting["fix_placements"] = true
# for (b,b_dict) in case["gmd_ne_blocker"]
#     if b in blockers
#         b_dict["blocker_placed"]=true
#     else
#         b_dict["blocker_placed"]=false
#     end
# end
# t = @elapsed begin
#     mld_ac_binary_fixed = _PMGMD.solve_ac_blocker_placement(case, juniper_solver; setting=setting)
# end


# scip_solver = JuMP.optimizer_with_attributes(SCIP.Optimizer, "display/vrerblevel"=> 5, "nlpi/ipopt/linear_solver" => "ma27", "nlpi/ipopt/optfile"=> "\"hsllib\"=>HSL_jll.libhsl_path, \"linear_solver\"=>\"ma27\", \"print_level\" => 5")

scip_solver = JuMP.optimizer_with_attributes(SCIP.Optimizer, "lp/initalgorithm"=>'d', "lp/resolvealgorithm" => 'd', "lp/scaling" => 2)#"nlpi/ipopt/priority" => 1000, "nlpi/ipopt/linear_solver" => "ma27", "nlpi/ipopt/optfile"=> "\"hsllib\"=>HSL_jll.libhsl_path")

setting["blocker_relax"] = false
t = @elapsed begin
    mld_ac_binary_scip = _PMGMD.solve_ac_blocker_placement(case, scip_solver; setting=setting)
end
solved = false
opt = 99999999
blockers = []
if mld_ac_binary_scip["termination_status"] == _PM.LOCALLY_SOLVED
    solved = true
    opt = mld_ac_binary_scip["objective"]
    for (idx, blocker) in mld_ac_binary_scip["solution"]["gmd_ne_blocker"]
        if blocker["blocker_placed"] == 1
            global blockers
            push!(blockers, idx)
        end
    end
end
println("Time to complete SCIP AC binary $t Solved: $solved Opt: $opt Blockers: $blockers")


# for (b,b_dict) in case["gmd_ne_blocker"]
#     if b in blockers
#         b_dict["status"] = 1
#     else
#         b_dict["status"] = 0
#     end
# end
# sol2 = _PMGMD.solve_gmd(case, ipopt_solver)

# setting["blocker_relax"] = false
# t = @elapsed begin
#     mld_bfa_binary = _PMGMD.solve_bfa_blocker_placement(case, gurobi_solver; setting=setting)
# end
# solved = false
# opt = 99999999
# blockers = []
# if mld_bfa_binary["termination_status"] == _PM.OPTIMAL
#     solved = true
#     opt = mld_bfa_binary["objective"]
#     for (idx, blocker) in mld_bfa_binary["solution"]["gmd_ne_blocker"]
#         if blocker["blocker_placed"] == 1
#             global blockers
#             push!(blockers, idx)
#         end
#     end
# end
# println("Time to complete BFA binary $t Solved: $solved Opt: $opt Blockers: $blockers")

