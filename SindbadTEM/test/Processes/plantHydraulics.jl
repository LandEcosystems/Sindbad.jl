import SindbadTEM.Processes as SM

#=
Legacy tests for the removed three-state handwritten Newton implementation are
kept here temporarily for reference. The active PHS model now solves the
five-state equilibrium with NonlinearSolve.jl; its tests follow this block.
@testset "plantHydraulics PHS Newton" verbose=true begin
    params = plantHydraulics_PHS(
        k_leaf_max=0.05,
        k_stem_max=0.05,
        p50_leaf=-100.0,
        p50_stem=-100.0,
        p50_leaf_stress=-100.0,
    )
    lai = 2.0
    sai = params.stem_to_leaf_area_ratio * lai
    canopy_height = 10.0

    @testset "finite vulnerability limits" begin
        for T in (Float32, Float64)
            extreme_tension = -floatmax(T)
            vulnerability = SM._phs_vulnerability(extreme_tension, -one(T), T(20))
            value, derivative = SM._phs_vulnerability_and_derivative(
                extreme_tension,
                -one(T),
                T(20),
            )
            @test isfinite(vulnerability) && iszero(vulnerability)
            @test isfinite(value) && iszero(value)
            @test isfinite(derivative) && iszero(derivative)
        end
    end

    @testset "non-finite input containment" begin
        bad_soil_params = plantHydraulics_PHS(nvg=NaN, avg=NaN)
        unsafe_params = plantHydraulics_PHS(
            root_radius=NaN,
            biomass_to_carbon=NaN,
            root_density=NaN,
            pi_value=NaN,
            min_root_length_density=NaN,
            minimum_height=NaN,
            minimum_lai=NaN,
            p50_leaf=NaN,
            p50_stem=NaN,
            p50_leaf_stress=NaN,
            shape_factor_leaf=NaN,
            shape_factor_stem=NaN,
            k_leaf_max=NaN,
            k_stem_max=NaN,
            newton_residual_tolerance=NaN,
            newton_relative_tolerance=NaN,
            newton_step_tolerance=NaN,
            newton_max_step=NaN,
            newton_min_damping=NaN,
        )

        for T in (Float32, Float64)
            values = T[NaN, -Inf, Inf, -floatmax(T), -one(T), zero(T), one(T), floatmax(T)]
            psi50_values = T[NaN, -Inf, Inf, -one(T), zero(T), floatmax(T)]
            shape_values = T[NaN, -Inf, Inf, -one(T), zero(T), one(T), T(20)]

            for psi in values, psi50 in psi50_values, shape in shape_values
                vulnerability = SM._phs_vulnerability(psi, psi50, shape)
                derivative = SM._phs_vulnerability_derivative(psi, psi50, shape)
                combined_value, combined_derivative =
                    SM._phs_vulnerability_and_derivative(psi, psi50, shape)
                @test all(isfinite, (vulnerability, derivative, combined_value, combined_derivative))
                @test zero(T) <= vulnerability <= one(T)
                @test zero(T) <= combined_value <= one(T)
            end

            for θ in values, θ_wp in values, inverse_range in values
                soil_potential = SM._phs_soil_potential(
                    bad_soil_params,
                    θ,
                    θ_wp,
                    inverse_range,
                )
                @test isfinite(soil_potential)
                @test -T(5.0e3) <= soil_potential <= zero(T)
            end

            for root_carbon in values, thickness in values, root_fraction in values
                spacing = SM._phs_root_spacing(
                    unsafe_params,
                    root_carbon,
                    thickness,
                    root_fraction,
                )
                @test isfinite(spacing) && spacing > zero(T)
            end

            invalid_states = (
                SindbadTEM.SVector(T(NaN), T(NaN), T(NaN)),
                SindbadTEM.SVector(-T(Inf), T(Inf), T(NaN)),
                SindbadTEM.SVector(-floatmax(T), -one(T), zero(T)),
            )
            bad_layers = T[NaN, -Inf, Inf]
            bad_conductance = T[NaN, -Inf, Inf]
            bad_uptake = T[NaN, -Inf, Inf]
            for state in invalid_states
                residual, jacobian = SM._phs_residual_jacobian(
                    unsafe_params,
                    state,
                    bad_layers,
                    bad_conductance,
                    bad_uptake,
                    T(NaN),
                    T(NaN),
                    T(NaN),
                    T(NaN),
                )
                @test all(isfinite, residual)
                @test all(isfinite, jacobian)

                solution, _, iterations, residual_norm = SM._solve_phs_newton(
                    unsafe_params,
                    state,
                    bad_layers,
                    bad_conductance,
                    bad_uptake,
                    T(NaN),
                    T(NaN),
                    T(NaN),
                    T(NaN),
                )
                @test all(isfinite, solution)
                @test isfinite(residual_norm)
                @test 0 <= iterations <= 50
            end

            bad_matrix = SM.SMatrix{3,3}(
                T(NaN), T(Inf), -T(Inf),
                floatmax(T), T(NaN), -floatmax(T),
                T(Inf), -T(Inf), T(NaN),
            )
            determinant = SM._phs_determinant(bad_matrix)
            linear_solution = SM._phs_solve_3x3(
                bad_matrix,
                SindbadTEM.SVector(T(NaN), T(Inf), -T(Inf)),
                determinant,
            )
            @test isfinite(determinant)
            @test all(isfinite, linear_solution)
        end
    end

    @testset "root-spacing parameters" begin
        @test params.biomass_to_carbon == 0.488
        @test params.root_density == 2.5e5
        @test params.pi_value ≈ pi

        reference_spacing = SM._phs_root_spacing(params, 100.0, 0.3, 0.5)
        dense_tissue_spacing = SM._phs_root_spacing(
            plantHydraulics_PHS(root_density=5.0e5), 100.0, 0.3, 0.5,
        )
        @test dense_tissue_spacing > reference_spacing
    end

    @testset "analytic Jacobian" begin
        state = SindbadTEM.SVector(-20.0, -15.0, -2.5)
        layer_head = [-1.0, -2.0, -4.0]
        layer_conductance = [0.05, 0.03, 0.02]
        uptake_capacity = fill(1.0, 3)
        demand = 1.0e-3
        _, jacobian = SM._phs_residual_jacobian(
            params,
            state,
            layer_head,
            layer_conductance,
            uptake_capacity,
            demand,
            lai,
            sai,
            canopy_height,
        )
        step = 1.0e-6
        for column in eachindex(state)
            state_plus = Base.setindex(state, state[column] + step, column)
            state_minus = Base.setindex(state, state[column] - step, column)
            residual_plus, _ = SM._phs_residual_jacobian(
                params, state_plus, layer_head, layer_conductance,
                uptake_capacity, demand,
                lai, sai, canopy_height,
            )
            residual_minus, _ = SM._phs_residual_jacobian(
                params, state_minus, layer_head, layer_conductance,
                uptake_capacity, demand,
                lai, sai, canopy_height,
            )
            finite_difference = (residual_plus - residual_minus) / (2 * step)
            @test jacobian[:, column] ≈ finite_difference rtol=1.0e-5 atol=1.0e-9
        end
    end

    @testset "flux continuity" begin
        layer_head = [-1.0, -2.0, -4.0]
        layer_conductance = [0.05, 0.03, 0.02]
        uptake_capacity = fill(1.0, 3)
        demand = 1.0e-3

        solution, converged, iterations, residual_norm = SM._solve_phs_newton(
            params,
            [-20.0, -15.0, -2.0],
            layer_head,
            layer_conductance,
            uptake_capacity,
            demand,
            lai,
            sai,
            canopy_height,
        )
        residual, _ = SM._phs_residual_jacobian(
            params,
            solution,
            layer_head,
            layer_conductance,
            uptake_capacity,
            demand,
            lai,
            sai,
            canopy_height,
        )

        @test converged
        @test iterations <= 10
        @test residual_norm < 1.0e-8
        @test maximum(abs, residual) < 1.0e-8
        @test solution[1] <= solution[2] <= solution[3]
    end

    @testset "one-way soil-to-root flux" begin
        layer_head = [-1.0, -10.0]
        layer_conductance = [0.1, 0.1]
        uptake_capacity = fill(1.0, 2)
        demand = 1.0e-4

        solution, converged, _, residual_norm = SM._solve_phs_newton(
            params,
            [-20.0, -15.0, -5.0],
            layer_head,
            layer_conductance,
            uptake_capacity,
            demand,
            lai,
            sai,
            canopy_height,
        )
        layer_flux = [
            SM._phs_bounded_soil_flux(
                layer_head[i],
                layer_conductance[i],
                uptake_capacity[i],
                solution[3],
            ) for i in eachindex(layer_head)
        ]
        transpiration = demand * SM._phs_vulnerability(
            solution[1],
            params.p50_leaf_stress,
            params.shape_factor_leaf,
        )

        @test converged
        @test residual_norm < 1.0e-8
        @test any(layer_flux .> 0)
        @test all(layer_flux .>= 0)
        @test layer_flux[2] == 0.0
        @test sum(layer_flux) ≈ transpiration atol=1.0e-8
    end

    @testset "water-availability constraint remains closed" begin
        layer_head = [-1.0, -2.0]
        layer_conductance = [0.1, 0.1]
        uptake_capacity = [1.0e-5, 1.0e-5]
        demand = 1.0e-2

        solution, converged, _, residual_norm = SM._solve_phs_newton(
            params,
            [-20.0, -15.0, -5.0],
            layer_head,
            layer_conductance,
            uptake_capacity,
            demand,
            lai,
            sai,
            canopy_height,
        )
        layer_flux = [
            SM._phs_bounded_soil_flux(
                layer_head[i],
                layer_conductance[i],
                uptake_capacity[i],
                solution[3],
            ) for i in eachindex(layer_head)
        ]
        transpiration = demand * SM._phs_vulnerability(
            solution[1],
            params.p50_leaf_stress,
            params.shape_factor_leaf,
        )

        @test converged
        @test residual_norm < 1.0e-8
        @test all(layer_flux .<= uptake_capacity)
        @test sum(layer_flux) ≈ transpiration atol=1.0e-8
    end

    @testset "nonnegative soil-water update and transpiration" begin
        phs_flux = [1.5, -0.5]
        land = (;
            pools=(; soilW=[10.0, 10.0], ΔsoilW=[0.0, 0.0]),
            diagnostics=(; phs_transpiration=1.5),
            fluxes=(; phs_root_water_uptake=phs_flux, root_water_uptake=zeros(2)),
        )
        land = SM.compute(rootWaterUptake_PHS(), nothing, land, tmp_helpers)
        @test land.fluxes.root_water_uptake == [1.5, 0.0]
        @test land.pools.ΔsoilW == [-1.5, 0.0]

        land = SM.compute(transpiration_PHS(), nothing, land, tmp_helpers)
        @test land.fluxes.transpiration == 1.5
    end
