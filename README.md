# PowerModelsGMD.jl

```
BRANCH FOR DEVELOPMENT. VERSION 0.5.0 WILL BE RELEASED IN THE FUTURE.
```

PowerModelsGMD (PMsGMD) is an open-source [Julia](https://julialang.org/) package - an extension to the [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) platform for power system simulation - which was specifically designed to evaluate the risks and mitigate the impacts of geomagnetic disturbances (GMDs) and E3 high-altitude electromagnetic pulse (HEMP) events on the electrical grid.

Due to its open-source nature, it is easy to verify and customize its operation to best fit the application circumstances. Due to its speed and reliability, it is suitable to be a key component of toolkits that monitor GMD manifestations in real-time, that predict GICs on the electrical grid, that assess risk, that enhance grid resilience by providing aid to system-operators, and that recommend modifications in the network configuration.
Consequently, PMsGMD is equally useful for both research and industry application.



## PMsGMD Dependencies

PMsGMD builds on the following Julia packages: [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) v0.18.0 and [InfrastructureModels](https://github.com/lanl-ansi/InfrastructureModels.jl) v0.6.0.
In addition, it relies on and was optimized for these packages: [JSON](https://github.com/JuliaIO/JSON.jl) v0.21, [JuMP](https://github.com/jump-dev/JuMP.jl) v0.21, and [Memento](https://github.com/invenia/Memento.jl) v1.2.



## Core Problem Specifications

PMsGMD solves for quasi-dc line flow and ac power flow problems in a system subjected to geomagnetically induced currents (GIC). It also solves for mitigation strategies by treating the transformer overheating problem as an optimal transmission switching problem.

Currently the following common industry and academic specifications have been implemented:
* GIC DC: quasi-dc power flow
* GIC AC-OPF: ac optimal power flow with sequential/coupled quasi-dc power flow
* GIC AC-OPF-TS: multi-time-series ac optimal power flow with sequential/coupled quasi-dc power flow
* GIC AC-MLS: ac minimum loadshed with sequential/coupled quasi-dc power flow
* GIC AC-OTS: ac optimal transmission switching with minimum loadshed coupled with a quasi-dc power flow
* GIC AC-OTS-TS: multi-time-series ac optimal transmission switching with minimum loadshed coupled with a quasi-dc power flow

Testing of implemented specifications was done with [Ipopt](https://github.com/jump-dev/Ipopt.jl) v0.7.0 and [Juniper](https://github.com/lanl-ansi/Juniper.jl) v0.7.0.
Alternatively, [Cbc](https://github.com/jump-dev/Cbc.jl) and [SCS](https://github.com/jump-dev/SCS.jl) solvers are supported as well.



## Installation

After the installation of its dependencies, PMsGMD can be installed from the Julia package manager:
```
add https://github.com/lanl-ansi/PowerModelsGMD.jl.git
```

To verify that all implemented specifications work as designed, test PMsGMD:
```
test PowerModelsGMD
```



## Quick Start

The most common use case is a quasi-dc solve followed by an AC-OPF where the currents from the quasi-dc solve are constant parameters that determine the reactive power consumption of transformers throughout the system.
For example:
```
using PowerModels, PowerModelsGMD, Ipopt

network_file = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/epri21.m")
case = PowerModels.parse_file(network_file)
solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer)

result = PowerModelsGMD.run_ac_gmd_opf_decoupled(case, solver)
```



## Problem Specification Reference


### GIC DC

Solves for steady-state dc currents on lines resulting from induced dc voltages on lines.
For example:
```
run_gmd("test/data/b4gic.m", solver)
```

For large systems (greater than 10,000 buses), the Lehtinen-Pirjola method may be used, which relies on a matrix solve instead of an optimizer.
This may called by omitting the solver parameter:
```
run_gmd("test/data/b4gic.m")
```

To save branch currents in addition to bus voltages:
```
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
run_gmd("test/data/b4gic.m", solver; setting)
```


### GIC AC-OPF

#### GIC -> AC-OPF

Solves for the quasi-dc voltages and currents, then uses the calculated quasi-dc currents through the transformer windings as inputs to an AC-OPF optimal power flow specification in order to calculate the increase in transformer reactive power consumption.
For example:
```
run_ac_gmd_opf_decoupled(case, solver)
```

#### GIC + AC-OPF

Solves the quasi-dc voltages and currents plus the AC-OPF optimal power flow specification concurrently. The dc network couples to the ac network by means of reactive power loss in transformers.
For example:
```
run_ac_gmd_opf(case, solver)
```

It is advised to adjust qloss in the results:
```
adjust_gmd_qloss(case, solution)
```

This specification has limitations in that it does not model increase in transformer reactive power consumption resulting from changes in the ac terminal voltages. Additionally, it may report higher reactive power consumption than reality on account of relaxing the "effective" transformer quasi-dc winding current magnitude.


### GIC AC-OPF-TS

#### GIC -> AC-OPF-TS

Solves for the quasi-dc voltages and currents, then uses the calculated quasi-dc currents through the transformer windings as inputs to a multi-time-series AC-OPF optimal power flow specification in order to calculate the increase in transformer reactive power consumption.
For example:
```
run_ac_gmd_opf_ts_decoupled(case, solver, waveform)
```

The implemented thermal model is disabled by default. To enable thermal calculations and display of results, the `disable_thermal` optional argument can be used.
For example:
```
run_ac_gmd_opf_ts_decoupled(case, solver, waveform; setting, disable_thermal=false)
```

#### GIC + AC-OPF-TS

Solves the quasi-dc voltages and currents plus the multi-time-series AC-OPF optimal power flow specification concurrently. The dc network couples to the ac network by means of reactive power loss in transformers.
For example:
```
run_ac_gmd_opf_ts(multinetworkcase, solver)
```


### GIC AC-MLS

#### GIC -> AC-MLS

Solves for the quasi-dc voltages and currents, then uses the calculated quasi-dc currents through the transformer windings as inputs to an AC-MLS minimum loadshedding specification in order to calculate the increase in transformer reactive power consumption. The network topology is fixed.
For example:
```
run_ac_gmd_mls_decoupled(case, solver)
```

Additionally, the decoupled AC-MLS minimum loadshedding specification was implemented as a decoupled [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification as well, with relaxed generator and bus participation.
For example:
```
run_soc_gmd_mld_decoupled(case, solver)
```

#### GIC + AC-MLS

Solves the quasi-dc voltages and currents plus the AC-MLS minimum loadshedding specification concurrently. The network topology is fixed.
For example:
```
run_ac_gmd_mls(case, solver)
```

Additionally, the sequential AC-MLS minimum loadshedding specification was implemented as a sequential [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification as well, with relaxed generator and bus participation.
For example:
```
run_soc_gmd_mld(case, solver)
```


### GIC AC-OTS

#### GIC + AC-OTS

Solves the AC-MLS minimum loadshedding specification for a system subjected to geomagnetically induced currents, where lines and transformers can be opened or closed. It uses transmission-switching to protect the system from GIC-induced voltage collapse and transformer overheating.
For example:
```
run_ac_gmd_mls_ots(case, solver)
```


### GIC AC-OTS-TS

#### GIC + AC-OTS-TS

Solves the multi-time-series AC-MLS minimum loadshedding specification for a system subjected to geomagnetically induced currents, where lines and transformers can be opened or closed. It uses transmission-switching to protect the system from GIC-induced voltage collapse and transformer overheating.
For example:
```
run_ac_gmd_mls_ots_ts(multinetworkcase, solver)
```

Actual observed GMDs show time-varying behavior in ground electric fields both in magnitude and direction. This could cause different transformer heating than observed in the field peak magnitude. Consequently, the GIC AC-OTS specification need to be extended to a multi-time-series specification as well, in which the physics of transformer heating over time are modeled and used to inform a new optimization model that mitigates the effects of heating in terms of the thermal degradation of the transformer winding insulation.



## Data Reference

PMsGMD uses several extensions to the PMs data format to provide input for its problem specifications.
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
* `len_km` - length of branch (in unit of km) -- optional
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
* `type` - type of branch -- "xfmr" / "transformer", "line", or "series_cap"
* `config` - winding configuration of transformer -- currently "delta-delta", "delta-wye", "wye-delta", "wye-wye", "delta-gwye", "gwye-delta", "gwye-gwye", and "gwye-gwye-auto" are supported

```
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
	1	3	1	-1	1.793	-1	-1	100	'xfmr'	'gwye-delta'
	1	2	-1	-1	-1	-1	-1	-1	'line'	'none'
	2	4	3	-1	1.793	-1	-1	100	'xfmr'	'gwye-delta'
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
* `hotspot_coeff` - relationship of hot-spot temperature rise to Ieff (in unit of Celsius/Amp)

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



## Acknowledgments

This code has been developed as part of the [Advanced Network Science Initiative](https://github.com/lanl-ansi) at Los Alamos National Laboratory.
The primary developers are [Arthur Barnes](https://github.com/bluejuniper) and [Adam Mate](https://github.com/adammate) with significant contributions from:
* [Russell Bent](https://github.com/rb004f)
* [Carleton Coffrin](https://github.com/ccoffrin)
* [David Fobes](https://github.com/pseudocubic)

Special thanks to 
Mowen Lu for developing- and Russell Bent for implementing the MLS and OTS problem specifications, which are used in the GIC AC-OPF and GIC AC-MLS problem specifications; to
Carleton Coffrin for developing and implementing the [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification, which is used in the GIC AC-MLS problem specification; and to
Michael Rivera for a reference implementation of the Latingen-Pijirola matrix solver.


### Development

Community-driven development and enhancement of PMsGMD are welcome and encouraged.
Please feel free to fork this repository and share your contributions to the master branch with a pull request.


### Citing PMsGMD

If you find PMsGMD useful in your work, we kindly request that you cite the following [publication](https://arxiv.org/abs/2101.05042):
```
@Misc{pmsgmd,
    author = {A. {Mate} and A. K. {Barnes} and R. W. {Bent} and E. {Cotilla-Sanchez}},
    title = {{Analyzing and Mitigating the Impacts of GMD and EMP Events on the Electrical Grid with PowerModelsGMD.jl}},
    year = {2021},
    month = {Jan.},
    pages = {1--9},
    archivePrefix = {arXiv},
    primaryClass = {eess.SY},    
    eprint = {2101.05042},
    note = {\url{https://arxiv.org/abs/2101.05042}. LA-UR-19-29623},
}
```



## License

This code is provided under a [BSD license](https://github.com/lanl-ansi/PowerModelsGMD.jl/blob/master/LICENSE.md) as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
