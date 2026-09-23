# export plantHydraulics_PHS

# using StaticArrays: SMatrix, SVector

# ### provide important solver functions.
# include("plantHydraulic_Solver.jl")

# const _NEWTON_MAX_ITERATIONS = 50
# const _NEWTON_MAX_BACKTRACKS = 8

# @inline _not_Inf_NaN(value, fallback) = isfinite(value) ? value : oftype(value, fallback)

# @inline function _pos_Inf_not_NaN(value)
#     if isfinite(value)
#         return value
#     elseif isnan(value)
#         return zero(value)
#     end
#     return copysign(floatmax(typeof(value)), value)
# end

# @inline function _pos_not_Inf_NaN(value, fallback)
#     return isfinite(value) && value > zero(value) ? value : oftype(value, fallback)
# end

# @inline function _Boundary_not_Inf_NaN(value, floor)
#     safe_floor = max(_not_Inf_NaN(floor, eps(typeof(floor))), eps(typeof(floor)))
#     return max(_pos_Inf_not_NaN(value), safe_floor)
# end

# @inline _non_negative_Finite(value) = max(_pos_Inf_not_NaN(value), zero(value))

# @inline _norm3(values) = max(abs(values[1]), abs(values[2]), abs(values[3]))

# @inline function _soil_root_conductance(k1, k2)
#     k1 = _non_negative_Finite(k1)
#     k2 = _non_negative_Finite(k2)

#     if iszero(k1) || iszero(k2)
#         return zero(k1 + k2)
#     end

#     inverse_sum = inv(k1) + inv(k2)
#     total_conductance = inv(inverse_sum)

#     if isfinite(total_conductance)
#         return total_conductance
#     end

#     low = min(k1, k2)
#     high = max(k1, k2)

#     return low / (one(low) + low / high)
# end

# #! format: off
# @bounds @describe @units @timescale @with_kw struct plantHydraulics_PHS{T} <: plantHydraulics
#     root_radius::T = 1.5e-3 | (1.0e-5, 1.0e-2) | "fine-root radius used to infer root spacing from SINDBAD root surface area" | "m" | ""
#     biomass_to_carbon::T = 0.488 | (0.1, 1.0) | "root carbon per unit root dry biomass" | "gC gDM-1" | ""
#     root_density::T = 2.5e5 | (1.0e3, 1.0e6) | "root tissue dry-matter density" | "gDM m-3" | ""
#     pi_value::T = 3.141592653589793 | (3.0, 3.2) | "pi constant used by the root-spacing geometry" | "" | ""
#     stem_to_leaf_area_ratio::T = 0.1 | (0.01, 0.9) | "stem area index to leaf area index ratio" | "" | ""
#     p50_leaf::T = -67.67 | (-500, -60.0) | "stem-to-leaf water potential at 50 percent conductivity loss" | "m" | ""
#     p50_stem::T = -342.51 | (-1500, -50.0) | "root-to-stem water potential at 50 percent conductivity loss" | "m" | ""
#     p50_root::T = -30.0 | (-1000, -20.0) | "soil-root water potential at 50 percent conductivity loss" | "m" | ""
#     p50_leaf_stress::T = -150.0 | (-Inf, -1.0) | "leaf water potential at 50 percent transpiration loss" | "m" | ""
#     shape_factor_leaf::T = 1.98 | (0.5, 10.0) | "leaf PHS vulnerability-curve shape factor" | "" | ""
#     shape_factor_stem::T = 1.98 | (0.5, 6.0) | "stem PHS vulnerability-curve shape factor" | "" | ""
#     shape_factor_root::T = 0.8 | (0.5, 6.0) | "root PHS vulnerability-curve shape factor" | "" | ""
#     k_root_max::T = 1.73e-4 | (8.64e-6, 8.64e-2) | "maximum root hydraulic conductivity" | "m d-1" | ""
#     k_stem_max::T = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum stem hydraulic conductivity" | "m d-1" | ""
#     k_leaf_max::T = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum leaf hydraulic conductance" | "d-1" | ""
#     root_lateral_length::T = 0.25 | (1.0e-3, 10.0) | "average coarse-root lateral length" | "m" | ""
#     minimum_conductance::T = 1.0e-12 | (0.0, 1.0) | "numerical floor for hydraulic conductance" | "d-1" | ""
#     minimum_lai::T = 1.0e-6 | (0.0, 1.0) | "minimum LAI for solving the hydraulic network" | "m2 m-2" | ""
#     minimum_height::T = 1.0e-3 | (1.0e-6, 10.0) | "minimum canopy height used in path-length scaling" | "m" | ""
#     min_root_length_density::T = 1.0e-12 | (0.0, Inf) | "root length-density floor used to avoid singular root spacing" | "m m-3" | ""
#     minimum_froot_allocation::T = 0.001 | (0.0001, 1.0) | "minimum fine-root allocation factor" | "" | ""
#     mm_2_m::T = 1.0e-3 | (0.0, Inf) | "unit conversion from mm to m" | "" | ""
#     m_to_mm::T = 1.0e3 | (0.0, Inf) | "unit conversion from m to mm" | "" | ""
#     m_to_MPa::T = 0.00980665 | (0.0, Inf) | "unit conversion of water potential from m to MPa" | "" | ""
#     nvg::T = 1.56 | (1.1, 10.0) | "van Genuchten shape parameter" | "" | ""
#     avg::T = 3.6 | (0.01, 100.0) | "van Genuchten inverse length parameter" | "m-1" | ""
#     newton_residual_tolerance::T = 1.0e-8 | (1.0e-14, 1.0e-2) | "absolute flux-balance tolerance" | "m d-1" | ""
#     newton_relative_tolerance::T = 1.0e-6 | (1.0e-12, 1.0e-2) | "relative flux-balance tolerance" | "" | ""
#     newton_step_tolerance::T = 1.0e-7 | (1.0e-12, 1.0) | "normalized coupled-state step tolerance" | "" | ""
#     newton_max_step::T = 50.0 | (1.0e-3, 1000.0) | "maximum normalized coupled-state step" | "" | ""
#     newton_min_damping::T = 1.0 / 256.0 | (1.0e-6, 1.0) | "minimum Newton line-search damping" | "" | ""
#     Jmax25::T = 10.0 | (0, 50) | "maximum electron transport rate, normalised to 25 ◦C" | "molC m-2 d-1" | ""
#     Vcmax25::T = 10.0 | (0, 50) | "Maximum rate of carboxylation, normalised to 25 ◦C" | "molC m-2 d-1" | ""
#     ha::T = 37830.0 | (3783, 378300) | "Gamma star params" | "" | ""
#     tk_ref::T = 298.15 | (298, 299) | "Gamma star params, 25deg" | "" | ""
#     k_Po::T = 101325.0 | (10132, 1013250) | "Gamma star params, one atm" | "" | ""
#     k_R::T = 8.3145 | (8, 9) | "universal gas constant" | "J mol-1 K-1" | ""
#     deg_2_K::T = 273.15 | (273, 274) | "Gamma star params, convert deg C to K" | "" | ""
#     gs25_0::T = 4.332 | (4.0, 5.0) | "reference value of gamma" | "Pa" | ""
#     diffusivity_ratio::T = 1.6 | (-Inf, Inf) | "Ratio of the molecular diffusivities for water vapor and CO2" | "" | ""
#     c_mol_mass::T = 12.0 | (-Inf, Inf) | "molecular mass of carbon" | "g/mol" | ""
#     w_mol_mass::T = 18.0 | (-Inf, Inf) | "molecular mass of water" | "g/mol" | ""
#     R_sc::T = 100.0 | (50, 200) | "scaling factor relevant to Solar radiation" | "W m-2" | ""
#     r_cs_max::T = 5000.0 | (1000, 10000) | "maximum canopy resistance related to PFTs" | "s m-1" | ""
#     r_cs_min::T = 100.0 | (10, 200) | "minimum canopy resistance related to PFTs" | "s m-1" | ""
#     Tmin::T = 0.0 | (-Inf, Inf) | "minimum temperature for stomatal conductance" | "deg C" | ""
#     Topt::T = 25.0 | (10, 35) | "optimal temperature for stomatal conductance" | "deg C" | ""
#     Tmax::T = 40.0 | (-Inf, Inf) | "maximum temperature for stomatal conductance" | "deg C" | ""
#     Rgas::T = 0.008314 | (-Inf, Inf) | "universal gas constant" | "KJ mol-1 K-1" | ""
#     k_Temp::T = 0.0016 | (0.0001, 0.01) | "temperature stress coefficient" | "unitless" | ""
#     day_second::T = 86400.0 | (-Inf, Inf) | "seconds in a day" | "s" | ""
#     daylight_seconds::T = 36000.0 | (3600, 86400) | "effective daylight duration used to convert daily radiation and fluxes" | "s d-1" | ""
#     k_VPD::T = 0.25 | (0.1, 0.3) | "Jarvis VPD stressor params" | "" | ""
#     par_ppfd::T = 4.57 | (0, 5) | "PAR to PPFD conversion factor, from W/m2 to umol/m2/s" | "" | ""
#     k_co::T = 209476.0 | (20947, 2094760) | "Michaelis–Menten coefficient params" | "" | ""
#     dhac::T = 79430.0 | (7943, 794300) | "Michaelis–Menten coefficient paramss" | "" | ""
#     dhao::T = 36380.0 | (3638, 363800) | "Michaelis–Menten coefficient params" | "" | ""
#     kc25::T = 39.97 | (39, 50) | "Michaelis–Menten coefficient params" | "" | ""
#     ko25::T = 27480.0 | (2748, 274800) | "Michaelis–Menten coefficient params" | "" | ""
#     CL::T = 0.25 | (0.1, 0.8) | "maximum quantum yield of photosystem II in light-adapted leaves" | "" | ""
# end
# #! format: on

