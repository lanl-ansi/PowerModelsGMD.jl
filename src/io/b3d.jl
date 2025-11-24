B3D_MAGIC_NUMBER = UInt32(34280)

function read_byte(io)
    return read(io, 1)[1]
end

function write_byte(io, b)
    return write(i, b)
end

function read_uint32(io)
    return copy(reinterpret(UInt32, read(io, 4)))[1]
end

function write_uint32(io, x)
    write(io, convert(UInt32, x)) 
end


function read_float32(io)
    return copy(reinterpret(Float32, read(io, 4)))[1] 
end

function write_float32(io, x)
    write(io, convert(Float32, x)) 
end

function read_float64(io)
    return copy(reinterpret(Float64, read(io, 8)))[1] 
end

function write_float64(io, x)
    write(io, convert(Float64, x)) 
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

function write_null_terminated_string(io, buf)
    for b in buf
        write_byte(io, convert(UInt8, b))
    end

    write_byte(io, convert(Uint8, 0))
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

    if n_byte_channels >= 1
        throw(ErrorException("File contains $n_byte_channels byte channels which are currently unspported"))
    end
 
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

    # TODO: getting rid of this loop will probably increase speed
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

    return b3d
end


function read_b3d(b3d_file::String)
    open(b3d_file) do io
        b3d = read_b3d(io)
    end
    return b3d
end


function write_b3d_header(io::IO, b3d)
    write_uint32(io, B3D_MAGIC_NUMBER)
    b3d_version = b3d["version"]

    if b3d_version != 4
        throw(ErrorException("Version $b3d_version is not supported. Only version 4 is supported"))
    end

    write_uint32(io, b3d_version)

    meta_strings = split(b3d["comment"], "\n")
    n_meta_strings = length(meta_strings)
    write_uint32(n_meta_strings)

    for s in meta_strings
        write_null_terminated_string(io, s)
    end

    write_uint32(b3d["n_float_channels"])
    write_uint32(b3d["n_byte_channels"])
    write_uint32(b3d["loc_format"])
    write_uint32(b3d["n_points"])


    for i in 1:b3d["n_points"]
        lon[i] = write_float64(io, b3d["lon"][i])
        lat[i] = write_float64(io, b3d["lat"][i])
        write_float64(io, b3d["dist_to_measurement_station"][i])   
    end

    write_uint32(io, b3d["start_time"])

    # const (
    # 	nsTimeUnits = -2
    # 	usTimeUnits = -1
    # 	msTimeUnits = 0
    # 	sTimeUnits  = 1
    # )

    time_units = Dict(-2 => 1e-9, -1 => 1e-6, 0 => 1e-3, 1 => 1.0)
    tu_codes = Dict(v => k for (k, v) in time_units)
    time_unit = b3d["time_unit"] 
    Memento.info(_LOGGER, "Time unit in seconds: $time_unit")
    time_unit_code = tu_codes[time_unit]
    Memento.debug(_LOGGER, "Time unit: $time_unit_code")
    write_uint32(io, time_unit_code)

    time_offset = b3d["time_offset"]
    Memento.info(_LOGGER, "Time offset in seconds: $time_offset")
    time_offset_raw = round(UInt32, time_offset/time_unit)
    Memento.debug(_LOGGER, "Time offset in time units: $time_offset_raw")
    write_uint32(io, time_offset_raw)

    time_step = b3d["time_step"]
    Memento.info(_LOGGER, "Time step in seconds: $time_step")
    time_step_raw = round(Uint32, time_step/time_unit)
    Memento.debug(_LOGGER, "Time step in raw units: $time_step_raw")
    write_uint32(io, time_step)
  
    
    write_uint32(io, b3d["n_times"])
end


function write_b3d(io::IO, b3d)
    write_b3d_header(io, b3d)

    n_times = b3d["header"]["n_times"]
    n_points = b3d["header"]["n_points"]
    Ex = b3d["Ex"]
    Ey = b3d["Ey"]

    Memento.info(_LOGGER, "Start writing electric field points")

    for i in 1:n_times
        # Memento.info(_LOGGER, "Reading time $i/$n_times")
        for j in 1:n_points
            write_float32(io, Ex[i,j])
            write_float32(io, Ey[i,j])
        end
    end

    Memento.info(_LOGGER, "Done writing electric field points")
end


function write_b3d(b3d_file::String, b3d)
    open(b3d_file, "w") do io
        write_b3d(io, b3d)
    end
end


function nn_coupling!(net, b3d)
    num_time_steps = b3d["header"]["n_times"]

    nearest_field_index = Dict()

    for time_step in 1:num_time_steps
        # println("Processing time $time_step/$num_time_steps")
        num_branches = length(net["branch"])

        for gmd_branch in values(net["gmd_branch"])
            # println("Branch $branch_number/$num_branches")
            # println("Processing time $time_step/$num_time_steps, branch $branch_number/$num_branches")

            if "BranchDeviceType" in keys(branch_feature["properties"]) && branch_feature["properties"]["BranchDeviceType"] != "Line"
                continue
            end

            # get from & to gmd buses

            # get from & to substations

            # get substation locations


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

            gmd_branch["DiplacementNorth"] = De
            gmd_branch["DisplacementEast"] = Dn
            gmd_branch["Distance"] = line_length
            gmd_branch["DisplacementAngle"] = angle
            gmd_branch["EEast"] = Ee
            gmd_branch["ENorth"] = En
            gmd_branch["EMagnitude"] = Em
            gmd_branch["EAngle"] = Ea
            gmd_branch["Vdc"] = vdc
            gmd_branch["MidpointLatitude"] = lat_mp
            gmd_branch["MidpointLongitude"] = lon_mp
            gmd_branch["EFieldLatitude"] = e_lat
            gmd_branch["EFieldLongitude"] = e_lon
        end
    end
end

