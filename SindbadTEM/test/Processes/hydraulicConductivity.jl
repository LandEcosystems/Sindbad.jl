import SindbadTEM.Processes as SM

@testset "hydraulicConductivity" verbose=true begin
    params = hydraulicConductivity_STEMMUS()
    @test typeof(params) <: LandEcosystem
    @test typeof(params) <: hydraulicConductivity

    vg = (; Theta_s = 0.43, Theta_r = 0.05, Alpha = 0.08, n = 1.6, m = 1.0 - 1.0 / 1.6)
    soil = (; Theta_U = 0.20, hh = -10.0, h = -8.0, hh_frez = 0.0, Phi_s = -0.5, Lamda = 2.0, Theta_L = 0.18, h_frez = 0.0)

    @testset "define and compute" begin
        tmp_model = hydraulicConductivity_STEMMUS(thmrlefc = 0)
        stemmus_soil_variables = (;
            Theta_U = fill(0.20f0, 4),
            hh = fill(-10.0f0, 4),
            h = fill(-8.0f0, 4),
            hh_frez = fill(0.0f0, 4),
            Phi_s = fill(-0.5f0, 4),
            Lamda = fill(2.0f0, 4),
            Theta_L = fill(0.18f0, 4),
            h_frez = fill(0.0f0, 4))
        van_genuchten = (;
            Theta_s = fill(0.43f0, 4),
            Theta_r = fill(0.05f0, 4),
            Alpha = fill(0.08f0, 4),
            n = fill(1.6f0, 4),
            m = fill(1.0f0 - 1.0f0 / 1.6f0, 4))
        land = (;
            tmp_land...,
            diagnostics = (;
                tmp_land.diagnostics...,
                dtheta_uuh = fill(-0.2f0, 4),
                theta_m = fill(0.31f0, 4),
                theta_uu = fill(0.28f0, 4),
                theta_ll = fill(0.25f0, 4),
                gamma_hh = fill(0.7f0, 4)),
            properties = (;
                tmp_land.properties...,
                stemmus_soil_variables = stemmus_soil_variables,
                van_genuchten = van_genuchten))

        land = SM.define(tmp_model, tmp_forcing, land, tmp_helpers)
        @test land.diagnostics.dtheta_llh == zero(tmp_land.pools.soilW)

        land = SM.compute(tmp_model, tmp_forcing, land, tmp_helpers)
        @test land.diagnostics.dtheta_llh ≈ fill((0.28f0 - 0.20f0) / (-10.0f0 + 8.0f0), 4)
    end

    @testset "subroutine formulas" begin
        heat_term = soil.hh
        expected = (0.31 - vg.Theta_r) * vg.Alpha * vg.n *
            abs(vg.Alpha * heat_term)^(vg.n - 1.0) *
            (-vg.m) *
            (1.0 + abs(vg.Alpha * heat_term)^vg.n)^(-vg.m - 1.0)
        got = calculateDTheta(
            params,
            1,
            heat_term,
            vg.Theta_s,
            vg.Theta_r,
            0.31,
            0.7,
            0.25,
            soil.Theta_L,
            0.28,
            soil.Theta_U,
            soil.hh,
            soil.h,
            soil.hh_frez,
            soil.h_frez,
            soil.Phi_s,
            soil.Lamda,
            vg.Alpha,
            vg.n,
            vg.m)
        @test got ≈ expected
    end

    @testset "SWCC and SFCC finite-difference branch" begin
        settings = (; SWCC = 1, SFCC = 1, Thmrlefc = false)
        expected = (0.28 - soil.Theta_U) / (soil.hh - soil.h)
        got = calculateDThetaLLh(params, -0.2, 0.31, 0.28, 0.25, 0.7, soil, vg, settings)
        @test got ≈ expected
    end

    @testset "SWCC without SFCC carries DTheta_UUh" begin
        settings = (; SWCC = true, SFCC = false, Thmrlefc = false)
        @test calculateDTheta_LLh(params, -0.2, 0.31, 0.28, 0.25, 0.7, soil, vg, settings) == -0.2
    end

    @testset "thermal branch for non-SWCC" begin
        settings = (; SWCC = 0, SFCC = 0, Thmrlefc = 1)
        expected = vg.Theta_s / soil.Phi_s * (soil.hh / soil.Phi_s)^(-soil.Lamda - 1.0)
        got = calculateDThetaLLh(params, -0.2, 0.31, 0.28, 0.25, 0.7, soil, vg, settings)
        @test got ≈ expected
    end

    @testset "zero guards" begin
        settings = (; SWCC = 1, SFCC = 1, Thmrlefc = true)
        @test iszero(calculateDThetaLLh(params, -0.2, 0.31, 0.28, 0.25, 0.0, soil, vg, settings))
    end
end
