using PowerModelsGMD
const _PMGMD = PowerModelsGMD

import InfrastructureModels
const _IM = InfrastructureModels
import PowerModels
const _PM = PowerModels

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


import Ipopt
import PowerModelsRestoration

# Default setup for optimizers:
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-5, "print_level"=>0)
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))


using Test

# Parse test cases:
case_b4gic = "../test/data/b4gic.m"

case_b4gic3w = "../test/data/b4gic3w.raw"
mods_b4gic3w = "../test/data/b4gic3w_mods.json"

b4gic3w_data = PowerModels.parse_file(case_b4gic3w)

f = open(mods_b4gic3w)
mods = JSON.parse(f)
close(f)

_PMGMD.apply_mods!(b4gic3w_data, mods)
_PMGMD.fix_gmd_indices!(b4gic3w_data)

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

