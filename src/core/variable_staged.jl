



# ===   CURRENT VARIABLES   === #





"VARIABLE: dc current magnitude squared"
function variable_dc_current_mag_sqr(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        i_dc_mag_sqr = _PM.var(pm, nw)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag_sqr",
            lower_bound = 0,
            upper_bound = calc_dc_mag_max(pm, i, nw=nw)^2,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start")
        )
    else
        i_dc_mag_sqr = _PM.var(pm, nw)[:i_dc_mag_sqr] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :branch)], base_name="$(nw)_i_dc_mag_sqr",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, i), "i_dc_mag_sqr_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :branch, :i_dc_mag_sqr, _PM.ids(pm, nw, :branch), i_dc_mag_sqr)

end


# ===   GENERATOR VARIABLES   === #


#"VARIABLE: active generation squared cost"
#function variable_active_generation_sqr_cost(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

#    if bounded
#        pg_sqr = _PM.var(pm, nw)[:pg_sqr] = JuMP.@variable(pm.model,
#            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_sqr",
#            lower_bound = 0,
#            upper_bound = _PM.ref(pm, nw, :gen, i)["cost"][1] * _PM.ref(pm, nw, :gen, i)["pmax"]^2,
#            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_sqr_start")
#        )
#    else
#        pg_sqr = _PM.var(pm, nw)[:pg_sqr] = JuMP.@variable(pm.model,
#            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_sqr",
#            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_sqr_start")
#        )
#    end

#    report && _PM.sol_component_value(pm, nw, :gen, :pg_sqr, _PM.ids(pm, nw, :gen), pg_sqr)

#end


"VARIABLE: active load"
function variable_active_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        pd = _PM.var(pm, nw)[:pd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pd",
            lower_bound = min(0,_PM.ref(pm, nw, :load, i)["pd"]),
            upper_bound = max(0,_PM.ref(pm, nw, :load, i)["pd"]),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd_start")
        )
    else
        pd = _PM.var(pm, nw)[:pd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pd",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)

end


"VARIABLE: reactive load"
function variable_reactive_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    if bounded
        qd = _PM.var(pm, nw)[:qd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qd",
            lower_bound = min(0, _PM.ref(pm, nw, :load, i)["qd"]),
            upper_bound = max(0, _PM.ref(pm, nw, :load, i)["qd"]),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd_start")
        )
    else
        qd = _PM.var(pm, nw)[:qd] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qd",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd_start")
        )
    end

    report && _PM.sol_component_value(pm, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)

end


# ===   MLD VARIABLES   === #


"VARIABLE: block gen indicator"
function variable_block_gen_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
# Reference:
#   variable is based on "variable_gen_indicator" of PowerModels.jl
#   (https://github.com/lanl-ansi/PowerModels.jl/blob/31f8273ec18aeea158a2995a0bfe6a31094fe98e/src/core/variable.jl#L350)

    if !relax
        z_gen = _PM.var(pm, nw)[:z_gen_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_gen",
            binary = true,
            start = 1
        )
    else
        z_gen = _PM.var(pm, nw)[:z_gen_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    end

    _PM.var(pm, nw)[:z_gen] = Dict(g => z_gen[1] for g in _PM.ids(pm, nw, :gen))

    report && _PM.sol_component_value(pm, nw, :gen, :gen_status, _PM.ids(pm, nw, :gen), _PM.var(pm, nw)[:z_gen])

end


"VARIABLE: block demand factor"
function variable_block_demand_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
# Reference:
#   variable is based on "variable_gen_indicator" of PowerModels.jl
#   (https://github.com/lanl-ansi/PowerModels.jl/blob/31f8273ec18aeea158a2995a0bfe6a31094fe98e/src/core/variable.jl#L1273)

    if !relax
        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_demand",
            binary = true,
            start = 1
        )
    else
        z_demand = _PM.var(pm, nw)[:z_demand_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_demand",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    end

    _PM.var(pm, nw)[:z_demand] = Dict(l => z_demand[1] for l in _PM.ids(pm, nw, :load))

    pd = _PM.var(pm, nw)[:pd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["pd"] for i in _PM.ids(pm, nw, :load))
    qd = _PM.var(pm, nw)[:qd] = Dict(i => _PM.var(pm, nw)[:z_demand][i].*_PM.ref(pm, nw, :load, i)["qd"] for i in _PM.ids(pm, nw, :load))

    report && _PM.sol_component_value(pm, nw, :load, :status, _PM.ids(pm, nw, :load), _PM.var(pm, nw)[:z_demand])
    report && _PM.sol_component_value(pm, nw, :load, :pd, _PM.ids(pm, nw, :load), pd)
    report && _PM.sol_component_value(pm, nw, :load, :qd, _PM.ids(pm, nw, :load), qd)

end


"VARIABLE: block shunt admittance factor"
function variable_block_shunt_admittance_factor(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default,  relax::Bool=false, report::Bool=true)
# Reference:
#   variable is based on "variable_shunt_admittance_factor" of PowerModels.jl
#   (https://github.com/lanl-ansi/PowerModels.jl/blob/31f8273ec18aeea158a2995a0bfe6a31094fe98e/src/core/variable.jl#L1300)

    if !relax
        z_shunt = _PM.var(pm, nw)[:z_shunt_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_shunt",
            binary = true,
            start = 1
        )
    else
        z_shunt = _PM.var(pm, nw)[:z_shunt_blocks] = _PM.JuMP.@variable(pm.model,
            [1], base_name="$(nw)_z_shunt",
            lower_bound = 0,
            upper_bound = 1,
            start = 1.0
        )
    end

    _PM.var(pm, nw)[:z_shunt] = Dict(g => z_shunt[1] for g in _PM.ids(pm, nw, :shunt))

    if report
        _PM.sol_component_value(pm, nw, :load, :shunt, _PM.ids(pm, nw, :shunt), _PM.var(pm, nw)[:z_shunt])
        sol_gs = Dict(i => z_shunt[1]*_PM.ref(pm, nw, :shunt, i)["gs"] for i in _PM.ids(pm, nw, :shunt))
        _PM.sol_component_value(pm, nw, :shunt, :gs, _PM.ids(pm, nw, :shunt), sol_gs)
        sol_bs = Dict(i => z_shunt[1]*_PM.ref(pm, nw, :shunt, i)["bs"] for i in _PM.ids(pm, nw, :shunt))
        _PM.sol_component_value(pm, nw, :shunt, :bs, _PM.ids(pm, nw, :shunt), sol_bs)
    end

    wz_shunt = _PM.var(pm, nw)[:wz_shunt] = JuMP.@variable(pm.model,
        [1], base_name="$(nw)_wz_shunt",
        lower_bound = 0,
        upper_bound = 1.1,
        start = 1.001
    )

    _PM.var(pm, nw)[:wz_shunt] = Dict(g => wz_shunt[1] for g in _PM.ids(pm, nw, :shunt))

    report && _PM.sol_component_value(pm, nw, :load, :shunt, _PM.ids(pm, nw, :shunt), _PM.var(pm, nw)[:wz_shunt])

end


# ===   GIC BLOCKER VARIABLES   === #
