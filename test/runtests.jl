using Sindbad
using BenchmarkTools
using Test
using LinearAlgebra
using PreallocationTools, ForwardDiff, Flux, Zygote
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