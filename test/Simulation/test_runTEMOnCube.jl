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
# the parameters per location used in the tests, at their defaults
const DEFAULT_PARAMETERS = Dict(
    "gppPotential__εmax" => fill(1.0, CUBE_N_LON, CUBE_N_LAT),
    "gppAirT__opt_airT" => fill(25.0, CUBE_N_LON, CUBE_N_LAT),
)

import Sindbad.Simulation: unpackYaxForward, setLocationParametersYax, fillOutputYax
import Sindbad.SindbadTEM.Processes as SM

@testset "runTEMYax pixel helpers" begin

    @testset "unpackYaxForward" begin
        xs = (:out1, :out2, :res1, :in1, :in2, :in3, :p1, :p2)
        outputs, inputs, restarts, parameter_inputs = unpackYaxForward(xs; output_vars=(1, 2), forcing_vars=(1, 2, 3), restart_vars=(1,))
        @test outputs == (:out1, :out2)
        @test restarts == (:res1,)
        @test inputs == (:in1, :in2, :in3)
        @test parameter_inputs == (:p1, :p2)

        outputs, inputs, restarts, parameter_inputs = unpackYaxForward(xs[[1, 2, 4, 5, 6]]; output_vars=(1, 2), forcing_vars=(1, 2, 3))
        @test isempty(restarts)
        @test inputs == (:in1, :in2, :in3)
        @test isempty(parameter_inputs)
    end

    @testset "setLocationParametersYax" begin
        models = (SM.ambientCO2_constant(), SM.gppPotential_Monteith())
        @test setLocationParametersYax(models, nothing, ()) === models

        parameter_table = Sindbad.Setup.getParameters(models, Float32, "day")
        selected = filter(row -> row.name == :εmax, parameter_table)
        parameter_to_index = getParameterIndices(models, selected)
        # xmap passes the value of a location as an array without dimensions
        updated = setLocationParametersYax(models, parameter_to_index, (fill(0.5f0),))
        @test updated[2].εmax == 0.5f0
        # parameters that are not in the table are not changed
        @test updated[1] == models[1]
        @test typeof(updated) == typeof(models)
    end

    @testset "fillOutputYax" begin
        xin = [Float32[t, 10t, 100t] for t in 1:4]
        # time is the first dimension, followed by the layers and singleton dimensions
        xout = zeros(Float32, 4, 3, 1)
        fillOutputYax(xout, xin, (:pools, :soilW))
        @test xout[:, :, 1] == Float32[1 10 100; 2 20 200; 3 30 300; 4 40 400]

        scalar_in = [Float32[t] for t in 1:4]
        scalar_out = zeros(Float32, 4, 1)
        fillOutputYax(scalar_out, scalar_in, (:fluxes, :gpp))
        @test vec(scalar_out) == Float32[1, 2, 3, 4]

        # the number of layers of the output must match the land
        @test_throws Exception fillOutputYax(zeros(Float32, 4, 2), xin, (:pools, :soilW))
    end
end

