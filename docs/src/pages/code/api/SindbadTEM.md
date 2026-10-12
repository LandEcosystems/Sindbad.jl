```@docs
SindbadTEM
```
## Functions

### analyse_process
```@docs
analyse_process
```

:::details Code

```julia
function analyse_process end

function _run_julia_script(repo_root::AbstractString, script::AbstractString)
    run(Cmd(`julia --project=SindbadTEM $script`; dir=repo_root))
    return nothing
end
```

:::


----

### analyse_tem
```@docs
analyse_tem
```

:::details Code

```julia
function analyse_tem end

"""
    analyse_process(names::AbstractString...)

Same as `analyse_tem`, restricted to the named process(es) (e.g. "soilProperties") instead of
the full catalog: runs every leaf approach of just those processes, informationally (logs
`@info`/`@warn` per phase, never throws on a per-approach problem). Unlike `test_model`, this
never hard-gates -- use `test_model` with that process's approach names instead if you want a
failure to throw.

```julia
using SindbadTEM, Test
analyse_process("soilProperties")
analyse_process("soilProperties", "vegClass")
```

Errors immediately if a name doesn't match any process, listing the valid names. Same
`using Test` / dev-linked-checkout requirement as `test_model`/`analyse_tem`.
"""
function analyse_process end

function _run_julia_script(repo_root::AbstractString, script::AbstractString)
    run(Cmd(`julia --project=SindbadTEM $script`; dir=repo_root))
    return nothing
end
```

:::


----

### test_model
```@docs
test_model
```

:::details Code

```julia
function test_model end

"""
    analyse_tem()

Same check CI's `analyse-tem` job runs: the full ~240-approach catalog, informational only (logs
`@info`/`@warn` per phase, never throws on a per-approach problem -- see
`SindbadTEM/test/README.md` for why). Same `using Test` / dev-linked-checkout requirement as
`test_model`.
"""
function analyse_tem end

"""
    analyse_process(names::AbstractString...)

Same as `analyse_tem`, restricted to the named process(es) (e.g. "soilProperties") instead of
the full catalog: runs every leaf approach of just those processes, informationally (logs
`@info`/`@warn` per phase, never throws on a per-approach problem). Unlike `test_model`, this
never hard-gates -- use `test_model` with that process's approach names instead if you want a
failure to throw.

```julia
using SindbadTEM, Test
analyse_process("soilProperties")
analyse_process("soilProperties", "vegClass")
```

Errors immediately if a name doesn't match any process, listing the valid names. Same
`using Test` / dev-linked-checkout requirement as `test_model`/`analyse_tem`.
"""
function analyse_process end

function _run_julia_script(repo_root::AbstractString, script::AbstractString)
    run(Cmd(`julia --project=SindbadTEM $script`; dir=repo_root))
    return nothing
end
```

:::


----

### test_tem
```@docs
test_tem
```

:::details Code

```julia
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
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using SindbadTEM
end
```

## Modules

- [`SindbadTEM.TEMTypes`](/pages/code/api/SindbadTEM.TEMTypes)
- [`SindbadTEM.Utils`](/pages/code/api/SindbadTEM.Utils)
- [`SindbadTEM.Variables`](/pages/code/api/SindbadTEM.Variables)
- [`SindbadTEM.Processes`](/pages/code/api/SindbadTEM.Processes)
