# For the implicit transformer branch resistances
impxfrm = Dict{Float64, Float64}(
    765.0 => 1.0892000157158984e-05,
    500.0 => 1.666666666676272e-05,
    345.0 => 2.4155598209192887e-05,
    230.0 => 3.623188405928273e-05,
    161.0 => 5.175983436949935e-05,
    138.0 => 6.038901527172248e-05,
    115.0 => 7.246376811370438e-05,
)

# Auto Transformer high side minimum kV
KVMIN = 50

# Resistance value for gmd_branches from each bus to substation
R_g_default = 25000.00

# Constants for Earth Model calculations
equatorial_radius = 6378.137
eccentricity_squared = 0.00669437999014

# TODO: include add_3w_xf! function here?
"Load a network dictionary from a set of GIC/RAW/CSV file paths"
function generate_dc_data(gic_file::String, raw_file::String, voltage_file::String)
    # TODO: add gz support to parse_file
    net =  generate_dc_data(gic_file, raw_file, 0.0)
    add_coupled_voltages!(voltage_file, net)
    return net
end


"Load a network dictionary from a pair of GIC/RAW file paths and calculate coupled voltages with a uniform field"
function generate_dc_data(gic_file::String, raw_file::String, field_mag::Float64=0.0, field_dir::Float64=90.0, min_line_length::Float64=1.0)
    # TODO: add gz support to parse_file
    gic_data = parse_gic(gic_file)
    raw_data = _PM.parse_file(raw_file)
    net =  generate_dc_data(gic_data, raw_data, field_mag, field_dir, min_line_length)
    return net
end


"Load a network dictionary from a pair of GIC/RAW file handles and calculate coupled voltages with a uniform field"
function generate_dc_data(gic_file::IO, raw_file::IO, field_mag::Float64=1.0, field_dir::Float64=90.0, min_line_length::Float64=1.0)
    return generate_dc_data_psse(gic_file, raw_file, field_mag, field_dir, min_line_length)
end


"Load a network dictionary from a pair of GIC/MatPower file handles and calculate coupled voltages with a uniform field"
function generate_dc_data_matpower(gic_file::IO, mp_file::IO, field_mag::Float64=1.0, field_dir::Float64=90.0, min_line_length::Float64=1.0)
    # This produces an annoying warning about the number of columns in the first row
    # TODO: How to get rid of it?
    gic_data = parse_gic(gic_file)
    mp_data = _PM.parse_matpower(mp_file)
    return generate_dc_data(gic_data, mp_data, field_mag, field_dir, min_line_length)
end


"Load a network dictionary from a pair of GIC/RAW file handles and calculate coupled voltages with a uniform field"
function generate_dc_data_psse(gic_file::IO, raw_file::IO, field_mag::Float64=1.0, field_dir::Float64=90.0, min_line_length::Float64=1.0)
    # This produces an annoying warning about the number of columns in the first row
    # TODO: How to get rid of it?
    gic_data = parse_gic(gic_file)
    raw_data = _PM.parse_psse(raw_file)
    return generate_dc_data(gic_data, raw_data, field_mag, field_dir, min_line_length)
end


# Configures the line voltages and distances
"Add coupled line voltages from a CSV file path into the branch table"
function add_coupled_voltages!(voltage_file::String, output::Dict{String, Any})
    lines_info = CSV.read(voltage_file, DataFrame; header=2)
    add_coupled_voltages!(lines_info, output)
end


"Add coupled line voltages from a file handle into the branch table"
function add_coupled_voltages!(voltage_file::IO, output::Dict{String, Any})
    lines_info = CSV.read(voltage_file, DataFrame; header=2, buffer_in_memory=true)
    add_coupled_voltages!(lines_info, output)
end

"Add coupled line voltages from a dataframe into the branch table"
function add_coupled_voltages!(lines_info::DataFrame, output::Dict{String, Any})
    branch_map = Dict{Array, Int64}()
    for branch in values(output["gmd_branch"])
        source_id = branch["source_id"]
        if source_id[1] != "branch"
            continue
        end
        source_id[4]  = strip(source_id[4])
        branch_map[source_id] = branch["index"]
    end

    dc_voltage_field = "GICInducedDCVolt"
    from_bus_field = "BusNumFrom"
    to_bus_field = "BusNumTo"
    ckt_field = "Circuit"

    if "GICObjectInputDCVolt" in names(lines_info)
        dc_voltage_field = "GICObjectInputDCVolt"
    end

    if "BusNum" in names(lines_info)
        from_bus_field = "BusNum"
    end

    if "BusNum:1" in names(lines_info)
        to_bus_field = "BusNum:1"
    end

    if "LineCircuit" in names(lines_info)
        ckt_field = "LineCircuit"
    end

    dc_voltages = lines_info[!, dc_voltage_field]
    froms = lines_info[!, from_bus_field]
    tos = lines_info[!, to_bus_field]
    ckts = lines_info[!, ckt_field]

    for (from, to, ckt, dc_voltage) in zip(froms, tos, ckts, dc_voltages)
        source_id = ["branch", from, to, "$ckt"]
        branch_id = branch_map[source_id]
        output["gmd_branch"]["$branch_id"]["br_v"] = dc_voltage
    end
