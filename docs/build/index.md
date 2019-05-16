
<a id='PowerModelsGMD.jl-Documentation-1'></a>

# PowerModelsGMD.jl Documentation


To run, first call


`using PowerModelsGMD, Ipopt`


The following formulations are supported.


<a id='GIC-Quasi-DC-only-analysis-1'></a>

# GIC Quasi-DC only analysis


This can be run from the command line via

<a id='PowerModelsGMD.run_gic-Tuple{Any,Any}' href='#PowerModelsGMD.run_gic-Tuple{Any,Any}'>#</a>
**`PowerModelsGMD.run_gic`** &mdash; *Method*.



```
run_gic(file, solver)
```

Run GIC current model only


<a target='_blank' href='https://github.com/bluejuniper/PowerModelsGMD.jl/blob/cc00d1c119f2eb9456146a78e620da3a073e1d68/src/prob/gic.jl#L4-L7' class='documenter-source'>source</a><br>


For large problems where Ipopt may incur excessive computational overhead the problem can be run using a matrix formulation via

<a id='PowerModelsGMD.run_gic_matrix-Tuple{Dict{String,Any}}' href='#PowerModelsGMD.run_gic_matrix-Tuple{Dict{String,Any}}'>#</a>
**`PowerModelsGMD.run_gic_matrix`** &mdash; *Method*.



```
run_gic_matrix(net)
```

Run gic matrix solve on data structure


<a target='_blank' href='https://github.com/bluejuniper/PowerModelsGMD.jl/blob/cc00d1c119f2eb9456146a78e620da3a073e1d68/src/prob/gic_matrix.jl#L14-L17' class='documenter-source'>source</a><br>


<a id='Coupled-Analysis-1'></a>

# Coupled Analysis


```
run_ac_gic_opf_decoupled(file)
```