# function define(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_canopy_height ⇐ forcing
#         soilW ⇐ land.pools
#         (z_zero, o_one) ⇐ land.constants
#         plant_form ⇐ land.states
#     end

#     if plant_form in (:tree, :shrub)
#         fine_root_fraction = oftype(z_zero, 0.141)
#     elseif plant_form == :herb
#         fine_root_fraction = oftype(z_zero, 0.885)
#     else
#         fine_root_fraction = oftype(z_zero, 0.15)
#     end

#     phs_root_water_uptake = zero(soilW)
#     phs_transpiration = z_zero
#     phs_transpiration_fick = z_zero
#     phs_transpiration_rwu = z_zero
#     phs_gpp = z_zero
#     phs_gpp_farquhar = z_zero
#     phs_gpp_fick = z_zero
#     ci_solver = z_zero
#     gs_solver = z_zero
#     gs_jarvis = z_zero
#     phs_root_spacing = zero(soilW)

#     Κ_soil_root = zero(soilW)
#     Κ_soil = zero(soilW)
#     Κ_root = zero(soilW)
#     Κ_soil_unsat = zero(soilW)

#     RAI = zero(soilW)

#     D_soil_inv_mm = zero(soilW)
#     D_soil_m = zero(soilW)
#     D_soil_cum_m = zero(soilW)
#     D_root_deno = zero(soilW)
#     θ_range_inv = zero(soilW)

#     H_canopy = f_canopy_height # canopy height, m

#     ψ_leaf = -H_canopy
#     ψ_stem = -H_canopy
#     ψ_root = z_zero
#     ψ_soil = zero(soilW)

#     β_leaf = o_one # leaf water stress factor (0-1) calculated based on leaf water potential and leaf vulnerability curve
#     β_stem = o_one # stem water stress factor (0-1) calculated based on stem water potential and stem vulnerability curve
#     β_root = zero(soilW)
    
#     ε_solver = z_zero
#     ε_solver_water = z_zero
#     ε_solver_carbon = z_zero
#     ε_solver_gs = z_zero
#     SOLVER_EVALUATIONS = z_zero
#     SOLVER_FALLBACK_STEPS = z_zero
#     SOLVER_TRUST_RADIUS = z_zero
#     gpp_f_soilW = o_one

