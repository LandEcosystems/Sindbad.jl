using SindbadTEM
using StaticArrays
using Test
import SindbadTEM.Processes as SM

# Tests of plantHydraulics_CLM: CLM5 leaf temperature and ci with the plant hydraulic system and the water stress of plantHydraulics_PHS.
# Run standalone with: julia --project=SindbadTEM SindbadTEM/test/Processes/plantHydraulics_CLM.jl

const SVec = SVector

# mock forcing and land of a four-layer soil, soil_frac is the relative soil moisture between the residual and saturated content.
function clm_mock_inputs(::Type{T}=Float64; soil_frac=0.6, LAI=3.0, VPD=1.2, airT=22.0, rn=14.0, par=10.0, ws=2.5, H=15.0) where {T}
    N = 4
    thickness = SVec{N,T}((T(100), T(200), T(400), T(800)))
    θ_sat, θ_res = T(0.45), T(0.05)
    soilW = SVec{N,T}(ntuple(i -> (θ_res + soil_frac * (θ_sat - θ_res)) * thickness[i], N))
    forcing = (;
        f_alpha_van_Genuchten=T(1.5), f_eta_van_Genuchten=T(1.6),
        f_thetar_van_Genuchten=θ_res, f_thetas_van_Genuchten=θ_sat,
        f_rn=T(rn), f_PAR=T(par), f_psurf_day=T(100.0), f_airT_day=T(airT), f_VPD_day=T(VPD),
        f_ws=T(ws), f_daytime_seconds=T(12 * 3600), f_canopy_height=T(H), f_month_air_temperature=T(airT),
    )
    land = (;
        pools=(; soilW, ΔsoilW=zero(soilW)),
        constants=(; z_zero=zero(T), o_one=one(T)),
        states=(; LAI=T(LAI), fAPAR=T(1 - exp(-0.5 * LAI)), ambient_CO2=T(400), PAW=soilW .- T(0.1) * T(0.4) .* thickness, plant_form=:tree),
        properties=(; soil_layer_thickness=thickness, sp_k_sat=SVec{N,T}(ntuple(_ -> T(500.0), N))),
        diagnostics=(; root_surface_area=SVec{N,T}((T(0.5), T(0.8), T(0.6), T(0.3))), c_allocation=SVec{3,T}((T(0.3), T(0.4), T(0.3)))),
        fluxes=(;),
        rootWaterEfficiency=(; root_over=SVec{N,T}(ntuple(_ -> one(T), N))),
    )
    return forcing, land
end

function clm_run(::Type{T}=Float64; params=SM.plantHydraulics_CLM{T}(), kwargs...) where {T}
    forcing, land = clm_mock_inputs(T; kwargs...)
    land = SM.define(params, forcing, land, nothing)
    land = SM.precompute(params, forcing, land, nothing)
    land = SM.compute(params, forcing, land, nothing)
    return land, forcing
end

