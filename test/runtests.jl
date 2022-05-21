using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import PowerModels
const _PM = PowerModels
import InfrastructureModels
const _IM = InfrastructureModels

import JSON
import JuMP
import Memento

# Suppress warning messages:
Memento.setlevel!(Memento.getlogger(_IM), "error")
Memento.setlevel!(Memento.getlogger(_PM), "error")
Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
_PMGMD.logger_config!("error")

const TESTLOG = Memento.getlogger(_PMGMD)
Memento.setlevel!(TESTLOG, "error")


import Cbc
import Ipopt
import Juniper
import PowerModelsRestoration

# Default setup for optimizers:
cbc_solver = JuMP.optimizer_with_attributes(Cbc.Optimizer, "logLevel"=>0)
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-5, "print_level"=>0)
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>PowerModels.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0), "log_levels"=>[])
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))


using Test

# Parse test cases:
case_b4gic = "../test/data/b4gic.m"
case_b6gic_nerc = "../test/data/b6gic_nerc.m"
case24_ieee_rts_0 = "../test/data/case24_ieee_rts_0.m"
case_epri21 = "../test/data/epri21.m"
case_uiuc150 = "../test/data/uiuc150_95pct_loading.m"
case_rtsgmlcgic = "../test/data/rtsgmlcgic/rts_gmlc_gic_pnw.m"
case_otstest = "../test/data/ots_test.m"


# Perform the tests of implemented specifications:
@testset "PowerModelsGMD" begin

    include("data_ac.jl")
    include("gmd_matrix.jl")
    include("gmd_mld_decoupled.jl")
    include("gmd_mld.jl")
    include("gmd_opf_decoupled.jl")
    include("gmd_opf_ts_decoupled.jl")
    include("gmd_opf.jl")
    # include("gmd_ots.jl")
    include("gmd.jl")

end