end


# Main Function for generating DC network
# TODO: use rectangular coordinates instead of polar coordinates?
"Load a network dictionary from a pair of GIC/RAW dictionary structures and calculate coupled voltages with a uniform field"
function generate_dc_data(gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, field_mag::Float64=0.0, field_dir::Float64=90.0, min_line_length::Float64=1.0)
    # Sets up output network dictionary
    output = Dict{String, Any}()
    output["source_type"] = "gic"

    if haskey(raw_data, "name")
        output["name"] = raw_data["name"]
    end

    output["source_version"] = "3"

    # Generates gmd_bus table
    dc_bus_map = _generate_gmd_bus!(output, gic_data, raw_data)

    # Creates a link between AC branches and gic transformers
    transformer_map = gen_transformer_map(gic_data)
    branch_map = gen_branch_map(gic_data)

    # Generates gmd_branch table
    _generate_gmd_branch!(output, gic_data, raw_data, dc_bus_map, transformer_map, branch_map)

    # Generates the rest of the AC Data
    _generate_ac_data!(output, gic_data, raw_data, transformer_map)

    if field_mag != 0.0
        _configure_line_info!(output, field_mag, field_dir, min_line_length)
    end

    # Copies over identical AC data
    output["dcline"] = raw_data["dcline"]
    output["storage"] = raw_data["storage"]
    output["switch"] = raw_data["switch"]
    output["baseMVA"] = raw_data["baseMVA"]
    output["load"] = raw_data["load"]
    output["shunt"] = raw_data["shunt"]

    return output
end


# Adds AC information into the output network
function _generate_ac_data!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Any}})
    # Adds bus table to network
    _add_bus_table!(output, gic_data, raw_data)
    
    # Make this optional
    _add_sub_table!(output, gic_data, raw_data)    

    # Copies over generator table
    output["gen"] = raw_data["gen"]

    _add_branch_table!(output, raw_data, transformer_map)
end


# Generates gmd_bus table
function _generate_gmd_bus!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    gmd_bus = Dict{String, Dict}()

    # Index for the values in the gmd_bus table
    gmd_bus_index = 1

    # Adds substations to the gmd_bus table
    gmd_bus_index, substation_map = _add_substation_table!(gmd_bus, gmd_bus_index, gic_data, raw_data)

    # Adds ac buses to the gmd_bus table
    bus_map = _add_gmd_bus_table!(gmd_bus, substation_map, gmd_bus_index, raw_data)
    
    output["gmd_bus"] = gmd_bus

    return bus_map
end

# Generate gmd_branch table
function _generate_gmd_branch!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int64, Int64}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Any}}, branch_map::Dict{Tuple{Int64, Int64, String}, Dict{String, Any}})
    branches = Dict{String, Dict{String, Any}}()
    gmd_3w_branch = Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Int64}}()

    three_winding_resistances = _generate_3w_resistances(raw_data)

    # Fetches all the generator and load buses from the ac data
    gen_buses, load_buses = _gen_load_buses(raw_data)

    gmd_branch_index = 1
    sorted_branch_indices = sort([x["index"] for x in values(raw_data["branch"])])

    for branch_index in sorted_branch_indices
        branch = raw_data["branch"]["$branch_index"]

        # TODO: If not three winding, corrects raw parser error of f_bus and t_bus being flipped sometimes
        if branch["source_id"][4] == 0
            branch["f_bus"] = branch["source_id"][2]
            branch["t_bus"] = branch["source_id"][3]
        end

        # Determines the high and low buses of a branch
        hi_bus = raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] < raw_data["bus"]["$(branch["t_bus"])"]["base_kv"] ? branch["t_bus"] : branch["f_bus"]
        lo_bus = raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] < raw_data["bus"]["$(branch["t_bus"])"]["base_kv"] ? branch["f_bus"] : branch["t_bus"]
        branch["hi_bus"] = hi_bus
        branch["lo_bus"] = lo_bus

        # Updates gmd_branch_index after adding to the branches dictionary
        gmd_branch_index = _set_branch_data!(branches, gmd_3w_branch, three_winding_resistances, branch, gic_data, raw_data, dc_bus_map, transformer_map, branch_map, gmd_branch_index, gen_buses, load_buses)
    end

    # Adds a gmd_branch from each bus to substation
    gmd_branch_index = _generate_bus_gmd_branches!(branches, dc_bus_map, raw_data, gmd_branch_index)

    # Adds Delta-gwye step up transformer to necessary transformers
    _generate_implicit_gsu!(branches, dc_bus_map, raw_data, gmd_branch_index)

    # Copies data to final output dictionary
    output["gmd_branch"] = branches

    # Finalizes the gmd_3w_branch table with collected information
    _generate_3w_branch_table!(output, gmd_3w_branch)