@testset "plantHydraulics_CLM" verbose=true begin
    p = SM.plantHydraulics_CLM()
    p_phs = SM.plantHydraulics_PHS()

    @testset "same parameter values, same hydraulics as plantHydraulics_PHS" begin
        # the shared parameters have the same names and defaults.
        for name in (:root_radius, :root_lateral_length, :stem_to_leaf_area_ratio, :p50_leaf, :p50_stem, :p50_root, :shape_factor_leaf, :shape_factor_stem,
            :shape_factor_root, :k_root_max, :k_stem_max, :k_leaf_max, :minimum_conductance, :minimum_lai, :minimum_soil_potential, :minimum_root_potential,
            :maximum_soil_root_resistance, :minimum_water_stress, :convergence_water_potential, :psi_leaf_damping, :m_to_MPa, :mm_2_m, :m_to_mm)
            @test getfield(p, name) == getfield(p_phs, name)
        end

        # vulnerability curve
        for ψ in (0.0, -5.0, -30.0, -67.67, -200.0, -1000.0), (ψ50, shape) in ((p.p50_leaf, p.shape_factor_leaf), (p.p50_root, p.shape_factor_root))
            @test SM.cal_vulnerability_curve(p, ψ, ψ50, shape) == SM.cal_vulnerability_curve(p_phs, ψ, ψ50, shape)
        end
        @test SM.cal_vulnerability_curve(p, 0.0, p.p50_leaf, p.shape_factor_leaf) == 1.0
        @test SM.cal_vulnerability_curve(p, -1.0e4, p.p50_leaf, p.shape_factor_leaf) < 1.0e-6

        # soil-root hydraulics, root potential, plant water potentials, and root uptake
        forcing, land = clm_mock_inputs()
        land_clm = SM.precompute(p, forcing, SM.define(p, forcing, land, nothing), nothing)
        land_phs = SM.precompute(p_phs, forcing, SM.define(p_phs, forcing, land, nothing), nothing)
        land_clm = SM.cal_soil_hydrology(p, forcing, land_clm, nothing)
        land_phs = SM.cal_soil_hydrology(p_phs, forcing, land_phs, nothing)
        for name in (:θ_soil, :θ_res, :θ_sat, :soil_saturation, :Κ_soil_root, :Κ_soil, :Κ_root, :Κ_soil_unsat, :ψ_soil, :ψ_soil_matric, :β_root, :RAI, :fraction_root)
            @test getfield(land_clm.diagnostics, name) == getfield(land_phs.diagnostics, name)
        end

        d = land_clm.diagnostics
        root_over = land.rootWaterEfficiency.root_over
        rl = SM._root_potential_linear(p, d.Κ_soil_root, d.Κ_soil, d.Κ_root, d.ψ_soil, d.fraction_root, d.root_surface_area, root_over)
        rl_phs = SM._root_potential_linear(p_phs, d.Κ_soil_root, d.Κ_soil, d.Κ_root, d.ψ_soil, d.fraction_root, d.root_surface_area, root_over)
        @test rl.mode == 1 && (rl.mode, rl.A, rl.B) == (rl_phs.mode, rl_phs.A, rl_phs.B)
        for Q in (0.0, 1.0e-4, 1.0e-3, 5.0e-3)
            @test SM._plant_hydraulic(p, rl, 15.0, 3.0, Q) == SM._plant_hydraulic(p_phs, rl_phs, 15.0, 3.0, Q)
        end
        ψ_root, ψ_stem, ψ_leaf = SM._plant_hydraulic(p, rl, 15.0, 3.0, 2.0e-3)
        @test ψ_leaf < ψ_stem < ψ_root # water flows from the soil to the atmosphere

        wn, _, _ = SM._root_layer_weights(p, d.Κ_soil, d.Κ_root, d.ψ_soil, d.fraction_root, d.root_surface_area, root_over)
        wn_phs, _, _ = SM._root_layer_weights(p_phs, d.Κ_soil, d.Κ_root, d.ψ_soil, d.fraction_root, d.root_surface_area, root_over)
        @test wn == wn_phs && sum(wn) ≈ 1
        @test SM._root_water_uptake_layers(p, wn, 3.0e-3, land.states.PAW) == SM._root_water_uptake_layers(p_phs, wn, 3.0e-3, land.states.PAW)
    end

    @testset "Medlyn conductance equals stomatalConductance_CLM" begin
        for an in (0.5, 5.0, 12.0, 25.0), vpd in (0.1, 1.0, 3.0), gb in (5.0e5, 2.0e6), P_kPa in (90.0, 101.3)
            cair = 400.0e-6 * P_kPa * 1000
            gs = SM._clm_medlyn_gs(p, an, cair, P_kPa * 1000, gb, vpd)
            reference = SM._clm_medlyn_conductance(an, 400.0, P_kPa, vpd, gb, p.g0 * 1.0e6, p.g1, p.diffusivity_ratio, p.boundary_co2_ratio, p.minimum_vpd)
            @test gs ≈ reference rtol=1.0e-10
        end
        # the conductance stays at its minimum when the net assimilation is negative.
        @test SM._clm_medlyn_gs(p, -1.0, 40.0, 1.0e5, 1.0e6, 1.0) == max(p.g0 * 1.0e6, p.minimum_gs)
    end

    @testset "ci is the single root of the CLM residual" begin
        P_Pa = 1.0e5
        bio = SM._clm_leaf_biochemistry(p, 298.15, 20.0, 3.0, 30.0, P_Pa)
        leaf = (; cair=40.0, oair=p.k_co / 1.0e6 * P_Pa, P_Pa, vpd=1.2, gb_mol=1.0e6, Dq=0.0)
        for b in (1.0, 0.5, 0.1)
            solution = SM._clm_solve_ci(p, bio, leaf, b, 28.0)
            @test solution.converged
            @test abs(solution.fval) < 1.0e-3
            @test bio.gamma_star < solution.ci < leaf.cair
            @test solution.ag > solution.an > 0
            grid = range(bio.gamma_star * 1.0005, leaf.cair, length=2000)
            residual = [SM._clm_ci_function(p, bio, leaf, ci, b)[1] for ci in grid]
            @test count(i -> residual[i] * residual[i+1] < 0, 1:length(grid)-1) == 1
        end
        # the water stress lowers the assimilation
        full = SM._clm_solve_ci(p, bio, leaf, 1.0, 28.0)
        stressed = SM._clm_solve_ci(p, bio, leaf, 0.1, 28.0)
        @test stressed.ag < full.ag
    end

    @testset "base case" begin
        land, forcing = clm_run()
        d = land.diagnostics
        @test d.clm_coupling_converged && d.clm_ci_converged && d.clm_hydraulic_converged
        @test d.clm_leaf_iterations <= 41
        @test 0 < d.ci_Pa < 400.0e-6 * 100.0e3
        @test d.gpp_farquhar > 0 && d.phs_transpiration > 0 && d.tran_gs > 0
        # the water stress is the vulnerability of the leaf water potential
        @test d.gpp_f_soilW == d.β_leaf
        @test d.β_leaf == SM.cal_vulnerability_curve(p, d.ψ_leaf, p.p50_leaf, p.shape_factor_leaf)
        @test 0 < d.β_leaf <= 1
        @test d.ψ_leaf <= d.ψ_stem <= d.ψ_root
        # the potentials are those of the transpiration: root, stem, and leaf water potentials of plantHydraulics_PHS
        forcing_, land_ = clm_mock_inputs()
        land_ = SM.precompute(p, forcing_, SM.define(p, forcing_, land_, nothing), nothing)
        land_ = SM.cal_soil_hydrology(p, forcing_, land_, nothing)
        dd = land_.diagnostics
        rl = SM._root_potential_linear(p, dd.Κ_soil_root, dd.Κ_soil, dd.Κ_root, dd.ψ_soil, dd.fraction_root, dd.root_surface_area, land_.rootWaterEfficiency.root_over)
        ψ_root, ψ_stem, ψ_leaf = SM._plant_hydraulic(p, rl, 15.0, 3.0, d.tran_gs * p.mm_2_m)
        @test d.ψ_root ≈ ψ_root && d.ψ_stem ≈ ψ_stem && d.ψ_leaf ≈ ψ_leaf
        # energy closes: Rn = H + LE
        @test abs(d.temp_leaf_balance) < 0.05
        @test d.LE_canopy + d.H_canopy_flux ≈ d.Rn_canopy atol=0.05
        # the latent heat is the transpiration (the canopy holds no water): mm d-1 is kg m-2 per day over the 12 daytime hours
        @test d.LE_canopy ≈ d.tran_gs / (12 * 3600) * p.hvap rtol=1.0e-3
        # the water-limited transpiration is the root water uptake, which is not more than the demand
        @test d.phs_transpiration ≈ sum(land.fluxes.phs_root_water_uptake)
        @test d.phs_transpiration <= d.tran_gs + 1.0e-9
        @test all(>=(0), land.fluxes.phs_root_water_uptake)
        # the leaf is warmer than the air by the sensible heat
        @test d.leaf_temp_diff > 0
        @test d.temp_leaf_degC ≈ forcing.f_airT_day + d.leaf_temp_diff
        @test d.temp_leaf_K ≈ d.temp_leaf_degC + 273.15
        @test d.clm_absorbed_par ≈ forcing.f_PAR * 1.0e6 / forcing.f_daytime_seconds * land.states.fAPAR
        # the net photosynthesis is the gross photosynthesis minus the dark respiration
        @test d.net_photosynthesis ≈ d.gpp_farquhar - d.dark_respiration
        @test d.gpp_farquhar <= d.Ac_gC + 1.0e-9 && d.gpp_farquhar <= d.Aj_gC + 1.0e-9
    end

    @testset "drought lowers the leaf water potential, the water stress, GPP, and transpiration" begin
        wet, _ = clm_run(soil_frac=0.8)
        mid, _ = clm_run(soil_frac=0.35)
        dry, _ = clm_run(soil_frac=0.12)
        @test wet.diagnostics.ψ_leaf >= mid.diagnostics.ψ_leaf >= dry.diagnostics.ψ_leaf
        @test wet.diagnostics.ψ_root >= mid.diagnostics.ψ_root >= dry.diagnostics.ψ_root
        for key in (:gpp_f_soilW, :gpp_farquhar, :tran_gs)
            @test getfield(wet.diagnostics, key) >= getfield(mid.diagnostics, key) >= getfield(dry.diagnostics, key)
        end
        @test dry.diagnostics.gpp_f_soilW < wet.diagnostics.gpp_f_soilW
        @test dry.diagnostics.leaf_temp_diff >= wet.diagnostics.leaf_temp_diff - 1.0e-6
    end

    @testset "climate sensitivity" begin
        cases = (
            (; airT=32.0, VPD=3.5), (; airT=3.0, VPD=0.3, par=4.0, rn=4.0), (; par=0.0, rn=0.0),
            (; ws=8.0), (; ws=0.2), (; LAI=0.4), (; LAI=7.0), (; airT=-5.0, VPD=0.2),
        )
        for kwargs in cases
            land, _ = clm_run(; kwargs...)
            d = land.diagnostics
            @test all(isfinite, (d.temp_leaf_degC, d.gpp_farquhar, d.tran_gs, d.phs_transpiration, d.ci_Pa, d.gpp_f_soilW, d.temp_leaf_balance, d.ψ_leaf))
            @test all(isfinite, land.fluxes.phs_root_water_uptake)
            @test d.clm_leaf_iterations <= 41
            @test d.gpp_farquhar >= 0
        end
        # without light there is no assimilation, only the minimum stomatal conductance
        dark, _ = clm_run(par=0.0, rn=0.0)
        @test dark.diagnostics.gpp_farquhar == 0
        @test dark.diagnostics.temp_leaf_degC ≈ 22.0 atol=0.1
        # more wind couples the leaf to the air
        calm, _ = clm_run(ws=0.5)
        windy, _ = clm_run(ws=8.0)
        @test windy.diagnostics.leaf_temp_diff < calm.diagnostics.leaf_temp_diff
    end

    @testset "inactive canopy" begin
        land, forcing = clm_run(LAI=0.0)
        d = land.diagnostics
        @test d.temp_leaf_degC ≈ forcing.f_airT_day
        @test d.gpp_farquhar == 0 && d.tran_gs == 0 && d.phs_transpiration == 0
        @test all(iszero, land.fluxes.phs_root_water_uptake)
        @test d.clm_leaf_iterations == 0
    end

    @testset "Float32 stays Float32 and agrees with Float64" begin
        land64, _ = clm_run(Float64)
        land32, _ = clm_run(Float32)
        d32 = land32.diagnostics
        @test d32.temp_leaf_degC isa Float32 && d32.gpp_farquhar isa Float32 && d32.phs_transpiration isa Float32
        @test eltype(land32.fluxes.phs_root_water_uptake) == Float32
        @test d32.temp_leaf_degC ≈ land64.diagnostics.temp_leaf_degC atol=0.01
        @test d32.gpp_farquhar ≈ land64.diagnostics.gpp_farquhar rtol=1.0e-3
        @test d32.phs_transpiration ≈ land64.diagnostics.phs_transpiration rtol=1.0e-3
        @test d32.clm_hydraulic_converged
    end

    @testset "random forcing: finite, bounded, and converged" begin
        # a deterministic pseudo-random sequence, the canopy radiation is consistent with LAI.
        state = UInt32(2463534242)
        next() = (state ⊻= state << 13; state ⊻= state >> 17; state ⊻= state << 5; Float64(state) / Float64(typemax(UInt32)))
        n = 300
        not_finite = not_converged = 0
        for _ in 1:n
            kwargs = (; soil_frac=0.02 + 0.98 * next(), LAI=exp(log(0.2) + next() * (log(8.0) - log(0.2))), VPD=0.05 + 5.0 * next(),
                airT=-8.0 + 48.0 * next(), rn=40.0 * next(), par=25.0 * next(), ws=0.1 + 9.0 * next(), H=0.1 + 40.0 * next())
            land, _ = clm_run(; kwargs...)
            d = land.diagnostics
            ok = all(isfinite, (d.temp_leaf_degC, d.gpp_farquhar, d.tran_gs, d.phs_transpiration, d.ci_Pa, d.gpp_f_soilW, d.temp_leaf_balance, d.ψ_leaf)) &&
                 all(isfinite, land.fluxes.phs_root_water_uptake)
            not_finite += !ok
            not_converged += !d.clm_coupling_converged
        end
        @test not_finite == 0
        @test not_converged <= 0.02 * n
    end

    @testset "consumers: gpp_PHS, rootWaterUptake_PHS, transpiration_PHS" begin
        land, forcing = clm_run()
        land = SM.define(SM.rootWaterUptake_PHS(), forcing, land, nothing)
        land = SM.compute(SM.rootWaterUptake_PHS(), forcing, land, nothing)
        land = SM.compute(SM.gpp_PHS(), forcing, land, nothing)
        land = SM.compute(SM.transpiration_PHS(), forcing, land, nothing)
        @test land.fluxes.gpp == land.diagnostics.gpp_farquhar
        @test land.fluxes.root_water_uptake == land.fluxes.phs_root_water_uptake
        @test land.pools.ΔsoilW == -land.fluxes.root_water_uptake
        @test land.fluxes.transpiration == min(land.diagnostics.tran_gs, sum(land.fluxes.root_water_uptake))
    end
end
