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

Or, from any session with `using SindbadTEM, Test` (both loaded activates SindbadTEM's `Test`
package extension, `SindbadTEM/ext/SindbadTEMTestExt.jl` -- see `SindbadTEM/Project.toml`'s
`[weakdeps]`/`[extensions]`; `Test` stays optional, not a hard runtime dependency), `test_model(...)`
and `analyse_tem()` call `runApproachTests` (below) directly, in-process -- no subprocess, so
repeat calls in the same session (e.g. after editing an approach, under Revise) skip Julia's
startup cost entirely. `test_tem()` is always available (no `Test` needed) and does spawn a
subprocess (matching `benchmarkApproaches.jl`, which isn't scoped/parameterized the way
`testApproaches.jl` is). All three need a dev-linked checkout of this monorepo -- see their
docstrings (`?test_model` etc.).

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
selection, see [Test data](#test-data)), in two separate passes matching the real pipeline
(all processes' `define`+`precompute` first, then all processes' `compute`), and at each process
slot in each pass *also* tests every one of that process's approaches against the same,
correctly-built-up upstream `land`. The tested approach's own output never feeds the *shared*
chain (only the reference approach's output advances what the next process sees), so testing one
approach can't contaminate another's -- except for its own `compute` check, which chains that
same approach's own `define`->`precompute`->`compute` on top of the shared upstream `land` (see
`checkComputeChain`), so `compute` sees exactly what its own `precompute` would hand it in a real
run, not whatever the *reference* approach for that process happened to produce. If the reference
approach itself errors at some step, `land` is left unchanged for that step (a warning is logged)
rather than aborting the whole run.

Four checks, in this order:

| Check | What it checks | Needs simulation? | Hard-fails the run? |
|---|---|---|---|
| `Process/approach type hierarchy` | Every process is a `LandEcosystem` subtype; every one of its approaches is a concrete subtype of that specific process | No -- pure reflection | Always -- a real `@test`, always either holds or signals an actual structural bug |
| `define+precompute (sequential)` | Every approach's `define` then `precompute`, `@inferred` (type-stable) and free of `NaN`/`Inf` | Yes | Only when scoped, and only `:bug`-severity results (see below) |
| `compute (sequential)` | Every approach's own `define`->`precompute`->`compute` chain, same checks, against upstream `land` built from earlier processes | Yes | Only when scoped, and only `:bug`-severity results |
| `update` | Every approach's `update`, against the fully-built final land state (not chained -- `update` is a separate, optional per-timestep path, only invoked when `inline_update` is set in `experiment.json`) | Yes | Only when scoped, and only `:bug`-severity results |

Every per-approach result is tagged one of two severities (see `outcomeFromException`):
- **`:incompatible`** -- the approach failed on a *missing field* (`land.<namespace>` genuinely
  doesn't have something it reads). This almost always means the approach legitimately depends on
  a *different* approach for some *other* process (e.g. a specific `soilWBase` variant) than the
  one the fixed test reference happens to select for that process -- not a bug in the approach
  under test (e.g. `soilWBase_smax1Layer` hard-requires exactly 1 soil layer while
  `soilWBase_smax2Layer` requires 2; the shared reference `land`/`helpers` can only match one of
  them at a time). **Always informational, scoped or not** -- it can never hard-fail a run, since
  it isn't a defect in the approach the run is actually about.
- **`:bug`** -- anything else (crashed some other way, type instability, `NaN`/`Inf`, non-zero
  allocation). Reflects the approach's own code. Informational when run **unscoped** (the default,
  and what `analyse-tem` in CI always does) -- hard-failing `Pkg.test` on the full catalog's
  pre-existing issues would make it permanently red -- but hard-fails when run **scoped**.

Each phase logs one consolidated `@info` (approach name -> reason) for `:incompatible` results and
one consolidated `@warn` (approach name -> reason) for `:bug` results, or one `@info` line if
everything passed.

When run **scoped** to specific approaches (`SINDBADTEM_TEST_APPROACHES` set -- what `test-model`
in CI does, filtered to just the approaches a push actually changed), a `:bug` among *those*
approaches is a reliable, actionable signal instead of catalog-wide noise, so the whole run exits
nonzero (a plain Julia `error(...)`, printing every failing check and why) if any of them failed
or errored with `:bug` severity. `:incompatible` results among the scoped approaches are still
logged, but never make the run exit nonzero.

**Scoped `precompute`/`compute` checks also enforce zero allocations.** `define` is excluded --
it legitimately allocates (it's creating pools/arrays) -- but a well-written `precompute`/
`compute` should allocate ~0 bytes once compiled, so scoped runs measure a warm (post-compile)
call's allocations and fail if it's anything above 0. Only checked once the correctness check for
that approach already passed (no point measuring allocations on something that doesn't even run).
See [What the results mean](#what-the-results-mean).

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
every approach, unscoped, same as `analyse-tem` in CI. Setting it scopes the run *and* makes it
hard-fail on a problem (see the table above) -- this is what `test-model` uses to check just the
approaches whose own file changed in a push:

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
- **`@info "<phase>: M/N approaches skipped -- incompatible upstream data..."`** -- prints a
  `Dict` of approach name -> reason, all `:incompatible` severity (see above): the approach hit a
  missing `land.<namespace>` field, almost always because it needs a different upstream approach
  (for some *other* process) than this test's fixed reference selects. Not a bug, never a hard
  failure even scoped -- check whether the *reference* approach for the relevant upstream process
  is a reasonable stand-in if you want to investigate further (see
  `test_data/referenceApproaches.jl`).
- **`@warn "<phase>: M/N approaches failed/errored..."`** -- prints a `Dict` of approach name ->
  problem description, all `:bug` severity. Each entry is one of:
  - `"did not return a NamedTuple"` -- the approach's return value itself is wrong.
  - `"NaN/Inf at <path>, ..."` -- one or more output fields are invalid; the dotted path names
    exactly which.
  - `"errored: ..."` -- the approach crashed on something other than a missing field. Common
    causes seen so far: a genuine bug in the approach's own source (e.g. a stray bitwise `&`/`|`
    instead of `&&`/`||`, which silently changes both behavior *and* type; forgetting to
    `@unpack_nt` a variable the approach's code goes on to use, which throws `UndefVarError`, not
    a missing-field error, so it stays `:bug`-severity rather than being reclassified as
    `:incompatible`), or a type instability caught by `@inferred`.
  Not a `Pkg.test` failure either way when unscoped -- treat this as a triage list, not a
  red/green signal.
- A separate `@warn "Reference approach failed while advancing the sequential chain..."` during
  the run means the *reference* approach for some process errored, so `land` wasn't advanced for
  that step -- expect knock-on failures in whatever reads that process's normal output.
- **Scoped runs** (`SINDBADTEM_TEST_APPROACHES` set, e.g. `test-model` in CI) additionally throw
  `ERROR: N check(s) failed for the tested approach(es): ...` and exit nonzero if any *targeted*
  approach had a `:bug`-severity result -- one line per failing `phase: approach` pair with its
  reason, same wording as the `@warn` entries above, plus (for `precompute`/`compute` only) two
  more possible reasons:
  - `"precompute allocated <N> bytes on a hot call (expected 0)"` / the `compute` equivalent --
    the approach runs correctly but isn't allocation-free once compiled. Look for the specific
    thing that allocates on every call: growing a `Vector` instead of using a fixed-size
    `SVector`, a closure that captures by boxing, string interpolation/formatting in a hot path,
    etc.
  - `"precompute allocation check errored: ..."` / the `compute` equivalent -- the allocation
    check itself crashed (rare, since the correctness check already passed with the same
    inputs); the message is the underlying exception.
  This is the one case where a problem here should actually block something: it's specific to
  the approach(es) a change touched.

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
