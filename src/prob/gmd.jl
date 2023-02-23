##########
# GIC DC #
##########


using SparseArrays


# ===   WITH OPTIMIZER   === #


"FUNCTION: solve GIC current model"
function solve_gmd(file, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        _PM.ACPPowerModel,
        optimizer,
        build_gmd;
        ref_extensions = [
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd!
        ],
        kwargs...,
    )
end


"FUNCTION: build the quasi-dc-pf problem
as a linear constraint satisfaction problem"
function build_gmd(pm::_PM.AbstractPowerModel; kwargs...)

    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    for i in _PM.ids(pm, :gmd_bus)
        constraint_dc_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end


# ===   WITH MATRIX SOLVE   === #


"FUNCTION: solve GIC matrix solve"
function solve_gmd(file::String; kwargs...)
    data = _PM.parse_file(file)
    return solve_gmd(data; kwargs...)
end

function solve_gmd(case::Dict{String,Any}; kwargs...)

    # Assumption: branchListStruct and busListStruct are snatched directly from JSON

    branchMap = case["gmd_branch"]
    busMap = case["gmd_bus"]

    # Solving for bus to ground currents: two matrices to worry about are Y and Z
    #   Y and Z are both 'nxn', where n is the number of busses
    #   Y is symettric and Z (fow now) is diagonal

    numBranch = length(branchMap)
    numBus = length(busMap)

    branchList = collect(values(branchMap))
    busList = collect(values(busMap))
    busKeys = collect(keys(busMap))
    busIdx = Dict( [(b["index"],i) for (i,b) in enumerate(busList)] )

    # Assume perfect earth grounding current at each bus location:
    #   sum of the emf on each line going into a substation times the y for that line

    J = zeros(numBus)

    mm = zeros(Int64, 2 * numBranch)  # off-diagonal rows
    nn = zeros(Int64, 2 * numBranch)  # off-diagonal columns
    matVals = zeros(2 * numBranch)  # off-diagonal values
    z = -1

    mmm = Array(1:numBus)  # diagonal rows
    nnn = Array(1:numBus)  # diagonal columns
    YY = zeros(numBus)  # diagonal values

    for i in 1:numBranch

        branch = branchList[i]
        m = busIdx[branch["f_bus"]]
        n = busIdx[branch["t_bus"]]

        if( (m!=n) && (branch["br_status"]==1) )

            J[m] -= (1.00 / branch["br_r"]) * branch["br_v"]
            J[n] += (1.00 / branch["br_r"]) * branch["br_v"]
            
            z += 2
            mm[z] = m
            nn[z] = n
            matVals[z] = -(1.00 / branch["br_r"])
            
            mm[z+1] = n
            nn[z+1] = m
            matVals[z+1] = matVals[z]
            
            YY[m] += (1.00 / branch["br_r"])
            YY[n] += (1.00 / branch["br_r"])

        end
        
    end

    # Y matix:

    Y = sparse(vcat(mmm,mm), vcat(nnn,nn), vcat(YY,matVals))

    zmm = zeros(Int64,numBus)
    znn = zeros(Int64,numBus)
    zmatVals = zeros(1,numBus)

    for i in 1:numBus

        bus = busList[i]
        zmm[i] = i
        znn[i] = i
        zmatVals[i] = (1.00 / max(bus["g_gnd"], 1e-6))

    end

    zmm = vec(zmm)
    znn = vec(znn)
    zmatVals = vec(zmatVals)

    # Z matix:

    Z = sparse(zmm, znn, zmatVals)

    I = sparse(SparseArrays.I, numBus, numBus)

    MM = Y * Z

    M = (I + MM)

    gic = M \ J
    vdc = Z * gic

    # Build the result structure:

    solution = Dict{String,Any}()
    solution["gmd_bus"] = Dict()
    solution["gmd_branch"] = Dict()
    result = Dict{String,Any}()
    result["status"] = :LocalOptimal
    result["solution"] = solution

    for (i, v) in enumerate(vdc)
        n = busKeys[i]
        solution["gmd_bus"]["$n"] = Dict()
        solution["gmd_bus"]["$n"]["gmd_vdc"] = v
    end

    for (n, branch) in case["gmd_branch"]
        nf = branch["f_bus"]
        nt = branch["t_bus"]
        g = 1 / branch["br_r"]

        vf = solution["gmd_bus"]["$nf"]["gmd_vdc"]
        vt = solution["gmd_bus"]["$nt"]["gmd_vdc"]
        solution["gmd_branch"]["$n"] = Dict()
        solution["gmd_branch"]["$n"]["gmd_idc"] = g * (vf - vt) 
    end

    return result

end

