using SindbadTEM
using Test

@testset "SindbadTEM smoke" begin
    # Module loads and key submodules are present -- fails fast with a clear message if package
    # structure itself is broken, rather than as a confusing crash deep in the approach tests.
    @test isdefined(SindbadTEM, :LandEcosystem)
    @test isdefined(SindbadTEM, :TEMTypes)
    @test isdefined(SindbadTEM, :Utils)
    @test isdefined(SindbadTEM, :Variables)
    @test isdefined(SindbadTEM, :Processes)
end

include(joinpath("test_data", "forcing.jl"))
include(joinpath("test_data", "land.jl"))
include(joinpath("test_data", "referenceApproaches.jl"))
include(joinpath("test_data", "helpers.jl"))
# provides tmp_forcing, land, reference_approaches, tmp_helpers

include("testDataCoverage.jl")
# checkApproaches.jl (every approach's define/precompute/compute -- update is opt-in, off by
# default -- run against the real process sequence) deliberately isn't included here: it's pure
# Julia logic with no OS-specific behavior, so running it across Pkg.test's full 3-OS x
# 2-Julia-version matrix on every push is wasted cost -- it runs on demand instead, via
# SindbadTEM/test/runApproachChecks.jl (see .github/workflows/SindbadTEM-benchmark.yml's
# approach-checks job, and SindbadTEM/test/README.md).
