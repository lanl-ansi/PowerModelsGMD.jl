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
Solve the minimum-load shedding problem for a network subjected to GIC with fixed topology.
`run_ac_gmd_ml("test/data/case24_ieee_rts_0.m")`


### GIC + AC-OTS 
 Solve the minimum-load shedding problem for a network subjected to GIC where lines and transformers can be opened or closed.
`run_ac_gmd_ots("test/data/ots_test.m")`

## Data Reference
PowerModelsGMD uses some extensions to the PowerModels data format. For generality, it uses a separate dc network
defined by the `gmd_bus` and `gmd_branch` tables. To correctly calculate increased reactive power consumption
for each transformer, it is necessary to specify its winding configuration. 


### GMD Bus Table
This table includes 
* the index of the corresponding bus in the ac network 
* whether the bus is active (1 is active, 0 is disabled)
* the admittance to ground in Siemens
* a descriptive name for the bus


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

### GMD Branch Table
This table includes
* the "from" bus in the gmd bus table
* to "to" bus in the gmd bus table
* the index of the corresponding branch in the ac network
* whether the branch is active (1 is active, 0 is disabled)
* the branch resistance in Ohms
* the induced quasi-dc voltage in volts
* the length of the branch in km (not required)
* a description name of the branch

```
%column_names%  f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
	3	1	1	1	0.1	0	0	'dc_xf1_hi'	
	3	4	2	1	1.00073475	170.78806587354	170.78806587354	'dc_br1'	
	4	2	3	1	0.1	0	0	'dc_xf2_hi'	
};
```

### Branch GMD 
This table includes information needed to correctly calculate increased reactive power consumption:
* the index of the high-side bus (in the ac network)
* the index of the low-side bus (in the ac network)
* the index of the gmd branch corresponding to the high-side winding (for two-winding transformers)
* the index of the gmd branch corresponding to the low-side winding (for two-winding transformers)
* the scaling factor used to calculate reactive power consumption in per-unit as a function of effective winding current (in per-unit)
* the index of the gmd branch corresponding to the series winding (for autotransformers)
* the index of the gmd branch corresponding to the common winding (for autotransformers) 
* the MVA base of the trasformer. For most networks this is 100 MVA
* the winding configuration of the transformer. Currently "gwye-gwye," "gwye-delta," "delta-delta," and "gwye-gwye-auto" are supported.

```
%column_names%  hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
	1	3	1	-1	1.793	-1	-1	100	'xf'	'gwye-delta'	
	1	2	-1	-1	0	-1	-1	100	'line'	'none'	
	2	4	3	-1	1.793	-1	-1	100	'xf'	'gwye-delta'	
};
```

### BUS GMD
This table includes the latitude and longitude of buses in the ac network for convenience if results are plotted spatially.

```
%column_names%  lat lon
mpc.bus_gmd = {
	40	-89	
	40	-87	
	40	-89	
	40	-87	
};
```

