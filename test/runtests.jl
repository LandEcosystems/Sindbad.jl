using Sindbad
using BenchmarkTools
using Test
using LinearAlgebra
using PreallocationTools, ForwardDiff
using PolyesterForwardDiff, FiniteDifferences, FiniteDiff

@testset "Sindbad smoke" begin
    # Module loads and reexports core stack
    @test isdefined(Main, :Sindbad)
    @test isdefined(Sindbad, :SindbadTEM)
    @test isdefined(Sindbad, :Types)
    @test isdefined(Sindbad, :Setup)
    @test isdefined(Sindbad, :Simulation)
    @test isdefined(Sindbad, :Experiment)

    # Core TEM root type is visible (reexported)
    @test isdefined(Sindbad, :LandEcosystem)

    # Convenience helper is available
    @test isdefined(Sindbad, :addExtensionToSindbad)
end

@testset "Inline algorithm options" begin
    function algorithm_test_info(algorithm_optimization)
        return (
            settings=(optimization=(; algorithm_optimization),),
            temp=(experiment=(dirs=(settings="",),),),
            optimization=(;),
        )
    end

    inline_options = (;
        method="CMAEvolutionStrategyCMAES",
        options=(; maxfevals=123, ftol=1.0e-5),
    )
    info = Sindbad.Setup.setAlgorithmOptions(
        algorithm_test_info(inline_options),
        :algorithm_optimization,
    )
    @test info.optimization.optimizer.method isa Sindbad.CMAEvolutionStrategyCMAES
    @test info.optimization.optimizer.options.maxfevals == 123
    @test info.optimization.optimizer.options.ftol == 1.0e-5

    inline_options_dict = Dict(
        "method" => "CMAEvolutionStrategyCMAES",
        "options" => Dict("maxfevals" => 456),
    )
    info = Sindbad.Setup.setAlgorithmOptions(
        algorithm_test_info(inline_options_dict),
        :algorithm_optimization,
    )
    @test info.optimization.optimizer.method isa Sindbad.CMAEvolutionStrategyCMAES
    @test info.optimization.optimizer.options.maxfevals == 456
end

@testset "DataLoaders utilsDataLoaders basics" begin
    using Sindbad.DataLoaders: getDimPermutation

    # fully present spatiotemporal case
    @test getDimPermutation([:lon, :lat, :time], [:time, :lat, :lon]) == [3, 2, 1]

    # spatiovertical case where the extra dim soil_depth is not in the target list
    # and must lead rather than trail
    @test getDimPermutation([:lon, :lat, :soil_depth], [:time, :lat, :lon]) == [3, 2, 1]

    # same semantics with the extra dim in a different physical position in the source
    # this is the case the old length permDims fallback got wrong
    @test getDimPermutation([:soil_depth, :lon, :lat], [:time, :lat, :lon]) == [1, 3, 2]

    # purely spatial case with no time dim at all like f_pft
    # must not crash or go out of range
    @test getDimPermutation([:lon, :lat], [:time, :lat, :lon]) == [2, 1]

    # target dim list already matches source order exactly so this is a no-op
    @test getDimPermutation([:time, :lat, :lon], [:time, :lat, :lon]) == [1, 2, 3]

    # result is always a valid permutation of 1 through length of datDims
    for (datDims, permDims) in (
        ([:lon, :lat, :time], [:time, :lat, :lon]),
        ([:lon, :lat, :soil_depth], [:time, :lat, :lon]),
        ([:soil_depth, :lon, :lat], [:time, :lat, :lon]),
        ([:lon, :lat], [:time, :lat, :lon]),
    )
        @test sort(getDimPermutation(datDims, permDims)) == collect(1:length(datDims))
    end
end

@testset "SindbadTEM model run (via Sindbad)" begin
    # Reuse SindbadTEM's lightweight mock inputs to validate that core TEM process models
    # are runnable when users only `using Sindbad`.
    include(joinpath(@__DIR__, "mock_input", "forcing.jl"))
    include(joinpath(@__DIR__, "mock_input", "land.jl"))
    include(joinpath(@__DIR__, "mock_input", "helpers.jl"))

    # When running `Pkg.test("Sindbad")`, only `Sindbad` is guaranteed to be on the load path.
    # Access SindbadTEM through the reexported module.
    import Sindbad.SindbadTEM.Processes as SM

    @testset "ambientCO2_constant" begin
        m = SM.ambientCO2_constant()
        land_d = SM.define(m, tmp_forcing, tmp_land, tmp_helpers)
        land_p = SM.precompute(m, tmp_forcing, land_d, tmp_helpers)
        @test (@ballocated SM.compute($m, $tmp_forcing, $land_p, $tmp_helpers)) == 0
        land = SM.compute(m, tmp_forcing, land_p, tmp_helpers)
        @test land.states.ambient_CO2 == 400.0
    end

    @testset "autoRespiration_none" begin
        m = SM.autoRespiration_none()
        land_d = SM.define(m, tmp_forcing, tmp_land, tmp_helpers)
        land_p = SM.precompute(m, tmp_forcing, land_d, tmp_helpers)
        @test (@ballocated SM.compute($m, $tmp_forcing, $land_p, $tmp_helpers)) == 0
        land = SM.compute(m, tmp_forcing, land_p, tmp_helpers)
        @test land.states.c_eco_efflux == zero(tmp_land.pools.cEco)
    end
end

include("MachineLearning/test_gradientSite.jl")
