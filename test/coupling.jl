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
        # TODO: rearrange the powerworld CSV exports into one folder
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
            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err) # line with zero voltage 
            @test isapprox(branch_voltage_map[[16, 20, "1 "]], 1.489666; atol = voltage_err) # line with smallest absolute nonzero voltage
            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err) # parallel line
            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err) # parallel line 

            # we don't have an objective, so check the stats of coupled voltages 
            # (and make sure to check the branch keys with min/max coupled voltages
            # TODO: export coupled voltages to more than 2 decimal places
            v = [x["br_v"] for x in values(data["gmd_branch"]) if x["source_id"][1] == "branch"]
            @test length(data["gmd_branch"]) == 58
            @test length(v) ==  16

            # mu, std = StatsBase.mean_and_std(v, corrected=true)
            @test isapprox(calc_mean(v), 85.624962; atol = voltage_err) 
            @test isapprox(calc_std(v), 135.194889; atol = voltage_err)  

            q = StatsBase.nquantile(v, 4)
            @test isapprox(q[2], -5.034325; atol = voltage_err) # 1st quartile 
            @test isapprox(q[3], 131.693298; atol = voltage_err) # median
            @test isapprox(q[4], 175.112583; atol = voltage_err) # 3rd quartile

            @test isapprox(calc_mean(abs.(v)), 135.389907; atol = voltage_err) 
            @test isapprox(calc_std(abs.(v)), 80.904958; atol = voltage_err)  

            qm = StatsBase.nquantile(abs.(v), 4)
            @test isapprox(qm[2], 113.742239; atol = voltage_err) # 1st quartile 
            @test isapprox(qm[3], 143.624488; atol = voltage_err) # median
            @test isapprox(qm[4], 175.112583; atol = voltage_err) # 3rd quartile      

            sorted_keys = sort([x["source_id"][2:4] for x in values(data["branch"]) if x["source_id"][1] == "branch"])
            vs = [branch_voltage_map[k] for k in sorted_keys]
            Vm = abs.(FFTW.fft(vs))

            @test isapprox(Vm[2], 679.012015; atol = voltage_err) 
            @test isapprox(Vm[5], 384.097304; atol = voltage_err) 
            @test isapprox(Vm[9], 80.690000; atol = voltage_err) 

            v_other = [x["br_v"] for x in values(data["gmd_branch"]) if x["source_id"][1] != "branch"]
            @test length(v_other) == 42
            @test isapprox(sum(abs.(v_other)), 0.0; atol = voltage_err)  
        end

        @testset "Run coupling" begin
            data = PowerModelsGMD.generate_dc_data(gic_file, raw_file)
            branch_voltage_map = create_branch_voltage_map(data)
            @test isapprox(branch_voltage_map[[2, 3, "1 "]], 120.603544; atol = voltage_err) # first line
            @test isapprox(branch_voltage_map[[17, 20, "1 "]], 158.178009; atol = voltage_err) # last line
            @test isapprox(branch_voltage_map[[5, 6, "1 "]], 190.986511; atol = voltage_err) # random line
            @test isapprox(branch_voltage_map[[16, 17, "1 "]], -155.555679; atol = voltage_err) # min voltage
            @test isapprox(branch_voltage_map[[4, 6, "1 "]], 321.261292; atol = voltage_err) # max voltage
            @test isapprox(branch_voltage_map[[5, 21, "1 "]], 0.0; atol = voltage_err) # line with zero voltage 
            @test isapprox(branch_voltage_map[[16, 20, "1 "]], 1.489666; atol = voltage_err) # line with smallest absolute nonzero voltage
            @test isapprox(branch_voltage_map[[15, 6, "1 "]], 191.110397; atol = voltage_err) # parallel line
            @test isapprox(branch_voltage_map[[15, 6, "2 "]], 191.110397; atol = voltage_err) # parallel line 
            
            v = [x["br_v"] for x in values(data["gmd_branch"]) if x["source_id"][1] == "branch"]
            @test length(data["gmd_branch"]) == 58
            @test length(v) ==  16

            mu, std = StatsBase.mean_and_std(v, corrected=true)
            @test isapprox(mu, 85.624962; atol = voltage_err) 
            @test isapprox(std, 135.194889; atol = voltage_err)  

            mu_m, std_m = StatsBase.mean_and_std(abs.(v), corrected=true)
            @test isapprox(mu_m, 135.389907; atol = voltage_err) 
            @test isapprox(std_m, 80.904958; atol = voltage_err) 

            qm = StatsBase.nquantile(abs.(v), 4)
            @test isapprox(qm[2], 113.742239; atol = voltage_err) # 1st quartile 
            @test isapprox(qm[3], 143.624488; atol = voltage_err) # median
            @test isapprox(qm[4], 175.112583; atol = voltage_err) # 3rd quartile      

            sorted_keys = sort([x["source_id"][2:4] for x in values(data["branch"]) if x["source_id"][1] == "branch"])
            vs = [branch_voltage_map[k] for k in sorted_keys]
            Vm = abs.(FFTW.fft(vs))

            @test isapprox(Vm[2], 679.012015; atol = voltage_err) 
            @test isapprox(Vm[5], 384.097304; atol = voltage_err) 
            @test isapprox(Vm[9], 80.690000; atol = voltage_err) 

            v_other = [x["br_v"] for x in values(data["gmd_branch"]) if x["source_id"][1] != "branch"]
            @test isapprox(sum(abs.(v_other)), 0.0; atol = voltage_err)  
        end        
    end    
end

