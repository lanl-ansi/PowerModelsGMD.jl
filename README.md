# PowerModelsGMD.jl

## Core Problem Specifications
* Geomagnetically Induced Current (GIC) DC Solve: Solve for steady-state dc currents on lines resulting from induced dc voltages on lines
* Coupled GIC + AC Optimal Power Flow (OPF): Solve the AC-OPF problem for a network subjected to GIC. The dc network couples to the ac network by means of reactive power loss in transformers.
* Coupled GIC + AC Minimum Load Shed (MLS). Solve the minimum-load shedding problem for a network subjected to GIC.
* Coupled GIC + AC Optimal Transmission Switching (OTS). Solve the minimum-load shedding problem for a network subjected to GIC where lines and transformers can be opened or closed.
* Couped GIC + AC Mimimum Error: Solve for a new set of generator operating points that is feasible for a network subjected to GIC where the new operating points are as close as possible to the baseline operating points in terms of sum-squared error (SSE).

### Todo: 
* Add quasi-dynamic formulation which uses SSE with respect to the previous time step as opposed to the initial time step
* Add Decoupled GIC + AC-OPF formulation where the AC-OPF is solved for after the GIC has been solved 
* Add time-extended GIC + AC-OTS formulation
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
1. GIC `run_gmd_gic("test/data/b4gic.m")`
2. GIC + AC-OPF `run_gmd("test/data/b4gic.m")`
3. GIC + AC-MLS `run_gmd_ls("test/data/b4gic.m")`
4. GIC + AC-OTS `run_gmd_ots("test/data/b4gic.m")`
5. GIC + AC-OTS `run_gmd_min_error("test/data/b4gic.m")`


