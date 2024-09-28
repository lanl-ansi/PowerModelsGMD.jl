# PowerModelsGMD.jl

Status:
[![CI](https://github.com/lanl-ansi/PowerModelsGMD.jl/workflows/CI/badge.svg)](https://github.com/lanl-ansi/PowerModelsGMD.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/lanl-ansi/PowerModelsGMD.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/lanl-ansi/PowerModelsGMD.jl)
[![Documentation](https://github.com/lanl-ansi/PowerModelsGMD.jl/workflows/Documentation/badge.svg)](https://lanl-ansi.github.io/PowerModelsGMD.jl/stable/)
</p>

PowerModelsGMD (PMsGMD) is an open-source [Julia](https://julialang.org/) tool for evaluating the risks and mitigating the impacts of geomagnetic disturbances (GMDs) and E3 high-altitude electromagnetic pulse (HEMP) events on electrical power transmission networks.
It solves for quasi-dc line flow and ac power flow problems in a system subjected to geomagnetically induced currents (GIC) and calculates GICs based on pre-determined geoelectric fields and takes in the coupled line voltages as inputs.

## PMsGMD Dependencies

PMsGMD directly builds on [PowerModels](https://github.com/lanl-ansi/PowerModels.jl) v0.19 - a package for electrical power transmission network modeling and optimization - of the [InfrastructureModels](https://github.com/lanl-ansi/InfrastructureModels.jl) v0.7 open-source software ecosystem.
Additionally, it relies on and was optimized for [PowerModelsRestoration](https://github.com/lanl-ansi/PowerModelsRestoration.jl) v0.7, [JSON](https://github.com/JuliaIO/JSON.jl) v0.21, [JuMP](https://github.com/jump-dev/JuMP.jl) v1.9, and [Memento](https://github.com/invenia/Memento.jl) v1.4 packages.

Automated testing of PMsGMD problem specifications is done with [Ipopt](https://github.com/jump-dev/Ipopt.jl) v1.2.0 and [Juniper](https://github.com/lanl-ansi/Juniper.jl) v0.9.1 packages.
Alternatively, commercial [KNITRO](https://github.com/jump-dev/KNITRO.jl) or [Gurobi](https://github.com/jump-dev/Gurobi.jl), or open-source [SCS](https://github.com/jump-dev/SCS.jl), [Pajarito](https://github.com/jump-dev/Pajarito.jl), [Pavito](https://github.com/jump-dev/Pavito.jl), or [SCIP](https://github.com/scipopt/SCIP.jl) optimizers may be used for specific problems.



## Core Problem Specifications

PMsGMD solves for quasi-dc line flow and ac power flow problems in a network subjected to GIC.
It also solves for mitigation strategies, such as minimum loadshedding or treating the transformer overheating problem as an optimal transmission switching problem.

At the moment, the following common industry and academic specifications are implemented:
* GIC DC: quasi-dc power flow
* GIC AC-OPF: ac optimal power flow with sequential/coupled quasi-dc power flow
* GIC AC-MLD: ac maximum loadability and minimum loadshedding with sequential/coupled quasi-dc power flow
* GIC AC-OTS: ac optimal transmission switching with minimum loadshedding coupled with a quasi-dc power flow



## Installation

...

After the installation of its dependencies, PMsGMD can be installed from the Julia package manager:
```
add https://github.com/lanl-ansi/PowerModelsGMD.jl.git
```

To verify that all implemented specifications work as designed, test PMsGMD:
```
test PowerModelsGMD
```



## Quick Start

The most common use case is a quasi-dc solve followed by an AC-OPF where the currents from the quasi-dc solve are constant parameters that determine the reactive power consumption of transformers throughout the network.
For example:
```
using PowerModels, PowerModelsGMD, JuMP, Ipopt

network_data = joinpath(dirname(pathof(PowerModelsGMD)), "../test/data/matpower/epri21.m")
network_case = PowerModels.parse_file(network_data)
optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer)

result = PowerModelsGMD.solve_ac_gmd_opf(network_case, optimizer)
```



## Problem Specification Reference


### GIC DC

Solves for steady-state dc currents on lines resulting from induced dc voltages on lines.
For example:
```
network_case = PowerModels.parse_file("test/data/matpower/b4gic.m")
solve_gmd(network_case, optimizer)
```

For large networks (greater than 10,000 buses), the Lehtinen-Pirjola method may be used, which relies on a matrix solve instead of an optimizer.
This may called by omitting the optimizer parameter:
```
solve_gmd(network_case)
```

To save branch currents in addition to bus voltages:
```
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
solve_gmd(network_case, optimizer; setting)
```

**Warning!** The default post-processing Qloss calculations used for the GMD and sequential (uncoupled??) GMD-AC*PF formtulations uses the per-unit voltages specified in the base case

### GIC AC-OPF

#### GIC -> AC-OPF

Solves for the quasi-dc voltages and currents, then uses the calculated quasi-dc currents through the transformer windings as inputs to an AC-OPF optimal power flow specification and calculates the increase in transformer reactive power consumption.
This specification was implemented with nonlinear ac polar relaxation.
For example:
```
solve_ac_gmd_opf_decoupled(network_case, optimizer)
```

#### GIC + AC-OPF

Solves the quasi-dc voltages and currents plus the AC-OPF optimal power flow specification concurrently.
The dc network couples to the ac network by means of reactive power loss in the transformers. This specification was implemented with nonlinear ac polar relaxation.
For example:
```
solve_ac_gmd_opf(network_case, optimizer)
```

This specification has limitations in that it does not model increase in transformer reactive power consumption resulting from changes in the ac terminal voltages.
Additionally, it may report higher reactive power consumption than reality on account of relaxing the "effective" transformer quasi-dc winding current magnitude.

#### GIC + AC-OPF-TS

Solves the quasi-dc voltages and currents plus the multi-time-series AC-OPF optimal power flow specification concurrently.
The dc network couples to the ac network by means of reactive power loss in the transformers. This specification was implemented with nonlinear ac polar relaxation.
For example:
```
solve_ac_gmd_opf_ts(multi_network_case, optimizer)
```


### GIC AC-MLD

#### GIC -> AC-MLD

Solves for the quasi-dc voltages and currents, then uses the calculated quasi-dc currents through the transformer windings as inputs to an AC-MLD maximum loadability specification and calculates the increase in transformer reactive power consumption.
This specification was implemented with fixed network topology, and with second order cone relaxation.
For example:
```
solve_soc_gmd_mld_decoupled(network_case, optimizer)
```

Additionally, to model and analyze cascading failure impact, a decoupled Cascade AC-MLD maximum loadability specification was implemented - based on the the [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification of [PowerModelsRestoration.jl](https://github.com/lanl-ansi/PowerModelsRestoration.jl) - with relaxed generator and bus participations, and with second order cone relaxation.
For example:
```
solve_soc_gmd_cascade_mld_decoupled(network_case, optimizer)
```

#### GIC + AC-MLD

Solves the quasi-dc voltages and currents plus the AC-MLD maximum loadability - based on the the [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification of [PowerModelsRestoration.jl](https://github.com/lanl-ansi/PowerModelsRestoration.jl) - problem specification concurrently.
This specification was implemented relaxed generator and bus participation, and with nonlinear ac polar, quadratic constrained least squares, and second order cone relaxations.
For example:
```
solve_soc_gmd_mld(network_case, optimizer)
```


### GIC AC-OTS

#### GIC + AC-OTS

Solves the quasi-dc voltages and currents plus the AC-OTS optimal transmission switching - where transformers and transmission lines can be openned or closed - problem specification concurrently.
This specification is an extension of the coupled AC-MLS minimum loadshedding specification: it uses transmission switching to protect the network from GIC-induced voltage collapse and transformer overheating, and was implemented with nonlinear ac polar, quadratic constrained least squares, and second order cone relaxations.
For example:
```
solve_soc_gmd_mls_ots(network_case, optimizer)
```

#### GIC + AC-OTS-TS

Actual observed GMDs show time-varying behavior in ground electric fields both in magnitude and direction. This could cause different transformer heating than observed in the field peak magnitude. Consequently, the GIC AC-OTS need to be extended to a multi-time-series specification, in which the physics of transformer heating over time are modeled and used to inform a new optimization model that mitigates the effects of heating in terms of the thermal degradation of the transformer winding insulation.

Solves the quasi-dc voltages and currents plus the multi-time-series AC-OTS optimal transmission switching - where transformers and transmission lines can be openned or closed - and AC-MLS minimum loadshedding problem specifications concurrently.
This specification is an extension of the coupled AC-OTS optimal transmission switching specification: it uses transmission switching to protect the network from GIC-induced voltage collapse and transformer overheating, and was implemented with nonlinear ac polar and second order cone relaxations.
For example:
```
solve_ac_gmd_mls_ots_ts(multi_network_case, optimizer)
```



## Acknowledgments

This code has been developed as part of the [Advanced Network Science Initiative](https://github.com/lanl-ansi) at [Los Alamos National Laboratory](https://www.lanl.gov/) (LANL).
The primary developers are [Arthur Barnes](https://github.com/bluejuniper) and [Adam Mate](https://github.com/adammate), with significant contributions from:
* [Russell Bent](https://github.com/rb004f)
* [Carleton Coffrin](https://github.com/ccoffrin)
* [David Fobes](https://github.com/pseudocubic)

Special thanks to:
* Mowen Lu and Russell Bent for developing and implementing the MLS and OTS problem specifications, which are used in the GIC AC-OPF and GIC AC-MLS problem specifications;
* Noah Rhodes and Carleton Coffrin for developing and implementing the [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification, which is used in the GIC AC-MLS problem specification;
* Michael Rivera for a reference implementation of the Latingen-Pijirola matrix optimizer.


### Development Funding Sources

This code has been developed as part of the following projects, with associated funding agency listed:
* DOE Office of Electricity (OE) -- Space Weather Mitigation Planning project (2022-)
* DOE Office of Science (SC) -- Space Weather Mitigation Planning project (2022-)
* DOE Office of Cybersecurity, Energy Security, and Emergency Response (CESER) -- Electricity Subsector Risk Characterization project (2021-22)
* LANL Laboratory Directed Research & Development (LDRD) -- Impacts of Extreme Space Weather Events on Power Grid Infrastructure project (2018-19)


### Community-Driven Development

Development and enhancement of PMsGMD are welcomed and encouraged. Please feel free to fork this repository and share your contributions to the #master branch with pull requests.
With questions, please reach out to the primary developers of PMsGMD.


### Citing PMsGMD

If you find PMsGMD useful in your work, we kindly request that you cite the following publication(s):
* A. Mate, A. K. Barnes, R. W. Bent, and E. Cotilla-Sanchez, "[Analyzing and Mitigating the Impacts of GMD and EMP Events on the Electrical Grid with PowerModelsGMD.jl](https://arxiv.org/abs/2101.05042)"
* A. Mate, A. K. Barnes, S. K. Morley, J. A. Friz-Trillo, E. Cotilla-Sanchez, and S. P. Blake, "[Relaxation Based Modeling of GMD Induced Cascading Failures in PowerModelsGMD.jl](https://arxiv.org/abs/2108.06585)"



## License

This code is provided under a [BSD license](https://github.com/lanl-ansi/PowerModelsGMD.jl/blob/master/LICENSE.md) as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
