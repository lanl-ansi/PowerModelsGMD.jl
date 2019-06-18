# PowerModelsGMD.jl

PowerModelsGMD provides extensions to [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) for solving for quasi-dc line flows 
and ac power flow problems for an electric power network subjected to geomagnetic disturbances. 


## Core Problem Specifications
* Geomagnetically Induced Current (GIC) DC Solve: Solve for steady-state dc currents on lines resulting from induced dc voltages on lines
* Coupled GIC + AC Optimal Power Flow (OPF): Solve the AC-OPF problem for a network subjected to GIC. The dc network couples to the ac network by means of reactive power loss in transformers.
* Coupled GIC + AC Minimum Load Shed (MLS). Solve the minimum-load shedding problem for a network subjected to GIC.
* Coupled GIC + AC Optimal Transmission Switching (OTS). Solve the minimum-load shedding problem for a network subjected to GIC where lines and transformers can be opened or closed.

## Installation

First, follow the installation instructions for [PowerModels](https://github.com/lanl-ansi/PowerModels.jl).
Install with,
```
Pkg.clone("git@github.com:lanl-ansi/PowerModelsGMD.jl.git")
```

Test with,
```
Pkg.test("PowerModelsGMD")
```

## Quick Start
The most common use case is a quasi-dc solve followed by an AC-OPF where the currents from the quasi-dc solve are constant parameters that 
determine the reactive power consumption of transformers on the system.

```
using PowerModels; using PowerModelsGMD; using Ipopt
network_file = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/epri21.m")
case = PowerModels.parse_file(network_file)

result = PowerModelsGMD.run_ac_gmd_opf_decoupled(case, with_optimizer(Ipopt.Optimizer))
```

## Function Reference
<!-- check that the test datasets correspond to those used in the test cases -->
1. GIC `run_gmd("test/data/b4gic.m")`
2. GIC -> AC-PF `run_ac_gmd_pf_decoupled("test/data/b4gic.m")`
3. GIC -> AC-OPF `run_ac_gmd_opf_decoupled("test/data/b4gic.m")`
4. GIC + AC-OPF `run_ac_gmd_opf("test/data/b4gic.m")`
5. GIC + AC-MLS `run_ac_gmd_ml("test/data/b4gic.m")`
6. GIC + AC-OTS `run_ac_gmd_ots("test/data/b4gic.m")`

## Future functions
1. AC-OPF with Min. SSE objective & GIC reactive power draw`run_ac_msse_qloss(net)`
2. GIC -> AC-OPF time-series `run_ac_gmd_opf_ts_decoupled(net, ts_mods)`
3. GIC + AC-OPF time-series `run_gmd_opf_ts(net, ts_mods)`
4. GIC + AC-OTS time-series `run_gmd_ots_ts(net, ts_mods)`
5. GIC + Min error `run_gmd_min_error("test/data/b4gic.m")`

