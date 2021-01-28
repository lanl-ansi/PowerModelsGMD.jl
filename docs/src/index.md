# PowerModelsGMD.jl Documentation

To run, first call

```using PowerModelsGMD, Ipopt```

The following formulations are supported.

# GIC Quasi-DC only analysis

This can be run from the command line via

```@docs
run_gic(net, optimizer)
```

For large problems where Ipopt may incur excessive computational overhead the problem can be run using a matrix formulation via

```@docs
run_gic_matrix(net::Dict{String,Any})
```

# Coupled Analysis

```@docs
run_ac_gic_opf_decoupled(file)
```
