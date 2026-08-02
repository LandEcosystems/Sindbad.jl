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
include("testApproaches.jl")
