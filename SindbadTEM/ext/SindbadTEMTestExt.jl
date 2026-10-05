module SindbadTEMTestExt

using SindbadTEM
using Test

# `test_model`/`analyse_tem`'s fixture-loading chain lives under SindbadTEM's own `test/`
# directory (shipped with the package) but also reaches into `tools/benchmark/TestSindbadTEM/`
# at the Sindbad.jl monorepo root (for the static approach-variable scanner), so these two only
# work from a dev-linked checkout of the monorepo, not a plain registry install.
#
# Deferred to first call, not module load: this extension activates merely from a session having
# both `SindbadTEM` and `Test` loaded (e.g. someone's own unrelated test suite) -- it must not
# error, or do any real work, just from that.
const _EXT_LOADED = Ref(false)

function _ensure_loaded()
    _EXT_LOADED[] && return nothing
    pkg_dir = pkgdir(SindbadTEM)
    repo_root = normpath(joinpath(pkg_dir, ".."))
    isdir(joinpath(repo_root, "tools", "benchmark", "TestSindbadTEM")) || error(
        "test_model/analyse_tem need a dev-linked checkout of the Sindbad.jl monorepo -- " *
        "looked for tools/benchmark/TestSindbadTEM next to the SindbadTEM package at " *
        "$repo_root and didn't find it.",
    )
    test_dir = joinpath(pkg_dir, "test")
    # Bare `include(relative_path)` resolves against the *including file's own* @__DIR__, not
    # pwd() -- absolute paths avoid that trap.
    ENV["SINDBADTEM_SKIP_AUTORUN"] = "true"
    Base.include(@__MODULE__, joinpath(test_dir, "test_data", "forcing.jl"))
    Base.include(@__MODULE__, joinpath(test_dir, "test_data", "land.jl"))
    Base.include(@__MODULE__, joinpath(test_dir, "test_data", "referenceApproaches.jl"))
    Base.include(@__MODULE__, joinpath(test_dir, "test_data", "helpers.jl"))
    Base.include(@__MODULE__, joinpath(test_dir, "testDataCoverage.jl"))
    Base.include(@__MODULE__, joinpath(test_dir, "checkApproaches.jl"))  # defines runApproachTests
    _EXT_LOADED[] = true
    return nothing
end

# `runApproachTests` is defined by the `include` chain above, at runtime -- `invokelatest` is
# needed on the first call in a given session to dodge the resulting world-age gap.
function SindbadTEM.test_model(names::AbstractString...)
    isempty(names) && error("usage: test_model(\"approach_name\", ...)")
    _ensure_loaded()
    Base.invokelatest(runApproachTests; approaches=collect(names))
end

function SindbadTEM.analyse_tem()
    _ensure_loaded()
    Base.invokelatest(runApproachTests)
end

function SindbadTEM.analyse_process(names::AbstractString...)
    isempty(names) && error("usage: analyse_process(\"process_name\", ...)")
    _ensure_loaded()
    Base.invokelatest(runApproachTests; processes=collect(names))
end

end # module
