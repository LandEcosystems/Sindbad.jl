# Convenience functions for running SindbadTEM's approach checks/benchmark locally, matching
# what CI's test-model/analyse-tem/test-tem jobs run (see SindbadTEM/test/README.md and
# .github/README.md for what each actually checks).
#
# test_model/analyse_tem run fully in-process (no subprocess) by loading testApproaches.jl's
# definitions once and calling its runApproachTests function directly -- repeat calls in the
# same session (e.g. under Revise, after editing an approach) skip Julia's startup/package-load
# cost entirely. test_tem still spawns a subprocess -- benchmarkApproaches.jl hasn't been
# refactored the same way, since it has no per-approach scoping to make repeat, targeted calls
# worthwhile the way test_model's does.
#
# Needs to be included under the SindbadTEM project (`julia --project=SindbadTEM`, or any
# session that already has SindbadTEM and Test loadable) -- same requirement
# runApproachChecks.jl itself has.
#
# Usage (from a Julia session, repo root as the working directory):
#   include("tools/dev_test.jl")
#   test_model("soilProperties_Saxton1986")                     # one changed approach
#   test_model("soilProperties_Saxton1986", "plantForm_fixed")  # several
#   analyse_tem()                                                # full catalog, informational
#   test_tem()                                                   # full benchmark + HTML report
#
# Note: this sets ENV["SINDBADTEM_SKIP_AUTORUN"] = "true" for the rest of the session (so loading
# testApproaches.jl's definitions below doesn't also immediately run them) -- if you separately
# `include("SindbadTEM/test/runApproachChecks.jl")` afterwards in the same session expecting its
# normal auto-run behavior, it won't run anything; unset that ENV var first, or use a fresh
# session for that.

using SindbadTEM
using Test

const DEV_TEST_REPO_ROOT = normpath(joinpath(@__DIR__, ".."))
const _SINDBADTEM_TEST_DIR = joinpath(DEV_TEST_REPO_ROOT, "SindbadTEM", "test")

# Bare `include(relative_path)` resolves relative to the *including file's own location*
# (`@__DIR__` of this file, i.e. tools/), not `pwd()` -- a `cd(...)` wrapper here wouldn't
# change that, so these need to be full paths into SindbadTEM/test/ instead.
ENV["SINDBADTEM_SKIP_AUTORUN"] = "true"
include(joinpath(_SINDBADTEM_TEST_DIR, "test_data", "forcing.jl"))
include(joinpath(_SINDBADTEM_TEST_DIR, "test_data", "land.jl"))
include(joinpath(_SINDBADTEM_TEST_DIR, "test_data", "referenceApproaches.jl"))
include(joinpath(_SINDBADTEM_TEST_DIR, "test_data", "helpers.jl"))
include(joinpath(_SINDBADTEM_TEST_DIR, "testDataCoverage.jl"))
include(joinpath(_SINDBADTEM_TEST_DIR, "testApproaches.jl"))  # defines runApproachTests; auto-run skipped, see above

"""
    test_model(names::AbstractString...)

Same check CI's `test-model` job runs, scoped to the approach(es) you name here instead of a
git diff: correctness (runs, type-stable, no `NaN`/`Inf`) *and* zero allocations on a warm
`precompute`/`compute` call. Throws if any named approach failed -- see the error message for
exactly which check and why.
"""
function test_model(names::AbstractString...)
    isempty(names) && error("usage: test_model(\"approach_name\", ...)")
    runApproachTests(; approaches=collect(names))
end

"""
    analyse_tem()

Same check CI's `analyse-tem` job runs: the full ~240-approach catalog, informational only
(logs `@info`/`@warn` per phase, never throws on a per-approach problem -- see
SindbadTEM/test/README.md for why).
"""
analyse_tem() = runApproachTests()

function _run_julia_script(script::AbstractString)
    run(Cmd(`julia --project=SindbadTEM $script`; dir=DEV_TEST_REPO_ROOT))
    return nothing
end

"""
    test_tem()

Same check CI's `test-tem` job runs: full timing/allocation benchmark across every approach,
rendered to an HTML report. Spawns a subprocess (see module docstring above) and prints the
report path when done.
"""
function test_tem()
    _run_julia_script(joinpath("tools", "benchmark", "TestSindbadTEM", "benchmarkApproaches.jl"))
    _run_julia_script(joinpath("tools", "benchmark", "TestSindbadTEM", "renderBenchmarkReport.jl"))
    report = joinpath(DEV_TEST_REPO_ROOT, "tools", "benchmark", "TestSindbadTEM", "benchmark_output", "benchmark_report.html")
    println("Report: ", report)
    return nothing
end
