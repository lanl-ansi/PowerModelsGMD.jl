---
title: 'PowerModelsGMD.jl: A Julia/JuMP package of analysi of geomagnetic events on bulk electric power systems'
tags:
  - Julia
  - space weather
  - power systems analysis
  - power systems optimization
authors:
  - name: Arthur K. Barnes
    orcid:  0000-0001-9718-3197
    corresponding: true # (This is how to denote the corresponding author)
    affiliation: 1
  - name: Jose E. Tabarez
    orcid: 0000-0003-4800-6340
    affiliation: 1
  - name: Adam Mate
    orcid: 0000-0002-5628-6509
    affiliation: 1
  - name: Russell W. Bent
    orcid: 0000-0002-7300-151X
    affiliation: 2
affiliations:
 - name: Analytics and Modeling Group, Los Alamos National National Laboratory, Los Alamos, NM, USA
   index: 1
   ror: 00hx57361
 - name: Applied Mathematics and Plasma Physics Group, Los Alamos National Laboratory, Los Alamos, NM, USA
   index: 2
date: 1 September 2025
bibliography: paper.bib

# Optional fields if submitting to a AAS journal too, see this blog post:
# https://blog.joss.theoj.org/2018/12/a-new-collaboration-with-aas-publishing
# aas-doi: 10.3847/xxxxx <- update this with the DOI from AAS once you know it.
# aas-journal: Astrophysical Journal <- The name of the AAS journal.
---

# Summary

PowerModelsGMD (PMsGMD) is an open-source Julia tool for evaluating the risks
and mitigating the impacts of geomagnetic disturbances (GMDs) and E3 high-
altitude electromagnetic pulse (HEMP) events on electrical power transmission
networks. It solves for quasi-dc line flow and ac power flow problems in a
system subjected to geomagnetically induced currents (GIC) and calculates GICs
based on pre-determined geoelectric fields and takes in the coupled line
voltages as inputs.

# Statement of need

- Geomagnetic Disturbances (GMDs) resulting from solar events can have adverse
imparts on the bulk electric system by causing geomagcnetically induced currents
(GICs)
- Impact could be blackouts or destruction of grid components with long lead times
such as large power transformers (LPTs)
- Varying claims as to the impact of severity of geomagnetic disturbances motivate
the need for rigorous analysis workflows to quanitfy the impact of GMD events on the
bulk power system in terms of metrics that can be interpreted by utility professionals
to guide reasonable investment in mitigation technologies and strategies
- High cost of mitigation technologies further motivates the development of optimal
placement strategies, especially as existing research suggests that a relatively
sparse placement of such devices can provide significant benefits
- Addressing mitigation strategies such as placement of GIC blocking devices or 
operational methods such as line switching or load shedding motivates the use of 
mathematical optimization methods. 
- Compared with existing software packages that perform GIC analysis, PowerModelsGMD.jl
provides flexibility in terms of separation of problem formulation, problem specification,
and solvers, allowing for changing power systems relaxations and numerical solvers employed
with minimal code changes
- The implementation in pure Julia and permissive license allows for cross-platform deployment on both 
desktop, high-performance computing, and commodity cloud computing resources 

# Capabilities

PMsGMD solves for quasi-dc line flow and ac power flow problems in a network subjected to GIC.
It also solves for mitigation strategies, such as minimum loadshedding or treating the transformer overheating problem as an optimal transmission switching problem.

At the moment, the following common industry and academic specifications are implemented:
- GIC DC: quasi-dc power flow
- GIC AC-OPF: ac optimal power flow with sequential/coupled quasi-dc power flow
- GIC AC-MLD: ac maximum loadability and minimum loadshedding with sequential/coupled quasi-dc power flow
- GIC AC-OTS: ac optimal transmission switching with minimum loadshedding coupled with a quasi-dc power flow

While the focus of PowerModelsGMD.jl is on 


# Installation

Before installing PowerModelsGMD.jl, it is necessary to install its dependencies. This involves first
installing the Julia language version 1.x, where is available on the Julia website https://julianlang.org.