#     ITERARIONS = z_zero
#     CONVERGED = false

#     @pack_nt begin
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno, θ_range_inv) ⇒ land.properties

#         (ψ_leaf, ψ_stem, ψ_root, ψ_soil,
#         β_leaf, β_stem, β_root, gpp_f_soilW,
#         Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat, RAI,
#         phs_transpiration, phs_transpiration_fick,phs_transpiration_rwu,
#         phs_gpp, phs_gpp_farquhar, phs_gpp_fick,
#         ci_solver, gs_solver, gs_jarvis,
#         phs_root_spacing, fine_root_fraction,
#         ε_solver, ε_solver_water, ε_solver_carbon, ε_solver_gs,
#         SOLVER_EVALUATIONS, SOLVER_FALLBACK_STEPS, SOLVER_TRUST_RADIUS,
#         ITERARIONS, CONVERGED) ⇒ land.diagnostics

#         phs_root_water_uptake ⇒ land.fluxes
#     end

#     return land
# end

# function precompute(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         soilW ⇐ land.pools
#         (z_zero, o_one) ⇐ land.constants
#         (sp_θ_fc, sp_θ_wp, soil_layer_thickness) ⇐ land.properties
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, θ_range_inv, D_root_deno) ⇐ land.properties
#     end

#     thickness_floor = oftype(o_one, 1.0e-12)

#     cumulative_depth_m = z_zero
#     @inbounds for sl in eachindex(soilW)
#         thickness = _Boundary_not_Inf_NaN(soil_layer_thickness[sl], thickness_floor)
#         thickness_m = _Boundary_not_Inf_NaN(thickness * mm_2_m, thickness_floor)
#         layer_midpoint_m = cumulative_depth_m + thickness_m / 2
#         cumulative_depth_m += thickness_m
#         root_depth_denominator = _Boundary_not_Inf_NaN(
#             root_lateral_length + layer_midpoint_m,
#             thickness_floor,
#         )

#         θ_range = _Boundary_not_Inf_NaN(
#             sp_θ_fc[sl] - sp_θ_wp[sl],
#             oftype(o_one, 1.0e-12),
#         )

#         @rep_elem inv(thickness) ⇒ (D_soil_inv_mm, sl, :soilW)
#         @rep_elem thickness_m ⇒ (D_soil_m, sl, :soilW)
#         # Total hydraulic head is evaluated at the layer midpoint, not at its lower boundary. This avoids a thickness-dependent gravity bias.
#         @rep_elem layer_midpoint_m ⇒ (D_soil_cum_m, sl, :soilW)
#         @rep_elem inv(θ_range) ⇒ (θ_range_inv, sl, :soilW)
#         @rep_elem root_depth_denominator ⇒ (D_root_deno, sl, :soilW)
#     end

#     @pack_nt (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno, θ_range_inv) ⇒ land.properties

#     return land
# end

# function compute(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_canopy_height, f_airT_day) ⇐ forcing
#         (LAI, PAW) ⇐ land.states
#         (ψ_leaf, ψ_stem, ψ_root, ci_solver, gs_solver) ⇐ land.diagnostics
#         phs_root_water_uptake ⇐ land.fluxes
#         root_over ⇐ land.rootWaterEfficiency
#         (z_zero, o_one) ⇐ land.constants
#     end

#     land = _phs_hydraulic_inputs(params, land, helpers)
#     @unpack_nt begin
#         (ψ_soil, Κ_soil_root) ⇐ land.diagnostics
#     end

#     uptake_capacity = _non_negative_Finite.(oftype(ψ_leaf, mm_2_m) * PAW)

#     H_canopy = _Boundary_not_Inf_NaN(f_canopy_height, minimum_height)
#     lai = LAI
#     sai = stem_to_leaf_area_ratio * lai

#     context = cal_basic_context(params, forcing, land, helpers)

#     ### initialize ci and gs -- the initial value also consider the previous state
#     if isfinite(ci_solver) && context.gamma_star <= ci_solver <= context.ca
#         ci_initial = ci_solver
#     else
#         ci_initial = (context.gamma_star + context.ca) / 2
#     end

#     if isfinite(gs_solver) && gs_solver >= z_zero
#         gs_initial = gs_solver
#     else
#         gs_initial = context.gs_unstressed
#     end

#     initial = SVector{5,typeof(ψ_leaf)}(
#         ψ_leaf, ψ_stem, ψ_root, ci_initial, gs_initial,
#     )
#     ### project and residual are functions here.
#     project = state -> _project_coupled_phs_state(
#         state, H_canopy, context.gamma_star, context.ca, context.gs_upper,
#     )
#     residual = state -> _phs_coupled_residual(
#         params, state, forcing, land, helpers,
#         ψ_soil, Κ_soil_root, uptake_capacity,
#         lai, sai, H_canopy, context,
#     )

#     ### define the conditions which no water uptake and no photosynthesis.
#     # low temperature, low light, low LAI.
#     low_activity = lai <= minimum_lai ||
#         context.absorbed_par_daily <= z_zero || f_airT_day <= z_zero ||
#         context.gs_upper <= z_zero

#     if low_activity
#         root = _ψ_root_when_zero_demand(
#             ψ_soil, Κ_soil_root, uptake_capacity, ψ_root,
#         )
#         solution = project(SVector{5,typeof(ψ_leaf)}(
#             root - H_canopy, root - H_canopy, root, context.ca, z_zero,
#         ))

#         final_residual = residual(solution)
#         result = _phs_coupled_result(
#             solution,
#             _phs_norm5(final_residual) <= newton_relative_tolerance ?
#                 :low_activity_converged : :low_activity_inconsistent,
#             _phs_norm5(final_residual) <= newton_relative_tolerance,
#             0,
#             _phs_norm5(final_residual),
#             z_zero, # zero ci?
#             z_zero, # zero gs -- yes
#         ) # these functions are provided in Solver.jl.

#     else

