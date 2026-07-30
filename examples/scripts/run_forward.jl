using Sindbad

# --------------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------------
# `setup`      : "LUE" or "WROASTED" -- which examples/setups/<setup> to run.
# `mode`       : :pixel   -- run a single site; `forcing.subset.site` is a 1-element vector.
#                :spatial -- run all sites at once; `forcing.subset.site` is a vector of every index.
# `site_index` : which site to use when `mode == :pixel` (1..205).
setup = "LUE"
mode = :pixel
site_index = 1

n_sites = 205
subset_site = mode == :pixel ? [site_index] : collect(1:n_sites)

experiment_json = joinpath(@__DIR__, "..", "setups", setup, "experiment.json")
output_path = joinpath(@__DIR__, "..", "output_$(setup)_forward_$(mode)")

# The setups' forcing.json bakes in a placeholder `data_path` ("examples/data/synthetic_data_examples.zarr").
# Sindbad resolves relative data paths against the SINDBAD_DATA_DEPOT environment variable when
# it is set (see `getAbsDataPath`/`getSindbadDataDepot` in src/Setup/utilsSetup.jl), which may
# already point elsewhere on your machine -- so we override it here with the actual absolute
# path instead of relying on the placeholder.
data_path = joinpath(@__DIR__, "..", "data", "synthetic_data_examples.zarr")

replace_info = Dict{String,Any}(
    "forcing.subset.site" => subset_site,
    "forcing.default_forcing.data_path" => data_path,
    "experiment.model_output.path" => output_path,
)

# --------------------------------------------------------------------------------------
# Run, one building block at a time
#
# This is exactly what `runExperimentForward` (src/Experiment/runExperiment.jl) does
# internally, minus the final call to `saveOutCubes`. Writing it out like this -- rather
# than hiding it behind a helper -- means every intermediate object (`info`, `forcing`,
# `run_helpers`, ...) stays around afterwards, so you can run this file one line at a time
# in the REPL and inspect any of them.
# --------------------------------------------------------------------------------------
info = getExperimentInfo(experiment_json; replace_info=replace_info) # parses and merges the setup's JSON files (experiment/forcing/model_structure/optimization)
forcing = getForcing(info) # loads the forcing cube and applies the `forcing.subset.site` + time-range subsetting
run_helpers = prepTEM(forcing, info) # builds per-location model/output/land state; models come from `info.models.forward`
runTEM!(
    run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing,
    run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info,
)
# `run_helpers.space_output` now holds the forward run's output for every selected site.

# Equivalent one-liner -- also writes the output cubes to `output_path`, which the steps
# above do not do:
# out_forward = runExperimentForward(experiment_json; replace_info=replace_info, log_level=:info)
