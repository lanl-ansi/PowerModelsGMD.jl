# PowerModelsGMD.jl

## Core Problem Specifications
* Geomagnetically Induced Current (GIC) DC Solve: Solve for steady-state dc currents on lines resulting from induced dc voltages on lines
* Coupled GIC + AC Optimal Power Flow (OPF): Solve the AC-OPF problem for a network subjected to GIC. The dc network couples to the ac network by means of reactive power loss in transformers.
* Coupled GIC + AC Minimum Load Shed (MLS). Solve the minimum-load shedding problem for a network subjected to GIC.
* Coupled GIC + AC Optimal Transmission Switching (OTS). Solve the minimum-load shedding problem for a network subjected to GIC where lines and transformers can be opened or closed.

### Todo: 
* Add quasi-dynamic formulation which uses SSE with respect to the previous time step as opposed to the initial time step
* Add time-extended GIC + AC-OTS formulation
* Move GIC Matrix time-series formulation to overload `run_gmd`
* Add GIC + AC harmonic power flow formulation


Extensions to PowerModels.jl for Geomagnetic Disturbance Studies.

## Installation

Install with,
```
Pkg.clone("git@github.com:lanl-ansi/PowerModelsGMD.jl.git")
```

Test with,
```
Pkg.test("PowerModelsGMD")
```

## Quick Start
<!-- check that the test datasets correspond to those used in the test cases -->
1. GIC `run_gmd("test/data/b4gic.m")`
2. GIC -> AC-PF `run_ac_gmd_pf_decoupled("test/data/b4gic.m")`
3. GIC -> AC-OPF `run_ac_gmd_opf_decoupled("test/data/b4gic.m")`
4. GIC + AC-OPF `run_ac_gmd_opf("test/data/b4gic.m")`
5. GIC + AC-MLS `run_ac_gmd_ml("test/data/b4gic.m")`
6. GIC + AC-OTS `run_ac_gmd_ots("test/data/b4gic.m")`
7. GIC + AC-OTS `run_gmd_min_error("test/data/b4gic.m")`

## More advanced functions
1. AC-OPF with Min. SSE objective & GIC reactive power draw`run_ac_msse_qloss(net)`
2. GIC -> AC-OPF time-series `run_ac_gmd_opf_ts_decoupled(net, ts_mods)`

## Future functions
1. GIC + AC-OPF time-series `run_gmd_opf_ts(net, ts_mods)`
2. GIC + AC-OTS time-series `run_gmd_ots_ts(net, ts_mods)`