PowerModelsGMD.jl requires the installation of some Julia package dependencies. This includes the 
JuMP library for that provides a high-level interface to optization solvers, the Julia
interface to Ipopt and the Juniper library for solving mixed integer nonlinear problems. For using
the built-in LP solver, the Julia LinearAlgebra and SparseArrays packages are required. Finally,
the CSV package is required for parsing coupled voltage input files. These can be installed with 
the Julia package REPL by first typing `]', then entering

``` bash
add Ipopt
add Juniper
add LinearAlgebra
add SparseArrays
add CSV
```

After the installation of its dependencies, PMsGMD can be installed from the Julia package manager:

```
add PowerModelsGMD
```

To verify that all implemented specifications work as designed, test PMsGMD. Note that some of the tests are commented out, and do not work. 

```
test PowerModelsGMD
```

# Quick Start

A simple test case can be run with the following code. From within the PowerModelsGMD.jl folder run:

``` Julia
using PowerModelsGMD
gic_file = "test/data/gic/bus4.gic"
raw_file = "test/data/pti/bus4.raw"
data = PowerModelsGMD.parse_files(gic_file, raw_file)
result = PowerModelsGMD.solve_gmd(data)
```

# Problem Specification Reference


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

#### GIC → AC-OPF

Solves for the quasi-dc voltages and currents, then uses the calculated quasi-dc currents through the transformer windings as inputs to an AC-OPF optimal power flow specification and calculates the increase in transformer reactive power consumption.
Configure the setting first, then run. Note that the solve_gmd_decoupled function requires the PowerModels AC polar power model, and therefore depends on PowerModels.jl. 
This specification was implemented with nonlinear ac polar relaxation.
For example:
``` Julia
# configure local setting for GIC solver 
setting = Dict{String,Any}("output" => Dict{String,Any}("branch_flows" => true))
local_setting = Dict{String,Any}("bound_voltage" => true)
        merge!(local_setting, setting)

network_case = PowerModelsGMD.parse_file("C:\\Users\\skyle\\OneDrive - Montana State University\\EELE 491\\150_sync\\uiuc150bus_10.m")

#----------CONFIGURE SOLVER, RUN ---------------------------------------------------------
solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes")
result = PowerModelsGMD.solve_gmd_decoupled(network_case, PowerModels.ACPPowerModel, solver, PowerModelsGMD.solve_gmd, PowerModelsGMD.solve_gmd_pf; setting=local_setting)
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

#### GIC → AC-MLD

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

# Software Architecture

# Acknowledgements

This code has been developed as part of the [Advanced Network Science Initiative](https://github.com/lanl-ansi) at [Los Alamos National Laboratory](https://www.lanl.gov/) (LANL).
The primary developers are [Arthur Barnes](https://github.com/bluejuniper) and [Adam Mate](https://github.com/adammate), with significant contributions from:
* [Russell Bent](https://github.com/rb004f)
* [Carleton Coffrin](https://github.com/ccoffrin)
* [David Fobes](https://github.com/pseudocubic)

Special thanks to:
* Mowen Lu and Russell Bent for developing and implementing the MLS and OTS problem specifications, which are used in the GIC AC-OPF and GIC AC-MLS problem specifications;
* Noah Rhodes and Carleton Coffrin for developing and implementing the [MLD](https://github.com/lanl-ansi/PowerModelsRestoration.jl/blob/master/src/prob/mld.jl) problem specification, which is used in the GIC AC-MLS problem specification;
* Michael Rivera for a reference implementation of the Lehtinen-Pirjola matrix optimizer.

## Development Funding Sources

This code has been developed as part of the following projects, with associated funding agency listed:
* DOE Office of Electricity (OE) -- Space Weather Mitigation Planning project (2022-)
* DOE Office of Science (SC) -- Space Weather Mitigation Planning project (2022-)
* DOE Office of Cybersecurity, Energy Security, and Emergency Response (CESER) -- Electricity Subsector Risk Characterization project (2021-22)
* LANL Laboratory Directed Research & Development (LDRD) -- Impacts of Extreme Space Weather Events on Power Grid Infrastructure project (2018-19)

# References
