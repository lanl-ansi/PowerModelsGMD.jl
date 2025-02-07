# PowerModelsGMD.jl Documentation

PowerModelsGMD.jl is a Julia package built on top of InfrastructureModels.jl for analysis of geomagnetic disturbances in the context of power systems optimization problems.

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
