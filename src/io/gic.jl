#################################################################
#                                                               #
# This file provides functions for interfacing with .gic files  #
#                                                               #
#################################################################

const _gic_sections = ["GICFILEVRSN", "SUBSTATION", "BUS", "TRANSFORMER", "FIXED SHUNT", "BRANCH", "EARTH MODEL", "END"]
# BUS, SWITCHED SHUNT, LOAD, and EXTRA BUSES are not consistent between excel and .gic file examples

# Ignoring all comments in these sections for now
const _substation_data = [("SUBSTATION", Int), ("NAME", String), ("BUS", Int), ("LAT", Float64), ("LONG", Float64), ("RG", Float64), ("EARTH_MODEL", String)]
# BUS doesn't seem to be a list, as stated in the spreadsheet, but rather a different section. EARTH_MODEL doesn't clarify what the options for the setting are supposed to be.
const _bus_data = [("ID", Int), ("SUBSTATION", Int)] # Assumed, as not stated elsewhere
const _transformer_data = [("BUSI", Int), ("BUSJ", Int), ("BUSK", Int), ("CKT", String), ("WRI", Float64), ("WRJ", Float64), ("WRK", Float64), ("GICBDI", Int), ("GICBDJ", Int), ("GICBDK", Int), ("VECGRP", String), ("CORE", Int), ("KFACTOR", Float64), ("GRDRI", Int), ("GRDRJ", Int), ("GRDRK", Int), ("TMODEL", Int)]
const _fixed_shunt_data = [("BUS", Int), ("ID", Int), ("R", Float64), ("RG", Float64)]
const _branch_data = [("BUSI", Int), ("BUSJ", Int), ("CKT", String), ("RBRN", Float64), ("INDVP", Float64), ("INDVQ", Float64)]
# const _earth_data = [("", String)] # Not sure the format yet

const _gic_data_forms = Dict{String, Array}(
    "SUBSTATION" => _substation_data, 
    "BUS" => _bus_data, 
    "TRANSFORMER" => _transformer_data, 
    "FIXED SHUNT" => _fixed_shunt_data, 
    "BRANCH" => _branch_data, 
    # "EARTH MODEL" => _earth_data,
)

# Default Values
const _substation_defaults = Dict{String, Any}(
    "RG" => 0.1,
    "EARTH_MODEL" => "Activity Optn",
    "RG_FLAG" => "Assumed"
)
const _transformer_defaults = Dict{String, Any}(
    # "WRI" => ,
    # "WRJ" => , 
    # "WRK" => , 
    "GICBDI" => 0,
    "GICBDJ" => 0,
    "GICBDK" => 0,
    "CORE" => 0,
    "KFACTOR" => 0,
    "GRDRI" => 0,
    "GRDRJ" => 0,
    "GRDRK" => 0,
    "TMODEL" => 0
)
const _fixed_shunt_defaults = Dict{String, Any}(
    "RG" => 0
)

const _branch_defaults = Dict{String, Any}(
    "RLNSHI" => 0,
    "RLNSHJ" => 0
)

const _gic_defaults = Dict{String, Dict}(
    "SUBSTATION" => _substation_defaults, 
    "TRANSFORMER" => _transformer_defaults, 
    "FIXED SHUNT" => _fixed_shunt_defaults, 
    "BRANCH" => _branch_defaults, 
    # "EARTH MODEL" => _earth_data,
)

const _gic_has_ID = Dict{String, String}(
    "SUBSTATION" => "SUBSTATION",
    "BUS" => "ID"
)

function parse_gic(io::IO)::Dict
    data = _parse_gic(io)

    data["name"] = match(r"^\<file\s[\/\\]*(?:.*[\/\\])*(.*)\.gic\>$", lowercase(io.name)).captures[1]
    return data
end

function parse_gic(file::String)::Dict
    io = open(file)
    return parse_gic(io)
end