end
=#

@testset "plantHydraulics PHS NonlinearSolve" verbose=true begin
    canopy_height = 2.0
    gamma_star = 10.0
    ca = 50.0
    gs_upper = 4.0
    state_scale = SindbadTEM.SVector(5.0, 5.0, 5.0, 20.0, 3.0)
    initial = SindbadTEM.SVector{5,Float32}(-8.0, -6.0, -2.0, 20.0, 1.0)
    target = SindbadTEM.SVector(-4.25, -3.5, -1.0, 30.0, 2.0)

    residual = state -> SindbadTEM.SVector(
        (state[1] - target[1]) / state_scale[1],
        (state[2] - target[2]) / state_scale[2],
        (state[3] - target[3]) / state_scale[3],
        (state[4] - target[4]) / state_scale[4],
        (state[5] - target[5]) / state_scale[5],
    )

    @testset "strict five-state equilibrium" begin
        result = SM.solve_coupled_phs_equilibrium(
            initial,
            residual,
            state_scale[1];
            canopy_height=canopy_height,
            gamma_star=gamma_star,
            ca=ca,
            gs_upper=gs_upper,
            residual_tolerance=1.0e-8,
        )

        @test result.converged
        @test result.status == :trust_region_converged
        @test result.residual_norm <= 1.0e-8
        @test maximum(abs, residual(result.solution)) <= 1.0e-8
        @test result.solution[1] < result.solution[2]
        @test result.solution[2] < result.solution[3] - canopy_height
        @test result.solution[3] < 0.0
        @test gamma_star < result.solution[4] < ca
        @test 0.0 < result.solution[5] < gs_upper
        @test result.function_evaluations > 0
        @test result.iterations > 0
    end

    @testset "strict failure for an inconsistent system" begin
        impossible_residual = _ -> SindbadTEM.SVector(1.0, 0.0, 0.0, 0.0, 0.0)
        result = SM.solve_coupled_phs_equilibrium(
            initial,
            impossible_residual,
            state_scale[1];
            canopy_height=canopy_height,
            gamma_star=gamma_star,
            ca=ca,
            gs_upper=gs_upper,
            residual_tolerance=1.0e-8,
            maximum_iterations=10,
        )

        @test !result.converged
        @test result.residual_norm == 1.0
        @test result.fallback_steps == 1
        @test result.iterations > 0
    end

    @testset "invalid physical interval is rejected" begin
        result = SM.solve_coupled_phs_equilibrium(
            initial,
            residual,
            state_scale[1];
            canopy_height=canopy_height,
            gamma_star=ca,
            ca=ca,
            gs_upper=gs_upper,
        )

        @test !result.converged
        @test result.status == :invalid_solver_setup
    end

    @testset "nonnegative soil-water update and transpiration" begin
        phs_flux = [1.5, -0.5]
        land = (;
            pools=(; soilW=[10.0, 10.0], ΔsoilW=[0.0, 0.0]),
            diagnostics=(; phs_transpiration=1.5),
            fluxes=(; phs_root_water_uptake=phs_flux, root_water_uptake=zeros(2)),
        )
        land = SM.compute(rootWaterUptake_PHS(), nothing, land, tmp_helpers)
        @test land.fluxes.root_water_uptake == [1.5, 0.0]
        @test land.pools.ΔsoilW == [-1.5, 0.0]

        land = SM.compute(transpiration_PHS(), nothing, land, tmp_helpers)
        @test land.fluxes.transpiration == 1.5
    end
