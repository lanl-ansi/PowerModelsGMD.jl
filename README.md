# PowerModelsGMD.jl


Release: 
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://lanl-ansi.github.io/PowerModelsGMD.jl/stable/)

Dev:
[![Build Status](https://travis-ci.org/lanl-ansi/PowerModelsGMD.jl.svg?branch=master)](https://travis-ci.org/lanl-ansi/PowerModelsGMD.jl)
<!--
[![codecov](https://codecov.io/gh/lanl-ansi/PowerModelsGMD.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/lanl-ansi/PowerModelsGMD.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://lanl-ansi.github.io/PowerModelsGMD.jl/latest/)
</p>
-->

PowerModelsGMD.jl (abbr. PMsGMD) is an open-source framework that provides extensions to [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) (abbr. PMs) for power system simulation, to evaluate the risks and mitigate the potential effects of Geomagnetic Disturbances (GMDs) and E3 High-altitude Electromagnetic Pulse (E3~HEMP) events on the power grid.

PMsGMD solves for quasi-dc line flow and ac power flow on a network subjected to Geomagnetically Induced Currents (GICs). It solves for mitigation strategies by treating the transformer overheating problem as an optimal transmission switching problem.
Since it is open-source, it is easy to study, verify and customize its operation to best fit an application environment. Due to its speed and reliability, it is suitable to be a key component of frameworks that monitor GMD manifestations in real-time, that predict GICs on the power grid, that assess risk, that enhance reliability by providing aid to system-operators, and that recommend modifications in the network configuration.
Thus, PMsGMD is equally useful for research and industry application.



## Core Problem Specifications

* GIC DC: quasi-dc power flow
* GIC -> AC - OPF: sequential quasi-dc power flow and ac optimal power flow
* GIC + AC - OPF: ac optimal power flow coupled with a quasi-dc power flow
* GIC + AC - MLS: ac minimum-load-shed coupled with a quasi-dc power flow
* GIC + AC - OTS: ac optimal transmission switching with load shed coupled with a quasi-dc power flow



## Installation

Prerequisite:
To use PMsGMD, the installation of PMs is required. Follow instructions [here](https://github.com/lanl-ansi/PowerModels.jl).


Installation:
From the Julia package manager REPL type
```
add https://github.com/lanl-ansi/PowerModelsGMD.jl.git
```

Testing:
```
test PowerModelsGMD
```



## Quick Start

The most common use case is a quasi-dc solve followed by an AC-OPF where the currents from the quasi-dc solve are constant parameters that determine the reactive power consumption of transformers on the system.

```
using PowerModels; using PowerModelsGMD; using Ipopt
network_file = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/epri21.m")
case = PowerModels.parse_file(network_file)

solver = with_optimizer(Ipopt.Optimizer)
result = PowerModelsGMD.run_ac_gmd_opf_decoupled(case, solver)
```



## Function Reference
<!-- 
1) check that the test datasets correspond to those used in the test cases
-->


### GIC DC

Solves for steady-state dc currents on lines resulting from induced dc voltages on lines.
`run_gmd("test/data/b4gic.m", solver)`

For large systems (greater than 10,000 buses), the Lehtinen-Pirjola (LP) method may be used that relies on a matrix solve instead of an optimizer.
This may called by omitting the solver parameter
`run_gmd("test/data/b4gic.m")`

To save branch currents in addition to bus voltages
```
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
run_gmd("test/data/b4gic.m", solver, setting=setting)
```


### GIC -> AC-OPF

Solves for the quasi-dc voltages and currents, and uses the calculated quasi-dc currents through transformer windings as inputs to an AC-OPF to calculate the increase in transformer reactive power consumption.
`run_ac_gmd_opf_decoupled("test/data/b4gic.m")`


### GIC + AC-OPF

Solves the quasi-dc voltages and currents and the AC-OPF concurrently. The dc network couples to the ac network by means of reactive power loss in transformers.
`run_ac_gmd_opf("test/data/b4gic.m")`

This formulation has limitations in that it does not model increase in transformer reactive power consumption resulting from changes in the ac terminal voltages.
Additionally, it may report higher reactive power consumption than reality on account of relaxing the "effective" transformer quasi-dc winding current magnitude.


### GIC + AC-MLS

Solve the minimum-load shedding problem for a network subjected to GIC with fixed topology.
`run_ac_gmd_ml("test/data/case24_ieee_rts_0.m")`


### GIC + AC-OTS

Solve the minimum-load shedding problem for a network subjected to GIC where lines and transformers can be opened or closed.
`run_ac_gmd_ots("test/data/ots_test.m")`

Mitigating transformer overheating is achieved by treating the problem as an optimal transmission switching formulation.
However, actual observed GMDs show time-varying behavior in ground electric fields both in magnitude and direction, which could cause different transformer heating than observed in the field peak magnitude.  
Thus, the problem is extended to a multi-time-series formulation as well, in which the physics of transformer heating over time are modeled and used to inform a new optimization model that mitigates the effects of heating in terms of the thermal degradation of the transformer winding insulation.



## Data Reference

PMsGMD uses several extensions to the PMs data format to provide input for its problem formulations.
For generality, it uses a separate dc network defined by the `gmd_bus` and `gmd_branch` tables.
To correctly calculate the increased reactive power consumption of each transformer, the `branch_gmd` table adds all winding configuration related data. Furthermore, `branch_thermal` table adds thermal data necessary to determine the temperature changes in transformers.
The `bus_gmd` table includes the latitude and longitude of buses in the ac network for use in distributionally robust optimization or for convenience in plotting the network.

The description of B4GIC, an included four-bus test case is presented below to demonstrate the use of the PMsGMD data format and introduce each input fields.


### GMD Bus Data Table

This table includes
* `parent_index` - index of corresponding ac network bus
* `status` - binary value that defines the status of bus (1: enabled, 0: disabled)
* `g_gnd` - admittance to ground (in unit of Siemens)
* `name` - a descriptive name for the bus

```
%column_names% parent_index status g_gnd name
mpc.gmd_bus = {
	1	1	5	'dc_sub1'
	2	1	5	'dc_sub2'
	1	1	0	'dc_bus1'
	2	1	0	'dc_bus2'
	3	1	0	'dc_bus3'
	4	1	0	'dc_bus4'
};
```


### GMD Branch Data Table

This table includes
* `f_bus` - "from" bus in the gmd bus table
* `t_bus` - "to" bus in the gmd bus table
* `parent_index` - index of corresponding ac network branch
* `br_status` - binary value that defines the status of branch (1: enabled, 0: disabled)
* `br_r` - branch resistance (in unit of Ohms)
* `br_v` - induced quasi-dc voltage (in unit of Volts)
* `len_km` - length of branch (in unit of km) -- not required
* `name` - a descriptive name for the branch

```
%column_names% f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
	3	1	1	1	0.1	0	0	'dc_xf1_hi'
	3	4	2	1	1.001	170.788	170.788	'dc_br1'
	4	2	3	1	0.1	0	0	'dc_xf2_hi'
};
```


### Branch GMD Data Table

This table includes
* `hi_bus` - index of high-side ac network bus
* `lo_bus` - index of low-side ac network bus
* `gmd_br_hi` - index of gmd branch corresponding to high-side winding (for two-winding transformers)
* `gmd_br_lo` - index of gmd branch corresponding to low-side winding (for two-winding transformers)
* `gmd_k` - scaling factor to calculate reactive power consumption as a function of effective winding current (in per-unit)
* `gmd_br_series` - index of gmd branch corresponding to series winding (for auto-transformers)
* `gmd_br_common` - index of gmd branch corresponding to common winding (for auto-transformers)
* `baseMVA` - MVA base of transformer
* `dispatchable` - binary value that defines if branch is dispatchable (1: dispatchable, 0: not dispatchable)
* `type` - type of branch -- "xfmr" / "transformer, "line", or "series_cap"
* `config` - winding configuration of transformer -- currently "gwye-gwye", "gwye-delta", "delta-delta", and "gwye-gwye-auto" are supported

```
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA dispatchable type config
mpc.branch_gmd = {
	1	3	1	-1	1.793	-1	-1	100	1	'xf'	'gwye-delta'
	1	2	-1	-1	-1	-1	-1	-1	1	'line'	'none'
	2	4	3	-1	1.793	-1	-1	100	1	'xf'	'gwye-delta'
};
```


### Branch Thermal Data Table 

This table includes
* `xfmr` - binary value that defines if branch is a transformer (1: transformer, 0: not a transformer)
* `temperature_ambient` - ambient temperature of transformer (in unit of Celsius)
* `hotspot_instant_limit` - 1-hour hot-spot temperature limit of transformer (in unit of Celsius)
* `hotspot_avg_limit` - 8-hour hot-spot temperature limit of transformer (in unit of Celsius)
* `hotspot_rated` - hot-spot temperature-rise of transformer at rated power (in unit of Celsius)
* `topoil_time_const` - top-oil temperature-rise time-constant of transformer (in unit of minutes)
* `topoil_rated` - top-oil temperature-rise of transformer at rated power (in unit of Celsius)
* `topoil_init` - initial top-oil temperature of transformer (in unit of Celsius)
* `topoil_initialized` - binary value that defines the initial top-oil temperature of transformer (1: temperature starts with `topoil_init` value, 0: temperature starts with steady-state value)
* `hotspot_coeff` - relationship of hot-spot temperature rise to Ieff (in unit of Celsius/amp)

```
%column_names% xfmr temperature_ambient hotspot_instant_limit hotspot_avg_limit hotspot_rated
topoil_time_const topoil_rated topoil_init topoil_initialized hotspot_coeff
mpc.branch_thermal = {
	1	25	280	240	150	71	75	0	1	0.63
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	1	25	280	240	150	71	75	0	1	0.63
};
```


### Bus GMD Data Table

This table includes 
* `lat` - latitude coordinate of ac network bus and corresponding dc network bus
* `lon` - longitude coordinate of ac network bus and corresponding dc network bus

```
%column_names% lat lon
mpc.bus_gmd = {
	40	-89
	40	-87
	40	-89
	40	-87
};
```



## Contributors

In alphabetical order:
* Art Barnes: Decoupled model
* Russell Bent: ML and OTS implementation
* Carleton Coffrin: Architecture
* Adam Mate: Decoupled time-extended model, [RTS-GMLC](https://github.com/GridMod/RTS-GMLC) integration

Acknowledgments:
The authors are grateful for Mowen Lu for developing the ML and OTS problem specifications and to Michael Rivera for a reference implementation of the Latingen-Pijirola matrix solver.

This code has been developed as part of the Advanced Network Science Initiative at Los Alamos National Laboratory.



## Citing PMsGMD

If you find PMsGMD useful in your work, we kindly request that you cite the following publication:

Adam Mate, Arthur Barnes, Russel Bent, and Eduardo Cotilla-Sanchez, "Analyzing and Mitigating the Impact of GMD and EMP Events on the Power Grid with PMsGMD," 2020 Power Systems Computation Conference (PSCC). [under review]


<!-- 
If you find PMsGMD useful in your work, we kindly request that you cite the following [publication](https://ieeexplore.ieee.org/document/...):

```
@inproceedings{..., 
  author = {Adam Mate and Arthur Barnes and Russell Bent}, 
  title = {Analyzing and Mitigating the Impact of GMD and EMP Events on the Power Grid with PMsGMD}, 
  booktitle = {2020 Power Systems Computation Conference (PSCC)}, 
  year = {...},
  month = {...},
  pages = {...}, 
  doi = {...}
}
```
-->



## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.