end

function _calc_xfmr_resistances(positive_sequence_r::Float64, turns_ratio::Float64, z_base_high::Float64, is_auto::Bool)
    R_high = (z_base_high * positive_sequence_r) / 2
    if is_auto
        R_low = R_high / ((turns_ratio - 1) ^ 2)
    else
        R_low = R_high / (turns_ratio ^ 2)
    end

    R_high = R_high == 0 ? 0.25 : R_high
    R_low = R_low == 0 ? 0.25 : R_low

    return R_high / 3, R_low / 3
end

# Configures the line voltages and distances
function _configure_line_info!(output::Dict{String, Any}, field_mag::Float64=1.0, field_dir::Float64=90.0, min_line_length::Float64=1.0)
    for branch in values(output["gmd_branch"])
        # Fetches substations for the buses on the branch
        sub_a = output["gmd_bus"]["$(branch["f_bus"])"]["sub"]
        sub_b = output["gmd_bus"]["$(branch["t_bus"])"]["sub"]

        # Calculates north south distance using the NERC appliation guide
        lat_a = output["gmd_bus"]["$sub_a"]["lat"]
        lat_b = output["gmd_bus"]["$sub_b"]["lat"]

        average_lat = (lat_a + lat_b) / 2

        radius_meridian = equatorial_radius * (1 - eccentricity_squared) / ((1 - eccentricity_squared * (sind(average_lat) ^ 2)) ^ 1.5)
        displacement_north_south = (pi / 180) * radius_meridian * (lat_b - lat_a)

        # Calculates east west distances using the NERC application guide
        long_a = output["gmd_bus"]["$sub_a"]["lon"]
        long_b = output["gmd_bus"]["$sub_b"]["lon"]

        radius_lat = equatorial_radius / ((1 - eccentricity_squared * (sind(average_lat) ^ 2)) ^ 0.5)
        displacement_east_west = (pi / 180) * radius_lat * cosd(average_lat) * (long_b - long_a)

        # Uses distances to calculate total vector distance and overall branch voltage
        branch["len_km"] = (displacement_north_south ^ 2 + displacement_east_west ^ 2) ^ 0.5

        if branch["len_km"] >= min_line_length
            branch["br_v"] = field_mag * (displacement_north_south * cosd(field_dir) + displacement_east_west * sind(field_dir))
        else
            branch["br_v"] = 0.0
        end
    end
end

# Defines a link between ac branch and gic transformer table
function gen_transformer_map(gic_data::Dict{String, Any})
    transformer_map = Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Any}}()
    for transformer in values(gic_data["TRANSFORMER"])
        key = (transformer["BUSI"], transformer["BUSJ"], transformer["BUSK"], transformer["CKT"])
        transformer_map[key] = transformer
    end

    return transformer_map
end

# Defines a link between ac branch and gic transformer table
function gen_branch_map(gic_data::Dict{String, Any})
    branch_map = Dict{Tuple{Int64, Int64, String}, Dict{String, Any}}()
    for branch in values(gic_data["BRANCH"])
        key = (branch["BUSI"], branch["BUSJ"], branch["CKT"])
        branch_map[key] = branch
    end

    return branch_map
end

