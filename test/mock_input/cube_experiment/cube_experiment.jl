# Minimal cube experiment: a synthetic forcing dataset written to a temporary zarr store
# plus the JSON settings next to this file. Nothing is read from disk or the network
# besides what is generated here.
using Dates
using Random
using YAXArrays
using Zarr
using DimensionalData: DimensionalData as DD

const CUBE_EXPERIMENT_JSON = joinpath(@__DIR__, "experiment.json")
const CUBE_N_LON = 2
const CUBE_N_LAT = 3
# pixel (lon, lat) that receives a NaN in its forcing to check that cleaning fills it
const CUBE_NAN_PIXEL = (2, 1)

"""
    makeMockForcingCube(dir; seed=42, all_nan_pixel=nothing)

write a small synthetic forcing dataset (Ti × longitude × latitude, plus one purely spatial
variable) to `dir/forcing.zarr` and return its path. Values are drawn inside the bounds set
in `forcing.json` so that the bounds clamping is a no-op on clean data.

With `all_nan_pixel`, a (lon, lat) index, every spatiotemporal variable of that pixel is NaN.
"""
function makeMockForcingCube(dir; seed=42, all_nan_pixel=nothing)
    rng = MersenneTwister(seed)
    lon = DD.Dim{:longitude}(range(10.0, step=0.5, length=CUBE_N_LON))
    lat = DD.Dim{:latitude}(range(50.0, step=0.5, length=CUBE_N_LAT))
    time = DD.Ti(DateTime(2015, 1, 1):Day(1):DateTime(2015, 12, 31))
    nt = length(time)
    doy = reshape(1:nt, 1, 1, nt)
    seasonal = @. 0.5 * (1 - cos(2π * doy / 365))
    spatiotemporal(lo, hi) = Float32.(lo .+ (hi - lo) .* clamp.(0.8 .* seasonal .+ 0.2 .* rand(rng, CUBE_N_LON, CUBE_N_LAT, nt), 0, 1))

    rg_pot = spatiotemporal(10.0, 40.0)
    rg = rg_pot .* Float32.(0.3 .+ 0.6 .* rand(rng, CUBE_N_LON, CUBE_N_LAT, nt))
    vars = Dict(
        "f_ambient_CO2" => spatiotemporal(390.0, 410.0),
        "f_PAR" => 0.5f0 .* rg,
        "f_rg" => rg,
        "f_rg_pot" => rg_pot,
        "f_airT_day" => spatiotemporal(-5.0, 30.0),
        "f_VPD_day" => spatiotemporal(0.1, 3.0),
    )
    vars["f_airT_day"][CUBE_NAN_PIXEL..., 10] = NaN32
    if !isnothing(all_nan_pixel)
        foreach(v -> v[all_nan_pixel..., :] .= NaN32, values(vars))
    end
    # stored time first, as the in-memory runner slices pixels assuming that order, the cube runner selects by name
    cubes = Dict{Symbol,Any}(Symbol(k) => YAXArray((time, lon, lat), permutedims(v, (3, 1, 2))) for (k, v) in vars)
    cubes[:f_static] = YAXArray((lon, lat), Float32.(rand(rng, CUBE_N_LON, CUBE_N_LAT)))

    path = joinpath(dir, "forcing.zarr")
    savedataset(Dataset(; cubes...); path=path, driver=:zarr, overwrite=true)
    return path
end

"""
    makeMockParameterCube(dir, forcing_path, parameter_values; parameter_attributes=Dict{String,Any}())

write the parameters per location to `dir/parameters.zarr` and return its path. 

`parameter_values` maps the name of a parameter variable, `<model>__<name>`, to a
(longitude, latitude) matrix of values in run units and within bounds. The coordinates are
those of the forcing in `forcing_path`. `parameter_attributes` are added to the attributes of
every variable.
"""
function makeMockParameterCube(dir, forcing_path, parameter_values; parameter_attributes=Dict{String,Any}())
    forcing_ds = open_dataset(forcing_path)
    lon = DD.dims(forcing_ds.f_static, :longitude)
    lat = DD.dims(forcing_ds.f_static, :latitude)
    cubes = Dict{Symbol,Any}(map(collect(parameter_values)) do (k, v)
        model, name = split(k, "__")
        # a parameter file given directly only uses the variables with these attributes
        Symbol(k) => YAXArray((lon, lat), Float32.(v), Dict{String,Any}("model" => model, "name" => name, parameter_attributes...))
    end)
    path = joinpath(dir, "parameters.zarr")
    savedataset(Dataset(; cubes...); path=path, driver=:zarr, overwrite=true)
    return path
end

"""
    mockCubeExperiment(dir; spinup=false, lazy=true, output_variables=nothing, parameter_values=nothing, parameter_attributes=Dict{String,Any}(), all_nan_pixel=nothing, filter_nan_pixels=false)

write the synthetic forcing to `dir`, set up the experiment in `CUBE_EXPERIMENT_JSON` with
its output redirected to `dir`, and return `(info, forcing)`.

With `lazy=false` the forcing is loaded in memory (keyed arrays) for the in-memory runner `runTEM!`
instead of the lazy cube runner `runTEMYax`.

`output_variables` replaces the output variables of `experiment.json`, as a `Dict` of
`"field.variable" => depth_dimension_or_nothing`. `replace_info` merges dictionaries instead
of replacing them, so in that case the settings are copied to `dir` and edited there.

`parameter_values` and `parameter_attributes`, see `makeMockParameterCube`, set the parameters per location from a
zarr file given as the `parameters` config file. `all_nan_pixel` is passed to
`makeMockForcingCube`.
"""
function mockCubeExperiment(dir; spinup=false, lazy=true, output_variables=nothing, parameter_values=nothing, parameter_attributes=Dict{String,Any}(), all_nan_pixel=nothing, filter_nan_pixels=false)
    forcing_path = makeMockForcingCube(dir; all_nan_pixel=all_nan_pixel)
    experiment_json = CUBE_EXPERIMENT_JSON
    if !isnothing(output_variables)
        settings_dir = mkpath(joinpath(dir, "settings"))
        for f in readdir(@__DIR__)
            endswith(f, ".json") && cp(joinpath(@__DIR__, f), joinpath(settings_dir, f); force=true)
        end
        experiment_json = joinpath(settings_dir, "experiment.json")
        settings = Sindbad.Setup.parsefile(experiment_json; dicttype=Sindbad.Setup.DataStructures.OrderedDict)
        settings["model_output"]["variables"] = output_variables
        open(io -> Sindbad.Setup.json_print(io, settings, 2), experiment_json, "w")
    end
    replace_info = Dict(
        "forcing.default_forcing.data_path" => forcing_path,
        "experiment.model_output.path" => dir,
        "experiment.flags.spinup_TEM" => spinup,
        "experiment.flags.run_lazy" => lazy,
        "experiment.flags.filter_nan_pixels" => filter_nan_pixels,
    )
    if !isnothing(parameter_values)
        replace_info["experiment.basics.config_files.parameters"] = makeMockParameterCube(dir, forcing_path, parameter_values; parameter_attributes=parameter_attributes)
    end
    info = getExperimentInfo(experiment_json; replace_info=replace_info)
    forcing = getForcing(info)
    return info, forcing
end