#         # Numerical scale for the smooth water-potential coordinates used only
#         # inside the solver. ci and gs are normalized by their physical bounds.
#         potential_scale = max(
#             o_one, abs(H_canopy), abs(p50_leaf), abs(p50_stem),
#             abs(p50_root), abs(p50_leaf),
#         )

#         result = solve_coupled_phs_equilibrium(
#             initial, residual, potential_scale;
#             canopy_height=H_canopy,
#             gamma_star=context.gamma_star,
#             ca=context.ca,
#             gs_upper=context.gs_upper,
#             residual_tolerance=newton_relative_tolerance,
#             maximum_iterations=_PHS_COUPLED_MAX_ITERATIONS,
#         )
#         solution = result.solution
#     end

#     ψ_leaf, ψ_stem, ψ_root, ci_solver, gs_solver = solution
#     fluxes = _phs_coupled_fluxes(
#         params, solution, forcing, land, helpers,
#         ψ_soil, Κ_soil_root, uptake_capacity,
#         lai, sai, H_canopy,
#     )

#     β_leaf = clamp_zero_one(cal_vulnerability_curve(ψ_leaf, p50_leaf, shape_factor_leaf))
#     β_stem = clamp_zero_one(cal_vulnerability_curve(ψ_root, p50_stem, shape_factor_stem))
#     gs_jarvis, _, _ = cal_gs_canopy(params, forcing, land, helpers, β_leaf)

#     ### While there is convergent, there are small residuals, so I use min to obtain the minimum value between them.
#     # GPP
#     phs_gpp_farquhar = fluxes.farquhar_canopy
#     phs_gpp_fick = fluxes.fick_canopy
#     phs_gpp_Ac = fluxes.ac_leaf
#     phs_gpp_Aj = fluxes.aj_leaf
#     phs_gpp = at_least_zero(min(phs_gpp_farquhar, phs_gpp_fick))
#     gpp_f_soilW = β_leaf

#     uptake_sum = z_zero
#     @inbounds for sl in eachindex(phs_root_water_uptake)
#         if root_over[sl] > zero(root_over[sl])
#             flux_m_per_day, _ = _soil_root_fluxes(ψ_soil[sl], Κ_soil_root[sl], uptake_capacity[sl], ψ_root)
#         else
#             flux_m_per_day = z_zero
#         end

#         uptake = flux_m_per_day * m_to_mm
#         uptake_sum += uptake
#         @rep_elem uptake ⇒ (phs_root_water_uptake, sl, :soilW)
#     end
#     ### While there is convergent, there are small residuals, so I use min to obtain the minimum value between them.
#     phs_transpiration_fick = fluxes.transpiration_m_per_day * m_to_mm
#     phs_transpiration_rwu = uptake_sum
#     phs_transpiration = at_least_zero(min(phs_transpiration_fick, phs_transpiration_rwu))

#     ca_Pa = context.ca
#     Gamma_star_Pa = context.gamma_star

#     CONVERGED = result.converged
#     ITERARIONS = result.iterations
#     ε_solver = result.residual_norm
#     final_residual = residual(solution)
#     ε_solver_water = max(
#         abs(final_residual[1]), abs(final_residual[2]), abs(final_residual[3]),
#     )
#     ε_solver_carbon = abs(final_residual[4])
#     ε_solver_gs = abs(final_residual[5])
#     SOLVER_EVALUATIONS = oftype(z_zero, result.function_evaluations)
#     SOLVER_FALLBACK_STEPS = oftype(z_zero, result.fallback_steps)
#     SOLVER_TRUST_RADIUS = result.trust_radius

#     @pack_nt begin
#         (ψ_leaf, ψ_stem, ψ_root,
#         β_leaf, β_stem, gpp_f_soilW,
#         ci_solver, ca_Pa, Gamma_star_Pa, gs_solver, gs_jarvis,
#         phs_gpp, phs_gpp_farquhar, phs_gpp_fick, phs_gpp_Ac, phs_gpp_Aj,
#         phs_transpiration, phs_transpiration_fick, phs_transpiration_rwu,
#         ε_solver, ε_solver_water, ε_solver_carbon, ε_solver_gs,
#         SOLVER_EVALUATIONS, SOLVER_FALLBACK_STEPS, SOLVER_TRUST_RADIUS,
#         ITERARIONS, CONVERGED) ⇒ land.diagnostics
#         phs_root_water_uptake ⇒ land.fluxes
#     end

#     return land
# end

# @inline function cal_efficient_LAI(lai)
#     con_3 = oftype(lai, 0.3)
#     con_12 = oftype(lai, 1.2)
#     lai = max(lai, zero(lai))
#     # efficient LAI
#     efficient_lai = con_3 * lai + con_12
#     return efficient_lai
# end

# function cal_basic_context(params, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_PAR, f_psurf_day) ⇐ forcing
#         (fAPAR, ambient_CO2, LAI) ⇐ land.states
#         o_one ⇐ land.constants
#         ambient_CO2 ⇐ land.states
#     end

#     con_1e3 = oftype(f_psurf_day, 1e3)
#     con_1e_6 = oftype(f_psurf_day, 1e-6)

#     efficient_lai = cal_efficient_LAI(LAI)
#     pressure_pa = f_psurf_day * con_1e3 # kPa to Pa
#     ca = ambient_CO2 * con_1e_6 * pressure_pa # ppm to Pa
#     gamma_star, _ = cal_gamma_star(params, forcing, land, helpers)

#     absorbed_par_daily = f_PAR * fAPAR

#     ### gs under no water stress
#     gs_unstressed, _, _ = cal_gs_canopy(params, forcing, land, helpers, o_one)
#     gs_unstressed = _non_negative_Finite(gs_unstressed)
#     gs_upper = 1.5 * gs_unstressed

#     midpoint_ci = clamp((gamma_star + ca) / 2, gamma_star, ca)
#     reference_rates = cal_GPP_Farquhar(
#         params, forcing, land, helpers, midpoint_ci, o_one
#     )