# Adds substations to the gmd_bus table
function _add_substation_table!(gmd_bus::Dict{String, Dict}, gmd_bus_index::Int64, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    # Generates bus_info for each substation; needed for R_g assumption for substations
    bus_info = Dict{Int64, Array{Float64}}()
    for (bus_index, bus) in raw_data["bus"]
        # Adds substation to the raw bus table to reduce calculations
        if haskey(gic_data["BUS"], "$bus_index")
            bus["sub"] = gic_data["BUS"]["$bus_index"]["SUBSTATION"]
            bus["starbus"] = false
        else
            bus["sub"] = gic_data["BUS"]["$(bus["source_id"][4])"]["SUBSTATION"]
            bus["starbus"] = true
        end

        # bus_info has two values per substation: [max_kV, num_buses]
        if !haskey(bus_info, bus["sub"])
            bus_info[bus["sub"]] = [0.0, 0.0]
        end
        bus_info[bus["sub"]][1] = max(bus["base_kv"], bus_info[bus["sub"]][1])
        bus_info[bus["sub"]][2] += 1
    end

    substation_map = Dict{Int64, Int64}()
    sorted_substation_indices = sort([x["SUBSTATION"] for x in values(gic_data["SUBSTATION"])])
    
    for substation_index in sorted_substation_indices
        substation = gic_data["SUBSTATION"]["$substation_index"]
        sub_name = "dc_" * replace(lowercase(substation["NAME"]), " " => "_")

        # Calculates conductance to ground value for substation
        # TODO: Make sure it works
        r_g = substation["RG"]
        if r_g == 0
            # Piecewise function for calculating assumed g value of a substation
            if bus_info[substation_index][1] <= 230
                g = 0.4778 * bus_info[substation_index][2] + 1.6841
            else
                g = 0.73 * bus_info[substation_index][2] + 4.2131
            end
            g = 10
        else
            g = 1/r_g
        end

        substation_data = Dict{String, Any}(
            "name" => sub_name,
            "g_gnd" => g,
            "index" => gmd_bus_index,
            "status" => 1,
            "source_id" => ["substation", substation_index],
            "sub" => gmd_bus_index,
            "lat" => substation["LAT"],
            "lon" => substation["LONG"],
            "parent_index" => substation_index,
            "parent_type" => "sub"
        )

        # Links the substation index to the gmd_bus index for future reference
        substation_map[substation_index] = gmd_bus_index

        gmd_bus["$gmd_bus_index"] = substation_data
        gmd_bus_index += 1
    end

    return gmd_bus_index, substation_map
end


# Adds ac buses to the gmd_bus table
function _add_gmd_bus_table!(gmd_bus::Dict{String, Dict}, substation_map::Dict{Int64, Int64}, gmd_bus_index::Int64, raw_data::Dict{String, Any})
    bus_map = Dict{Int64, Int64}()
    sorted_bus_indices = sort([x["index"] for x in values(raw_data["bus"])])

    for bus_index in sorted_bus_indices
        bus = raw_data["bus"]["$bus_index"]
        bus["sub"] = substation_map[bus["sub"]]

        bus_name = "dc_" * replace(lowercase(strip(bus["name"])), " " => "_")

        bus_data = Dict{String, Any}(
            "name" => bus_name,
            "g_gnd" => 0.0, # Not tied to ground directly
            "index" => gmd_bus_index,
            "status" => 1,
            "sub" => bus["sub"], # Converts to new gmd_bus index for substation
            "source_id" => ["bus", bus_index],
            "parent_index" => bus_index,
            "parent_type" => "bus"
        )

        # Links bus indices from raw table to new gmd_bus table
        bus_map[bus_index] = gmd_bus_index

        gmd_bus["$gmd_bus_index"] = bus_data
        gmd_bus_index += 1
    end

    return bus_map
end


# Combines transformer resistances for primary-secondary positive sequence resistance of three winding transformers
function _generate_3w_resistances(raw_data::Dict{String, Any})
    # TODO calculate resistances for tertiary too by storing coil resistances instead of pu resistances in array
    three_winding_resistances = Dict{Tuple{Int64, Int64, Int64, String}, Float64}()
    for branch in values(raw_data["branch"])
        # If not a transformer, not three winding, or delta side of three winding
        if branch["source_id"][1] != "transformer" || branch["source_id"][4] == 0 || branch["f_bus"] == branch["source_id"][4]
            continue
        end

        if !haskey(three_winding_resistances, Tuple(branch["source_id"][2:5])) 
            three_winding_resistances[Tuple(branch["source_id"][2:5])] = 0
        end

        three_winding_resistances[Tuple(branch["source_id"][2:5])] += branch["br_r"]
    end

    return three_winding_resistances
end


# Compiles arrays of gen and load buses
function _gen_load_buses(raw_data::Dict{String, Any})
    # Compile all generator buses to array
    gen_buses = []
    for generator in values(raw_data["gen"])
        push!(gen_buses, generator["gen_bus"])
    end

    # Compile all load buses to array
    load_buses = []
    for load in values(raw_data["load"])
        push!(load_buses, load["load_bus"])
    end

    return gen_buses, load_buses
end


# Generates transformer branches for non-auto xfmrs
function _handle_normal_transformer!(branches::Dict{String, Dict{String, Any}}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int64, Int64}, branch::Dict{String, Any}, transformer::Dict{String, Any}, gmd_branch_index::Int64)
    hi_side_winding = false
    lo_side_winding = false

    hi_bus = branch["hi_bus"]
    lo_bus = branch["lo_bus"]

    # High side winding exists if high side is a grounded wye winding
    if (startswith(transformer["VECGRP"], "YN") && hi_bus == branch["f_bus"]) || (endswith(transformer["VECGRP"], r"yn.*") && branch["t_bus"] == hi_bus)
        hi_side_winding = !raw_data["bus"]["$hi_bus"]["starbus"] # Not modeled if to starbus
    end
    
    # Low side winding exists if low side is a grounded wye winding
    if (endswith(transformer["VECGRP"], r"yn.*") && lo_bus == branch["t_bus"]) || (startswith(transformer["VECGRP"], "YN") && lo_bus == branch["f_bus"])
        lo_side_winding = !raw_data["bus"]["$lo_bus"]["starbus"] # Not modeled if to starbus
    end

    R_hi, R_lo = _calc_xfmr_resistances(transformer["xfmr_r"], transformer["turns_ratio"], transformer["hi_base_z"], true)

    if (hi_side_winding)
        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[hi_bus],
            "t_bus" => transformer["substation"],
            "br_r" => hi_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
            "name" => "dc_x$(branch["index"])_hi",
            "br_status" => 1,
            "index" => gmd_branch_index,
            "parent_index" => branch["index"],
            "parent_type" => "branch",
            "source_id" => branch["source_id"],
            "br_v" => 0.0,
            "len_km" => 0.0,
        )

        # Sets default resistance if needed
        if branch_data["br_r"] == 0
            branch_data["br_r"] = R_hi
        end

        branches["$gmd_branch_index"] = branch_data
        branch["gmd_br_hi"] = gmd_branch_index
        gmd_branch_index += 1
    end

    if (lo_side_winding)
        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[lo_bus],
            "t_bus" => transformer["substation"],
            "br_r" => lo_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
            "name" => "dc_x$(branch["index"])_lo",
            "br_status" => 1,
            "index" => gmd_branch_index,
            "parent_index" => branch["index"],
            "parent_type" => "branch",
            "source_id" => branch["source_id"],
            "br_v" => 0.0,
            "len_km" => 0.0,
        )

        # Sets default resistance if needed
        if branch_data["br_r"] == 0
            branch_data["br_r"] = R_lo
        end

        branches["$gmd_branch_index"] = branch_data
        branch["gmd_br_lo"] = gmd_branch_index
        gmd_branch_index += 1
    end

    return gmd_branch_index
