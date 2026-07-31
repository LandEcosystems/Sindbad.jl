# tools/benchmark/

A small self-contained tool for comparing Sindbad's runtime performance across
different Julia versions *before* switching your default Julia version. It grew
out of investigating a suspected Julia 1.11 -> 1.12 regression in the parameter
optimization loop (see the `sk/julia_version` branch history) and turned out to be
generally useful, so it lives here as a standing tool rather than a one-off script.

It benchmarks the actual call cascade an optimization run exercises on every
function evaluation:

```
cost_function(x)              # the closure the optimizer calls each eval
└── cost(...)
    ├── updateModels          # apply the optimizer's parameter vector to the models
    ├── runTEM!                # run the forward/spinup simulation
    ├── metricVector
    │   ├── getData
    │   │   └── getHarmonizedData
    │   ├── getDataWithoutNaN
    │   └── metric
    └── combineMetric
```

If the given experiment isn't configured for optimization (no observations/cost
options), it falls back to benchmarking `prepTEM` + `runTEM!` alone.

## Files

- `compare_julia_versions.jl` — the driver you run. Takes an experiment JSON and a
  list of Julia versions, runs the benchmark under each, and writes a side-by-side
  Markdown comparison table.
- `cascade_bench_worker.jl` — runs inside a single Julia process (invoked by the
  driver once per version); you shouldn't need to run this directly.
- `.jlbench_envs/` — created automatically, gitignored. One throwaway Pkg
  environment per Julia version tested, dev-linked to this checkout of Sindbad.
  Kept separate from your real environment and from each other, since a
  `Manifest.toml` resolved under one Julia version can become unusable if
  re-instantiated under another.
- `tmp_*.md` — reports land here by default, named after the experiment file
  (gitignored — copy one elsewhere if you want to keep it).

## Usage

```sh
julia tools/benchmark/compare_julia_versions.jl \
    --experiment=examples/setups/WROASTED/experiment.json \
    --versions=1.11.9,1.12.6 \
    [--project=path/to/env] \
    [--replace-info=path/to/replace_info.json] \
    [--threads=8] \
    [--out=path/to/report.md]
```

To benchmark against a spatial (multi-site) run instead of the setup's default, pass
`--replace-info=tools/benchmark/replace_info_spatial_WROASTED.json` — it overrides
`forcing.subset.site` to a 16-site subset (same convention as
`examples/scripts/run_forward.jl`'s `:spatial` mode) rather than the full 205 sites,
to keep runs fast.

- `--experiment` — path to the experiment's `experiment.json`.
- `--project` — optional. A Pkg environment whose `Project.toml` lists any *extra*
  dependencies your experiment needs beyond `Sindbad` + `BenchmarkTools` (which are
  always provided automatically) — e.g. `CMAEvolutionStrategy` if your optimizer
  method needs its extension loaded. Only its `Project.toml` is used as a template;
  a fresh `Manifest.toml` is resolved per Julia version, so this doesn't need to be
  pre-instantiated for every version you plan to test. If omitted, a minimal env is
  built from scratch — enough for the benchmark cascade itself.
- `--versions` — comma-separated juliaup channel/version names, e.g.
  `1.11.9,1.12.6`, or `release,lts`. Run `juliaup list` to see what's installed;
  any version not yet installed will need `juliaup add <version>` first.
- `--replace-info` — optional path to a JSON file with a `replace_info`-style dict
  of experiment config overrides (same format `getExperimentInfo` accepts).
- `--threads` — Julia threads per run (`-t`), applied identically to every version
  for a fair comparison. Defaults to half the machine's CPU count.
- `--out` — where to write the report. Defaults to
  `tools/benchmark/tmp_<experiment-file-basename>.md`.

The report includes the experiment file's path, the full raw `experiment.json`
content, per-version environment metadata (Julia version, thread count), and the
timing table itself with a ratio column when comparing more than one version.

Each version's first run pays a one-time `Pkg.instantiate()` + precompilation cost;
subsequent runs against the same version reuse its `.jlbench_envs/` copy.