end

struct _STEMMUSTestUnsaturatedConductivity end
SM.unsatK(land, helpers, sl, ::_STEMMUSTestUnsaturatedConductivity) = 50.0

@testset "plantHydraulics STEMMUS daily coupling" verbose=true begin
    @testset "retention, vulnerability, and gas-exchange equations" begin
        @test SM._stemmus_soil_potential(
            0.30, 0.10, 5.0, 1.56, 3.6, -5000.0,
        ) ≈ 0.0 atol=1.0e-10
        @test -5000.0 <= SM._stemmus_soil_potential(
            0.10, 0.10, 5.0, 1.56, 3.6, -5000.0,
        ) < 0.0
        for curve in (1.0, 2.0, 3.0)
            @test SM._stemmus_hydraulic_stress(
                -100.0, -100.0, 1.98, curve, -0.33, 0.00981,
            ) ≈ 0.5
        end

        assimilation = SM._stemmus_leaf_assimilation(
            12.011 * 86400 / 1.0e6, 1.0, 1.0e-6, 12.011, 86400.0,
        )
        @test assimilation ≈ 1.0
        relative_humidity = SM._stemmus_relative_humidity(20.0, 1.0)
        @test 0.0 < relative_humidity < 1.0
        conductance = SM._stemmus_stomatal_conductance(
            2.0, assimilation, 400.0, 1.0, relative_humidity,
            9.0, 0.01, 9.0, 0.001, 0.05,
        )
        transpiration, canopy_conductance =
            SM._stemmus_transpiration_from_conductance(
                conductance, 2.0, 2.0, 1.0, 101.3,
                0.01801528, 86400.0, 1.0e-6,
            )
        @test conductance > 0.0
        @test 0.0 < canopy_conductance < conductance
        @test transpiration > 0.0
    end

    @testset "root-stem-leaf process chain" begin
        forcing = (;
            f_airT_day=20.0,
            f_VPD_day=1.0,
            f_psurf_day=101.3,
            f_canopy_height=10.0,
        )
        land = (;
            pools=(; soilW=[90.0, 120.0, 150.0], ΔsoilW=zeros(3)),
            constants=(; z_zero=0.0, o_one=1.0),
            states=(;
                LAI=2.0,
                PAW=[60.0, 90.0, 120.0],
                ambient_CO2=400.0,
            ),
            properties=(;
                soil_layer_thickness=fill(300.0, 3),
                sp_k_sat=fill(100.0, 3),
                sp_θ_sat=fill(0.50, 3),
                sp_θ_fc=fill(0.30, 3),
                sp_θ_wp=fill(0.10, 3),
            ),
            diagnostics=(; gpp_demand=20.0),
            fluxes=(;),
            rootWaterEfficiency=(; root_over=ones(3)),
            models=(; unsat_k_model=_STEMMUSTestUnsaturatedConductivity()),
        )

        stomata = stomatalConductance_STEMMUS()
        demand = transpirationDemand_STEMMUS()
        hydraulics = plantHydraulics_STEMMUS(
            k_leaf_max=0.05,
            k_stem_max=0.05,
            p50_leaf=-100.0,
            p50_stem=-100.0,
            p50_leaf_stress=-100.0,
        )
        land = SM.define(stomata, forcing, land, tmp_helpers)
        land = SM.compute(stomata, forcing, land, tmp_helpers)
        land = SM.define(demand, forcing, land, tmp_helpers)
        land = SM.compute(demand, forcing, land, tmp_helpers)
        land = SM.define(hydraulics, forcing, land, tmp_helpers)
        land = SM.precompute(hydraulics, forcing, land, tmp_helpers)
        land = SM.compute(hydraulics, forcing, land, tmp_helpers)

        @test sum(land.properties.stemmus_root_fraction) > 0.0
        @test all(isfinite, land.properties.stemmus_root_spacing)
        @test all(land.properties.stemmus_root_spacing .> 0.0)
        @test all(land.diagnostics.Κ_soil_root .> 0.0)
        @test all(isfinite, (
            land.diagnostics.ψ_leaf,
            land.diagnostics.ψ_stem,
            land.diagnostics.ψ_root,
        ))
        @test land.diagnostics.ψ_leaf <=
            land.diagnostics.ψ_stem <=
            land.diagnostics.ψ_root
        @test 1 <= land.diagnostics.stemmus_iterations <= 30
        @test 0.0 <= land.diagnostics.stemmus_leaf_stress <= 1.0
        @test land.diagnostics.stemmus_gpp <= land.diagnostics.gpp_demand
        @test land.diagnostics.stemmus_transpiration >= 0.0
        @test all(land.fluxes.stemmus_root_water_uptake .>= 0.0)
        @test all(land.fluxes.stemmus_root_water_uptake .<= land.states.PAW)

        land = SM.define(rootWaterUptake_STEMMUS(), nothing, land, tmp_helpers)
        land = SM.compute(rootWaterUptake_STEMMUS(), nothing, land, tmp_helpers)
        land = SM.compute(gpp_STEMMUS(), nothing, land, tmp_helpers)
        land = SM.compute(transpiration_STEMMUS(), nothing, land, tmp_helpers)
        @test land.fluxes.root_water_uptake ==
            land.fluxes.stemmus_root_water_uptake
        @test land.pools.ΔsoilW == -land.fluxes.root_water_uptake
        @test land.fluxes.gpp == land.diagnostics.stemmus_gpp
        @test land.fluxes.transpiration ==
            land.diagnostics.stemmus_transpiration
    end
