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

solver = with_optimizer(Ipopt.Optimizer)
result = PowerModelsGMD.run_ac_gmd_opf_decoupled(case, solver)
```

## Function Reference
<!-- check that the test datasets correspond to those used in the test cases -->
### GIC
This solves for the quasi-dc voltage and currents on a system
`run_gmd("test/data/b4gic.m", solver)`

For large systems of greater than 10,000 buses consider using the Lehtinen-Pirjola (LP) form which uses a matrix solve instead 
of an optimizer. This is called by omitting the solver parameter
`run_gmd("test/data/b4gic.m")`

To save branch currents in addition to bus voltages
```
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
run_gmd("test/data/b4gic.m", solver, setting=setting)
```
### GIC -> AC-OPF 
This solves for the quasi-dc voltages and currents, and uses the calculated quasi-dc currents through trasformer windings as
inputs to a an AC-OPF to calculate the increase in transformer reactive power consumption.

 `run_ac_gmd_opf_decoupled("test/data/b4gic.m")`

### GIC + AC-OPF 
This solves the quasi-dc voltages and currents and the AC-OPF concurrently. This formulation has limitations in that it
does not model increase in transformer reactive power consumption resulting from changes in the ac terminal voltages. 
Additionally, it may report higher reactive power consumption than reality on account of relaxing the "effective" transformer
quasi-dc winding current magnitude.

`run_ac_gmd_opf("test/data/b4gic.m")`

### GIC + AC-MLS
`run_ac_gmd_ml("test/data/b4gic.m")`


### GIC + AC-OTS 
`run_ac_gmd_ots("test/data/b4gic.m")`


