using Sindbad
using Test

include(joinpath(@__DIR__, "..", "mock_input", "cube_experiment", "cube_experiment.jl"))

# one value per time step
const SCALAR_OUTPUTS = Dict{String,Any}(
    "fluxes.gpp" => nothing,
    "diagnostics.gpp_f_airT" => nothing,
    "states.ambient_CO2" => nothing,          # copied from the forcing f_ambient_CO2
    "diagnostics.gpp_potential" => nothing,   # εmax * f_PAR
)
const SCALAR_NAMES = Set([:gpp, :gpp_f_airT, :ambient_CO2, :gpp_potential])
# three different extra axes: two pools sized from depth_dimensions, and a vector sized by an integer
const LAYERED_OUTPUTS = Dict{String,Any}(
    "fluxes.gpp" => nothing,
    "diagnostics.gpp_f_airT" => nothing,
    "pools.soilW" => "d_soil",
    "pools.TWS" => "d_tws",
    "diagnostics.gpp_climate_stressors" => 4,  # (f_airT, f_vpd, f_light, f_cloud)
)

import Sindbad.Simulation: splitPixelArgs, cleanPixelForcing, updatePixelModels, fillPixelOutputs!
import Sindbad.SindbadTEM.Processes as SM

@testset "runTEMOnCube pixel helpers" begin

    @testset "splitPixelArgs" begin
        xs = (:out1, :out2, :in1, :in2, :in3)
        outputs, inputs, pixel_parameters = splitPixelArgs(xs, 2, 3)
        @test outputs == (:out1, :out2)
        @test inputs == (:in1, :in2, :in3)
        @test isnothing(pixel_parameters)

        outputs, inputs, pixel_parameters = splitPixelArgs((xs..., :params), 2, 3)
        @test outputs == (:out1, :out2)
        @test inputs == (:in1, :in2, :in3)
        @test pixel_parameters == :params
    end

    @testset "cleanPixelForcing" begin
        clean_data = (;
            data_fill=0.0f0,
            default_info=(; additive_unit_conversion=false, source_to_sindbad_unit=1.0, bounds=nothing),
            num_type=Val{Float64}(),
            vars_info=(;
                f_co2=(; bounds=[200, 500]),
                f_par=(; source_to_sindbad_unit=0.5),
            ))
        inputs = (Float32[300, NaN, 600], [4.0f0, missing])
        loc_forcing = cleanPixelForcing(inputs, (:f_co2, :f_par), clean_data)
        @test keys(loc_forcing) == (:f_co2, :f_par)
        # NaN is filled with 0 and then clamped to the lower bound, 600 is clamped to the upper bound
        @test loc_forcing.f_co2 == [300.0, 200.0, 500.0]
        # missing is filled, the unit conversion of the variable overrides the default one
        @test loc_forcing.f_par == [2.0, 0.0]
        @test eltype(loc_forcing.f_co2) == Float64
        @test eltype(loc_forcing.f_par) == Float64
    end

    @testset "updatePixelModels" begin
        models = (SM.ambientCO2_constant(), SM.gppPotential_Monteith())
        @test updatePixelModels(models, nothing, nothing) === models

        parameter_table = getParameters(models, Float32, "day")
        selected = filter(row -> row.name == :εmax, parameter_table)
        parameter_to_index = getParameterIndices(models, selected)
        updated = updatePixelModels(models, parameter_to_index, [0.5])
        @test updated[2].εmax == 0.5
        # parameters that are not in the table are not changed
        @test updated[1] == models[1]
        @test typeof(updated) == typeof(models)
    end

    @testset "fillPixelOutputs!" begin
        land_time_series = [
            (; fluxes=(; gpp=Float32(t)), pools=(; soilW=Float32[t, 10t, 100t])) for t in 1:4
        ]
        land_out = LandWrapper(land_time_series)
        output_vars = ((:fluxes, :gpp), (:fluxes, :gpp), (:pools, :soilW), (:pools, :soilW))
        # time is the first dimension, followed by layers and singleton dimensions
        outputs = (zeros(Float32, 4), zeros(Float32, 4, 1), zeros(Float32, 4, 3), zeros(Float32, 4, 3, 1))
        fillPixelOutputs!(outputs, land_out, output_vars)
        @test outputs[1] == Float32[1, 2, 3, 4]
        @test vec(outputs[2]) == Float32[1, 2, 3, 4]
        @test outputs[3] == Float32[1 10 100; 2 20 200; 3 30 300; 4 40 400]
        @test dropdims(outputs[4]; dims=3) == outputs[3]
    end
end

