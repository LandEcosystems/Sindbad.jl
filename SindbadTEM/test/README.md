# SindbadTEM test suite

This suite doesn't hand-write expected values per approach. Instead it discovers every
concrete approach struct for every process (via `subtypes`) and, for each one, calls it the
same way SINDBAD itself would and checks that it behaves: runs without crashing, is
type-stable, and produces no `NaN`/`Inf`. New approaches get covered automatically -- nothing
needs to be added here when someone adds a new `*.jl` file under `SindbadTEM/src/Processes/`.

## Layout

```
SindbadTEM/test/
  runtests.jl           entry point (what `Pkg.test("SindbadTEM")` runs)
  testDataCoverage.jl   static check: does test_data have every variable an approach reads?
  testApproaches.jl     the per-approach checks (type hierarchy + define/precompute/compute/update)
  runApproachChecks.jl  standalone entry point for testApproaches.jl -- NOT run by Pkg.test, see below
  test_data/            generated fixtures (forcing.jl, land.jl, helpers.jl, referenceApproaches.jl)
  _archive/             old, no-longer-run tests kept for reference only
```

`tools/benchmark/TestSindbadTEM/` (outside `SindbadTEM/`, alongside the rest of the repo's
tooling) holds the setup that `test_data/` is generated from, plus a separate benchmark tool
that reports timing/allocations per approach using the same test data -- see
[Test data](#test-data) below and that directory's own scripts for details.

## What's tested

`runtests.jl` (what `Pkg.test("SindbadTEM")` runs) includes, in order:

1. **SindbadTEM smoke** -- the package and its key submodules (`LandEcosystem`, `TEMTypes`,
   `Utils`, `Variables`, `Processes`) actually loaded. Fails fast with a clear message if
   package structure itself is broken, instead of as a confusing crash deep in the approach
   tests.
2. **Test data coverage** (`testDataCoverage.jl`) -- static check, no simulation involved.

`testApproaches.jl` -- the actual per-approach checks -- deliberately is **not** included by
`runtests.jl`, so it doesn't run as part of `Pkg.test`. It's pure Julia logic with no
OS-specific behavior, so running it across `Pkg.test`'s full 3-OS x 2-Julia-version CI matrix on
every push would be wasted cost. Run it directly instead:

```sh
julia --project=SindbadTEM SindbadTEM/test/runApproachChecks.jl
```

In CI, the full-catalog version is the `analyse-tem` job in
`.github/workflows/SindbadTEM-benchmark.yml` -- it runs alongside `test-tem` (the benchmark)
under the exact same trigger: a PR/push touching `SindbadTEM/src/Processes/`, the
`/test-tem` PR comment, or manually. That same workflow's `test-model` job runs a scoped
version of the same check on the same trigger, filtered down to just the approaches whose own
file changed (via `SINDBADTEM_TEST_APPROACHES`, see below) -- see that workflow and
[`.github/README.md`](../../.github/README.md) for the full detail.

### All approaches (`testApproaches.jl`)

Real SINDBAD runs (`runTEMOne` -> `definePrecomputeTEM`, then `computeTEM`; see
`SindbadTEM/src/Methods.jl`) call every process's `define`+`precompute` in sequence first
(threading `land` through all of them), and only *then*, in a separate pass, call `compute`
for every process in the same order. A single static `land` snapshot is not what any approach
actually sees -- it's the land some *other* upstream choice of approaches would have produced.

So this file replays the real sequence with one **reference approach** per process (from
`test_data/referenceApproaches.jl` -- normally `TestSindbadTEM/model_structure.json`'s own
selection, see [Test data](#test-data)), and at each process slot *also* runs every one of
that process's approaches against the same, correctly-built-up upstream `land` -- without
letting the tested approach's own output feed forward (only the reference approach's output
advances the chain). If the reference approach itself errors at some step, `land` is left
unchanged for that step (a warning is logged) rather than aborting the whole run.

Four checks, in this order:

| Check | What it checks | Needs simulation? | `Pkg.test`-style gate? |
|---|---|---|---|
| `Process/approach type hierarchy` | Every process is a `LandEcosystem` subtype; every one of its approaches is a concrete subtype of that specific process | No -- pure reflection | Yes -- a real `@test`, always either holds or signals an actual structural bug |
| `define+precompute (sequential)` | Every approach's `define` then `precompute`, `@inferred` (type-stable) and free of `NaN`/`Inf` | Yes | No -- `@info`/`@warn` only |
| `compute (sequential)` | Every approach's `compute`, same checks, against the land built up through the real `define`+`precompute` sequence | Yes | No -- `@info`/`@warn` only |
| `update` | Every approach's `update`, against the fully-built final land state (not chained -- `update` is a separate, optional per-timestep path, only invoked when `inline_update` is set in `experiment.json`) | Yes | No -- `@info`/`@warn` only |

The three simulation-driving checks are deliberately *not* `@test`-gated: many "failures" are
inherent, mutually exclusive structural requirements between approaches of the same process
(e.g. `soilWBase_smax1Layer` hard-requires exactly 1 soil layer while `soilWBase_smax2Layer`
requires 2 -- the shared reference `land`/`helpers` can only match one of them at a time), not
bugs -- hard-failing on them would make this permanently red. Each phase logs one consolidated
`@warn` (approach name -> problem description) if anything failed/errored, or one `@info` line
if everything passed -- see [What the results mean](#what-the-results-mean).

**`update` is excluded by default** -- most approaches don't override it (they inherit the
no-op default), so testing it by default mostly just measures how many approaches happen to
inherit that default against a land state most of them were never designed to see. Which
functions actually get checked is customizable via the `SINDBADTEM_TEST_FUNCTIONS` environment
variable (comma-separated):

```sh
# default
SINDBADTEM_TEST_FUNCTIONS="define,precompute,compute" julia --project=SindbadTEM SindbadTEM/test/runApproachChecks.jl

# also check update
SINDBADTEM_TEST_FUNCTIONS="define,precompute,compute,update" julia --project=SindbadTEM SindbadTEM/test/runApproachChecks.jl
```

**Which approaches get checked is customizable too**, via `SINDBADTEM_TEST_APPROACHES`
(comma-separated approach struct names). Unset/empty (the default) means no filter -- check
every approach, same as `analyse-tem` in CI. This is what `test-model` uses to scope a
run down to just the approaches whose own file changed in a push:

```sh
SINDBADTEM_TEST_APPROACHES="soilProperties_Saxton1986,soilWBase_smax1Layer" julia --project=SindbadTEM SindbadTEM/test/runApproachChecks.jl
```

### Test data coverage (`testDataCoverage.jl`)

Reuses `SindbadTEM.Utils.getInOutModel` (the same I/O-parsing helper that powers
auto-generated approach docstrings) to statically scan every approach's source for every
`forcing`/`land` variable it reads, and diffs that against what `test_data/` actually
provides. See `tools/benchmark/TestSindbadTEM/scanApproachVariables.jl` for the scanner
itself.

Only `missing.forcing` is a hard `@test` failure. `missing.land` and `missing.helpers` are
logged as a warning, not asserted on, because they're known-noisy:

- **`land`** is the *minimal*, pre-processing land (most process namespaces start out empty --
  see [Test data](#test-data)), so many `:input` land reads show up as "missing" simply
  because they haven't been populated yet at that point in the sequence, not because the test
  data is actually incomplete.
- **`helpers`** coverage is *derived* (the scanner infers which `helpers.pools.*` entries a
  pool needs from its name), and that heuristic only strips a leading `Δ` -- ordinary
  `_prev`/`zero...`-style `land.pools` fields (not real pools) trip false positives.
- **`forcing`** doesn't have either problem -- its shape is fixed for the whole sequence -- so
  it's the one category worth hard-failing on.

If you want the full report (not just what made it into a warning), run the scanner directly:

```sh
julia --project=SindbadTEM tools/benchmark/TestSindbadTEM/scanApproachVariables.jl
```

## What the results mean

- **`Process/approach type hierarchy` fails** -- an actual structural bug (a process or approach
  doesn't subtype what it should). This is the one real `@test` gate; it should never fail in
  practice.
- **`@info "<phase>: all N approaches OK"`** -- every approach in that phase ran, was
  type-stable, and produced no `NaN`/`Inf`. Nothing to do.
- **`@warn "<phase>: M/N approaches failed/errored..."`** -- prints a `Dict` of approach name ->
  problem description. Each entry is one of:
  - `"did not return a NamedTuple"` -- the approach's return value itself is wrong.
  - `"NaN/Inf at <path>, ..."` -- one or more output fields are invalid; the dotted path names
    exactly which.
  - `"errored: ..."` -- the approach crashed outright. Common causes seen so far: a genuine bug
    in the approach's own source (e.g. a stray bitwise `&`/`|` instead of `&&`/`||`, which
    silently changes both behavior *and* type), a type instability caught by `@inferred`, an
    inherent structural requirement the shared test data can't satisfy for every approach at
    once (e.g. a hard-coded soil-layer count), or the reference-approach chain not having
    produced a `land` shape this particular approach expects (check whether the *reference*
    approach for that process is a reasonable stand-in -- see `test_data/referenceApproaches.jl`).
  Not a `Pkg.test` failure either way -- treat this as a triage list, not a red/green signal.
- A separate `@warn "Reference approach failed while advancing the sequential chain..."` during
  the run means the *reference* approach for some process errored, so `land` wasn't advanced for
  that step -- expect knock-on failures in whatever reads that process's normal output.

None of this is a hand-checked "is the math correct" assertion (see the note in this
repo's git history if curious why) -- it's a smoke test: does every approach run, stay
type-stable, and avoid producing garbage, when driven through the real sequence real SINDBAD
runs use.

## Test data

`test_data/*.jl` are generated files (do not hand-edit -- each one says so in its header) that
provide four top-level bindings, `include`d by `runtests.jl`:

| File | Binds | What it is |
|---|---|---|
| `forcing.jl` | `tmp_forcing` | One location's forcing, averaged over the whole loaded period for time-varying variables (rather than pinned to one arbitrary day) |
| `helpers.jl` | `tmp_helpers` | The `(dates, run, numbers, pools)`-shaped `helpers` `define`/`precompute`/`compute` actually receive (note: *not* the same as `getRunTEMInfo`'s own return value -- that's a wrapper; this is its `.model_helpers` field) |
| `land.jl` | `land` | The minimal, pre-processing land (`info.helpers.land_init`, with an empty `NamedTuple` placeholder added for every process in `standard_sindbad_model` that the model structure doesn't already select) |
| `referenceApproaches.jl` | `reference_approaches` | One approach per process, used to advance `land` through the real sequence in `testApproaches.jl` -- see [All approaches](#all-approaches-testapproachesjl) |

All four are generated from a real run of `tools/benchmark/TestSindbadTEM/`'s own setup
(`experiment.json` + `forcing.json` + `model_structure.json`) -- not tied to any one specific
example experiment (e.g. WROASTED). That setup's `forcing.json` is purpose-built to cover
every approach's forcing needs across all 88 processes, and its `model_structure.json` is a
real, working model structure (so `reference_approaches` mostly comes from an actual
selection, not an arbitrary fallback).

### Regenerating test data

```sh
julia --project=tools/benchmark/TestSindbadTEM tools/benchmark/TestSindbadTEM/derive_sindbadTEM_test_data.jl
```

Do this whenever `tools/benchmark/TestSindbadTEM/forcing.json` or `model_structure.json`
changes, or whenever `testDataCoverage.jl` reports a missing `forcing` variable. It overwrites
all four `test_data/*.jl` files in place.

This needs `tools/benchmark/TestSindbadTEM/`'s own `Project.toml` (not the repo root's, and not
SindbadTEM's) -- it pins `HTTP.jl` to `1.x`, same fix as `examples/scripts/Project.toml`: Zarr.jl's
`HTTPStore` forces the OpenSSL TLS backend via a `socket_type_tls` kwarg that only HTTP.jl's `1.x`
client honors; HTTP `2.x` silently ignores it and fails the TLS handshake against the S3 bucket
`forcing.json`'s `data_path` points at. Running under the repo root's `--project=.` (which
resolves HTTP `2.x`) fails with a misleading "certificate has expired" error -- it isn't actually
about the certificate.

### Adding a new forcing variable

If `testDataCoverage.jl` (or the scanner) reports an approach needs a forcing variable that
`tools/benchmark/TestSindbadTEM/forcing.json` doesn't have:

1. Add an entry under `"variables"` in `tools/benchmark/TestSindbadTEM/forcing.json`, following
   the existing entries' shape:

   ```json
   "f_yourVariable": {
     "bounds": [0.0, 100.0],
     "standard_name": "Human-readable name",
     "sindbad_unit": "mm",
     "source_unit": "mm",
     "source_to_sindbad_unit": 1.0,
     "source_variable": "SomeVariableInTheZarrDataset",
     "space_time_type": "spatiotemporal"
   }
   ```

2. `source_variable` must name a variable that actually exists in
   `examples/data/synthetic_data_examples.zarr`. List what's available with:

   ```sh
   julia --project=. -e 'using YAXArrays, Zarr; ds = open_dataset("examples/data/synthetic_data_examples.zarr"); println.(sort(collect(keys(ds.cubes))))'
   ```

   The synthetic dataset is small and doesn't have a real source for every conceivable
   variable (e.g. there's no rooting-depth or soil-water-capacity field) -- picking a
   reasonable proxy (the way `f_AWC` reuses `SLTPPT_SoilGrids`, scaled) is a domain judgment
   call, not something to guess at automatically.
3. Regenerate test data (see above), then rerun `Pkg.test("SindbadTEM")` (for the
   `testDataCoverage.jl` check) and `julia --project=SindbadTEM SindbadTEM/test/runApproachChecks.jl`
   (to confirm the approach that needed the variable now actually runs).

## `_archive/`

Earlier, hand-written per-approach tests (mirrored-file-per-process pattern, mock input data),
kept for reference. Nothing in `runtests.jl` includes anything under `_archive/` -- it isn't
run, and isn't maintained to stay working as the source it tests evolves.