#     ### these scalers are used to normalize the residuals because of different units. Because these scalers are used as demoninators, we need to make sure they are not zero.
#     # water scale -- no water stress; carbon scale -- middle CO2 level; gs scale -- no water stress
#     water_scale = max(cal_Transpiration_Fick(params, forcing, gs_unstressed), con_1e_6)
#     carbon_scale = max(reference_rates.gpp_farquhar, con_1e_6)
#     gs_scale = max(gs_unstressed, con_1e_6)

#     return (
#         efficient_lai=efficient_lai,
#         pressure_pa=pressure_pa,
#         ca=ca,
#         gamma_star=gamma_star,
#         absorbed_par_daily=absorbed_par_daily,
#         gs_unstressed=gs_unstressed,
#         gs_upper=gs_upper,
#         water_scale=water_scale,
#         carbon_scale=carbon_scale,
#         gs_scale=gs_scale,
#     )
# end

# @inline function _project_coupled_phs_state(
#     state,
#     canopy_height,
#     gamma_star,
#     ca,
#     gs_upper,
# )
#     ### matrix of three water potentials: leaf, stem, root
#     potentials = _project_potentials(
#         SVector{3,eltype(state)}(state[1], state[2], state[3]),
#         canopy_height,
#     )
#     ### matrix of ci and gs
#     ci_upper = max(ca, gamma_star)
#     ci = clamp(_not_Inf_NaN(state[4], ci_upper), gamma_star, ci_upper)
#     gs = clamp(_not_Inf_NaN(state[5], zero(state[5])), zero(state[5]), gs_upper)

#     return SVector{5,eltype(state)}(
#         potentials[1], potentials[2], potentials[3], ci, gs,
#     )
# end

# @inline function cal_Transpiration_Fick(params::plantHydraulics_PHS, forcing, gs_canopy)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt (f_VPD_day, f_psurf_day) ⇐ forcing

#     th_1000 = oftype(f_psurf_day, 1000)
#     pressure_pa = f_psurf_day * th_1000
#     vpd = at_least_zero(f_VPD_day) * th_1000

#     water_mol_ground_second = diffusivity_ratio * gs_canopy * vpd / pressure_pa # molH2O m-2 d-1

#     transpiration_m = water_mol_ground_second * (w_mol_mass / th_1000) * mm_2_m # to m d-1

#     return transpiration_m
# end

# @inline function cal_GPP_Fick(params::plantHydraulics_PHS, forcing, land, ci, gs_canopy)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_psurf_day ⇐ forcing
#         ambient_CO2 ⇐ land.states
#     end

#     th_1e_6 = oftype(ambient_CO2, 1.0e-6)

#     ### TODO: unit issue. - Done!
#     ### ppm to Pa
#     th_1000 = oftype(f_psurf_day, 1000)
#     pressure_pa = f_psurf_day * th_1000 # kPa to Pa
#     ca = ambient_CO2 * th_1e_6 * pressure_pa ### ppm to Pa
#     gs_canopy = at_least_zero(gs_canopy) # molC m-2 d-1 Pa-1

#     co2_gradient = at_least_zero(ca - ci) # at Pa unit
#     gpp_fick = gs_canopy * co2_gradient
#     ### convert to gC m-2 d-1
#     gpp_fick = gpp_fick * c_mol_mass

#     return gpp_fick
# end

# function _phs_coupled_fluxes(
#     params::plantHydraulics_PHS,
#     state,
#     forcing,
#     land,
#     helpers,
#     layer_head,
#     layer_conductance,
#     uptake_capacity,
#     lai,
#     sai,
#     canopy_height,
# )
#     @unpack_plantHydraulics_PHS params
#     leaf, stem, root, ci, gs_canopy = state
#     z_zero = zero(leaf)

#     leaf_stress = cal_vulnerability_curve(leaf, p50_leaf, shape_factor_leaf)
#     leaf_conductance = at_least_zero(lai * k_leaf_max * cal_vulnerability_curve(stem, p50_leaf, shape_factor_leaf))
#     stem_to_leaf = at_least_zero(leaf_conductance * (stem - leaf))

#     stem_conductance = at_least_zero(sai * k_stem_max / canopy_height * cal_vulnerability_curve(root, p50_stem, shape_factor_stem))

#     root_to_stem = at_least_zero(stem_conductance * (root - stem - canopy_height))

#     soil_to_root = z_zero
#     @inbounds for sl in eachindex(layer_head)
#         layer_flux, _ = _soil_root_fluxes(
#             layer_head[sl], layer_conductance[sl], uptake_capacity[sl], root,
#         )
#         soil_to_root += layer_flux
#     end

#     farquhar = cal_GPP_Farquhar(params, forcing, land, helpers, ci, leaf_stress)
#     fick_canopy = cal_GPP_Fick(params, forcing, land, ci, gs_canopy)

#     transpiration_m_per_day = cal_Transpiration_Fick(
#         params, forcing, gs_canopy,
#     )

#     return (
#         transpiration_m_per_day=transpiration_m_per_day,
#         stem_to_leaf=stem_to_leaf,
#         root_to_stem=root_to_stem,
#         soil_to_root=soil_to_root,
#         farquhar_canopy=farquhar.gpp_farquhar,
#         fick_canopy=fick_canopy,
#         ac_leaf=farquhar.ac_leaf,
#         aj_leaf=farquhar.aj_leaf,
#     )
# end

# function _phs_coupled_residual(
#     params::plantHydraulics_PHS,
#     state,
#     forcing,
#     land,
#     helpers,
#     layer_head,
#     layer_conductance,
#     uptake_capacity,
#     lai,
#     sai,
#     canopy_height,
#     context,
# )
#     @unpack_plantHydraulics_PHS params
#     fluxes = _phs_coupled_fluxes(
#         params, state, forcing, land, helpers,
#         layer_head, layer_conductance, uptake_capacity,
#         lai, sai, canopy_height,
#     )
#     leaf_stress = cal_vulnerability_curve(
#         state[1], p50_leaf, shape_factor_leaf,
#     )
#     gs_target, _, _ = cal_gs_canopy(
#         params, forcing, land, helpers, leaf_stress,
#     )

