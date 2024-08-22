# Test cases for GIC file parser

@testset "test .gic file parser" begin
    @testset "Parse Example GIC files" begin
        Memento.setlevel!(TESTLOG, "warn")
        @test_nowarn PowerModelsGMD.parse_gic("../test/data/gic/epri.gic")
        Memento.setlevel!(TESTLOG, "error")
    end
    @testset "Check GIC parser errors" begin
        Memento.setlevel!(TESTLOG, "warn")
        @test_throws(TESTLOG, "This parser only interprets GIC Version 3. Please ensure you are using the correct format.",
            PowerModelsGMD.parse_gic("../test/data/gic/wrong_version.gic"))
        @test_throws(TESTLOG, "At line 2, the number of \"'\" characters are mismatched. Please make sure you close all your strings.",
            PowerModelsGMD.parse_gic("../test/data/gic/mismatched_quotes.gic"))
        # TODO: Parsing error
        Memento.setlevel!(TESTLOG, "error")
    end
    @testset "Check GIC parser warnings" begin
        @testset "Warns about missing parsing for EARTH MODEL data" begin
            Memento.setlevel!(TESTLOG, "warn")
            @test_warn(TESTLOG, "EARTH MODEL data is not supported by this parser and will be ignored.",
                PowerModelsGMD.parse_gic("../test/data/gic/earth_model.gic"))
            Memento.setlevel!(TESTLOG, "error")
        end
        @testset "Warns about incorrect formatting of data" begin
            Memento.setlevel!(TESTLOG, "warn")
            @test_warn(TESTLOG, "At line 2, SUBSTATION has extra fields, which will be ignored.",
                PowerModelsGMD.parse_gic("../test/data/gic/excess_elements.gic"))
            @test_warn(TESTLOG, "At line 6, BUS is missing SUBSTATION, which will be set to default.",
                PowerModelsGMD.parse_gic("../test/data/gic/missing_field.gic"))
            @test_warn(TESTLOG, "At line 6, BUS is missing SUBSTATION, which will be set to default.",
                PowerModelsGMD.parse_gic("../test/data/gic/missing_field.gic"))
            # Parse warning
            @test_warn(TESTLOG, "At line 9, section BUS started with '0', but additional non-comment data is present. Pattern '^\\s*0\\s*[/]*.*' is reserved for section start/end.",
                PowerModelsGMD.parse_gic("../test/data/gic/incorrect_section_start.gic"))
            @test_warn(TESTLOG, "Too many sections at line 17. Please ensure you don't have any extra sections.",
                PowerModelsGMD.parse_gic("../test/data/gic/extra_section.gic"))
            Memento.setlevel!(TESTLOG, "error")
        end
    end
    @testset "Bus4 file" begin
        data_dict = PowerModelsGMD.parse_gic("../test/data/gic/bus4.gic")
        @test isa(data_dict, Dict)

        @test length(data_dict["SUBSTATION"]) == 2
        for (key, item) in data_dict["SUBSTATION"]
            @test length(item) == 7
        end

        @test length(data_dict["BUS"]) == 4
        for (key, item) in data_dict["BUS"]
            @test length(item) == 2
        end

        @test length(data_dict["TRANSFORMER"]) == 2
        for (key, item) in data_dict["TRANSFORMER"]
            @test length(item) == 17
        end

        @test length(data_dict["BRANCH"]) == 1
        for (key, item) in data_dict["BRANCH"]
            @test length(item) == 6
        end
    end

    @testset "EPRI file" begin
        data_dict = PowerModelsGMD.parse_gic("../test/data/gic/epri.gic")
        @test isa(data_dict, Dict)

        @test length(data_dict["SUBSTATION"]) == 8
        for (key, item) in data_dict["SUBSTATION"]
            @test length(item) == 7
        end

        @test length(data_dict["BUS"]) == 19
        for (key, item) in data_dict["BUS"]
            @test length(item) == 2
        end

        @test length(data_dict["TRANSFORMER"]) == 15
        for (key, item) in data_dict["TRANSFORMER"]
            @test length(item) == 17
        end

        @test length(data_dict["BRANCH"]) == 16
        for (key, item) in data_dict["BRANCH"]
            @test length(item) == 6
        end
    end



    @testset "Defaults file" begin
        data_dict = PowerModelsGMD.parse_gic("../test/data/gic/defaults.gic")
        @test isa(data_dict, Dict)

        @test length(data_dict["SUBSTATION"]) == 2
        for (key, item) in data_dict["SUBSTATION"]
            @test length(item) == 7
        end

        @test length(data_dict["BUS"]) == 4
        for (key, item) in data_dict["BUS"]
            @test length(item) == 2
        end

        @test length(data_dict["TRANSFORMER"]) == 2
        for (key, item) in data_dict["TRANSFORMER"]
            @test length(item) == 17
        end

        @test length(data_dict["BRANCH"]) == 1
        for (key, item) in data_dict["BRANCH"]
            @test length(item) == 6
        end
    end
end
