# Tests for data conversion from PSS(R)E to PowerModels data structure
# TODO: add tests to compare extended MatPower & RAW/GIC results

TESTLOG = Memento.getlogger(PowerModels)

# TODO: Rename this to PSSE? Or leave psse.jl unit tests for comparison against MatPower cases?
# Compare coupled voltages for both csv & coupling code
# Compare GMD solve results against PW - put this in PSSE.jl?

function create_branch_voltage_map(net)
    branch_map = Dict()

    for (key, branch) in net["gmd_branch"]
        source_id = branch["source_id"]

        if source_id[1] != "branch"
            continue
        end

        if length(source_id[4]) == 1
            source_id[4] = source_id[4] * " "
        end

        branch_map[source_id[2:end]] = branch["br_v"]
    end

    return branch_map
end

calc_gmd_branch_length = data -> length(data["gmd_branch"])
calc_v_sum = data -> sum(map(x -> x["br_v"], values(gmd_branch)))
calc_v_mean(data) -> calc_v_sum(data)/calc_gmd_branch_length(data)

function calc_v_std(data)
    n = calc_gmd_branch_length(data)
    v_mean = calc_v_mean(data)
    return sqrt(sum(map(x -> (x["br_v"] - v_mean)^2, values(data["gmd_branch"])))/(n - 1))
end

calc_v_mag_sum = data -> sum(map(x -> abs(x["br_v"]), values(data["gmd_branch"])))
calc_v_mag_mean = data -> calc_v_mag_sum(data)/calc_gmd_branch_length(data) 

function calc_v_mag_std(data)
    n = calc_gmd_branch_length(data)
    v_mag_mean = calc_v_mag_mean(data)
    return sqrt(sum(map(x -> (abs(x["br_v"]) - v_mag_mean)^2, values(data["gmd_branch"])))/(n - 1))
end

const voltage_err = 0.01

@testset "Test Coupling" begin
    @testset "Bus4 file" begin
        gic_file = "../test/data/gic/bus4.gic"
        raw_file = "../test/data/pti/bus4.raw"
        csv_file = "../test/data/lines/bus4_1v_km.csv"

        @testset "Load coupled voltages from CSV" begin

            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file, csv_file)
            @test isapprox(data["gmd_branch"]["1"]["br_v"], 170.788589; atol = voltage_err)
        end

        @testset "Run Coupling" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file)
            @test isapprox(data["gmd_branch"]["1"]["br_v"], 170.788589; atol = voltage_err)
        end        
    end

    @testset "EPRI20 file" begin
        gic_file = "../test/data/gic/epri.gic"
        raw_file = "../test/data/pti/epri.raw"
        csv_file = "../test/data/lines/epri_1v_km.csv"

        @testset "Load coupled voltages from CSV" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file, csv_file)
            branch_voltage_map = create_branch_voltage_map(data)
            # Pick some different cases: 
            # first/last branch, highest/lowest voltage, middle branch
            # branch with zero voltage, 2 parallel transmission lines
            @test isapprox(branch_voltage_map[[2, 3, "1 "]], 120.603544; atol = voltage_err) # first line
            @test isapprox(branch_voltage_map[[17, 20, "1 "]], 158.178009; atol = voltage_err) # last line
            @test isapprox(branch_voltage_map[[5, 6, "1 "]], 190.986511; atol = voltage_err) # random line
            @test isapprox(branch_voltage_map[[16, 17, "1 "]], -155.555679; atol = voltage_err) # min voltage
            @test isapprox(branch_voltage_map[[4, 6, "1 "]], 321.261292; atol = voltage_err) # max voltage
            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err) # zero voltage 
            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err) # parallel line
            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err) # parallel line 

            # we don't have an objective, so check the moments of the coupled voltage (along with the min/max)
            # TODO: use Julia stats package for this
            # TODO: export coupled voltages to more than 2 decimal places
            @test calc_gmd_branch_length(data) ==  30
            @test isapprox(calc_v_mean(data), 1369.97; atol = voltage_err) 
            @test isapprox(calc_v_std(data), 1360.426081; atol = voltage_err)  
            @test isapprox(calc_v_mag_mean(data), 2166.25; atol = voltage_err) 
            @test isapprox(calc_v_mag_std(data), 2148.762437; atol = voltage_err)  
        end

        @testset "Run coupling" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file)
            branch_voltage_map = create_branch_voltage_map(data)
            @test isapprox(branch_voltage_map[[2, 3, "1 "]], 120.603544; atol = voltage_err)
            @test isapprox(branch_voltage_map[[17, 20, "1 "]], 158.178009; atol = voltage_err)
            @test isapprox(branch_voltage_map[[5, 6, "1 "]], 190.986511; atol = voltage_err)
            @test isapprox(branch_voltage_map[[16, 17, "1 "]], -155.555679; atol = voltage_err)
            @test isapprox(branch_voltage_map[[4, 6, "1 "]], 321.261292; atol = voltage_err)
            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err)
            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err)
            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err)      
        end        
    end    
end

