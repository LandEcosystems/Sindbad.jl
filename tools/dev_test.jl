# Convenience wrappers for running SindbadTEM's approach checks/benchmark locally, matching
# what CI's test-model/analyse-tem/test-tem jobs run (see SindbadTEM/test/README.md and
# .github/README.md for what each actually checks). Each function spawns a real
# `julia --project=SindbadTEM ...` subprocess -- the same command you'd type directly, just
# wrapped -- so expect the usual Julia startup/package-load cost (~15-20s) on every call, even
# from an already-running session. That cost is inherent to running a fresh script process; a
# true in-process function would need testApproaches.jl restructured away from its current
# script-with-top-level-`include`s form, which isn't worth the risk to already-tested code just
# for this convenience.
#
# Usage (from a Julia session, repo root as the working directory):
#   include("tools/dev_test.jl")
#   test_model("soilProperties_Saxton1986")                     # one changed approach
#   test_model("soilProperties_Saxton1986", "plantForm_fixed")  # several
#   analyse_tem()                                                # full catalog, informational
#   test_tem()                                                   # full benchmark + HTML report

const DEV_TEST_REPO_ROOT = normpath(joinpath(@__DIR__, ".."))

function _run_julia_script(script::AbstractString, extra_env::Vector{Pair{String,String}}=Pair{String,String}[])
    cmd = Cmd(`julia --project=SindbadTEM $script`; dir=DEV_TEST_REPO_ROOT)
    isempty(extra_env) || (cmd = addenv(cmd, extra_env...))
    run(cmd)
    return nothing
end

"""
    test_model(names::AbstractString...)

Same check CI's `test-model` job runs, scoped to the approach(es) you name here instead of a
git diff: correctness (runs, type-stable, no `NaN`/`Inf`) *and* zero allocations on a warm
`precompute`/`compute` call. Throws if the subprocess exits nonzero (i.e. any named approach
failed) -- see the error output above the exception for exactly which check and why.
"""
function test_model(names::AbstractString...)
    isempty(names) && error("usage: test_model(\"approach_name\", ...)")
    _run_julia_script(
        joinpath("SindbadTEM", "test", "runApproachChecks.jl"),
        ["SINDBADTEM_TEST_APPROACHES" => join(names, ",")],
    )
end

"""
    analyse_tem()

Same check CI's `analyse-tem` job runs: the full ~240-approach catalog, informational only
(logs `@info`/`@warn` per phase, never throws on a per-approach problem -- see
SindbadTEM/test/README.md for why).
"""
analyse_tem() = _run_julia_script(joinpath("SindbadTEM", "test", "runApproachChecks.jl"))

"""
    test_tem()

Same check CI's `test-tem` job runs: full timing/allocation benchmark across every approach,
rendered to an HTML report. Prints the report path when done.
"""
function test_tem()
    _run_julia_script(joinpath("tools", "benchmark", "TestSindbadTEM", "benchmarkApproaches.jl"))
    _run_julia_script(joinpath("tools", "benchmark", "TestSindbadTEM", "renderBenchmarkReport.jl"))
    report = joinpath(DEV_TEST_REPO_ROOT, "tools", "benchmark", "TestSindbadTEM", "benchmark_output", "benchmark_report.html")
    println("Report: ", report)
    return nothing
end