#     # normalization
#     residual = SVector{5,eltype(state)}(
#         (fluxes.transpiration_m_per_day - fluxes.stem_to_leaf) /
#             context.water_scale,
#         (fluxes.stem_to_leaf - fluxes.root_to_stem) /
#             context.water_scale,
#         (fluxes.root_to_stem - fluxes.soil_to_root) /
#             context.water_scale,
#         (fluxes.fick_canopy - fluxes.farquhar_canopy) /
#             context.carbon_scale,
#         (state[5] - gs_target) / context.gs_scale,
#     )

#     return residual
# end

# function _phs_hydraulic_inputs(params::plantHydraulics_PHS, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (soilW, ΔsoilW) ⇐ land.pools
#         (sp_θ_wp, D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno, θ_range_inv) ⇐ land.properties
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat, ψ_soil, phs_root_spacing, β_root, RAI) ⇐ land.diagnostics
#         (root_surface_area, c_allocation, fine_root_fraction) ⇐ land.diagnostics
#         root_over ⇐ land.rootWaterEfficiency
#         unsat_k_model ⇐ land.models
#         z_zero ⇐ land.constants
#         cEco ⇐ land.pools
#         LAI ⇐ land.states
#     end

#     total_root_surface_area = sum(root_surface_area)
#     lai = at_least_zero(LAI)
#     sai = stem_to_leaf_area_ratio * lai

#     # new fine-root carbon to new foliage carbon ratio, which is not carbon allocation.
#     # TODO: I need to update it.
#     froot_2_leaf = c_allocation[1]

#     @inbounds for sl in eachindex(soilW)
#         if root_over[sl] > zero(root_over[sl])
#             root_fraction = root_surface_area[sl] / total_root_surface_area
#             θ = (soilW[sl] + ΔsoilW[sl]) * D_soil_inv_mm[sl]

#             soil_potential = _soil_potential(params, θ, sp_θ_wp[sl], θ_range_inv[sl])
#             layer_head = _pos_Inf_not_NaN(soil_potential - D_soil_cum_m[sl])

#             rai = (sai + lai) * root_fraction * froot_2_leaf
#             root_spacing = _root_spacing(params, cEco[1] * fine_root_fraction, D_soil_m[sl], root_fraction)
#             k_soil_unsat = at_least_zero(unsatK(land, helpers, sl, unsat_k_model) * mm_2_m)
#             k_soil = _Boundary_not_Inf_NaN(k_soil_unsat / root_spacing, minimum_conductance)

#             root_stress = cal_vulnerability_curve(soil_potential, p50_root, shape_factor_root)
#             k_root = _Boundary_not_Inf_NaN(root_stress * rai * k_root_max / D_root_deno[sl], minimum_conductance)

#             soil_to_root = _soil_root_conductance(k_soil, k_root)

#         else
#             layer_head = soil_to_root = root_spacing = k_soil = k_root = k_soil_unsat = root_stress = rai = z_zero
#         end

#         @rep_elem layer_head ⇒ (ψ_soil, sl, :soilW)
#         @rep_elem soil_to_root ⇒ (Κ_soil_root, sl, :soilW)
#         @rep_elem root_spacing ⇒ (phs_root_spacing, sl, :soilW)
#         @rep_elem k_soil ⇒ (Κ_soil, sl, :soilW)
#         @rep_elem k_root ⇒ (Κ_root, sl, :soilW)
#         @rep_elem k_soil_unsat ⇒ (Κ_soil_unsat, sl, :soilW)
#         @rep_elem root_stress ⇒ (β_root, sl, :soilW)
#         @rep_elem rai ⇒ (RAI, sl, :soilW)
#     end

#     @pack_nt (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat, ψ_soil, β_root, RAI, phs_root_spacing) ⇒ land.diagnostics

#     return land
# end

# @inline function _soil_root_fluxes(head, conductance, uptake_capacity, root)

#     z_zero = zero(root)

#     conductance = max(conductance, z_zero)
#     uptake_capacity = _non_negative_Finite(uptake_capacity)
#     raw_flux = _pos_Inf_not_NaN(conductance * (head - root))
#     bounded_flux = clamp(raw_flux, z_zero, uptake_capacity)

#     if z_zero < raw_flux < uptake_capacity
#         derivative = -conductance
#     else
#         derivative = z_zero
#     end

#     return bounded_flux, derivative
# end

# function _ψ_root_when_zero_demand(layer_head, layer_conductance, uptake_capacity, initial_root)

#     z_zero = zero(initial_root)

#     root = min(_not_Inf_NaN(initial_root, z_zero), z_zero)

#     for _ in 1:20
#         flux = z_zero
#         derivative = z_zero

#         @inbounds for sl in eachindex(layer_head)
#             layer_flux, layer_derivative = _soil_root_fluxes(layer_head[sl], layer_conductance[sl], uptake_capacity[sl], root)
#             flux += layer_flux
#             derivative += layer_derivative
#         end

#         if !isfinite(flux) || !isfinite(derivative) || abs(flux) <= oftype(flux, 1.0e-12) || abs(derivative) <= oftype(derivative, 1.0e-24)
#             break
#         end

#         candidate = root - flux / derivative
#         if !isfinite(candidate)
#             break
#         end

#         root = min(candidate, z_zero)
#     end

#     root = min(root, z_zero)

#     return root
# end

# @inline function _project_potentials(x, H_canopy)

#     root = min(_not_Inf_NaN(x[3], zero(x[3])), zero(x[3]))
#     highest_stem = _pos_Inf_not_NaN(root - H_canopy)
#     stem = min(_not_Inf_NaN(x[2], highest_stem), highest_stem)
#     leaf = min(_not_Inf_NaN(x[1], stem), stem)

#     return SVector{3,typeof(root)}(leaf, stem, root)
# end

# @inline function cal_vulnerability_curve(psi, psi50, shape_factor)

#     z_zero = zero(psi50)
#     o_one = one(psi50)

#     if psi >= z_zero
#         return o_one
#     elseif !isfinite(psi)
#         return z_zero
#     end

#     ratio = _non_negative_Finite(psi / psi50)

