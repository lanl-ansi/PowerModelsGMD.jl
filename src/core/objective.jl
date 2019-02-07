"Computes a load shed cost"
function calc_load_shed_cost(pm::GenericPowerModel)
    max_cost = 0
    for (n, nw_ref) in nws(pm)
        for (i,gen) in nw_ref[:gen]
            if gen["pmax"] != 0
                cost_mw = (gen["cost"][1]*gen["pmax"]^2 + gen["cost"][2]*gen["pmax"]) / gen["pmax"] + gen["cost"][3]
                max_cost = max(max_cost, cost_mw)
            end
        end
    end
    return max_cost * 2.0
end


" OPF objective"
function objective_gic_min_fuel(pm::GenericPowerModel)
    #@assert all(!PMs.ismulticonductor(pm) for n in nws(pm))

    #i_dc_mag = Dict(n => pm.var[:nw][n][:i_dc_mag] for n in nws) #pm.var[:i_dc_mag]
    #pg = Dict(n => pm.var[:nw][n][:pg] for n in nws) #pm.var[:pg]

    return @objective(pm.model, Min,
    sum(
        sum(
            gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor_ids(pm, n))^2 +
            gen["cost"][2]*sum( var(pm, n, c, :pg, i) for c in conductor_ids(pm, n)) +
            gen["cost"][3]
        for (i,gen) in nw_ref[:gen]) +
        sum(
            sum( var(pm, n, c, :i_dc_mag, i)^2 for c in conductor_ids(pm, n) )
        for (i,branch) in nw_ref[:branch])
    for (n, nw_ref) in nws(pm))
    )

end


" SSE objective: keep generators as close as possible to original setpoint"
function objective_gic_min_error(pm::GenericPowerModel)
    @assert all(!PMs.ismulticonductor(pm) for n in nws(pm))

    #i_dc_mag = Dict(n => pm.var[:nw][n][:i_dc_mag] for n in nws) #pm.var[:i_dc_mag]
    #pg = Dict(n => pm.var[:nw][n][:pg] for n in nws) # pm.var[:pg]
    #qg = Dict(n => pm.var[:nw][n][:qg] for n in nws) # pm.var[:qg]
    #z_demand = Dict(n => pm.var[:nw][n][:z_demand] for n in nws) # pm.var[:z_demand]

    M_p = Dict(n => max([gen["pmax"] for (i,gen) in nw_ref[:gen]]) for (n, nw_ref) in nws(pm))

    #=
    for n in nws
        for (i,gen) in pm.ref[:nw][n][:gen]
            @printf "sg[%d] = %f + j%f\n" i gen["pg"] gen["qg"]
            if gen["pmax"] > pmax
                pmax = gen["pmax"]
            end
        end
    end
    =#

    # return @objective(pm.model, Min, sum{ i_dc_mag[i]^2, i in keys(pm.ref[:branch])})
    # return @objective(pm.model, Min, sum(gen["cost"][1]*pg[i]^2 + gen["cost"][2]*pg[i] + gen["cost"][3] for (i,gen) in pm.ref[:gen]) )
    return @objective(pm.model, Min,
    sum(
        sum(
            (gen["pg"] - var(pm, :pg, i, nw=n))^2 + (gen["qg"] - var(pm, :qg, i, nw=n))^2
        for (i,gen) in ref(pm, n, :gen)) +
        sum(
            var(pm, :i_dc_mag, i, nw=n)^2
        for (i,branch) in ref(pm, n, :branch)) +
        sum(
            -100.0*M_p^2*var(pm, :z_demand, i, nw=n)
        for (i,load) in ref(pm, n, :load))
    for (n, nw_ref) in nws(pm))
    )

end


" Minimizes load shedding and fuel cost"
function objective_gic_min_ls(pm::GenericPowerModel)
    @assert all(!PMs.ismulticonductor(pm) for n in nws(pm))

    #pg = Dict(n => pm.var[:nw][n][:pg] for n in nws)
    #pd = Dict(n => pm.var[:nw][n][:pd] for n in nws)
    #qd = Dict(n => pm.var[:nw][n][:qd] for n in nws)

    shed_cost = calc_load_shed_cost(pm)

    return @objective(pm.model, Min, 
    sum(
        sum(
            gen["cost"][1]*var(pm, :pg, i, nw=n)^2 +
            gen["cost"][2]*var(pm, :pg, i, nw=n) +
            gen["cost"][3]
        for (i,gen) in nw_ref[:gen]) +
        sum(
            shed_cost*(var(pm, :pd, i, nw=n) + var(pm, :qd, i, nw=n))
        for (i,load) in nw_ref[:load])
    for (n, nw_ref) in nws(pm))
    )

end


" Minimizes load shedding and fuel cost"
function objective_gic_min_ls_on_off(pm::GenericPowerModel)
    @assert all(!PMs.ismulticonductor(pm) for n in nws(pm))

    #pg     = Dict(n => pm.var[:nw][n][:pg] for n in nws)
    #pd     = Dict(n => pm.var[:nw][n][:pd] for n in nws)
    #qd     = Dict(n => pm.var[:nw][n][:qd] for n in nws)
    #z      = Dict(n => pm.var[:nw][n][:gen_z] for n in nws)
    #pg_sqr = Dict(n => pm.var[:nw][n][:pg_sqr] for n in nws)

    shed_cost = calc_load_shed_cost(pm)

    return @objective(pm.model, Min,
    sum(
        sum(
            var(pm, :pg_sqr, i, nw=n) + 
            gen["cost"][2]*var(pm, :pg, i, nw=n) +
            gen["cost"][3]*var(pm, :gen_z, i, nw=n)
        for (i,gen) in nw_ref[:gen]) +
        sum(
            shed_cost*(var(pm, :pd, i, nw=n) + var(pm, :qd, i, nw=n))
        for (i,load) in nw_ref[:load])
    for (n, nw_ref) in nws(pm))
    )

end