end


# Generates branches for auto transformers
function _handle_auto_transformer!(branches::Dict{String, Dict{String, Any}}, dc_bus_map::Dict{Int64, Int64}, branch::Dict{String, Any}, transformer::Dict{String, Any}, gmd_branch_index::Int64)
    hi_bus = branch["hi_bus"]
    lo_bus = branch["lo_bus"]
    
    # Auto transformer case
    R_s, R_c = _calc_xfmr_resistances(transformer["xfmr_r"], transformer["turns_ratio"], transformer["hi_base_z"], true)

    # In this case R_c is calculated as Inf, but should be defaulted to = R_s
    if (transformer["turns_ratio"] == 1)
        R_c = R_s
    end

    # Models the two transformers (primary-star and secondary-star) to behave like a singular transformer
    if transformer["three_winding"] && transformer["hi_side_bus"] == branch["f_bus"]
        R_c = 1e6
    end

    if transformer["three_winding"] && transformer["lo_side_bus"] == branch["f_bus"]
        R_s = 1e-6
    end

    # Creates gmd_branch for common side of the auto transformer
    common_data = Dict{String, Any}(
        "f_bus" => dc_bus_map[lo_bus],
        "t_bus" => transformer["substation"],
        "br_r" => lo_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
        "name" => "dc_x$(branch["index"])_common",
        "br_status" => 1,
        "index" => gmd_branch_index,
        "parent_index" => branch["index"],
        "parent_type" => "branch",
        "source_id" => branch["source_id"],
        "br_v" => 0.0,
        "len_km" => 0.0,
    )

    # Sets default resistance if needed
    if common_data["br_r"] == 0
        common_data["br_r"] = R_c
    end

    branches["$gmd_branch_index"] = common_data
    branch["gmd_br_common"] = gmd_branch_index
    gmd_branch_index += 1

    # Creates gmd_branch for series side of the auto transformer
    series_data = Dict{String, Any}(
        "f_bus" => dc_bus_map[hi_bus],
        "t_bus" => dc_bus_map[lo_bus],
        "br_r" => hi_bus == transformer["BUSI"] ? transformer["WRI"]/3 : transformer["WRJ"]/3,
        "name" => "dc_x$(branch["index"])_series",
        "br_status" => 1,
        "index" => gmd_branch_index,
        "parent_index" => branch["index"],
        "parent_type" => "branch",
        "source_id" => branch["source_id"],
        "br_v" => 0.0,
        "len_km" => 0.0,
    )

    # Sets default resistance if needed
    if series_data["br_r"] == 0
        series_data["br_r"] = R_s
    end

    branches["$gmd_branch_index"] = series_data
    branch["gmd_br_series"] = gmd_branch_index
    gmd_branch_index += 1

    return gmd_branch_index
end


# Adjusts transformer configuration to match specific AC branch
function _create_pseudo_3w_config!(transformer::Dict{String, Any}, branch::Dict{String, Any})
    if branch["source_id"][3] == branch["f_bus"]
        # Branch corresponds to secondary-starbus branch
        transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[2]) * "yn"
        if transformer["VECGRP"] == "Ayn"
            transformer["VECGRP"] = "YNa"
        end
    elseif branch["source_id"][4] == branch["f_bus"]
        transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[3]) * "yn"
        transformer["BUSI"] = transformer["BUSK"]
    else
        if startswith(transformer["VECGRP"],"YNa")
            transformer["VECGRP"] = "YNa"
        else
            transformer["VECGRP"] = uppercase(match(r"(YN|Y|D)(a|d|yn|y).*(d|yn|y).*", transformer["VECGRP"])[1]) * "yn" 
        end
    end
