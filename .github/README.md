# CI workflows

Reference for everything in `.github/workflows/`: what each one does, what triggers it, and
whether it's required to merge. For the short, contributor-facing version -- which comment
command to use and when -- see the [PR template](PULL_REQUEST_TEMPLATE.md); that's what you see
when opening a PR. This file is the detail behind it.

## At a glance

| Workflow (job) | Runs on | Required to merge? |
|---|---|---|
| `Sindbad.yml` (`quick`) | every PR push | Yes |
| `SindbadTEM.yml` (`quick`) | every PR push | Yes |
| `Sindbad.yml` + `SindbadTEM.yml` (`full-matrix`) | push to `main`/tag, `/compile-os`, or manual | No |
| `SindbadTEM-benchmark.yml` (`test-tem`, `analyse-tem`) | PR/push touching `SindbadTEM/src/Processes/` (see below), `/test-tem`, or manual -- both run together, always | No |
| `SindbadTEM-benchmark.yml` (`test-model`) | every PR/push touching `SindbadTEM/src/Processes/` (same trigger as `test-tem`) | No -- but see below |
| `TestSimulations.yml` | PR/push touching `src/`, `/test-simulation`, or manual | No |
| `Documenter.yml` | push to `main`/tag, `/build-docs`, or manual (never on PRs directly) | No |
| `ci-commands.yml` | PR comments (dispatches the workflows above) | n/a |
| `TagBot.yml` | Julia registry merge comment, or manual | n/a (release automation) |

"Manual" means the Actions tab -> pick the workflow -> "Run workflow" -> select a branch, which
works for any of these at any time, on any branch.

## Required checks

`Sindbad.yml`'s and `SindbadTEM.yml`'s `quick` jobs run automatically on every push to an open
PR: ubuntu-only, Julia `lts` + `1` (4 jobs total). Kept fast and narrow on purpose so pushing to
a PR doesn't get slow. This is the only thing *actually configured as* required to merge in the
repo's branch protection settings -- everything else below is on-demand or path-triggered,
informational, or both.

`test-model` (see below) is the one exception worth calling out: unlike every other job here,
it's *capable* of hard-failing (nonzero exit) on a genuine problem, specifically in whichever
approach a push touched -- see `SindbadTEM/test/README.md`. Making it actually block merging
still needs an admin to add "SindbadTEM: test-model" under Settings -> Branches -> branch
protection rules -> required status checks; nothing in this repo's files can do that on its own.

## On-demand comment commands

Handled by `ci-commands.yml`: comment one or more of these on a PR (gated to commenters with
write access; it only dispatches the workflows below against the PR's branch, it never checks
out or runs any PR code itself):

- **`/check-pr`**: everything below at once. Meant as the last, comprehensive check right before
  merging, and again after any new commits land on top of an earlier run -- not something to run
  on every push.
- **`/build-docs`**: `Documenter.yml` only. Use after changes to any docstring, or when a new
  function is introduced.
- **`/compile-os`**: `Sindbad.yml` + `SindbadTEM.yml` full matrix only. Use after changes under
  `src/`, `SindbadTEM/src/`, or `Project.toml` dependencies. Note that `test/Project.toml` only
  pulls in a handful of the optional extensions under `ext/`, so this doesn't exercise all of
  them -- prefer `/check-pr` (or a manual local check) if you're touching an extension outside
  that set.
- **`/test-simulation`**: `TestSimulations.yml` only. Auto-triggered by changes under `src/` (see
  below); use this to also run it for changes elsewhere that still affect the core simulation
  run path (forward/optimization execution). Does not cover ML or visualization code -- the
  LUE/WROASTED setups it runs are neither hybrid-ML nor plotting paths.
