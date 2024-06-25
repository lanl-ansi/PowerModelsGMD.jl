import PowerModelsGMD
import JSON
import Memento

const _LOGGER = Memento.getlogger(@__MODULE__)

include("../src/io/gic.jl")

gic_data = parse_gic("../test/data/gic/Bus4.gic")

open("../gicBus4.json", "w") do f
    JSON.print(f, gic_data)
end

# Test cases for GIC file parser

# @testset "test .gic file parser" begin
#     @testset "Parse Example GIC files" begin
#         Memento.setlevel!(TESTLOG, "warn")
#         @test_nowarn PowerModelsGMD.parse_gic("../test/data/gic/EPRI.gic")
#         Memento.setlevel!(TESTLOG, "error")
#     end
#     @testset "Check GIC parser errors" begin
#         Memento.setlevel!(TESTLOG, "warn")
#         @test_throws(TESTLOG, "This parser only interprets GIC Version 3. Please ensure you are using the correct format.",
#             PowerModelsGMD.parse_gic("../test/data/gic/WrongVersion.gic"))
#         @test_throws(TESTLOG, "At line 2, the number of \"'\" characters are mismatched. Please make sure you close all your strings.",
#             PowerModelsGMD.parse_gic("../test/data/gic/MisMatchedQuotes.gic"))
#         # TODO: Parsing error
#         Memento.setlevel!(TESTLOG, "error")
#     end
#     @testset "Check GIC parser warnings" begin
#         @testset "Warns about missing parsing for EARTH MODEL data" begin
#             Memento.setlevel!(TESTLOG, "warn")
#             @test_warn(TESTLOG, "EARTH MODEL data is not supported by this parser and will be ignored.",
#                 PowerModelsGMD.parse_gic("../test/data/gic/EarthModel.gic"))
#             Memento.setlevel!(TESTLOG, "error")
#         end
#         @testset "Warns about incorrect formatting of data" begin
#             Memento.setlevel!(TESTLOG, "warn")
#             @test_warn(TESTLOG, "At line 2, SUBSTATION has extra fields, which will be ignored.",
#                 PowerModelsGMD.parse_gic("../test/data/gic/ExcessElements.gic"))
#             @test_warn(TESTLOG, "At line 6, BUS is missing SUBSTATION, which will be set to default.",
#                 PowerModelsGMD.parse_gic("../test/data/gic/MissingField.gic"))
#             @test_warn(TESTLOG, "At line 6, BUS is missing SUBSTATION, which will be set to default.",
#                 PowerModelsGMD.parse_gic("../test/data/gic/MissingField.gic"))
#             # Parse warning
#             @test_warn(TESTLOG, "At line 9, section BUS started with '0', but additional non-comment data is present. Pattern '^\\s*0\\s*[/]*.*' is reserved for section start/end.",
#                 PowerModelsGMD.parse_gic("../test/data/gic/IncorrectSectionStart.gic"))
#             @test_warn(TESTLOG, "Too many sections at line 17. Please ensure you don't have any extra sections.",
#                 PowerModelsGMD.parse_gic("../test/data/gic/ExtraSection.gic"))
#             Memento.setlevel!(TESTLOG, "error")
#         end
#     end
#     @testset "Bus4 file" begin
#         data_dict = PowerModelsGMD.parse_gic("../test/data/gic/Bus4.gic")
#         @test isa(data_dict, Dict)

#         @test length(data_dict["SUBSTATION"]) == 2
#         for (key, item) in data_dict["SUBSTATION"]
#             @test length(item) == 7
#         end

#         @test length(data_dict["BUS"]) == 4
#         for (key, item) in data_dict["BUS"]
#             @test length(item) == 2
#         end

#         @test length(data_dict["TRANSFORMER"]) == 2
#         for (key, item) in data_dict["TRANSFORMER"]
#             @test length(item) == 17
#         end

#         @test length(data_dict["BRANCH"]) == 1
#         for (key, item) in data_dict["BRANCH"]
#             @test length(item) == 6
#         end
#     end

#     @testset "EPRI file" begin
#         data_dict = PowerModelsGMD.parse_gic("../test/data/gic/EPRI.gic")
#         @test isa(data_dict, Dict)

#         @test length(data_dict["SUBSTATION"]) == 8
#         for (key, item) in data_dict["SUBSTATION"]
#             @test length(item) == 7
#         end

#         @test length(data_dict["BUS"]) == 19
#         for (key, item) in data_dict["BUS"]
#             @test length(item) == 2
#         end

#         @test length(data_dict["TRANSFORMER"]) == 15
#         for (key, item) in data_dict["TRANSFORMER"]
#             @test length(item) == 17
#         end

#         @test length(data_dict["BRANCH"]) == 16
#         for (key, item) in data_dict["BRANCH"]
#             @test length(item) == 6
#         end
#     end

#     @testset "200 Node Case" begin
#         data_dict = PowerModelsGMD.parse_gic("../test/data/gic/activsg200.gic")
#         @test isa(data_dict, Dict)

#         @test length(data_dict["SUBSTATION"]) == 111
#         for (key, item) in data_dict["SUBSTATION"]
#             @test length(item) == 7
#         end

#         @test length(data_dict["BUS"]) == 200
#         for (key, item) in data_dict["BUS"]
#             @test length(item) == 2
#         end

#         @test length(data_dict["TRANSFORMER"]) == 66
#         for (key, item) in data_dict["TRANSFORMER"]
#             @test length(item) == 17
#         end

#         @test length(data_dict["BRANCH"]) == 180
#         for (key, item) in data_dict["BRANCH"]
#             @test length(item) == 6
#         end
#     end

#     @testset "Defaults file" begin
#         data_dict = PowerModelsGMD.parse_gic("../test/data/gic/Defaults.gic")
#         @test isa(data_dict, Dict)

#         @test length(data_dict["SUBSTATION"]) == 2
#         for (key, item) in data_dict["SUBSTATION"]
#             @test length(item) == 7
#         end

#         @test length(data_dict["BUS"]) == 4
#         for (key, item) in data_dict["BUS"]
#             @test length(item) == 2
#         end

#         @test length(data_dict["TRANSFORMER"]) == 2
#         for (key, item) in data_dict["TRANSFORMER"]
#             @test length(item) == 17
#         end

#         @test length(data_dict["BRANCH"]) == 1
#         for (key, item) in data_dict["BRANCH"]
#             @test length(item) == 6
#         end
#     end
# end