# Local dev-loop convenience functions for running SindbadTEM's approach checks/benchmark --
# matching what CI's test-model/analyse-tem/test-tem jobs run (see SindbadTEM/test/README.md
# and .github/README.md for what each actually checks).
#
# `test_model`/`analyse_tem` are declared here as empty generic functions (no methods) and given
# their real bodies in ext/SindbadTEMTestExt.jl -- a package extension that only activates once a
# session also has `Test` loaded (`using SindbadTEM, Test`). That keeps `Test` a *weak* dependency:
# it's needed to run these two, but never becomes a hard runtime dependency for ordinary
# `using SindbadTEM` users who never call them.
#
# `test_tem` needs no `Test` machinery (it just spawns a subprocess benchmark script), so it's a
# normal, always-available function, defined directly below.
#
# All three need a dev-linked checkout of the Sindbad.jl monorepo -- they reach into `tools/` at
# the repo root, next to (not inside) the SindbadTEM package -- so they raise a clear error rather
# than working for a plain registry install.

"""
    test_model(names::AbstractString...)

Same check CI's `test-model` job runs, scoped to the approach(es) you name here instead of a
git diff: correctness (runs, type-stable, no `NaN`/`Inf`) *and* zero allocations on a warm
`precompute`/`compute` call. Throws if any named approach failed -- see the error message for
exactly which check and why.

```julia
using SindbadTEM, Test
test_model("soilProperties_Saxton1986")
test_model("soilProperties_Saxton1986", "plantForm_fixed")
```

Needs `using Test` loaded alongside `SindbadTEM` (this method is provided by SindbadTEM's `Test`
package extension) and a dev-linked checkout of the Sindbad.jl monorepo.
"""
function test_model end

"""
    analyse_tem()

Same check CI's `analyse-tem` job runs: the full ~240-approach catalog, informational only (logs
`@info`/`@warn` per phase, never throws on a per-approach problem -- see
`SindbadTEM/test/README.md` for why). Same `using Test` / dev-linked-checkout requirement as
`test_model`.
"""
function analyse_tem end

function _run_julia_script(repo_root::AbstractString, script::AbstractString)
    run(Cmd(`julia --project=SindbadTEM $script`; dir=repo_root))
    return nothing
end

"""
    test_tem()

Same check CI's `test-tem` job runs: full timing/allocation benchmark across every approach,
rendered to an HTML report. Spawns a subprocess and prints the report path when done. Needs a
dev-linked checkout of the Sindbad.jl monorepo, same as `test_model`/`analyse_tem`.
"""
function test_tem()
    repo_root = normpath(joinpath(pkgdir(@__MODULE__), ".."))
    isdir(joinpath(repo_root, "tools", "benchmark", "TestSindbadTEM")) || error(
        "test_tem() needs a dev-linked checkout of the Sindbad.jl monorepo -- looked for " *
        "tools/benchmark/TestSindbadTEM next to the SindbadTEM package at $repo_root and didn't find it.",
    )
    _run_julia_script(repo_root, joinpath("tools", "benchmark", "TestSindbadTEM", "benchmarkApproaches.jl"))
    _run_julia_script(repo_root, joinpath("tools", "benchmark", "TestSindbadTEM", "renderBenchmarkReport.jl"))
    report = joinpath(repo_root, "tools", "benchmark", "TestSindbadTEM", "benchmark_output", "benchmark_report.html")
    println("Report: ", report)
    return nothing
end
