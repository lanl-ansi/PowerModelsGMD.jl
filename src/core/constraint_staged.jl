# ===   VOLTAGE CONSTRAINTS   === #

"CONSTRAINT: voltage magnitude on/off constraint"
function constraint_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)

    vm = _PM.var(pm, n, :vm, i)
    z_voltage = _PM.var(pm, n, :z_voltage, i)

    JuMP.@constraint(pm.model,
        vm
        <=
        vmax * z_voltage
    )
    JuMP.@constraint(pm.model,
        vm
        >=
        vmin * z_voltage
    )

end


"CONSTRAINT: squared voltage magnitude on/off constraint"
function constraint_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmin, vmax)

    w = _PM.var(pm, n, :w, i)
    z_voltage = _PM.var(pm, n, :z_voltage, i)

    JuMP.@constraint(pm.model,
        w
        <=
        vmax^2 * z_voltage
    )
    JuMP.@constraint(pm.model,
        w
        >=
        vmin^2 * z_voltage
    )

end


"CONSTRAINT: on/off dc current on the ac lines"
function constraint_dc_current_mag_on_off(pm::_PM.AbstractPowerModel, n::Int, k, dc_max)

    ieff = _PM.var(pm, n, :i_dc_mag)[k]
    z = _PM.var(pm, n, :z_branch)[k]

    JuMP.@constraint(pm.model,
        ieff
        <=
        z * dc_max
    )

end


"CONSTRAINT: perspective constraint for generation cost"
function constraint_gen_perspective(pm::_PM.AbstractPowerModel, n::Int, i, cost)

    z = _PM.var(pm, n, :z_gen)[i]
    pg_sqr = _PM.var(pm, n, :pg_sqr)[i]
    pg = _PM.var(pm, n, :pg)[i]

    JuMP.@constraint(pm.model,
        z * pg_sqr
        >=
        cost[1] * pg^2
    )

end


"CONSTRAINT: tie OTS variables to gen variables"
function constraint_gen_ots_on_off(pm::_PM.AbstractPowerModel, n::Int, i, bus_arcs)

    z = _PM.var(pm, n, :z_gen)[i]
    zb = _PM.var(pm, n, :z_branch)

    JuMP.@constraint(pm.model,
        z
        <=
        sum(zb[a[1]] for a in bus_arcs)
    )

end

"CONSTRAINT: ohms on/off constraint for dc circuits"
function constraint_dc_ohms_on_off(pm::_PM.AbstractPowerModel, n::Int, i, f_bus, t_bus, f_idx, t_idx, ac_branch, vs, gs)

    Memento.debug(_LOGGER, "branch $i: ($f_bus,$t_bus), $vs, $gs \n")

    v_dc_diff = _PM.var(pm, n, :v_dc_diff)[i]
    vfr = _PM.var(pm, n, :v_dc)[f_bus]
    vto = _PM.var(pm, n, :v_dc)[t_bus]

    dc = _PM.var(pm, n, :dc)[(i,f_bus,t_bus)]
    vz = _PM.var(pm, n, :vz)[i]
    z = _PM.var(pm, n, :z_branch)[ac_branch]

    JuMP.@constraint(pm.model,
        v_dc_diff
        ==
        vfr - vto
    )

    JuMP.@constraint(pm.model,
        dc
        ==
        gs * (vz + z * vs)
    )

    _IM.relaxation_product(pm.model, z, v_dc_diff, vz)

end


"CONSTRAINT: qloss assuming constant 1.0 dc voltage"
function constraint_qloss_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, branchMVA, K)

    qloss = _PM.var(pm, n, :qloss)
    i_dc_mag = _PM.var(pm, n, :i_dc_mag)[k]

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * i_dc_mag) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: decoupled qloss assuming constant ac voltage"
function constraint_qloss_decoupled_vnom(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, branchMVA, ieff)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * ieff) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: qloss assuming varying ac voltage"
function constraint_qloss_decoupled(pm::_PM.AbstractPowerModel, n::Int, k, i, j, branchMVA, K, ieff, ih)

    qloss = _PM.var(pm, n, :qloss)
    v = _PM.var(pm, n, :vm)[ih]
        # ih is the index of the high-side bus

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * v * ieff) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


"CONSTRAINT: decoupled qloss assuming constant ac voltage for MLD"
function constraint_qloss_decoupled_vnom_mld(pm::_PM.AbstractPowerModel, n::Int, k, i, j, K, branchMVA, ieff)

    qloss = _PM.var(pm, n, :qloss)
    z_voltage = _PM.var(pm, n, :z_voltage)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        (K * ieff * z_voltage[i]) / (3.0 * branchMVA)
            # K is per phase
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end


# ===   GIC BLOCKER CONSTRAINTS   === #


#"CONSTRAINT: weighted load shed is below a specified ratio"
#function constraint_load_shed(pm::_PM.AbstractPowerModel, max_load_shed)

#    nws = _PM.nw_ids(pm)

#    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

#    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    # z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    # z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    # z_voltage = Dict(n => _PM.var(pm, n, :z_voltage) for n in nws)

#    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)
#    load_weight = Dict(n => Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load)) for n in nws)
#    for n in nws
#        scaled_weight = [load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]
#        if isempty(scaled_weight)
#            scaled_weight = [1.0]
#        end
#    end

#    JuMP.@constraint(pm.model,
#        sum((time_elapsed[n]*(sum(load_weight[n][i]*abs(load["pd"])*(1 - z_demand[n][i]) for (i,load) in _PM.ref(pm, n, :load)))) for n in nws)
#        <=
#        max_load_shed
#    )

#end




"CONSTRAINT: zero qloss"
function constraint_zero_qloss(pm::_PM.AbstractPowerModel, n::Int, k, i, j)

    qloss = _PM.var(pm, n, :qloss)

    JuMP.@constraint(pm.model,
        qloss[(k,i,j)]
        ==
        0.0
    )

    JuMP.@constraint(pm.model,
        qloss[(k,j,i)]
        ==
        0.0
    )

end