@testset "runTEMYax" begin

    # reads every output cube of a Dataset into memory
    readOutputs(ds) = Dict(k => readcubedata(ds.cubes[k]) for k in keys(ds.cubes))
    sameOutputs(a, b) = keys(a) == keys(b) && all(k -> DD.dims(a[k]) == DD.dims(b[k]) && isequal(a[k].data, b[k].data), keys(a))

    # the same experiment run by the in-memory runner, runTEM! on keyed arrays, as an independent reference.
    # Its outputs are (Ti, layer or 1, longitude, latitude) arrays, and its restart arrays (1, layer, longitude, latitude).
    function inMemoryRun(output_variables; kwargs...)
        info_m, forcing_m = mockCubeExperiment(mktempdir(); lazy=false, output_variables=output_variables, kwargs...)
        @test info_m.helpers.run.run_lazy isa Sindbad.Types.DoNotRunLazy
        run_m = Sindbad.Experiment.runForward(info_m.models.forward, forcing_m, info_m, Sindbad.Types.DoNotRunLazy())
        restart = Dict(last(v) => d for (v, d) in zip(run_m.restart.variables, run_m.restart.data))
        return (; output=Dict(pairs(run_m.output)), restart=restart)
    end
    # dropping the singleton axes of a cube gives the in-memory layout
    sameAsInMemory(cubes, in_memory) = keys(cubes) == keys(in_memory) &&
        all(k -> length(cubes[k]) == length(in_memory[k]) && reshape(cubes[k].data, size(in_memory[k])) == in_memory[k], keys(cubes))

    info, forcing = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS)
    models = info.models.forward
    run = runTEMYax(models, forcing, info)
    plain = readOutputs(run.output)

    @testset "mock cube experiment setup" begin
        @test info.helpers.run.run_lazy isa Sindbad.Types.DoRunLazy
        @test info.helpers.run.spinup_TEM isa Sindbad.Types.DoNotSpinupTEM
        @test forcing.variables == (:f_ambient_CO2, :f_PAR, :f_rg, :f_rg_pot, :f_airT_day, :f_VPD_day, :f_static)
        # every spatiotemporal input keeps only time per pixel, the purely spatial one keeps nothing
        @test forcing.dims == (ntuple(_ -> (:Ti,), 6)..., ())
        @test isnothing(forcing.parameters)
    end

    @testset "a lazy run does not load the cubes" begin
        # the forcing stays on disk, it is cleaned per pixel in TEMYax
        @test all(c -> c isa YAXArray && !(c.data isa Array), forcing.data)
        # prepTEM of a lazy run has no per location data, models or spinup
        run_helpers = prepTEM(forcing, info)
        @test !hasproperty(run_helpers, :space_selected_models)
        @test !hasproperty(run_helpers, :space_forcing)
        @test !hasproperty(run_helpers, :space_ind)
    end

    @testset "runTEMYax with scalar outputs" begin
        @test Set(keys(plain)) == SCALAR_NAMES
        for name in SCALAR_NAMES
            @test DD.name(DD.dims(plain[name])) == (:Ti, :longitude, :latitude)
            @test size(plain[name]) == (365, CUBE_N_LON, CUBE_N_LAT)
            # the NaN put in the forcing is filled by cleanData, so no pixel is lost
            @test all(isfinite, plain[name])
        end
        @test all(0 .<= plain[:gpp_f_airT] .<= 1)
        @test all(plain[:gpp] .>= 0)
    end

    in_memory = inMemoryRun(SCALAR_OUTPUTS)

    @testset "runTEMYax matches the in-memory runner" begin
        @test sameAsInMemory(plain, in_memory.output)
    end

    @testset "runTEMYax restart matches the in-memory runner" begin
        restart = readOutputs(run.restart)
        @test run.restart_vars == ((:pools, :TWS),)
        @test run.spinup_mode == "none"
        # without spinup the restart holds the initial pools of every pixel
        # the layers of a pool are its first dimension, and there is no time dimension
        @test DD.name(DD.dims(restart[:TWS]))[2:end] == (:longitude, :latitude)
        @test size(restart[:TWS]) == (length(info.helpers.land_init.pools.TWS), CUBE_N_LON, CUBE_N_LAT)
        @test all(restart[:TWS][:, i, j] == info.helpers.land_init.pools.TWS for i in 1:CUBE_N_LON, j in 1:CUBE_N_LAT)
        @test sameAsInMemory(restart, in_memory.restart)
    end

    @testset "runForward in lazy mode runs runTEMYax" begin
        lazy_run = Sindbad.Experiment.runForward(models, forcing, info, Sindbad.Types.DoRunLazy())
        @test sameOutputs(readOutputs(lazy_run.output), plain)
        @test sameOutputs(readOutputs(lazy_run.restart.dataset), readOutputs(run.restart))
        @test lazy_run.restart.variables == run.restart_vars
    end

    # a forcing variable as an array with the axes of the scalar outputs, (Ti, longitude, latitude)
    forcingArray(forcing, name) = permutedims(readcubedata(forcing.data[findfirst(==(name), forcing.variables)]), (:Ti, :longitude, :latitude)).data

    @testset "runTEMYax outputs follow the forcing" begin
        # ambient_CO2 is the forcing itself, so every pixel and time step must land in its place
        @test plain[:ambient_CO2].data == forcingArray(forcing, :f_ambient_CO2)
        # gpp_potential = εmax * f_PAR, with the default εmax of 1
        @test models[findfirst(m -> m isa SM.gppPotential_Monteith, models)].εmax == 1
        @test plain[:gpp_potential].data == forcingArray(forcing, :f_PAR)
    end

    @testset "runTEMYax with layered outputs" begin
        info_l, forcing_l = mockCubeExperiment(mktempdir(); output_variables=LAYERED_OUTPUTS)
        layered = readOutputs(runTEMYax(info_l.models.forward, forcing_l, info_l).output)
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
        # same values and layer order as the in-memory runner
        @test sameAsInMemory(layered, inMemoryRun(LAYERED_OUTPUTS).output)
    end

    @testset "runTEMYax with a single output variable" begin
        # xmap returns the cube itself instead of a tuple for a single output
        info_s, forcing_s = mockCubeExperiment(mktempdir(); output_variables=Dict{String,Any}("fluxes.gpp" => nothing))
        single = readOutputs(runTEMYax(info_s.models.forward, forcing_s, info_s).output)
        @test collect(keys(single)) == [:gpp]
        @test single[:gpp].data == plain[:gpp].data
    end

    @testset "runTEMYax matches the in-memory runner with spinup" begin
        info_sp, forcing_sp = mockCubeExperiment(mktempdir(); spinup=true, output_variables=SCALAR_OUTPUTS)
        @test info_sp.helpers.run.spinup_TEM isa Sindbad.Types.DoSpinupTEM
        run_sp = runTEMYax(info_sp.models.forward, forcing_sp, info_sp)
        in_memory_sp = inMemoryRun(SCALAR_OUTPUTS; spinup=true)
        @test sameAsInMemory(readOutputs(run_sp.output), in_memory_sp.output)
        @test sameAsInMemory(readOutputs(run_sp.restart), in_memory_sp.restart)
    end

    @testset "parameters per location" begin
        info_p, forcing_p = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS, parameter_values=DEFAULT_PARAMETERS)

        @testset "the parameter cubes are not loaded" begin
            @test Set(forcing_p.parameters.variables) == Set(Symbol.(keys(DEFAULT_PARAMETERS)))
            @test all(c -> c isa YAXArray && !(c.data isa Array), forcing_p.parameters.data)
            @test all(c -> DD.name(DD.dims(c)) == (:longitude, :latitude), forcing_p.parameters.data)
            # the values are not checked in a lazy run
            @test all(ismissing, forcing_p.parameters.parameter_table.n_nan)
            @test all(ismissing, forcing_p.parameters.parameter_table.n_clamped)
        end

        @testset "with default parameters in every pixel" begin
            with_parameters = readOutputs(runTEMYax(info_p.models.forward, forcing_p, info_p).output)
            @test sameOutputs(with_parameters, plain)
        end

        @testset "with a parameter changed in one pixel" begin
            pixel = (1, 2)
            parameter_values = deepcopy(DEFAULT_PARAMETERS)
            parameter_values["gppPotential__εmax"][pixel...] = 2.0
            info_c, forcing_c = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS, parameter_values=parameter_values)
            changed = readOutputs(runTEMYax(info_c.models.forward, forcing_c, info_c).output)
            others = [(i, j) for i in 1:CUBE_N_LON, j in 1:CUBE_N_LAT if (i, j) != pixel]
            @test all(changed[:gpp][:, i, j] == plain[:gpp][:, i, j] for (i, j) in others)
            @test changed[:gpp][:, pixel...] != plain[:gpp][:, pixel...]
            # gpp_potential = εmax * f_PAR doubles exactly in that pixel
            @test changed[:gpp_potential][:, pixel...] == 2 .* plain[:gpp_potential][:, pixel...]
            @test all(changed[:gpp_potential][:, i, j] == plain[:gpp_potential][:, i, j] for (i, j) in others)
            # εmax enters neither the temperature scalar nor the forcing
            @test changed[:gpp_f_airT].data == plain[:gpp_f_airT].data
            @test changed[:ambient_CO2].data == plain[:ambient_CO2].data
            # same as the in-memory runner with the same parameters per location
            @test sameAsInMemory(changed, inMemoryRun(SCALAR_OUTPUTS; parameter_values=parameter_values).output)
        end

        @testset "values that are not in run units are refused" begin
            # values for another time step would need a conversion, which a lazy run does not do
            @test_throws ErrorException mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS,
                parameter_values=DEFAULT_PARAMETERS, parameter_attributes=Dict{String,Any}("timescale_run" => "hour"))
        end
    end

    @testset "all-NaN pixels" begin
        nan_pixel = (2, 3)
        others = [(i, j) for i in 1:CUBE_N_LON, j in 1:CUBE_N_LAT if (i, j) != nan_pixel]

        @testset "are run with filled forcing without filter_nan_pixels" begin
            info_n, forcing_n = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS, all_nan_pixel=nan_pixel)
            kept = readOutputs(runTEMYax(info_n.models.forward, forcing_n, info_n).output)
            @test all(all(isfinite, kept[k]) for k in keys(kept))
            @test all(kept[:gpp][:, i, j] == plain[:gpp][:, i, j] for (i, j) in others)
        end

        @testset "are skipped with filter_nan_pixels" begin
            info_f, forcing_f = mockCubeExperiment(mktempdir(); output_variables=SCALAR_OUTPUTS, all_nan_pixel=nan_pixel, filter_nan_pixels=true)
            run_f = runTEMYax(info_f.models.forward, forcing_f, info_f)
            skipped = readOutputs(run_f.output)
            for k in keys(skipped)
                @test all(isnan, skipped[k][:, nan_pixel...])
                @test all(skipped[k][:, i, j] == plain[k][:, i, j] for (i, j) in others)
            end
            restart_f = readOutputs(run_f.restart)
            @test all(isnan, restart_f[:TWS][:, nan_pixel...])
            @test all(restart_f[:TWS][:, i, j] == info_f.helpers.land_init.pools.TWS for (i, j) in others)
        end
    end
end
