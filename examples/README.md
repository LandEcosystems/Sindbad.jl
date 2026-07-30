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

Both setups run against the same sample dataset, `synthetic_data_examples.zarr` (205 sites,
one year of daily data), and share the same JSON layout:

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
`https://s3.bgc-jena.mpg.de:9000/sindbad/synthetic_data_examples.zarr`, so no local data or
path override is needed to run either setup.

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
`getObservation` + `optimizeTEM` for an optimization run -- rather than hidden behind a single
convenience call. This is deliberate: every intermediate object (`info`,
`forcing`, `run_helpers`, `observations`, ...) stays defined afterwards, so you can open either
script in the REPL, run it one line at a time, and inspect any of those objects directly. Each
line has a short comment explaining what it produces; see `run_forward.jl` and
`run_optimization.jl` directly for the exact calls.

Both scripts also end with a commented-out one-line equivalent (`runExperimentForward`/
`runExperimentOpti`) -- the convenience wrapper that does the same steps in one call (plus
saving output cubes, and for optimization, a default-vs-optimized loss table).

## Examples report (manual CI)

`.github/workflows/examples_report.yml` is a manually-triggered workflow (`workflow_dispatch`,
run from the Actions tab), pinned to the latest Julia only, that runs on ubuntu, macOS, and
windows runners in parallel. Each OS runs `scripts/simulation_report.jl`, which executes all 8
combinations of `{LUE,WROASTED} x {pixel,spatial} x {forward,optimization}` and writes a CSV of
status, wall time, memory allocated, mean simulated GPP, and (for optimization runs) the total
optimized cost for each. A final `combine` job
downloads all three OSes' CSVs and merges them into one Markdown table (OS and Julia version
included per row) written to the workflow run's job summary, via
`scripts/combine_simulation_reports.jl`.

`simulation_report.jl` also works standalone locally:

```sh
julia --project=examples/scripts examples/scripts/simulation_report.jl
```

which writes `examples/output_simulation_report_<os>.csv` and `.md` (both git-ignored).

The PR template (`.github/PULL_REQUEST_TEMPLATE.md`) includes a checklist item requiring this
report to be run and pasted/linked in the PR whenever the change could affect the example
setups' forward/optimization runs -- reviewers should check for it before approving.
