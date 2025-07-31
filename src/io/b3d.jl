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
