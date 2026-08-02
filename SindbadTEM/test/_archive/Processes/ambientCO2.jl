import SindbadTEM.Processes as SM

@testset "ambientCO2" verbose=true begin
    check_allocations = get(ENV, "SINDBADTEM_TEST_ALLOCATIONS", "false") == "true"
    @testset "ambientCO2_constant" begin
        tmp_model = ambientCO2_constant()
        @test typeof(tmp_model) <: LandEcosystem
        @test typeof(tmp_model) <: ambientCO2
        # update land with define
        land_d = SM.define(tmp_model, tmp_forcing, tmp_land, tmp_helpers)
        land_p = SM.precompute(tmp_model, tmp_forcing, land_d, tmp_helpers)
        # Optional performance check (can be brittle across Julia/CI)
        if check_allocations
            SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers) # warm-up
            @test (@allocated SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers)) == 0
        end
        # check output
        land = SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers)
        # here, it should be the default value
        @test land.states.ambient_CO2 == 400.0
    end
    @testset "ambientCO2_forcing" begin
        tmp_model = ambientCO2_forcing()
        @test typeof(tmp_model) <: LandEcosystem
        @test typeof(tmp_model) <: ambientCO2
        # update land with define
        land_d = SM.define(tmp_model, tmp_forcing, tmp_land, tmp_helpers)
        land_p = SM.precompute(tmp_model, tmp_forcing, land_d, tmp_helpers)
        # Optional performance check (can be brittle across Julia/CI)
        if check_allocations
            SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers) # warm-up
            @test (@allocated SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers)) == 0
        end
        # check output
        land = SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers)
        # here, it should be the input forcing
        @test land.states.ambient_CO2 == 336.01f0
    end
end