- **`/test-tem`**: `SindbadTEM-benchmark.yml`'s `test-tem` and `analyse-tem` jobs, which
  always run together (not `test-model` -- see below, it needs a real commit diff, which a
  manual dispatch doesn't have). Both are auto-triggered by changes under
  `SindbadTEM/src/Processes/` (see below); use `/test-tem` to also run them for changes
  elsewhere that still affect approach behavior, without also re-running `SindbadTEM.yml`'s
  full OS matrix, or any other time you want them (e.g. before a release).

Each on-demand workflow posts its own progress to the PR as a comment automatically -- an
"in progress" comment naming what's running as soon as it starts, updated with the result once
it finishes (see `.github/scripts/upsert_pr_comment.sh`).

## What each workflow actually runs

- **`Sindbad.yml` / `SindbadTEM.yml` full matrix**: the same tests as the quick check, across all
  three OSes (`ubuntu`/`macOS`/`windows`) x both Julia versions (6 jobs each). Each job writes a
  one-row CSV of its pass/fail status and wall time; when triggered on-demand (`workflow_dispatch`,
  e.g. via `/compile-os`), a final `report` job downloads all 6 jobs' CSVs and posts a Markdown
  table (OS, Julia version, status, time) on the PR alongside the overall result.
- **`Documenter.yml`**: builds the docs (no PR preview deploy; see `docs/make.jl`'s
  `push_preview = false`). Only runs on push to `main`/tag or manually -- never automatically on
  a PR, since there's nowhere to preview-deploy it to.
- **`SindbadTEM-benchmark.yml`**: three independent jobs, all against the committed test data in
  `SindbadTEM/test/test_data/` (see `SindbadTEM/test/README.md`). `test-tem` and `analyse-tem`
  share the exact same trigger (neither has its own `if:`) and so always run together;
  `test-model` has its own, narrower trigger.
  - `test-tem`, the comprehensive one, runs every approach's
    `define`/`precompute`/`compute`/`update` multiple times each (for accurate timing/allocation
    measurement) and reports status/time/allocations per approach, both as a job summary and as
    a downloadable HTML artifact.
  - `analyse-tem`, the quick full-catalog one, runs `SindbadTEM/test/testApproaches.jl` directly
    with no filter -- one call per approach, type-stability + `NaN`/`Inf` checks, informational
    only.
  - `test-model` is the fast, per-push, *scoped* version of the same check as `analyse-tem`:
    `git diff`s the base and head commits for `.jl` files under `SindbadTEM/src/Processes/`,
    maps each one to its approach struct name (the filename always matches, e.g.
    `soilProperties_Saxton1986.jl` defines `soilProperties_Saxton1986`) via
    `SINDBADTEM_TEST_APPROACHES`, and runs `SindbadTEM/test/testApproaches.jl` scoped to just
    those approaches. Runs on every PR/push touching `SindbadTEM/src/Processes/` (same trigger
    as `test-tem`/`analyse-tem`); silently does nothing if the changed files don't map to a
    specific approach (e.g. only a process's shared abstract-type file, or
    `SindbadTEM/src/Processes.jl`, changed) -- `analyse-tem`/`test-tem` cover that case instead.
    Unlike `analyse-tem`, a problem in a *targeted* approach here fails the job: correctness
    (runs, type-stable, no `NaN`/`Inf`) same as `analyse-tem`, *plus* zero-allocation on a warm
    `precompute`/`compute` call (`define` is excluded -- it legitimately allocates) -- see
    [Required checks](#required-checks) above for what it'd take to make that actually block
    merging.
- **`TestSimulations.yml`** ("Test Simulations"): runs one job per
  `{ubuntu,macOS,windows} x {LUE,WROASTED} x {pixel,spatial}` combination (12 jobs, in parallel),
  named so it's clear at a glance what each is running -- e.g. "LUE x pixel x F+O x ubuntu-latest"
  (F+O = runs both forward and optimization). Each job runs `examples/scripts/simulation_report.jl`
  restricted to its one setup/mode (via the `SIMULATION_SETUPS`/`SIMULATION_MODES` environment
  variables), for both `forward` and `optimization` kinds, and writes a CSV of status, wall time,
  memory allocated, mean simulated GPP, and (for optimization runs) the total optimized cost for
  each (see `examples/README.md` for what the LUE/WROASTED setups are). A final `combine` job
  downloads all 12 jobs' CSVs and merges them into one Markdown table (OS and Julia version
  included per row), via `examples/scripts/combine_simulation_reports.jl`.

  `simulation_report.jl` also works standalone locally:

  ```sh
  julia --project=examples/scripts examples/scripts/simulation_report.jl
  ```

  which writes `examples/output_simulation_report_<os>.csv` and `.md` (both git-ignored).
- **`TagBot.yml`**: standard `JuliaRegistries/TagBot` release automation -- tags a GitHub release
  once the Julia General registry merges a new version PR (`Sindbad` and, via its `subdir`
  matrix, `SindbadTEM`). Not something you trigger directly.
