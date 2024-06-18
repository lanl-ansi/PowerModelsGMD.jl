#################################################################
#                                                               #
# This file provides functions for interfacing with .gic files  #
#                                                               #
#################################################################

const _gic_sections = ["GICFILEVRSN", "SUBSTATION", "BUS", "TRANSFORMER", "FIXED SHUNT", "BRANCH", "EARTH MODEL", "SWITCHED SHUNT", "DC", "VSC DC", "Multi-Terminal DC Data", "FACTS", "LOAD", "END"]
# BUS, SWITCHED SHUNT, LOAD, and EXTRA BUSES are not consistent between excel and .gic file examples

# Ignoring all comments in these sections for now
const _substation_data = [("SUBSTATION", Int), ("NAME", String), ("BUS", Int), ("LAT", Float64), ("LONG", Float64), ("RG", Float64), ("EARTH_MODEL", String), ("RG_FLAG", String)]
# BUS doesn't seem to be a list, as stated in the spreadsheet, but rather a different section. EARTH_MODEL doesn't clarify what the options for the setting are supposed to be.
const _bus_data = [("ID", Int), ("SUBSTATION", Int)] # Assumed, as not stated elsewhere
const _transformer_data = [("BUSI", Int), ("BUSJ", Int), ("BUSK", Int), ("CKT", String), ("WRI", Float64), ("WRJ", Float64), ("WRK", Float64), ("GICBDI", Int), ("GICBDJ", Int), ("GICBDK", Int), ("VECGRP", String), ("CORE", Int), ("KFACTOR", Float64), ("GRDRI", Int), ("GRDRJ", Int), ("GRDRK", Int), ("TMODEL", Int)]
const _fixed_shunt_data = [("BUS", Int), ("ID", Int), ("R", Float64), ("RG", Float64)]
const _branch_data = [("BUSI", Int), ("BUSJ", Int), ("CKT", String), ("RBRN", Float64), ("INDVP", Float64), ("INDVQ", Float64), ("RLNSHI", Float64), ("RLNSHJ", Float64)]
# const _earth_data = [("", String)] # Not sure the format yet
const _switched_shunt_data = [("BUS", Int), ("ID", Int), ("R", Float64), ("RG", Float64)] # ID is not listed anywhere, but I believe it is inferred
const _dc_data = [("NAME", String), ("BUS", Int), ("ID", Int), ("R", Float64), ("RG", Float64)]
const _vsc_dc_data = [("NAME", String), ("BUS", Int), ("ID", Int), ("R", Float64), ("RG", Float64)]
const _facts_data = [("NAME", String), ("BUS", Int), ("ID", Int), ("R", Float64), ("RG", Float64)]
# const _load_data = [("", Int)] # Information not provided as to what this is

const _gic_data_forms = Dict{String, Array}(
    "GICFILEVRSN" => _bus_data, 
    "SUBSTATION" => _substation_data, 
    "BUS" => _bus_data, 
    "TRANSFORMER" => _transformer_data, 
    "FIXED SHUNT" => _fixed_shunt_data, 
    "BRANCH" => _branch_data, 
    # "EARTH MODEL" => _earth_data,
    "SWITCHED SHUNT" => _switched_shunt_data, 
    "DC" => _dc_data, 
    "VSC DC" => _vsc_dc_data, 
    "FACTS" => _facts_data, 
    # "LOAD" => _load_data
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

function _parse_gic_line!(gic_data::Dict, elements::Array, section::AbstractString, line_number::Int)
    missing_fields = []
    section_data = Dict{String, Any}()

    if !haskey(_gic_data_forms, "$section")
        Memento.warn(_LOGGER, "$section data is not supported by this parser and will be ignored.")
        return
    end

    if length(elements) > length(_gic_data_forms["$section"])
        Memento.warn(_LOGGER, "At line $line_number, $section has extra fields, which will be ignored.")
    end

    for (i, (field, dtype)) in enumerate(_gic_data_forms["$section"])
        if i > length(elements)
            Memento.warn(_LOGGER, "At line $line_number, $section is missing $field, which will be set to default.")
            push!(missing_fields, field)
            continue
        end

        element = strip(elements[i])

        try
            # TODO Set default value for the field before possibly rewriting it
            if dtype != String && element != ""
                section_data[field] = parse(dtype, element)
            else
                if dtype == String && startswith(element, "'") && endswith(element, "'")
                    section_data[field] = strip(chop(element[nextind(element, 1):end]))
                else
                    section_data[field] = element
                end
            end
        catch message
            # Memento.warn(_LOGGER, "At line $line_number, element #$i is not of type $dtype, which is what is expected.")
            if isa(message, Meta.ParseError)
                section_data[field] = element
            else
                throw(Memento.error(_LOGGER, "At line $line_number, element #$i could not be parsed."))
            end
        end
    end

    if length(missing_fields) == 0
        if haskey(gic_data, "$section")
            push!(gic_data["$section"], section_data)
        else
            gic_data["$section"] = [section_data]
        end
    end
end

function _parse_gic(data_io::IO)::Dict
    sections = deepcopy(_gic_sections)
    data_lines = readlines(data_io)

    gic_data = Dict{AbstractString, Any}()

    section = popfirst!(sections)

    for (line_number, line) in enumerate(data_lines)
        (elements, comment) = _get_line_elements(line, line_number)

        if length(elements) == 0
            continue
        end

        # Stop condition
        if elements[1] == "Q"
            break
        end

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
            continue
        elseif line_number == 2
            section = popfirst!(sections) # Done with the version section after the first line
        end

        if section == "GICFILEVRSN" 
            if elements[1] != "GICFILEVRSN=4"
                throw(Memento.error(_LOGGER, "This parser only interprets GIC Version 4. Please ensure you are using the correct format."))
            end
            continue
        end

        _parse_gic_line!(gic_data, elements, section, line_number)
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