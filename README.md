# PowerModelsGMD.jl

```
DEVELOPMENT BRANCH

PMSGMD V0.5.0 WILL BE RELEASED IN EARLY 2022
```

PowerModelsGMD (PMsGMD) is an open-source [Julia](https://julialang.org/) package - an extension to the [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) platform for power system simulation - which was specifically designed to evaluate the risks and mitigate the impacts of geomagnetic disturbances (GMDs) and E3 high-altitude electromagnetic pulse (HEMP) events on the electrical grid.

Due to its open-source nature, it is easy to verify and customize its operation to best fit the application circumstances. Due to its speed and reliability, it is suitable to be a key component of toolkits that monitor GMD manifestations in real-time, that predict GICs on the electrical grid, that assess risk, that enhance grid resilience by providing aid to system-operators, and that recommend modifications in the network configuration.
Consequently, PMsGMD is equally useful for both research and industry application.



## PMsGMD Dependencies

PMsGMD builds on the following Julia packages: [InfrastructureModels](https://github.com/lanl-ansi/InfrastructureModels.jl) v0.7.5 and [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) v0.19.6.
Additionally, it relies on and was optimized for these packages: [JSON](https://github.com/JuliaIO/JSON.jl) v0.21, [JuMP](https://github.com/jump-dev/JuMP.jl) v0.4, and [Memento](https://github.com/invenia/Memento.jl) v1.4.



## Core Problem Specifications

PMsGMD solves for quasi-dc line flow and ac power flow problems in a system subjected to geomagnetically induced currents (GIC). It also solves for mitigation strategies by treating the transformer overheating problem as an optimal transmission switching problem.

Currently the following common industry and academic specifications have been implemented:
* GIC DC: quasi-dc power flow
* GIC AC-OPF: ac optimal power flow with sequential/coupled quasi-dc power flow
* GIC AC-OPF-TS: multi-time-series ac optimal power flow with sequential/coupled quasi-dc power flow
* GIC AC-MLS: ac minimum loadshed with sequential/coupled quasi-dc power flow
* GIC AC-OTS: ac optimal transmission switching with minimum loadshed coupled with a quasi-dc power flow
* GIC AC-OTS-TS: multi-time-series ac optimal transmission switching with minimum loadshed coupled with a quasi-dc power flow

Testing of implemented specifications was done with [Ipopt](https://github.com/jump-dev/Ipopt.jl) v1.1.0 and [KNITRO](https://github.com/jump-dev/KNITRO.jl) v0.13.1.
Alternatively, [Cbc](https://github.com/jump-dev/Cbc.jl), [SCS](https://github.com/jump-dev/SCS.jl), or [Juniper](https://github.com/lanl-ansi/Juniper.jl) solvers may be used for certain problems.



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



## Acknowledgments

This code has been developed as part of the [Advanced Network Science Initiative](https://github.com/lanl-ansi) at Los Alamos National Laboratory (LANL).
The primary developers are [Arthur Barnes](https://github.com/bluejuniper) and [Adam Mate](https://github.com/adammate), with significant contributions from:
* [Russell Bent](https://github.com/rb004f)
* [Carleton Coffrin](https://github.com/ccoffrin)
* [David Fobes](https://github.com/pseudocubic)

Special thanks to:
* Mowen Lu and Russell Bent for developing and implementing the MLS and OTS problem specifications, which are used in the GIC AC-OPF and GIC AC-MLS problem specifications
* Noah Rhodes and Carleton Coffrin for developing and implementing the [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification, which is used in the GIC AC-MLS problem specification
* Michael Rivera for a reference implementation of the Latingen-Pijirola matrix solver


### Development Funding Sources

This code has been developed as part of the following projects, with associated funding agency listed:
* DOE Office of Electricity -- Space Weather Mitigation Planning project (2022-)
* DOE Office of Science -- Space Weather Mitigation Planning project (2022-)
* DOE Office of Cybersecurity, Energy Security, and Emergency Response -- Electricity Subsector Risk Characterization project (2021-22)
* LANL Laboratory Directed Research & Development -- Impacts of Extreme Space Weather Events on Power Grid Infrastructure project (2018-19)


### Community-Driven Development

Development and enhancement of PMsGMD are welcomed and encouraged.
Please feel free to fork this repository and share your contributions to the master branch with pull requests.
With questions, please reach out to the primary developers of PMsGMD.


### Citing PMsGMD

If you find PMsGMD useful in your work, we kindly request that you cite the following publication(s):
* A. Mate, A. K. Barnes, R. W. Bent, and E. Cotilla-Sanchez, "[Analyzing and Mitigating the Impacts of GMD and EMP Events on the Electrical Grid with PowerModelsGMD.jl](https://arxiv.org/abs/2101.05042)"
* A. Mate, A. K. Barnes, S. K. Morley, J. A. Friz-Trillo, E. Cotilla-Sanchez, and S. P. Blake, "[Relaxation Based Modeling of GMD Induced Cascading Failures in PowerModelsGMD.jl](https://arxiv.org/abs/2108.06585)"



## License

This code is provided under a [BSD license](https://github.com/lanl-ansi/PowerModelsGMD.jl/blob/master/LICENSE.md) as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.


