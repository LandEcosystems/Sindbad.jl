# Standalone entry point for checkApproaches.jl -- deliberately NOT included by runtests.jl (see
# the comment there for why). Run directly:
#
#   julia --project=SindbadTEM SindbadTEM/test/runApproachChecks.jl
#
# from the repo root, or as the "approach-checks" job in .github/workflows/SindbadTEM-benchmark.yml.

using SindbadTEM
using Test

cd(@__DIR__) do
    include(joinpath("test_data", "forcing.jl"))
    include(joinpath("test_data", "land.jl"))
    include(joinpath("test_data", "referenceApproaches.jl"))
    include(joinpath("test_data", "helpers.jl"))
    include("testDataCoverage.jl")
    include("checkApproaches.jl")
end
