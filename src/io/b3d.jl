B3D_MAGIC_NUMBER = UInt32(34280)

function read_byte(io)
    return read(io, 1)[1]
end

function read_uint32(io)
    return copy(reinterpret(UInt32, read(io, 4)))[1]
end

function read_float32(io)
    return copy(reinterpret(Float32, read(io, 4)))[1] 
end

function read_float64(io)
    return copy(reinterpret(Float64, read(io, 8)))[1] 
end

function read_null_terminated_string(io)
    buf = Vector{UInt8}()

    b = read_byte(io)

    while b != 0
        push!(buf, b[1])
        b = read_byte(io)
    end

    return String(buf)
end

function read_b3d_header(io::IO)
    b3d = Dict()
    magic_number = read_uint32(io)

    Memento.debug(_LOGGER, "Magic number: $magic_number")

    if magic_number != B3D_MAGIC_NUMBER
        throw(ErrorException("Invalid B3D file with magic number $magic_number, expecting $B3D_MAGIC_NUMBER"))
    end

    b3d_version = read_uint32(io)
    Memento.info(_LOGGER, "B3D version: $b3d_version")
    b3d["version"] = b3d_version

    if b3d_version != 4
        throw(ErrorException("Version $b3d_version is not supported. Only version 4 is supported"))
    end

    n_meta_strings =  read_uint32(io)
    Memento.debug(_LOGGER, "Number of metadata strings: $n_meta_strings")
    b3d["n_meta_strings"] = n_meta_strings

    meta_strings = []

    for i in 1:n_meta_strings
        meta_string = read_null_terminated_string(io)
        push!(meta_strings, meta_string)
        Memento.info(_LOGGER, "Comment $i: $meta_string")
    end

    # Note: 2nd string may be used for dimensions of 2d point array
    comments = join(meta_strings, '\n')
    b3d["comments"] = comments

    n_float_channels = read_uint32(io)
    Memento.debug(_LOGGER, "Number of float channels: $n_float_channels")
    b3d["n_float_channels"] = n_float_channels

    if n_float_channels < 2
        throw(ErrorException("Unspported number of float channels $n_float_channels, only B3D files with at least 2 float channels are supported"))
    end

    n_byte_channels = read_uint32(io)
    Memento.debug(_LOGGER, "Number of byte channels: $n_byte_channels")
    b3d["n_byte_channels"] = n_byte_channels
 
    loc_format = read_uint32(io)
    Memento.info(_LOGGER, "Location format: $loc_format")
    b3d["loc_format"] = loc_format
    
    if loc_format != 1
        throw(ErrorException("Unspported location format $loc_format, only location format 1 is supported"))
    end

    n_points = read_uint32(io)
    Memento.info(_LOGGER, "Number of points: $n_points")
    b3d["n_points"] = n_points

    lat = zeros(n_points)
    lon = zeros(n_points)
    dist_to_measurement_station = zeros(n_points)

    # const (
    # 	measurement_station_location         float64 = 0.0
    # 	measurement_station_location_unknown float64 = -1.0
    # )

    for i in 1:n_points
        lon[i] = read_float64(io)
        lat[i] = read_float64(io)
        dist_to_measurement_station[i] = read_float64(io)   
    end

    b3d["lon"] = lon
    b3d["lat"] = lat
    b3d["dist_to_measurement_station"] = dist_to_measurement_station

    start_time = read_uint32(io)
    Memento.debug(_LOGGER, "Start time in seconds since epoch: $start_time")
    b3d["start_time"] = start_time

    # const (
    # 	nsTimeUnits = -2
    # 	usTimeUnits = -1
    # 	msTimeUnits = 0
    # 	sTimeUnits  = 1
    # )

    time_units = Dict(-2 => 1e-9, -1 => 1e-6, 0 => 1e-3, 1 => 1.0)

    time_unit_code = read_uint32(io)
    Memento.debug(_LOGGER, "Time unit: $time_unit_code")
    # b3d["time_unit_code"] = time_unit_code

    time_unit = time_units[time_unit_code]
    Memento.info(_LOGGER, "Time unit in seconds: $time_unit")
    b3d["time_unit"] = time_unit

    time_offset_raw = read_uint32(io)
    Memento.debug(_LOGGER, "Time offset in time units: $time_offset_raw")
    # b3d["time_offset_raw"] = time_offset_raw

    time_offset = time_unit*convert(Float64, time_offset_raw)
    Memento.info(_LOGGER, "Time offset in seconds: $time_offset")
    b3d["time_offset"] = time_offset

    time_step_raw = read_uint32(io)
    Memento.debug(_LOGGER, "Time step in raw units: $time_step_raw")
    # b3d["time_step_raw"] = time_step_raw

    time_step = time_unit*convert(Float64, time_step_raw)
    Memento.info(_LOGGER, "Time step in seconds: $time_step")
    b3d["time_step"] = time_step

    n_times = read_uint32(io)
    Memento.info(_LOGGER, "Number of time steps: $n_times")
    b3d["n_times"] = n_times

    return b3d
end

function read_b3d(b3d_file::String)
    io = open(b3d_file)
    b3d = read_b3d(io)
    close(io)
    return b3d
end

