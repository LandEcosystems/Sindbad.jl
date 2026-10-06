using Test
using Sindbad
using Sindbad.DataLoaders: DD
using DimensionalData
using YAXArrays: YAXArray, Cube
using Flux

@testset "MachineLearningParameters & predictParameters" begin
    @testset "assembleFeatures" begin
        # 1. PFT single feature
        f_pft1 = assembleFeatures(1)
        @test length(f_pft1) == 17
        @test f_pft1[1] == 1.0f0
        @test sum(f_pft1) == 1.0f0

        f_pft3 = assembleFeatures([3])
        @test length(f_pft3) == 17
        @test f_pft3[3] == 1.0f0

        # Vegetation class mapping
        f_veg = assembleFeatures(1; veg_cat=true)
        @test length(f_veg) == 5 # 5 vegetation labels: Tree, Shrub, Savanna, Herb, Non-Veg

        # 2. PFT + KG
        f_pft_kg = assembleFeatures(1, 5)
        @test length(f_pft_kg) == 32 + 17
        # First 32 are KG, next 17 are PFT
        @test f_pft_kg[5] == 1.0f0 # KG index 5
        @test f_pft_kg[32 + 1] == 1.0f0 # PFT index 1

        # 3. PFT + KG + continuous covariates
        extra_vars = Float32[0.5, 1.2, -0.3]
        f_all = assembleFeatures(1, 5, extra_vars)
        @test length(f_all) == 32 + 17 + 3
        @test f_all[32 + 17 + 1:end] == extra_vars
    end

    @testset "predictParametersPixel!" begin
        # Dummy neural network: 17 inputs -> 2 outputs
        nn = Flux.Chain(Flux.Dense(17 => 4, Flux.relu), Flux.Dense(4 => 2, Flux.sigmoid))
        lower_bound = Float32[10.0, 100.0]
        upper_bound = Float32[20.0, 200.0]

        out_ps = zeros(Float32, 2)
        predictParametersPixel!(
            out_ps, 1;
            trained_nn = nn,
            lower_bound = lower_bound,
            upper_bound = upper_bound,
        )

        @test 10.0f0 <= out_ps[1] <= 20.0f0
        @test 100.0f0 <= out_ps[2] <= 200.0f0

        # Pixel with NaN
        out_nan = zeros(Float32, 2)
        predictParametersPixel!(
            out_nan, NaN32;
            trained_nn = nn,
            lower_bound = lower_bound,
            upper_bound = upper_bound,
        )
        @test all(isnan, out_nan)
    end

    @testset "predictParameters with YAXArrays Cubes" begin
        # Create test spatial axes
        lons = [10.0, 11.0, 12.0]
        lats = [50.0, 51.0]
        ax_lon = Dim{:Lon}(lons)
        ax_lat = Dim{:Lat}(lats)

        # 1. PFT single cube
        pft_data = Float32[1.0 2.0; 3.0 NaN32; 5.0 6.0]
        pft_cube = YAXArray((ax_lon, ax_lat), pft_data)

        ps_names = ["param_a", "param_b"]
        lower_bound = Float32[0.0, 100.0]
        upper_bound = Float32[10.0, 200.0]

        nn_pft = Flux.Chain(Flux.Dense(17 => 4, Flux.relu), Flux.Dense(4 => 2, Flux.sigmoid))

        out_cube = predictParameters(
            pft_cube,
            nn_pft,
            lower_bound,
            upper_bound,
            ps_names,
        )

        # Verify output dimension ordering: (:parameter, :Lon, :Lat)
        @test name.(dims(out_cube)) == (:parameter, :Lon, :Lat)
        @test size(out_cube) == (2, 3, 2)
        @test lookup(out_cube, :parameter) == ["param_a", "param_b"]

        # Check bounds on valid pixel
        @test 0.0f0 <= out_cube[1, 1, 1] <= 10.0f0
        @test 100.0f0 <= out_cube[2, 1, 1] <= 200.0f0

        # Check metadata properties
        @test out_cube.properties["name"] == "parameters"
        @test out_cube.properties["long_name"] == "Estimated Ecosystem Model Parameters"
        @test out_cube.properties["n_parameters"] == 2
        @test out_cube.properties["parameter_names"] == ["param_a", "param_b"]
        @test haskey(out_cube.properties, "created_at")
        @test haskey(out_cube.properties, "source")

        # Check NaN pixel (Lon index 2, Lat index 2 was NaN)
        @test isnan(out_cube[1, 2, 2])
        @test isnan(out_cube[2, 2, 2])

        # 2. Multi-cube (PFT + KG + Soil Covariates cube)
        kg_data = Float32[1.0 2.0; 3.0 4.0; 5.0 6.0]
        kg_cube = YAXArray((ax_lon, ax_lat), kg_data)

        # Continuous soil/site covariates: Soil Organic Carbon, Sand, Clay
        vars = ["soc", "sand", "clay"]
        ax_var = Dim{:Variables}(vars)
        cov_data = rand(Float32, 3, 2, length(vars)) # (Lon, Lat, Variables)
        cov_cube = YAXArray((ax_lon, ax_lat, ax_var), cov_data)

        n_inputs = 32 + 17 + length(vars) # 32 (KG) + 17 (PFT) + 3 (Soil covariates) = 52
        nn_all = Flux.Chain(Flux.Dense(n_inputs => 8, Flux.relu), Flux.Dense(8 => 2, Flux.sigmoid))

        out_multi = predictParameters(
            (pft_cube, kg_cube, cov_cube),
            nn_all,
            lower_bound,
            upper_bound,
            ps_names,
        )

        @test name.(dims(out_multi)) == (:parameter, :Lon, :Lat)
        @test size(out_multi) == (2, 3, 2)
        @test 0.0f0 <= out_multi[1, 1, 1] <= 10.0f0
        @test 100.0f0 <= out_multi[2, 1, 1] <= 200.0f0
        # NaN propagation from pft_cube[2, 2]
        @test isnan(out_multi[1, 2, 2])
        @test isnan(out_multi[2, 2, 2])
    end
end