#     ratio_power = ratio ^ shape_factor
#     if !isfinite(ratio_power)
#         return z_zero
#     end

#     stress = exp2(-ratio_power)

#     return stress
# end

# @inline function _vulnerability_curve_derivative(psi, psi50, shape_factor)

#     z_zero = zero(psi50)
#     o_one = one(psi50)

#     if psi >= z_zero
#         return o_one, z_zero
#     elseif !isfinite(psi)
#         return z_zero, z_zero
#     end

#     ratio = _non_negative_Finite(psi / psi50)

#     ratio_power = ratio ^ shape_factor
#     if !isfinite(ratio_power)
#         return z_zero, z_zero
#     end

#     vulnerability = exp2(-ratio_power)
#     if !isfinite(vulnerability) || iszero(vulnerability)
#         return z_zero, z_zero
#     end

#     tension = -psi
#     derivative = vulnerability * log(oftype(psi, 2)) * shape_factor * ratio_power / tension
#     derivative = _non_negative_Finite(derivative)

#     return vulnerability, derivative
# end

# @inline function _soil_potential(params::plantHydraulics_PHS, θ, θ_wp, θ_range_inv)

#     @unpack_plantHydraulics_PHS params

#     o_one = one(θ)
#     z_zero = zero(θ)

#     saturation = clamp_zero_one(_pos_Inf_not_NaN((θ - θ_wp) * θ_range_inv))
#     saturation = max(saturation, oftype(saturation, 1.0e-12))

#     cvg = o_one - o_one / nvg

#     inverse_saturation = saturation ^ (-o_one / cvg)
#     if !isfinite(inverse_saturation)
#         return -oftype(saturation, 5.0e3)
#     end

#     pressure_term = max(inverse_saturation - o_one, z_zero)
#     psi_soil = -(pressure_term ^ (o_one / nvg)) / avg
#     if !isfinite(psi_soil)
#         return -oftype(saturation, 5.0e3)
#     end

#     psi_soil = clamp(psi_soil, -oftype(psi_soil, 5.0e3), zero(psi_soil))

#     return psi_soil
# end

# @inline function _root_spacing(params::plantHydraulics_PHS, root_carbon, layer_thickness_m, root_fraction)

#     @unpack_plantHydraulics_PHS params

#     # The root carbon should be fine root carbon, not total root carbon.
#     numerator = root_carbon * root_fraction

#     denominator = biomass_to_carbon * root_density * pi_value * root_radius ^ 2 * layer_thickness_m
#     denominator = _Boundary_not_Inf_NaN(denominator, oftype(root_carbon, 1.0e-24))

#     root_length_density = _Boundary_not_Inf_NaN(numerator / denominator, min_root_length_density)

#     spacing = sqrt(inv(pi_value * root_length_density))
#     root_space = _Boundary_not_Inf_NaN(spacing, oftype(root_carbon, 1.0e-12))

#     return root_space
# end

# function cal_KM(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_airT_day) ⇐ forcing
#         (z_zero, o_one) ⇐ land.constants
#     end

#     ### This function is used to calculate The effective Michaelis–Menten coefficient K (Pa) of RuBisCO-limited photosynthesis.
#     patm = f_psurf_day * 1e3 # kPa to Pa
#     tk = f_airT_day + deg_2_K # deg C to K

#     kc_exponent = dhac * (tk - tk_ref) / (tk_ref * k_R * tk)
#     ko_exponent = dhao * (tk - tk_ref) / (tk_ref * k_R * tk)
#     kc = kc25 * exp(kc_exponent)
#     ko = ko25 * exp(ko_exponent)
#     po = k_co * 1e-06 * patm
#     kmm = kc * (o_one + po / ko)

#     return kmm
# end

# function cal_Phi_o(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_airT_day ⇐ forcing
#     end

#     ### This function is used to calculate the intrinsic quantum yield (φ0(T), mol mol−1).
#     f_T = 0.325 + 0.022 * f_airT_day - 0.00034 * f_airT_day ^ 2 # dimensionless
#     phi_o = CL * f_T # dimensionless
#     # CL = 0.25, refer to P model

#     return phi_o
# end

# function cal_Jmax_Vmax(params::plantHydraulics_PHS, forcing, land, helpers)
    
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_airT_day ⇐ forcing
#     end

#     ### according to arrhenius function to convert Vcmax25 and Jmax25 to Vcmax and Jmax at current temperature.
#     tk = f_airT_day + deg_2_K # deg C to K
#     exponent = ha * (tk - tk_ref) / (tk_ref * k_R * tk)
#     arrhenius_factor = exp(exponent) # dimensionless

#     Vcmax = Vcmax25 * arrhenius_factor # molC m-2 d-1
#     Jmax = Jmax25 * arrhenius_factor # molC m-2 d-1

#     return Jmax, Vcmax
# end

# function cal_GPP_Farquhar(params::plantHydraulics_PHS, forcing, land, helpers, ci, leaf_stress)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_PAR ⇐ forcing
#         (LAI, fAPAR) ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end

#     con_1e6 = oftype(f_PAR, 1e6)

#     efficient_lai = cal_efficient_LAI(LAI)
#     gamma_star, _ = cal_gamma_star(params, forcing, land, helpers)
#     kmm = cal_KM(params, forcing, land, helpers)
#     jmax, vcmax = cal_Jmax_Vmax(params, forcing, land, helpers)

#     ### carboxylation-limited rate.
#     co2_numerator = at_least_zero(ci - gamma_star)
#     vc_actual = vcmax * leaf_stress
#     ac_leaf = vc_actual * co2_numerator / (ci + kmm)

#     ### light-limited rate.
#     fAPAR = 0.5
#     Iabs = f_PAR * fAPAR * par_ppfd * con_1e6 / day_second
#     phi0 = at_least_zero(cal_Phi_o(params, forcing, land, helpers))
#     electron_flux = 4 * phi0 * Iabs
#     if jmax > z_zero
#         J_actual = electron_flux / sqrt(o_one + (electron_flux / jmax) ^ 2)
#     else
#         J_actual = z_zero
#     end
#     if ci > gamma_star
#         aj_leaf = J_actual * co2_numerator / (4 * ci + 8 * gamma_star)
#     else
#         aj_leaf = z_zero
#     end