function _parse_gic_line!(gic_data::Dict, elements::Array, section::AbstractString, line_number::Int, ID::Int)
    section_data = Dict{String, Any}()

    if !haskey(_gic_data_forms, "$section")
        Memento.warn(_LOGGER, "$section data is not supported by this parser and will be ignored.")
        return
    end

    if length(elements) > length(_gic_data_forms["$section"])
        Memento.warn(_LOGGER, "At line $line_number, $section has extra fields, which will be ignored.")
    end

    for (i, (field, dtype)) in enumerate(_gic_data_forms["$section"])
        if haskey(_gic_defaults, section) && haskey(_gic_defaults["$section"], field)
            section_data[field] = _gic_defaults["$section"]["$field"]
        end

        if i > length(elements)
            Memento.warn(_LOGGER, "At line $line_number, $section is missing $field, which will be set to default.")
            continue
        end

        element = strip(elements[i])

        try
            if dtype != String && element != ""
                section_data[field] = parse(dtype, element)
            else
                if dtype == String && startswith(element, "'") && endswith(element, "'")
                    section_data[field] = chop(element[nextind(element, 1):end])
                else
                    section_data[field] = element
                end
            end

            if field == "CKT" && length(strip(section_data[field])) == 1
                section_data[field] = strip(section_data[field]) * " "
            end
        catch message
            # Memento.warn(_LOGGER, "At line $line_number, element #$i is not of type $dtype, which is what is expected.")
            if isa(message, Meta.ParseError)
                section_data[field] = element
            else
                Memento.warn(_LOGGER, "At line $line_number, element #$i could not be parsed.")
                if !haskey(_gic_defaults, section) && haskey(_gic_defaults["$section"], field)
                    Memento.warn(_LOGGER, "At line $line_number, element #$i did not have a default value to be substituted in") # TODO Add test for this
                end
                # throw(Memento.error(_LOGGER, "At line $line_number, element #$i could not be parsed."))
            end
        end
    end

    if haskey(_gic_has_ID, "$section")
        ID = section_data["$(_gic_has_ID["$section"])"]
    end

    if haskey(gic_data, "$section")
        gic_data["$section"]["$ID"] = section_data
    else
        gic_data["$section"] = Dict{String, Any}(
            "$ID" => section_data
            )
    end
end

function _parse_gic(data_io::IO)::Dict
    sections = deepcopy(_gic_sections)
    data_lines = readlines(data_io)

    gic_data = Dict{String, Any}()

    section = popfirst!(sections)

    ID = 0
    for (line_number, line) in enumerate(data_lines)
        ID += 1
        (elements, comment) = _get_line_elements(line, line_number)

        if length(elements) == 0
            continue
        end

        # Stop condition
        if elements[1] == "Q"
            break
        end

        old_section = section
        # Check new section        
        if (elements[1] == "0")
            if (line_number == 2) 
                section = popfirst!(sections) # Skip this section, as default is to start without indicating a new section
            end
    
            if length(elements) > 1
                Memento.warn(_LOGGER, "At line $line_number, section $section started with '0', but additional non-comment data is present. Pattern '^\\s*0\\s*[/]*.*' is reserved for section start/end.")
            elseif length(comment) > 0
                Memento.debug(_LOGGER, "At line $line_number, switched to parsing the $section section.")
            end
    
            if !isempty(sections)
                section = popfirst!(sections)
            else
                Memento.warn(_LOGGER, "Too many sections at line $line_number. Please ensure you don't have any extra sections.")
            end
            ID = 0
            continue
        elseif line_number == 2
            section = popfirst!(sections) # Done with the version section after the first line
        end

        if section == "GICFILEVRSN" 
            if elements[1] != "GICFILEVRSN=3"
                throw(Memento.error(_LOGGER, "This parser only interprets GIC Version 3. Please ensure you are using the correct format."))
            end
            continue
        end

        if old_section != section
            ID = 1
        end

        _parse_gic_line!(gic_data, elements, section, line_number, ID)
    end

    return gic_data
end

const _comment_split = r"(?!\B[\'][^\']*)[\/](?![^\']*[\']\B)"
const _split_string = r",(?=(?:[^']*'[^']*')*[^']*$)"

function _get_line_elements(line::AbstractString, line_number::Int)
    if count(i->(i=='\''), line) % 2 == 1
        throw(Memento.error(_LOGGER, "At line $line_number, the number of \"'\" characters are mismatched. Please make sure you close all your strings."))
    end

    line_split = split(line, _comment_split, limit=2)

    elements = split(strip(line_split[1]), _split_string)
    comment = length(line_split) > 1 ? line_split[2] : ""

    return (elements, comment)
end