end

struct _CLMTestUnsaturatedConductivity end
SM.unsatK(land, helpers, sl, ::_CLMTestUnsaturatedConductivity) = 50.0

@testset "plantHydraulics CLM5 single leaf" verbose=true begin
    params = plantHydraulics_CLM(
        k_leaf_max=0.05,
        k_xylem_max=0.05,
        p50_leaf=-100.0,
        p50_xylem=-100.0,
        p50_root=-100.0,
    )
    lai = 2.0
    sai = params.stem_to_leaf_area_ratio * lai
    canopy_height = 10.0
    layer_head = [-1.0, -2.0, -4.0]
    layer_conductance = [0.05, 0.03, 0.02]
    demand = 1.0e-3

    @testset "CLM Weibull and Saxton matric potential" begin
        @test SM._clm_vulnerability(-100.0, -100.0, 2.0, 0.005) ≈ 0.5
        @test SM._clm_vulnerability(-1000.0, -100.0, 2.0, 0.005) == 0.0
        @test SM._clm_vulnerability_derivative(-100.0, -100.0, 2.0) ≈
            log(2.0) / 100.0
        @test SM._clm_soil_matric_potential(
            0.30, 0.50, 0.30, 0.10, 0.0, 33.0, 1500.0, 0.1019716213,
        ) ≈ -33.0 * 0.1019716213
        @test SM._clm_soil_matric_potential(
            0.10, 0.50, 0.30, 0.10, 0.0, 33.0, 1500.0, 0.1019716213,
        ) ≈ -1500.0 * 0.1019716213
    end

    @testset "analytic CLM spacA Jacobian" begin
        state = SindbadTEM.SVector(-20.0, -15.0, -2.0)
        _, jacobian = SM._clm_residual_jacobian(
            params, state, layer_head, layer_conductance,
            demand, lai, sai, canopy_height,
        )
        step = 1.0e-6
        for column in eachindex(state)
            state_plus = Base.setindex(state, state[column] + step, column)
            state_minus = Base.setindex(state, state[column] - step, column)
            residual_plus = SM._clm_residual(
                params, state_plus, layer_head, layer_conductance,
                demand, lai, sai, canopy_height,
            )
            residual_minus = SM._clm_residual(
                params, state_minus, layer_head, layer_conductance,
                demand, lai, sai, canopy_height,
            )
            finite_difference = (residual_plus - residual_minus) / (2 * step)
            @test jacobian[:, column] ≈ finite_difference rtol=1.0e-6 atol=1.0e-9
        end
    end

    @testset "undamped Newton and getvegwp fallback" begin
        solution, converged, fallback, iterations, residual_norm =
            SM._solve_clm_newton(
                params,
                [-20.0, -15.0, -2.0],
                layer_head,
                layer_conductance,
                demand,
                lai,
                sai,
                canopy_height,
            )
        @test converged
        @test !fallback
        @test iterations <= 10
        @test residual_norm < 1.0e-8
        @test solution[1] <= solution[2] <= solution[3]

        zero_solution, _, zero_fallback, zero_iterations, zero_residual =
            SM._solve_clm_newton(
                params,
                solution,
                layer_head,
                layer_conductance,
                0.0,
                lai,
                sai,
                canopy_height,
            )
        @test zero_fallback
        @test zero_iterations == 0
        @test zero_residual < 1.0e-12
        @test zero_solution[1] == zero_solution[2]
        @test zero_solution[2] ≈ zero_solution[3] - canopy_height
    end

    @testset "daily Farquhar, Ci convergence, Medlyn, and stressed-gs inversion" begin
        assimilation = 10.0
        gb = 2.0e6
        gs = SM._clm_medlyn_conductance(
            assimilation, 400.0, 101.3, 1.0, gb,
            1.0e4, 4.45, 1.6, 1.4, 0.05,
        )
        @test isfinite(gs) && gs > 1.0e4
        attenuation = 0.5
        stress = SM._clm_stomatal_stress_from_flux_attenuation(
            attenuation, gb, gs,
        )
        stressed_gs = stress * gs
        series_unstressed = gb * gs / (gb + gs)
        series_stressed = gb * stressed_gs / (gb + stressed_gs)
        @test series_stressed / series_unstressed ≈ attenuation
        @test 0.0 < stress < attenuation

        exchange = SM._clm_daily_gas_exchange(
            params, 1.0, 2.0, 0.8, 400.0, 20.0, 1.0, 101.3, 12.0,
        )
        stressed_exchange = SM._clm_daily_gas_exchange(
            params, 0.25, 2.0, 0.8, 400.0, 20.0, 1.0, 101.3, 12.0,
        )
        @test exchange.ci_converged
        @test abs(exchange.residual) < 1.0e-2
        @test exchange.gamma_star < exchange.ci < exchange.cair
        @test exchange.ag > exchange.an > 0.0
        @test exchange.gs > params.medlyn_intercept
        @test stressed_exchange.ag < exchange.ag
        @test stressed_exchange.gs < exchange.gs
        @test SM._clm_transpiration_from_conductance(
            params, exchange.gs, gb, 2.0, 0.2, 1.0, 101.3,
        ) > 0.0
    end

    @testset "coupled GPP, transpiration, hydraulics, and signed water update" begin
        forcing = (;
            f_canopy_height=10.0,
            f_airT_day=20.0,
            f_VPD_day=1.0,
            f_psurf_day=101.3,
            f_PAR=12.0,
        )
        land = (;
            pools=(;
                soilW=[90.0, 120.0, 150.0],
                ΔsoilW=zeros(3),
                cVegRoot=[100.0],
            ),
            constants=(; z_zero=0.0, o_one=1.0),
            states=(; LAI=2.0, fAPAR=0.8, ambient_CO2=400.0),
            properties=(;
                soil_layer_thickness=fill(300.0, 3),
                sp_k_sat=fill(100.0, 3),
                sp_θ_sat=fill(0.50, 3),
                sp_θ_fc=fill(0.30, 3),
                sp_θ_wp=fill(0.10, 3),
                sp_ψ_sat=zeros(3),
                sp_ψ_fc=fill(33.0, 3),
                sp_ψ_wp=fill(1500.0, 3),
            ),
            diagnostics=(; root_surface_area=[0.2, 0.5, 0.3]),
            fluxes=(;),
            rootWaterEfficiency=(; root_over=ones(3)),
            models=(; unsat_k_model=_CLMTestUnsaturatedConductivity()),
        )
        land = SM.define(params, forcing, land, tmp_helpers)
        land = SM.precompute(params, forcing, land, tmp_helpers)
        land = SM.compute(params, forcing, land, tmp_helpers)
        @test land.diagnostics.clm_soil_root_conductance[1] == 0.0
        @test all(land.diagnostics.clm_soil_root_conductance[2:3] .> 0.0)
        @test land.diagnostics.clm_solver_converged
        @test land.diagnostics.clm_ci_converged
        @test land.diagnostics.clm_coupling_converged
        @test land.diagnostics.clm_leaf_temperature == forcing.f_airT_day
        @test land.diagnostics.clm_absorbed_par ≈ forcing.f_PAR * land.states.fAPAR
        @test land.diagnostics.clm_ci < 400.0e-6 * 101300.0
        @test land.diagnostics.clm_gpp > 0.0
        @test land.diagnostics.clm_gs_mol_stressed > 0.0
        @test land.diagnostics.clm_transpiration > 0.0
        @test sum(land.fluxes.clm_root_water_uptake) ≈
            land.diagnostics.clm_transpiration atol=1.0e-7

        land = SM.compute(gpp_CLM(), nothing, land, tmp_helpers)
        land = SM.compute(transpiration_CLM(), nothing, land, tmp_helpers)
        @test land.fluxes.gpp == land.diagnostics.clm_gpp
        @test land.fluxes.transpiration == land.diagnostics.clm_transpiration

        signed_flux = [1.5, -0.5]
        water_land = (;
            pools=(; soilW=[10.0, 10.0], ΔsoilW=[0.0, 0.0]),
            fluxes=(;
                clm_root_water_uptake=signed_flux,
                root_water_uptake=zeros(2),
            ),
            diagnostics=(; clm_transpiration=1.0),
        )
        water_land = SM.compute(rootWaterUptake_CLM(), nothing, water_land, tmp_helpers)
        @test water_land.fluxes.root_water_uptake == signed_flux
        @test water_land.pools.ΔsoilW == [-1.5, 0.5]
        water_land = SM.compute(transpiration_CLM(), nothing, water_land, tmp_helpers)
        @test water_land.fluxes.transpiration == 1.0
    end
end