end

# Adds to gmd_3w_table and creates pseudo config for three winding transformer gmd_branches
function _handle_3w_transformer!(transformer::Dict{String, Any}, gmd_3w_branch::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Int64}}, branch::Dict{String, Any})
    # Adds to gmd_3w_branch table
    if !haskey(gmd_3w_branch, Tuple(branch["source_id"][2:5]))
        gmd_3w_branch[Tuple(branch["source_id"][2:5])] = Dict{String, Int64}()
    end

    # Determines prefix for the gmd_3w_branch table
    if transformer["lo_side_bus"] == branch["f_bus"]
        prefix = "lo"
    elseif transformer["hi_side_bus"] == branch["f_bus"]
        prefix = "hi"
    else
        prefix = "tr"
    end

    gmd_3w_branch[Tuple(branch["source_id"][2:5])]["$(prefix)_3w_branch"] = branch["index"]

    _create_pseudo_3w_config!(transformer, branch)
end


# Determines assumed configurations according to PowerWorld rules
function _set_default_config!(transformer::Dict{String, Any}, gen_buses::Vector{Any}, load_buses::Vector{Any}, branch::Dict{String, Any})
    if transformer["hi_side_bus_kv"] >= KVMIN && (transformer["lo_side_bus_kv"] < KVMIN || transformer["lo_side_bus"] in load_buses)
        if transformer["hi_side_bus"] == branch["f_bus"]
            transformer["VECGRP"] = "Dyn"
        else
            transformer["VECGRP"] = "YNd"
        end
    end

    if (transformer["hi_side_bus_kv"] >= KVMIN && transformer["lo_side_bus"] in gen_buses) || (transformer["hi_side_bus_kv"] >= 300 && transformer["lo_side_bus_kv"] < KVMIN)
        if transformer["hi_side_bus"] == branch["f_bus"]
            transformer["VECGRP"] = "YNd"
        else
            transformer["VECGRP"] = "Dyn"
        end
    end

    if (transformer["hi_side_bus_kv"] >= KVMIN && transformer["lo_side_bus_kv"] >= KVMIN) || (transformer["hi_side_bus_kv"] < KVMIN && transformer["lo_side_bus_kv"] < KVMIN)
        transformer["VECGRP"] = "YNyn"
    end

    # Assumes auto transformer
    if transformer["VECGRP"] == "YNyn" && transformer["turns_ratio"] <= 4 && transformer["turns_ratio"] != 1 && transformer["hi_side_bus_kv"] >= KVMIN
        transformer["VECGRP"] = "YNa"
    end

    # Adds assumed delta tertiary if three winding
    if transformer["three_winding"]
        transformer["VECGRP"] *= "0d0"
    end

    Memento.warn(_LOGGER, "Transformer configuration corresponding to index $(branch["index"]) in the raw branch table was assumed as $(transformer["VECGRP"])")
end


# Calls other functions to create branches for any transformer
function _handle_transformer!(branches::Dict{String, Dict{String, Any}}, gmd_3w_branch::Dict{Tuple{Int64, Int64, Int64, String}}, three_winding_resistances::Dict{Tuple{Int64, Int64, Int64, String}, Float64}, branch::Dict{String, Any}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int64, Int64}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Any}}, gmd_branch_index::Int64, gen_buses::Vector{Any}, load_buses::Vector{Any})
    # Branch is a transformer
    transformer = deepcopy(transformer_map[Tuple(branch["source_id"][2:5])])

    # Determines the high and low bus out of the primary and secondary sides of the transformers
    transformer["hi_side_bus"] = raw_data["bus"]["$(branch["source_id"][2])"]["base_kv"] >= raw_data["bus"]["$(branch["source_id"][3])"]["base_kv"] ? branch["source_id"][2] : branch["source_id"][3]
    transformer["lo_side_bus"] = raw_data["bus"]["$(branch["source_id"][2])"]["base_kv"] >= raw_data["bus"]["$(branch["source_id"][3])"]["base_kv"] ? branch["source_id"][3] : branch["source_id"][2]

    # Fetches the nominal voltages of the high side and low side buses 
    transformer["hi_side_bus_kv"] = raw_data["bus"]["$(transformer["hi_side_bus"])"]["base_kv"]
    transformer["lo_side_bus_kv"] = raw_data["bus"]["$(transformer["lo_side_bus"])"]["base_kv"]

    # Three winding if tertiary winding in source id is not 0
    transformer["three_winding"] = branch["source_id"][4] != 0

    transformer["turns_ratio"] = transformer["hi_side_bus_kv"] / transformer["lo_side_bus_kv"]

    # If no transformer configuration given or non gwye-gwye auto transformer
    if length(strip(transformer["VECGRP"])) == 0 || (endswith(transformer["VECGRP"], r"a.*") && !startswith(transformer["VECGRP"],"YNa"))
        _set_default_config!(transformer, gen_buses, load_buses, branch)
    end

    # Calculates/Fetches information for the transformer
    transformer["hi_base_z"] = (transformer["hi_side_bus_kv"] ^ 2) / raw_data["baseMVA"]
    transformer["xfmr_r"] = branch["br_r"]
    transformer["substation"] = raw_data["bus"]["$(branch["t_bus"])"]["sub"]

    # Default gmd_br pointers to -1
    branch["gmd_br_hi"] = -1
    branch["gmd_br_lo"] = -1
    branch["gmd_br_common"] = -1
    branch["gmd_br_series"] = -1

    # Sets transformer config and resets xfmr_r for 3w
    if transformer["three_winding"]
        _handle_3w_transformer!(transformer, gmd_3w_branch, branch)
        transformer["xfmr_r"] = three_winding_resistances[Tuple(branch["source_id"][2:5])]
    end

    if endswith(transformer["VECGRP"], r"a.*")
        return _handle_auto_transformer!(branches, dc_bus_map, branch, transformer, gmd_branch_index)
    end

    return _handle_normal_transformer!(branches, raw_data, dc_bus_map, branch, transformer, gmd_branch_index)