#     ### consider two limitations.
#     assimilation_leaf = at_least_zero(min(ac_leaf, aj_leaf))

#     ### upscale to canopy level using effective LAI, and the assumption is one Big-tree canopy.
#     # molC m-2 d-1
#     gpp_farquhar=assimilation_leaf * efficient_lai
#     # gC m-2 d-1
#     gpp_farquhar *= c_mol_mass

#     ### also for Ac and Aj, which are used for diagnostics.
#     ac_leaf *= efficient_lai * c_mol_mass
#     aj_leaf *= efficient_lai * c_mol_mass

#     return (
#         ac_leaf=ac_leaf,
#         aj_leaf=aj_leaf,
#         assimilation_leaf=assimilation_leaf,
#         gpp_farquhar=gpp_farquhar,
#     )
# end

# function cal_gamma_star(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_airT_day) ⇐ forcing
#     end

#     patm = f_psurf_day * 1000 # kPa to Pa
#     tk = f_airT_day + deg_2_K # deg C to K
#     exponent = ha * (tk - tk_ref) / (tk_ref * k_R * tk)
#     arrhenius_factor = exp(exponent) # dimensionless
#     gamma_star = (gs25_0 * patm / k_Po) * arrhenius_factor # Pa

#     return gamma_star, arrhenius_factor
# end

# function cal_gs_canopy(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_airT_day) ⇐ forcing
#         (z_zero, o_one) ⇐ land.constants
#     end

#     con_1e6 = oftype(f_psurf_day, 1e6)
#     ### Canopy resistance, s m-1
#     rs_c = cal_r_sc(params, forcing, land, helpers, leaf_stress) # s m-1

#     patm = f_psurf_day # kPa
#     temp = f_airT_day # deg C

#     rs = rs_c * Rgas * temp / (patm * con_1e6) # m2 s umol-1 C

#     if rs > z_zero
#         if rs_c == r_cs_max
#             gs_c = z_zero
#         else
#             gs_c = o_one / rs
#         end
#     else
#         gs_c = z_zero
#     end

#     gs_c = gs_c * day_second / con_1e6 # molC m-2 d-1 Pa-1

#     return gs_c, rs, rs_c
# end

# function cal_r_sc(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_VPD_day, f_airT_day, f_rg) ⇐ forcing
#         LAI ⇐ land.states
#         tolerance ⇐ helpers.numbers
#         (z_zero, o_one) ⇐ land.constants
#     end

#     ### leaf_stress is provided by the Newton solver here.

#     # _, _, _, _, _, _, r_cs_min, _ = get_pft_value(params, forcing, land, helpers)
#     con_1e6 = oftype(z_zero, 1e6)

#     # radiation stress
#     R_solar = at_least_zero(f_rg) * con_1e6 / day_second # MJ m-2 d-1 -> W m-2 daylight
#     lai_safe = max(LAI, minimum_lai)
#     f = oftype(R_solar, 1.1) * R_solar / (R_sc * lai_safe)
#     f1_rad = (f + r_cs_min / r_cs_max) / (f + o_one)

#     # Temperature stress
#     T = f_airT_day # deg C
#     f2_T = (Tmin < T && T < Tmax) ? clamp_zero_one(o_one - k_Temp * (Topt - T) ^ 2) : z_zero

#     # VPD stress
#     VPD = at_least_zero(f_VPD_day) # kPa
#     f3_VPD = clamp_zero_one(o_one - k_VPD * VPD)

#     # water stress -- based on PSi
#     f4_water = clamp_zero_one(leaf_stress)

#     # efficient LAI -- to consider clumping  effect
#     F_s = oftype(LAI, 0.3) * LAI + oftype(LAI, 1.2)

#     # canopy resistance, s m-1
#     denominator = max(LAI, z_zero) * f1_rad * f2_T * f3_VPD * f4_water
#     r_sc = denominator <= tolerance ? r_cs_max : r_cs_min * F_s / denominator
#     r_sc = clamp(r_sc, r_cs_min, r_cs_max)

#     return r_sc
# end

# # function get_pft_value(params::plantHydraulics_PHS, forcing, land, helpers)

# #     @unpack_plantHydraulics_PHS params
# #     @unpack_nt PFT ⇐ land.PFT

# #     PFT = clamp(Int(PFT), 1, 12)

# #     # only includes PFTs from 1-12
# #     LAI_max = [5.5, 7, 3.3, 7, 5.7, 4.6, 3, 1.5, 0.9, 1.8, 6, 7]
# #     w_max = [0.001, 0.05, 0.001, 0.08, 0.04, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01]
# #     h_c_min = [17, 30, 17, 25, 20, 1.5, 1, 0.8, 0.1, 0.05, 0.05, 0]
# #     h_c_max = [17, 30, 17, 25, 20, 1.5, 1, 0.8, 0.8, 0.8, 1.0, 0.8]
# #     k_VPD = [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.155, 0.00, 0.23]
# #     z_0g = [0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.005]
# #     r_cs_min = [125, 150, 150, 100, 125, 150, 100, 70, 70, 40, 100, 40] # s m-1
# #     Cr = [0.45, 0.59, 0.45, 0.59, 0.59, 0.56, 0.56, 0.5, 0.5, 0.5, 0.0, 0.62]

# #     return LAI_max[PFT], w_max[PFT], h_c_min[PFT], h_c_max[PFT], k_VPD[PFT], z_0g[PFT], r_cs_min[PFT], Cr[PFT]
# # end

# purpose(::Type{plantHydraulics_PHS}) = "Coupled Farquhar-Fick-Jarvis three-node plant hydraulics solved by safeguarded Newton iteration."

# @doc """

# $(getModelDocString(plantHydraulics_PHS))

# ---

# # Extended help

# *Versions*
#  - 1.0 on 18.09.2026 [jzhou]

# *Created by*
#  - jzhou
# """
# plantHydraulics_PHS
