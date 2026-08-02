import SindbadTEM.Processes as SM

@testset "autoRespiration" verbose=true begin
    check_allocations = get(ENV, "SINDBADTEM_TEST_ALLOCATIONS", "false") == "true"
    @testset "autoRespiration_none" begin
        tmp_model = autoRespiration_none()
        @test typeof(tmp_model) <: LandEcosystem
        @test typeof(tmp_model) <: autoRespiration
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
        # here, it should zeros
        @test land.states.c_eco_efflux == zero(tmp_land.pools.cEco)
    end
    @testset "autoRespiration_Thornley2000A" begin
        tmp_model = autoRespiration_Thornley2000A()
        @test typeof(tmp_model) <: LandEcosystem
        @test typeof(tmp_model) <: autoRespiration
        # update land with define
        land_d = SM.define(tmp_model, tmp_forcing, tmp_land, tmp_helpers)
        land_p = SM.precompute(tmp_model, tmp_forcing, land_d, tmp_helpers)
        # Optional performance check (can be brittle across Julia/CI)
        if check_allocations
            SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers) # warm-up
            @test (@allocated SM.compute(tmp_model, tmp_forcing, land_p, tmp_helpers)) == 0
        end
        # # check output
        # land = SM.compute(tmp_model, tmp_forcing, land_d, tmp_helpers)
        # # here
        # 
    end
end