@testset "runTEMOnCube" begin

    @testset "mock cube experiment setup" begin
        info, forcing = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS)
        @test info.helpers.run.run_lazy isa Sindbad.Types.DoRunLazy
        @test info.helpers.run.spinup_TEM isa Sindbad.Types.DoNotSpinupTEM
        @test forcing.variables == (:f_ambient_CO2, :f_PAR, :f_rg, :f_rg_pot, :f_airT_day, :f_VPD_day, :f_static)
        # every spatiotemporal input keeps only time per pixel, the purely spatial one keeps nothing
        @test forcing.dims == (ntuple(_ -> (:Ti,), 6)..., ())
        @test all(c -> c isa YAXArray, forcing.data)
    end

    @testset "runTEMYax (reference) with scalar outputs" begin
        info, forcing = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS)
        ds = runTEMYax(info.models.forward, forcing, info)
        @test ds isa Dataset
        @test Set(keys(ds.cubes)) == SCALAR_NAMES
        for name in SCALAR_NAMES
            cube = ds.cubes[name]
            @test DD.name(DD.dims(cube)) == (:Ti, :longitude, :latitude)
            @test size(cube) == (365, CUBE_N_LON, CUBE_N_LAT)
            # the NaN put in the forcing is filled by cleanData, so no pixel is lost
            @test all(isfinite, cube[:, :, :])
        end
        @test all(0 .<= ds.cubes[:gpp_f_airT][:, :, :] .<= 1)
        @test all(ds.cubes[:gpp][:, :, :] .>= 0)
    end

    @testset "runTEMYax (reference) with layered outputs" begin
        # getOutDims puts the layer axis before time, (d_soil, Ti), while fillOutputYax
        # writes as if time came first, so any per-layer output fails with a DimensionMismatch
        # xmap is lazy, the error only shows up once the cube is read
        info, forcing = mockCubeExperiment(mktempdir(); output_variables=LAYERED_OUTPUTS)
        ds = runTEMYax(info.models.forward, forcing, info)
        @test ds isa Dataset
        @test_broken try
            all(isfinite, readcubedata(ds.cubes[:soilW]))
        catch err
            err isa DimensionMismatch || rethrow()
            false
        end
    end

    # reads every output cube of a Dataset into memory
    readOutputs(ds) = Dict(k => readcubedata(ds.cubes[k]) for k in keys(ds.cubes))
    sameOutputs(a, b) = keys(a) == keys(b) && all(k -> DD.dims(a[k]) == DD.dims(b[k]) && a[k].data == b[k].data, keys(a))

    # a parameter cube with the spatial axes of the forcing and the default values of `parameter_table` in every pixel
    function defaultParameterCube(forcing, parameter_table)
        space = DD.dims(first(forcing.data), (:longitude, :latitude))
        parameter = DD.Dim{:parameter}(string.(collect(parameter_table.name)))
        values = repeat(Float32.(collect(parameter_table.default)), 1, length.(space)...)
        return YAXArray((parameter, space...), values)
    end

    info, forcing = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS)
    models = info.models.forward
    reference = readOutputs(runTEMYax(models, forcing, info))
    plain = readOutputs(runTEMOnCube(models, forcing, info))
    parameter_table = filter(row -> row.name in (:εmax, :opt_airT),
        getParameters(models, info.helpers.numbers.num_type, info.helpers.dates.temporal_resolution))

    @testset "runTEMOnCube matches runTEMYax" begin
        @test Set(keys(plain)) == SCALAR_NAMES
        @test sameOutputs(plain, reference)
    end

    # a forcing variable as an array with the axes of the scalar outputs, (Ti, longitude, latitude)
    forcingArray(forcing, name) = permutedims(readcubedata(forcing.data[findfirst(==(name), forcing.variables)]), (:Ti, :longitude, :latitude)).data

    @testset "runTEMOnCube outputs follow the forcing" begin
        # ambient_CO2 is the forcing itself, so every pixel and time step must land in its place
        @test plain[:ambient_CO2].data == forcingArray(forcing, :f_ambient_CO2)
        # gpp_potential = εmax * f_PAR, with the default εmax of 1
        @test only(unique(collect(parameter_table.default)[parameter_table.name .== :εmax])) == 1
        @test plain[:gpp_potential].data == forcingArray(forcing, :f_PAR)
    end

    @testset "runTEMOnCube with layered outputs" begin
        info_l, forcing_l = mockCubeExperiment(mktempdir(); output_variables=LAYERED_OUTPUTS)
        layered = readOutputs(runTEMOnCube(info_l.models.forward, forcing_l, info_l))
        @test Set(keys(layered)) == Set([:gpp, :gpp_f_airT, :soilW, :TWS, :gpp_climate_stressors])
        extra_axes = (d_soil=3, d_tws=3, gpp_climate_stressors_idx=4)
        own_axis = (gpp=nothing, gpp_f_airT=nothing, soilW=:d_soil, TWS=:d_tws, gpp_climate_stressors=:gpp_climate_stressors_idx)
        for (name, cube) in layered
            names = DD.name(DD.dims(cube))
            # time first, then the variable's own axis, then singletons of the other extra axes, then space
            @test first(names) == :Ti
            @test names[end-1:end] == (:longitude, :latitude)
            @test Set(names) == Set((:Ti, keys(extra_axes)..., :longitude, :latitude))
            isnothing(own_axis[name]) || @test names[2] == own_axis[name]
            for (axis, n) in pairs(extra_axes)
                @test size(cube, axis) == (axis == own_axis[name] ? n : 1)
            end
        end

        # every cube in the same axis order, (Ti, d_soil, d_tws, gpp_climate_stressors_idx, longitude, latitude)
        canonical(name) = permutedims(layered[name], (:Ti, keys(extra_axes)..., :longitude, :latitude)).data
        soilW = canonical(:soilW)[:, :, 1, 1, :, :]
        TWS = canonical(:TWS)[:, 1, :, 1, :, :]
        stressors = canonical(:gpp_climate_stressors)[:, 1, 1, :, :, :]
        gpp_f_airT = canonical(:gpp_f_airT)[:, 1, 1, 1, :, :]
        pixels = ((t, i, j) for t in 1:365, i in 1:CUBE_N_LON, j in 1:CUBE_N_LAT)
        # no model changes water, so every time step of every pixel keeps the initial layers
        @test all(soilW[t, :, i, j] == info_l.helpers.land_init.pools.soilW for (t, i, j) in pixels)
        @test all(TWS[t, :, i, j] == info_l.helpers.land_init.pools.TWS for (t, i, j) in pixels)
        # the first stressor is the temperature scalar, so the vector lands on the right axis in the right order
        @test stressors[:, 1, :, :] == gpp_f_airT
        @test all(0 .<= stressors .<= 1)
        # the singleton axes do not change the values
        @test canonical(:gpp)[:, 1, 1, 1, :, :] == plain[:gpp].data
        @test gpp_f_airT == plain[:gpp_f_airT].data
    end

    @testset "runTEMOnCube with a single output variable" begin
        # xmap returns the cube itself instead of a tuple for a single output
        info_s, forcing_s = mockCubeExperiment(mktempdir(); output_variables=Dict{String,Any}("fluxes.gpp" => nothing))
        single = readOutputs(runTEMOnCube(info_s.models.forward, forcing_s, info_s))
        @test collect(keys(single)) == [:gpp]
        @test single[:gpp].data == plain[:gpp].data
    end

    @testset "runTEMOnCube with default parameters in every pixel" begin
        parameter_cube = defaultParameterCube(forcing, parameter_table)
        with_parameters = readOutputs(runTEMOnCube(models, forcing, info, parameter_cube, parameter_table))
        # same axes as without parameters, the parameter axis is dropped
        @test sameOutputs(with_parameters, plain)
        # the deprecated entry point forwards to runTEMOnCube
        deprecated = readOutputs(Sindbad.Simulation.runTEMYaxParameters(models, forcing, parameter_cube, parameter_table, info))
        @test sameOutputs(deprecated, plain)
    end

    @testset "runTEMOnCube with a parameter changed in one pixel" begin
        parameter_cube = defaultParameterCube(forcing, parameter_table)
        i_εmax = findfirst(==(:εmax), parameter_table.name)
        pixel = (1, 2)
        parameter_cube.data[i_εmax, pixel...] *= 2
        changed = readOutputs(runTEMOnCube(models, forcing, info, parameter_cube, parameter_table))
        others = [(i, j) for i in 1:CUBE_N_LON, j in 1:CUBE_N_LAT if (i, j) != pixel]
        @test all(changed[:gpp][:, i, j] == plain[:gpp][:, i, j] for (i, j) in others)
        @test changed[:gpp][:, pixel...] != plain[:gpp][:, pixel...]
        # gpp_potential = εmax * f_PAR doubles exactly in that pixel
        @test changed[:gpp_potential][:, pixel...] == 2 .* plain[:gpp_potential][:, pixel...]
        @test all(changed[:gpp_potential][:, i, j] == plain[:gpp_potential][:, i, j] for (i, j) in others)
        # εmax enters neither the temperature scalar nor the forcing
        @test changed[:gpp_f_airT].data == plain[:gpp_f_airT].data
        @test changed[:ambient_CO2].data == plain[:ambient_CO2].data
    end

    @testset "runTEMOnCube matches runTEMYax with spinup" begin
        info_sp, forcing_sp = mockCubeExperiment(mktempdir(); spinup=true, output_variables=SCALAR_OUTPUTS)
        @test info_sp.helpers.run.spinup_TEM isa Sindbad.Types.DoSpinupTEM
        reference_sp = readOutputs(runTEMYax(info_sp.models.forward, forcing_sp, info_sp))
        plain_sp = readOutputs(runTEMOnCube(info_sp.models.forward, forcing_sp, info_sp))
        @test sameOutputs(plain_sp, reference_sp)
    end
end
