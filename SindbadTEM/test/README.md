# SindbadTEM test suite

This suite doesn't hand-write expected values per approach. Instead it discovers every
concrete approach struct for every process (via `subtypes`) and, for each one, calls it the
same way SINDBAD itself would and checks that it behaves: runs without crashing, is
type-stable, and produces no `NaN`/`Inf`. New approaches get covered automatically -- nothing
needs to be added here when someone adds a new `*.jl` file under `SindbadTEM/src/Processes/`.

## Layout

```
SindbadTEM/test/
  runtests.jl          entry point (what `Pkg.test("SindbadTEM")` runs)
  testDataCoverage.jl  static check: does test_data have every variable an approach reads?
  testApproaches.jl    the actual approach tests (type hierarchy + define/precompute/compute/update)
  test_data/           generated fixtures (forcing.jl, land.jl, helpers.jl, referenceApproaches.jl)
  _archive/            old, no-longer-run tests kept for reference only
```

`tools/benchmark/TestSindbadTEM/` (outside `SindbadTEM/`, alongside the rest of the repo's
tooling) holds the setup that `test_data/` is generated from, plus a separate benchmark tool
that reports timing/allocations per approach using the same test data -- see
[Test data](#test-data) below and that directory's own scripts for details.

## What's tested

`runtests.jl` includes, in order:

1. **SindbadTEM smoke** -- the package and its key submodules (`LandEcosystem`, `TEMTypes`,
   `Utils`, `Variables`, `Processes`) actually loaded. Fails fast with a clear message if
   package structure itself is broken, instead of as a confusing crash deep in the approach
   tests.
2. **Test data coverage** (`testDataCoverage.jl`) -- static check, no simulation involved.
3. **All approaches** (`testApproaches.jl`) -- the real per-approach tests.

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

| Testset | What it checks | Needs simulation? |
|---|---|---|
| `Process/approach type hierarchy` | Every process is a `LandEcosystem` subtype; every one of its approaches is a concrete subtype of that specific process | No -- pure reflection |
| `define+precompute (sequential)` | Every approach's `define` then `precompute`, `@inferred` (type-stable) and free of `NaN`/`Inf` | Yes |
| `compute (sequential)` | Every approach's `compute`, same checks, against the land built up through the real `define`+`precompute` sequence | Yes |
| `update` | Every approach's `update`, against the fully-built final land state (not chained -- `update` is a separate, optional per-timestep path, only invoked when `inline_update` is set in `experiment.json`) | Yes |

**`update` is excluded by default** -- most approaches don't override it (they inherit the
no-op default), so testing it by default mostly just measures how many approaches happen to
inherit that default against a land state most of them were never designed to see. Which
functions actually get tested is customizable via the `SINDBADTEM_TEST_FUNCTIONS` environment
variable (comma-separated):

```sh
# default
SINDBADTEM_TEST_FUNCTIONS="define,precompute,compute" julia --project=SindbadTEM -e 'using Pkg; Pkg.test("SindbadTEM")'

# also test update
SINDBADTEM_TEST_FUNCTIONS="define,precompute,compute,update" julia --project=SindbadTEM -e 'using Pkg; Pkg.test("SindbadTEM")'
```

All four testsets are nested under one shared outer `@testset "All approaches"` so that a
failure/error in one doesn't abort the others -- `Test.jl` only throws when the *outermost*
testset in a file finishes with failures; a nested one just records them and lets its
siblings run.

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

- **Pass** -- ran, type-stable, no `NaN`/`Inf`. Nothing to do.
- **Fail** (`@test` returned `false`, e.g. `NaN`/`Inf` found, or `missing.forcing` non-empty)
  -- a concrete, actionable problem: either a real bug in that approach, or test data missing
  a variable it needs.
- **Error** (an exception was thrown) -- the approach crashed outright. Common causes seen so
  far: a genuine bug in the approach's own source (e.g. a stray bitwise `&`/`|` instead of
  `&&`/`||`, which silently changes both behavior *and* type), a type instability caught by
  `@inferred`, or the reference-approach chain not having produced a `land` shape this
  particular approach expects (check whether the *reference* approach for that process is a
  reasonable stand-in -- see `test_data/referenceApproaches.jl`).
- A `@warn "Reference approach failed while advancing the sequential chain..."` during the run
  means the *reference* approach for some process errored, so `land` wasn't advanced for that
  step -- expect knock-on failures in whatever reads that process's normal output.

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
3. Regenerate test data (see above) and rerun `Pkg.test("SindbadTEM")`.

## `_archive/`

Earlier, hand-written per-approach tests (mirrored-file-per-process pattern, mock input data),
kept for reference. Nothing in `runtests.jl` includes anything under `_archive/` -- it isn't
run, and isn't maintained to stay working as the source it tests evolves.
