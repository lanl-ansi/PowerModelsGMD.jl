"Parse a file given a file path and return as a
dictionary structure

File type is inferred based on the file extension"
function parse_file(file::String; kwargs...)::Dict
    filetype = lowercase(splitext(file)[end])
    if filetype != ".gic"
        return PowerModels.parse_file(file; kwargs...)
    end

    io = open(file)
    return parse_gic(io)
    close(io)
end

# TODO: handle csv voltage file?
"Parse a set of files given their paths and return as multinetwork 
dictionary structure

File type is inferred based on the file extension"
function parse_files(files::String...; kwargs...)::Dict
    mn_data = Dict{String, Any}(
        "nw" => Dict{String, Any}(),
        "per_unit" => true,
        "multinetwork" => true
    )

    names = Array{String, 1}()

    for (i, filename) in enumerate(files)
        data = parse_file(filename; kwargs...)

        delete!(data, "multinetwork")
        delete!(data, "per_unit")

        mn_data["nw"]["$i"] = data
        push!(names, "$(data["name"])")
    end

    mn_data["name"] = join(names, " + ")

    return mn_data
end
