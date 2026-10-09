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
    makeMockForcingCube(dir; seed=42)

write a small synthetic forcing dataset (Ti × longitude × latitude, plus one purely spatial
variable) to `dir/forcing.zarr` and return its path. Values are drawn inside the bounds set
in `forcing.json` so that the bounds clamping is a no-op on clean data.
"""
function makeMockForcingCube(dir; seed=42)
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
    # stored time first, as the in-memory runner slices pixels assuming that order, the cube runner selects by name
    cubes = Dict{Symbol,Any}(Symbol(k) => YAXArray((time, lon, lat), permutedims(v, (3, 1, 2))) for (k, v) in vars)
    cubes[:f_static] = YAXArray((lon, lat), Float32.(rand(rng, CUBE_N_LON, CUBE_N_LAT)))

    path = joinpath(dir, "forcing.zarr")
    savedataset(Dataset(; cubes...); path=path, driver=:zarr, overwrite=true)
    return path
end

"""
    mockCubeExperiment(dir; spinup=false, lazy=true, output_variables=nothing)

write the synthetic forcing to `dir`, set up the experiment in `CUBE_EXPERIMENT_JSON` with
its output redirected to `dir`, and return `(info, forcing)`.

With `lazy=false` the forcing is loaded in memory (keyed arrays) for the in-memory runner `runTEM!`
instead of the lazy cube runner `runTEMOnCube`.

`output_variables` replaces the output variables of `experiment.json`, as a `Dict` of
`"field.variable" => depth_dimension_or_nothing`. `replace_info` merges dictionaries instead
of replacing them, so in that case the settings are copied to `dir` and edited there.
"""
function mockCubeExperiment(dir; spinup=false, lazy=true, output_variables=nothing)
    forcing_path = makeMockForcingCube(dir)
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
    )
    info = getExperimentInfo(experiment_json; replace_info=replace_info)
    forcing = getForcing(info)
    return info, forcing
end