end


# Creates a gmd_branch equivalent for a given ac branch
function _set_branch_data!(branches::Dict{String, Dict{String, Any}}, gmd_3w_branch::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Int64}}, three_winding_resistances::Dict{Tuple{Int64, Int64, Int64, String}, Float64}, branch::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any}, dc_bus_map::Dict{Int64, Int64}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Any}}, branch_map::Dict{Tuple{Int64, Int64, String}, Dict{String, Any}}, gmd_branch_index::Int64, gen_buses::Vector{Any}, load_buses::Vector{Any})
    if !branch["transformer"]
        # Branch is a line

        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[branch["f_bus"]],
            "t_bus" => dc_bus_map[branch["t_bus"]],
            "br_r" => branch["br_r"] != 0 ? branch["br_r"] * (raw_data["bus"]["$(branch["f_bus"])"]["base_kv"] ^ 2) / (3 * raw_data["baseMVA"]) : 0.0005, # TODO add 1e-4 ohms per km
            "name" => "dc_br$(gmd_branch_index)",
            "br_status" => 1,
            "index" => gmd_branch_index,
            "parent_index" => branch["index"],
            "parent_type" => "branch",
            "source_id" => branch["source_id"],
            "br_v" => branch_map[Tuple(branch["source_id"][2:4])]["INDVP"],
            "len_km" => 0.0,
        )

        branches["$gmd_branch_index"] = branch_data
        gmd_branch_index += 1
        return gmd_branch_index
    end

    _handle_transformer!(branches, gmd_3w_branch, three_winding_resistances, branch, raw_data, dc_bus_map, transformer_map, gmd_branch_index, gen_buses, load_buses)
end


# Makes a unique branch for each bus to its substation
function _generate_bus_gmd_branches!(branches::Dict{String, Dict{String, Any}}, dc_bus_map::Dict{Int64, Int64}, raw_data::Dict{String, Any}, gmd_branch_index::Int64)
    sorted_bus_indices = sort([x["index"] for x in values(raw_data["bus"])])

    for bus_id in sorted_bus_indices
        bus = raw_data["bus"]["$bus_id"]

        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[bus_id],
            "t_bus" => bus["sub"],
            "br_r" => R_g_default,
            "name" => "dc_bus$bus_id",
            "br_status" => 1,
            "parent_index" => bus_id,
            "index" => gmd_branch_index,
            "parent_type" => "bus",
            "source_id" => ["gmd_branch", gmd_branch_index],
            "br_v" => 0.0,
            "len_km" => 0.0,
        )

        branches["$gmd_branch_index"] = branch_data
        gmd_branch_index += 1
    end

    return gmd_branch_index
end