function read_b3d(io::IO)
    b3d = Dict{String,Any}()
    b3d["header"] = read_b3d_header(io)
    n_times = b3d["header"]["n_times"]
    n_points = b3d["header"]["n_points"]
    time_unit = b3d["header"]["time_unit"]
    time_offset = b3d["header"]["time_offset"]

    t = zeros(n_times)

    for i in 1:n_times
        t[i] = time_unit*read_uint32(io) + time_offset
    end    

    b3d["t"] = t    

    Ex = zeros(Float32, (n_times, n_points))
    Ey = zeros(Float32, (n_times, n_points))

    Memento.info(_LOGGER, "Start reading electric field points")

    for i in 1:n_times
        # Memento.info(_LOGGER, "Reading time $i/$n_times")
        for j in 1:n_points
            Ex[i,j] = read_float32(io)
            Ey[i,j] = read_float32(io)
        end
    end

    Memento.info(_LOGGER, "Done reading electric field points")
    b3d["Ex"] = Ex
    b3d["Ey"] = Ey
    close(io)

    return b3d
end

function coupling(net, b3d)
    if length(ARGS) >= 1 
        #event = ARGS[2]
        #output_event = replace(lowercase(event), "-" => "_")
        branch_geo = ARGS[1]
    end

    if length(ARGS) >= 2
        #network = ARGS[1]
        #output_network = replace(lowercase(network), "-" => "_")
        input_folder = ARGS[2]
    end

    if length(ARGS) >= 3
        output_folder = ARGS[3]
    end

    files = readdir(input_folder)
    e_field_files = filter(x->endswith(x, ".csv"), files)

    mkpath(output_folder)


    f = open(branch_geo)
    branch_collection = JSON.parse(f)
    close(f)

    num_time_steps = length(e_field_files)

    nearest_field_index = Dict()

    for (time_step,e_field_file) in enumerate(sort(e_field_files))
        # println("Processing time $time_step/$num_time_steps")

        in_path = "$input_folder/$e_field_file"

        output_file = replace(e_field_file, "geoe_grid_full_full_res_1_e" => "e_field_")
        output_file = replace(output_file, "-" => "_")
        output_file = replace(output_file, ".csv" => ".geojson")
        out_path = "$output_folder/$output_file"

        # println("Input: $in_path\nOutput: $out_path\n")
        println("Time step: $time_step/$num_time_steps\nInput: $in_path\nOutput: $out_path\n")

        E = DelimitedFiles.readdlm(in_path, ',', Float64, skipstart=1);

        line_collection = Dict()
        line_collection["type"] = "FeatureCollection"
        line_collection["features"] = []

        num_branches = length(branch_collection["features"])

        for (branch_number,branch_feature) in enumerate(branch_collection["features"])
            # println("Branch $branch_number/$num_branches")
            # println("Processing time $time_step/$num_time_steps, branch $branch_number/$num_branches")

            if "BranchDeviceType" in keys(branch_feature["properties"]) && branch_feature["properties"]["BranchDeviceType"] != "Line"
                continue
            end

            # feature = deepcopy(branch_feature)
            feature = branch_feature

            coords = feature["geometry"]["coordinates"]
            lon1 = coords[1][1]
            lat1 = coords[1][2]

            lon2 = coords[end][1]
            lat2 = coords[end][2]

            Dlon = lon2 - lon1
            Dlat = lat2 - lat1

            lon_mp = (lon1 + lon2)/2
            lat_mp = (lat1 + lat2)/2
            
            alpha = (pi/180)*lat_mp

            Dn = 111.2*Dlat
            De = 111.2*Dlon*sin(pi/2 - alpha)

            line_length = sqrt(De^2 + Dn^2)
            angle = atand(Dn, De)


            if !((lon_mp, lat_mp) in keys(nearest_field_index))
                nearest_field_index[(lon_mp, lat_mp)] = 1
                e_lat = E[1,1]
                e_lon = E[1,2]

                if e_lon >= 180
                    e_lon = 360 - e_lon
                end

                dmin = (e_lon - lon_mp)^2 + (e_lat - lat_mp)^2

                for j = 1:size(E,1)
                    e_lat = E[j,1]
                    e_lon = E[j,2]

                    if e_lon >= 180
                    e_lon = 360 - e_lon
                    end


                    d = (e_lon - lon_mp)^2 + (e_lat - lat_mp)^2

                    if d < dmin
                        nearest_field_index[(lon_mp, lat_mp)] = j
                        dmin = d
                    end
                end

                #println("Setting nearest point for ($lon_mp,$lat_mp) to $(nearest_field_index[(lon_mp, lat_mp)])")
            end

            i = nearest_field_index[(lon_mp, lat_mp)]


            e_lat = E[i,1]
            e_lon = E[i,2]

            #println("Nearest point to ($lon_mp,$lat_mp) is E[$i] at ($e_lon,$e_lat)")

            Ee = E[i,3]
            En = E[i,4]
            Em = sqrt(Ee^2 + En^2)
            Ea = atand(En, Ee)

            vdc = De*Ee + Dn*En

            feature["properties"]["DiplacementNorth"] = De
            feature["properties"]["DisplacementEast"] = Dn
            feature["properties"]["Distance"] = line_length
            feature["properties"]["DisplacementAngle"] = angle
            feature["properties"]["EEast"] = Ee
            feature["properties"]["ENorth"] = En
            feature["properties"]["EMagnitude"] = Em
            feature["properties"]["EAngle"] = Ea
            feature["properties"]["Vdc"] = vdc
            feature["properties"]["MidpointLatitude"] = lat_mp
            feature["properties"]["MidpointLongitude"] = lon_mp
            feature["properties"]["EFieldLatitude"] = e_lat
            feature["properties"]["EFieldLongitude"] = e_lon

            push!(line_collection["features"], feature)
        end


        fo = open(out_path, "w")
        JSON.print(fo, line_collection)
        close(fo)
    end
end

