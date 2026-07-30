# Examples

This part of the repo is being trimmed down to a small, canonical set of examples that always
runs against the currently released Sindbad.jl. Individual research experiments are moving out
to their own repos over time.

- `setups/` -- model + data configuration for each example model structure.
- `scripts/` -- runnable workflows (data prep, forward run, optimization run) that operate on
  any setup in `setups/`.
- `exp_*` folders -- pre-existing, per-project experiments from before this reorganization.
  They are untouched for now and will be migrated or removed in a follow-up change; don't take
  them as the current template for new examples -- use `setups/`/`scripts/` instead.

## Setups

Both setups run against the same 2015-only, 205-site FLUXNET-derived dataset (see
[Data](#data) below) and share the same JSON layout:

- `experiment.json` -- top-level experiment definition: which other config files to use, the
  domain/name/date range, execution flags, spinup sequence, and requested output variables.
- `forcing.json` -- the forcing variables the model reads, each mapped to a `source_variable`
  in the data cube (with units/bounds/conversion).
- `model_structure.json`/`model_structure_LUE.json` -- which modeling approach is selected for
  each process.
- `optimization.json` -- which model parameters are optimized, against which
  `observational_constraints`, and with which cost settings.
- `CMAEvolutionStrategy_CMAES.json` -- the CMA-ES optimizer settings (`maxfevals: 100` in both,
  so example optimization runs finish quickly rather than converging).

**`setups/LUE`**: a minimal GPP-only model (light-use-efficiency approach). Optimizes 6
parameters against `gpp` alone.

**`setups/WROASTED`**: a full carbon+water cycle model (vegetation, soil, snow, runoff, carbon
pools and allocation). Optimizes ~34 parameters against `gpp`, `nee`, `reco`, `transpiration`,
`evapotranspiration`, `agb`, and `ndvi`.

Both setups' `forcing.json`/`optimization.json` point `data_path` at
`examples/data/synthetic_data_examples.zarr` -- this is a **local-only placeholder path**. The
run scripts (below) override it at runtime with the resolved absolute path, since Sindbad
resolves relative data paths against the `SINDBAD_DATA_DEPOT` environment variable when it's
set, which may point elsewhere on your machine. Once this derived dataset is uploaded to the
sindbad S3 bucket, both setups will be updated to read it directly from there instead.

## Data

`scripts/derive_example_data.jl` derives `examples/data/synthetic_data_examples.zarr` -- the
dataset both setups run against -- from the full
`FLUXNET_v2023_12_1D_REPLACED_Noise003_v1.zarr` cube (205 sites x ~39 years, daily). It:

1. Slices the cube down to calendar year 2015.
2. Keeps only the 25 variables actually referenced (as `source_variable`) by the two setups'
   `forcing.json` and the *active* `observational_constraints` in their `optimization.json`.

That second step matters: the raw (non-gap-filled) FLUXNET tower variables and their
`_QC*`/`_RANDUNC` companions are excluded on purpose. Real tower observation coverage in this
cube ends around 2014 -- every `_QC*`/`_RANDUNC` variable is 100% `NaN` for 2015 regardless of
site, which is also why both setups set `use_quality_flag`/`use_uncertainty: false` in
`optimization.json`. What's left is a small (25-variable), gap-free dataset.

To (re-)run it:

```sh
SINDBAD_TUTORIALS_DATA_DEPOT=/path/to/dir/containing/FLUXNET_v2023_12_1D_REPLACED_Noise003_v1.zarr \
  julia --project=examples/scripts examples/scripts/derive_example_data.jl
```

`examples/data/` is git-ignored -- the derived file is meant to be regenerated locally, not
committed.

## Running the scripts

Both scripts share the same three config variables at the top of the file:

- `setup` -- `"LUE"` or `"WROASTED"`.
- `mode` -- `:pixel` (single site; `forcing.subset.site` becomes a 1-element vector) or
  `:spatial` (all 205 sites at once; `forcing.subset.site` becomes a vector of every index).
- `site_index` -- which site to use when `mode == :pixel`.

Edit those three lines and run the file:

```sh
julia --project=examples/scripts examples/scripts/run_forward.jl
julia --project=examples/scripts examples/scripts/run_optimization.jl
```

For example, to run WROASTED's optimization jointly across all sites, set `setup = "WROASTED"`
and `mode = :spatial` at the top of `run_optimization.jl` before running it.

## Calling the inner functions yourself

Both scripts are written as a flat sequence of calls -- `getExperimentInfo`/`getForcing` (or
`prepExperiment`, which does both), then `prepTEM`/`runTEM!` for a forward run, or
`getObservation` + `optimizeTEMYax`/`optimizeTEM` for an optimization run -- rather than hidden
behind a single convenience call. This is deliberate: every intermediate object (`info`,
`forcing`, `run_helpers`, `observations`, ...) stays defined afterwards, so you can open either
script in the REPL, run it one line at a time, and inspect any of those objects directly. Each
line has a short comment explaining what it produces; see `run_forward.jl` and
`run_optimization.jl` directly for the exact calls.

Both scripts also end with a commented-out one-line equivalent (`runExperimentForward`/
`runExperimentOpti`) -- the convenience wrapper that does the same steps in one call (plus
saving output cubes, and for optimization, a default-vs-optimized loss table).