# Adds GSU transformer at each active generator above 30kV
function _generate_implicit_gsu!(branches::Dict{String, Dict{String, Any}}, dc_bus_map::Dict{Int64, Int64}, raw_data::Dict{String, Any}, gmd_branch_index::Int64)
    sorted_gen_indices = sort([x["index"] for x in values(raw_data["gen"])])

    for gen_id in sorted_gen_indices
        gen = raw_data["gen"]["$gen_id"]

        gen_bus = gen["gen_bus"]
        gen_base_kv = raw_data["bus"]["$gen_bus"]["base_kv"]
        if gen_base_kv < 30.0 || gen["gen_status"] == 0
            continue
        end

        # Impedance base for the generator helps determine the assumed resistance of the transformer
        z_base = (gen_base_kv ^ 2) / gen["mbase"]

        branch_data = Dict{String, Any}(
            "f_bus" => dc_bus_map[gen["gen_bus"]],
            "t_bus" => raw_data["bus"]["$gen_bus"]["sub"],
            "br_r" => impxfrm[gen_base_kv] * z_base,
            "name" => "dc_gen$gen_id",
            "br_status" => 1,
            "parent_index" => gen_id,
            "index" => gmd_branch_index,
            "parent_type" => "gen",
            "source_id" => ["gen", gen_id],
            "br_v" => 0.0,
            "len_km" => 0.0,
        )

        branches["$gmd_branch_index"] = branch_data
        gmd_branch_index += 1
    end
end


# Compiles all the three winding transformers to gmd_3w_branch table
function _generate_3w_branch_table!(output::Dict{String, Any}, gmd_3w_branch::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Int64}})
    gmd_3w_branch_index = 1
    output["gmd_3w_branch"] = Dict{String, Dict{String, Int64}}()
    for branch in values(gmd_3w_branch)
        branch["index"] = gmd_3w_branch_index
        output["gmd_3w_branch"]["$gmd_3w_branch_index"] = branch
        gmd_3w_branch_index += 1
    end
end


# Adds bus table to network
function _add_bus_table!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    output["bus"] = Dict{String, Any}()
    for (bus_id, bus) in raw_data["bus"]
        bus_data = deepcopy(bus)

        # Sets position of bus with information from substation
        sub_id = output["gmd_bus"]["$(bus["sub"])"]["parent_index"]
        bus_data["lat"] = gic_data["SUBSTATION"]["$sub_id"]["LAT"]
        bus_data["lon"] = gic_data["SUBSTATION"]["$sub_id"]["LONG"]
        output["bus"][bus_id] = bus_data
    end
end

# TODO: add option for additional fields, and whether this should be added to the ac network
# TODO: this is confusingly similarly named to _add_substation_table!
function _add_sub_table!(output::Dict{String, Any}, gic_data::Dict{String, Any}, raw_data::Dict{String, Any})
    output["sub"] = Dict{String, Any}()
    for (sub_id, sub) in gic_data["SUBSTATION"]
        sub_data = Dict{String,Any}(lowercase(k) => v for (k,v) in sub)
        sub_data["index"] = pop!(sub_data, "substation")
        sub_data["lon"] = pop!(sub_data, "long")
        delete!(sub_data, "earth_model")
        output["sub"][sub_id] = sub_data
    end
end


# Adds branch table to network
# TODO: Add fields: hotspot coeff, gmd_k, pt, topoil_init, hotspot_instant_limit, topoil_rated, topoil_initialized, topoil_time_const, pf, qf, temperature_ambient, qt, hotspot_avg_limit, hotspot_rated
function _add_branch_table!(output::Dict{String, Any}, raw_data::Dict{String, Any}, transformer_map::Dict{Tuple{Int64, Int64, Int64, String}, Dict{String, Any}})
    output["branch"] = Dict{String, Any}()
    for (branch_id, branch) in raw_data["branch"]
        branch_data = deepcopy(branch)
        branch_data["xfmr"] = branch["transformer"] ? 1 : 0
        branch_data["baseMVA"] = raw_data["baseMVA"]
        
        # Sets branch configuration
        branch_data["config"] = "none"
        if branch["transformer"]
            key = Tuple(branch["source_id"][2:5])
            transformer = deepcopy(transformer_map[key])
            config = ""
            config_map = Dict{String, String}(
                "Y" => "wye",
                "YN" => "gwye",
                "D" => "delta",
                "yn" => "-gwye",
                "y" => "-wye",
                "d" => "-delta",
                "a" => "-gwye-auto"
            )

            three_winding = branch["source_id"][4] != 0
            if three_winding
                _create_pseudo_3w_config!(transformer, branch)
            end

            for key in keys(config_map)
                if startswith(transformer["VECGRP"], key * r"[a-z]+")
                    config = config_map[key] * config
                end
                if endswith(transformer["VECGRP"], r"[A-Z]+" * key * r"[^a-z]*")
                    config *= config_map[key]
                end
            end

            branch_data["config"] = config

            # Converts kfactor into per unit
            branch_data["gmd_k"] = transformer["KFACTOR"] * 2 * sqrt(2/3)

            branch["ckt"] = branch["source_id"][5]
        else
            branch["ckt"] = branch["source_id"][4]
        end
        
        # Determines type of the transformer
        if branch["transformer"]
            branch_data["type"] = "xfmr"
        elseif branch_data["br_r"] == 0
            branch_data["type"] = "series_cap"
        else
            branch_data["type"] = "line"
        end

        output["branch"][branch_id] = branch_data
    end
end
