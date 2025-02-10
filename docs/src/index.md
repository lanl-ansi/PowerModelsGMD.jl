# PowerModelsGMD.jl Documentation

PowerModelsGMD.jl is a Julia package built on top of [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl/) and [InfrastructureModels.jl](https://github.com/lanl-ansi/InfrastructureModels.jl) for analysis of geomagnetic disturbances in the context of power systems optimization problems.

```@meta
CurrentModule = PowerModelsGMD
```

## Problem Specifications

### GIC-Only 

```@docs
solve_gmd

build_gmd

solve_gmd_ts_decoupled
```

### GIC-PF

```@docs
solve_gmd_pf

build_gmd_pf

solve_ac_gmd_pf_uncoupled

solve_soc_gmd_pf_uncoupled

solve_qc_gmd_pf_uncoupled
```

### GIC-OPF

```@docs
solve_ac_gmd_opf

solve_soc_gmd_opf

solve_gmd_opf

build_gmd_opf

solve_ac_gmd_opf_uncoupled

solve_soc_gmd_opf_uncoupled

solve_gmd_opf_uncoupled

build_gmd_opf_uncoupled
```

### GIC-MLD

```@docs
solve_ac_gmd_mld

solve_soc_gmd_mld

solve_qc_gmd_mld

build_gmd_mld

solve_ac_gmd_mld_uncoupled

solve_soc_gmd_mld_uncoupled

solve_qc_gmd_mld_uncoupled

build_gmd_mld_uncoupled
```

### GIC-OTS

```@docs
solve_ac_gmd_ots

solve_soc_gmd_ots

solve_qc_gmd_ots
```

### Blocker Placement

```@docs
solve_ac_blocker_placement

solve_soc_blocker_placement

build_blocker_placement

solve_ac_blocker_placement_multi_scenario

solve_soc_blocker_placement_multi_scenario

build_blocker_placement_multi_scenario
```

## Objectives

```@docs
objective_blocker_placement_cost

objective_blocker_placement_cost_multi_scenario

objective_max_qloss

objective_bound_gmd_bus_v

objective_max_loadability

objective_gmd_min_fuel

objective_gmd_min_error

objective_gmd_mls_on_off

objective_gmd_min_mls

objective_gmd_min_transformer_heating
```

## Constraints

```@docs
constraint_load_served

constraint_gmd_connections
```

### Voltage Constraints

```@docs
constraint_model_voltage

constraint_model_voltage_on_off
```

### DC Current Constraints

```@docs
constraint_dc_current_mag_gwye_delta_xf

constraint_dc_current_mag_gwye_gwye_xf

constraint_dc_current_mag_gwye_gwye_auto_xf
```

### Power Balance Constraints

```@docs
constraint_power_balance_gmd

constraint_power_balance_gmd_shunt

constraint_power_balance_gmd_shunt_ls

constraint_dc_kcl

constraint_dc_power_balance_ne_blocker

constraint_dc_kcl_ne_blocker
```

### Ohm's Law Constraints

```@docs
constraint_dc_ohms
```

### Qloss Constraints

```@docs
constraint_qloss_gmd

constraint_qloss

constraint_qloss_pu

constraint_qloss_constant_ieff
```

### Transformer Temperature Constraints

```@docs
constraint_temperature_state

constraint_temperature_state_ss

constraint_hotspot_temperature_state_ss

constraint_hotspot_temperature_state

constraint_absolute_hotspot_temperature_state
```

## Variables

Not found: `variable_iv`

```@docs
variable_bus_voltage

variable_bus_voltage_on_off

variable_gic_current

variable_dc_current_mag


variable_ac_positive_current_mag

variable_ac_current_mag_sqr

variable_ne_blocker_indicator
```

### Voltage Variables

```@docs
variable_dc_voltage

variable_dc_voltage_difference

variable_dc_voltage_on_off
```

### Power Balance Variables

Not found: `variable_dc_bus_flow`

```@docs
variable_dc_line_flow

variable_dc_gen_flow
```

### Qloss Variables

```@docs
variable_qloss
```

### Transformer Heating Variables

```@docs
variable_hotspot

variable_delta_hotspot_ss

variable_delta_hotspot

variable_delta_oil_ss

variable_delta_oil
```

## Solution Builders

```@docs
solution_gmd_qloss!

solution_gmd!

solution_gmd

add_ieff_solution!

source_id_keys!

solution_add_qloss_bound_case!

solution_get_qloss_bound

solution_add_gmd_bus_v_bounds_case!

solution_get_gmd_bus_v_bounds
```

## Reference Dictionary Builders

```@docs
ref_add_gmd!

ref_add_ne_blocker!

ref_add_ieff!

ref_add_gmd_connections!

ref_add_transformers!
```

## Base

```@docs
check_gmd_branch_parent_status
```

## Data Management

```@docs
apply_mods!

fix_gmd_indices!

create_sid_map

add_gmd_data!

make_gmd_mixed_units!

make_gmd_per_unit!

add_connected_components!

get_connected_components

add_blockers!

filter_gmd_ne_blockers!

update_cost_multiplier!

create_ts_net
```

### Transformer Ieff Calculation

```@docs
calc_ieff_current_mag

calc_ieff_current_mag_line

calc_ieff_current_mag_grounded_xf

calc_ieff_current_mag_gwye_delta_xf

calc_ieff_current_mag_gwye_gwye_xf

calc_ieff_current_mag_gwye_gwye_auto_xf

calc_ieff_current_mag_3w_xf
```

### DC Current Calculation

```@docs
calc_dc_current_line

calc_dc_current_xfmr

calc_dc_current_sub
```

### Transformer Temperature

```@docs
default_topoil_rated_temp_rise_c

default_hotspot_coeff

default_hotspot_time_const_secs

default_topoil_time_const_mins

default_ambient_temp_c

calc_transformer_temps!

calc_hotspot_temp!

calc_delta_hotspotrise!

calc_delta_topoilrise_ss

calc_delta_topoilrise!
```

### Bounds Calculation

```@docs
calc_min_dc_voltage

calc_max_dc_voltage

calc_max_q_loss

calc_ac_positive_current_mag_min

calc_ac_current_mag_max
```

### DC Network Building

```@docs

generate_dc_data

generate_dc_data_psse

generate_dc_data_matpower

parse_files

parse_gic

add_coupled_voltages!
```

## Utility Functions

```@docs
get_warn

generate_g_i_matrix

build_adjacency_matrix
```
