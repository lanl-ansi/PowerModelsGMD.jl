# PowerModelsGMD.jl Documentation

PowerModelsGMD.jl is a Julia package built on top of InfrastructureModels.jl for analysis of geomagnetic disturbances in the context of power systems optimization problems.

```@meta
CurrentModule = PowerModelsGMD
```

## Problem Specifications

### GIC-Only 

```@docs
solve_gmd

solve_gmd_ts_decoupled
```

### GIC-PF

```@docs
solve_gmd_pf

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


