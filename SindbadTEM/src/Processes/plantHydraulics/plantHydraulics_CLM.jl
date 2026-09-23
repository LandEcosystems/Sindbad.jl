# export plantHydraulics_PHS

# using StaticArrays: SMatrix, SVector

# const _NEWTON_MAX_ITERATIONS = 50
# const _NEWTON_MAX_BACKTRACKS = 8

# @inline _not_Inf_NaN(value, fallback) = isfinite(value) ? value : oftype(value, fallback)

# function _pos_Inf_not_NaN(value)
#     if isfinite(value)
#         return value
#     elseif isnan(value)
#         return zero(value)
#     end
#     return copysign(floatmax(typeof(value)), value)
# end

# function _pos_not_Inf_NaN(value, fallback)
#     return isfinite(value) && value > zero(value) ? value : oftype(value, fallback)
# end

# function _Boundary_not_Inf_NaN(value, floor)
#     safe_floor = max(_not_Inf_NaN(floor, eps(typeof(floor))), eps(typeof(floor)))
#     return max(_pos_Inf_not_NaN(value), safe_floor)
# end

# @inline _non_negative_Finite(value) = max(_pos_Inf_not_NaN(value), zero(value))

# @inline _norm3(values) = max(abs(values[1]), abs(values[2]), abs(values[3]))

# function _soil_root_conductance(k1, k2)
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

# ### highly recommended to use Ti, where i is the order of params. Because the type of each params can be different in this case, otherwise, the type of params will be promoted to the same type, which may cause some problems.
# #! format: off
# @bounds @describe @units @timescale @with_kw struct plantHydraulics_PHS{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36,T37,T38,T39,T40,T41,T42,T43,T44,T45,T46,T47,T48,T49,T50,T51,T52,T53,T54,T55,T56,T57,T58,T59,T60} <: plantHydraulics
#     # root params
#     root_radius::T1 = 1.5e-3 | (1.0e-5, 1.0e-2) | "fine-root radius used to infer root spacing from SINDBAD root surface area" | "m" | ""
#     biomass_to_carbon::T2 = 0.488 | (0.1, 1.0) | "root carbon per unit root dry biomass" | "gC gDM-1" | ""
#     root_density::T3 = 2.5e5 | (1.0e3, 1.0e6) | "root tissue dry-matter density" | "gDM m-3" | ""
#     root_lateral_length::T4 = 0.25 | (1.0e-3, 10.0) | "average coarse-root lateral length" | "m" | ""
#     stem_to_leaf_area_ratio::T5 = 0.1 | (0.01, 0.9) | "stem area index to leaf area index ratio" | "" | ""

#     # plant hydraulic traits
#     p50_leaf::T6 = -67.67 | (-500, -60.0) | "stem-to-leaf water potential at 50 percent conductivity loss" | "m" | ""
#     p50_stem::T7 = -342.51 | (-1500, -50.0) | "root-to-stem water potential at 50 percent conductivity loss" | "m" | ""
#     p50_root::T8 = -30.0 | (-1000, -20.0) | "soil-root water potential at 50 percent conductivity loss" | "m" | ""
#     p50_leaf_stress::T9 = -150.0 | (-Inf, -1.0) | "leaf water potential at 50 percent transpiration loss" | "m" | ""

#     # plant hydraulic vulnerability-curve factors
#     shape_factor_leaf::T10 = 1.98 | (0.5, 10.0) | "leaf PHS vulnerability-curve shape factor" | "" | ""
#     shape_factor_stem::T11 = 1.98 | (0.5, 6.0) | "stem PHS vulnerability-curve shape factor" | "" | ""
#     shape_factor_root::T12 = 0.8 | (0.5, 6.0) | "root PHS vulnerability-curve shape factor" | "" | ""

#     # hydraulic conductance traits
#     k_root_max::T13 = 1.73e-4 | (8.64e-6, 8.64e-2) | "maximum root hydraulic conductivity" | "m d-1" | ""
#     k_stem_max::T14 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum stem hydraulic conductivity" | "m d-1" | ""
#     k_leaf_max::T15 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum leaf hydraulic conductance" | "d-1" | ""

#     # soil hydrology
#     nvg::T16 = 1.56 | (1.1, 10.0) | "van Genuchten shape parameter" | "" | ""
#     avg::T17 = 3.6 | (0.01, 100.0) | "van Genuchten inverse length parameter" | "m-1" | ""

#     # Newton solvers
#     newton_residual_tolerance::T18 = 1.0e-8 | (1.0e-14, 1.0e-2) | "absolute flux-balance tolerance" | "m d-1" | ""
#     newton_relative_tolerance::T19 = 1.0e-6 | (1.0e-12, 1.0e-2) | "relative flux-balance tolerance" | "" | ""
#     newton_step_tolerance::T20 = 1.0e-7 | (1.0e-12, 1.0) | "water-potential step tolerance" | "m" | ""
#     newton_max_step::T21 = 50.0 | (1.0e-3, 1000.0) | "maximum Newton water-potential step" | "" | ""
#     newton_min_damping::T22 = 1.0 / 256.0 | (1.0e-6, 1.0) | "minimum Newton line-search damping" | "" | ""

#     # photosynthesis parameters
#     Jmax25::T23 = 1e-4 | (2e-5, 3e-4) | "maximum electron transport rate, normalised to 25 ◦C" | "molC m-2 s-1" | ""
#     Vcmax25::T24 = 5e-5 | (1e-5, 1.5e-4) | "Maximum rate of carboxylation, normalised to 25 ◦C. Ratio between J/V is about 1.5 to 2.1." | "molC m-2 s-1" | ""

#     # dark-respiration
#     rate_dark::T25 = 0.02 | (0.005, 0.05) | "dark-respiration rate per unit carboxylation capacity" | "" | ""

#     # CO2 compensation point  parameters
#     ha::T26 = 37830.0 | (1e-2, 1e7) | "Activation energy for gamma star" | "J mol-1" | ""
#     gs25_0::T27 = 4.332 | (4.0, 5.0) | "Photorespiratory compensation point" | "Pa" | ""

#     # Michaelis-Menten constants
#     k_co::T28 = 209476 | (1e-2, 1e7) | "Michaelis–Menten coefficient params" | "" | ""
#     dhac::T29 = 79430 | (1e-2, 1e7) | "Activation energy for Kc" | "J mol-1" | ""
#     dhao::T30 = 36380 | (1e-2, 1e7) | "Activation energy for Ko" | "J mol-1" | ""
#     kc25::T31 = 39.97 | (1e-2, 1e7) | "Michaelis-Menten constant for CO2 at 25C" | "Pa" | ""
#     ko25::T32 = 27480 | (1e-2, 1e7) | "Michaelis-Menten constant for O2 at 25C" | "Pa" | ""

#     # Medlyn gs model parameters
#     g0::T33 = 0.001 | (-0.05, 0.05) | "the minimum stomatal conductance, ranges are refer to Medlyn paper" | "mol m-2 s-1" | ""
#     g1::T34 = 3.0 | (1, 12.0) | "stomatal conductance parameter, ranges are refer to Medlyn paper" | "kPa^0.5" | ""
    
#     # Jarvis gs model parameters
#     R_sc::T35 = 100 | (1e-2, 1e3) | "scaling factor relevant to Solar radiation" | "W m-2" | ""
#     r_cs_max::T36 = 5000 | (1e3, 1e7) | "maximum canopy resistance related to PFTs" | "s m-1" | ""
#     Tmin::T37 = 0 | (-10, 5) | "minimum temperature for stomatal conductance" | "deg C" | ""
#     Topt::T38 = 25 | (10, 40) | "optimal temperature for stomatal conductance" | "deg C" | ""
#     Tmax::T39 = 40 | (30, 55) | "maximum temperature for stomatal conductance" | "deg C" | ""
#     k_Temp::T40 = 0.0016 | (1e-4, 1e-1) | "temperature stress coefficient" | "unitless" | ""
#     k_VPD::T41 = 0.25 | (0.1, 0.3) | "Jarvis VPD stressor params" | "" | ""
    
#     # constants
#     CL::T42 = 0.25 | (0.1, 0.8) | "maximum quantum yield of photosystem II in light-adapted leaves, for PAR to Iabs, refer to P model" | "" | ""
#     k_R::T43 = 8.3145 | (8, 9) | "universal gas constant" | "J mol-1 K-1" | ""
#     diffusivity_ratio::T44 = 1.6 | (-Inf, Inf) | "Ratio of the molecular diffusivities for water vapor and CO2" | "" | ""
#     k_Po::T45 = 101325.0 | (1, 1e7) | "one standard ATM" | "Pa" | ""
#     tk_ref::T46 = 298.15 | (298, 299) | "25 deg C in unit of K" | "" | ""

#     # boundary conditions
#     minimum_conductance::T47 = 1.0e-12 | (0.0, 1.0) | "numerical floor for hydraulic conductance" | "d-1" | ""
#     minimum_lai::T48 = 1.0e-6 | (0.0, 1.0) | "minimum LAI for solving the hydraulic network" | "m2 m-2" | ""
#     minimum_height::T49 = 1.0e-3 | (1.0e-6, 10.0) | "minimum canopy height used in path-length scaling" | "m" | ""
#     min_root_length_density::T50 = 1.0e-12 | (0.0, 1e7) | "root length-density floor used to avoid singular root spacing" | "m m-3" | ""
#     minimum_froot_allocation::T51 = 0.001 | (0.0001, 1.0) | "minimum fine-root allocation factor" | "" | ""

#     # unit conversions
#     mm_2_m::T52 = 1.0e-3 | (0.0, 1e7) | "unit conversion from mm to m" | "" | ""
#     m_to_mm::T53 = 1.0e3 | (0.0, 1e7) | "unit conversion from m to mm" | "" | ""
#     m_to_MPa::T54 = 0.00980665 | (0.0, 1e7) | "unit conversion of water potential from m to MPa" | "" | ""
#     deg_2_K::T55 = 273.15 | (1e-2, 1e7) | "Gamma star params, convert deg C to K" | "" | ""
#     c_mol_mass::T56 = 12.0 | (1e-2, 1e7) | "molecular mass of carbon" | "g/mol" | ""
#     w_mol_mass::T57 = 18.0 | (1e-2, 1e7) | "molecular mass of water" | "g/mol" | ""
#     par_ppfd::T58 = 4.57 | (0, 5) | "PAR to PPFD conversion factor, from W/m2 to umol/m2/s" | "" | ""
#     day_second::T59 = 86400 | (1e-2, 1e7) | "seconds in a day" | "s" | ""
#     daytime_second::T60 = 36000 | (1e-2, 1e7) | "seconds in a daytime, assuming daytime has 10 hours" | "s" | ""
    
# end
# #! format: on

# function define(params::plantHydraulics_PHS, forcing, land, helpers)

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

#     ψ_leaf_prev = -H_canopy # intial leaf water potential, m
#     ψ_leaf = -H_canopy
#     ψ_stem = -H_canopy
#     ψ_root = z_zero
#     ψ_soil = zero(soilW)
#     ψ_soil_matric = zero(soilW) # don't consider the soil depth gravity potential, only the matric potential, unit: m.

#     θ_soil = zero(soilW) # in m3 m-3

#     β_leaf = o_one # leaf water stress factor (0-1) calculated based on leaf water potential and leaf vulnerability curve
#     β_stem = o_one # stem water stress factor (0-1) calculated based on stem water potential and stem vulnerability curve
#     β_root = zero(soilW)
#     gpp_f_soilW = o_one
    
#     ε_solver = z_zero
#     ITERARIONS = z_zero
#     CONVERGED = false

#     @pack_nt begin
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.properties
#         (θ_range_inv, θ_soil) ⇒ land.properties
#         (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root, ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
#         (β_leaf, β_stem, β_root, gpp_f_soilW) ⇒ land.diagnostics
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
#         (RAI, phs_root_spacing, fine_root_fraction) ⇒ land.diagnostics
#         (ε_solver, ITERARIONS, CONVERGED) ⇒ land.diagnostics
#         phs_transpiration ⇒ land.diagnostics
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
#     cumulative_depth_m = z_zero
#     @inbounds for sl in eachindex(soilW)
#         thickness = soil_layer_thickness[sl]
#         thickness_m = thickness * mm_2_m
#         cumulative_depth_m += thickness_m
#         root_depth_denominator = root_lateral_length + cumulative_depth_m
#         θ_range = sp_θ_fc[sl] - sp_θ_wp[sl]

#         @rep_elem inv(thickness) ⇒ (D_soil_inv_mm, sl, :soilW)
#         @rep_elem thickness_m ⇒ (D_soil_m, sl, :soilW)
#         @rep_elem cumulative_depth_m ⇒ (D_soil_cum_m, sl, :soilW)
#         @rep_elem inv(θ_range) ⇒ (θ_range_inv, sl, :soilW)
#         @rep_elem root_depth_denominator ⇒ (D_root_deno, sl, :soilW)
#     end
#     @pack_nt begin
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.properties
#         θ_range_inv ⇒ land.properties
#     end
#     return land
# end

# function compute(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_canopy_height ⇐ forcing
#         (LAI, PAW) ⇐ land.states
#         (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇐ land.diagnostics
#         phs_root_water_uptake ⇐ land.fluxes
#         root_over ⇐ land.rootWaterEfficiency
#         (z_zero, o_one) ⇐ land.constants
#     end

#     land = cal_soil_hydrology(params, land, helpers)
#     @unpack_nt begin
#         (ψ_soil, Κ_soil_root) ⇐ land.diagnostics
#     end

#     uptake_capacity = _non_negative_Finite.(oftype(ψ_leaf, mm_2_m) * PAW)

#     H_canopy = _Boundary_not_Inf_NaN(
#         oftype(ψ_leaf, f_canopy_height),
#         oftype(ψ_leaf, minimum_height),
#     )
#     lai = _non_negative_Finite(oftype(ψ_leaf, LAI))
#     sai = _non_negative_Finite(oftype(ψ_leaf, stem_to_leaf_area_ratio) * lai)

#     initial = SVector{3,typeof(ψ_leaf)}(ψ_leaf, ψ_stem, ψ_root)

#     solution, CONVERGED, ITERARIONS, ε_solver = _SOLVE_Newton(
#             params, forcing, land, helpers, initial,
#             ψ_soil, Κ_soil_root, uptake_capacity,
#             lai, sai, H_canopy,
#         )

#     ψ_leaf = solution[1]
#     ψ_stem = solution[2]
#     ψ_root = solution[3]

#     β_leaf = cal_vulnerability_curve(ψ_leaf, p50_leaf, shape_factor_leaf)
#     β_leaf = clamp_zero_one(β_leaf)
#     β_stem = cal_vulnerability_curve(ψ_root, p50_stem, shape_factor_stem)
#     β_stem = clamp_zero_one(β_stem)

#     gpp_f_soilW = β_leaf

#     gpp_farquhar, Ac, Aj, Vc_actual, J_actual, dark_respiration, net_photosynthesis, gs_Medlyn, ci_Pa = cal_GPP_Farquhar(params, forcing, land, helpers, β_leaf)
#     phs_transpiration = cal_transpiration_Fick(params, forcing, land, helpers, gs_Medlyn) # mm d-1

#     @inbounds for sl in eachindex(phs_root_water_uptake)

#         if root_over[sl] > zero(root_over[sl])
#             flux_m_per_day, _ = cal_root_water_uptake(ψ_soil[sl], Κ_soil_root[sl], uptake_capacity[sl], ψ_root)
#         else
#             flux_m_per_day = z_zero
#         end

#         uptake = flux_m_per_day * m_to_mm
#         @rep_elem uptake ⇒ (phs_root_water_uptake, sl, :soilW)
#     end

#     @pack_nt begin
#         (ψ_leaf, ψ_stem, ψ_root) ⇒ land.diagnostics
#         (β_leaf, β_stem, gpp_f_soilW) ⇒ land.diagnostics
#         (ε_solver, ITERARIONS, CONVERGED) ⇒ land.diagnostics
#         phs_root_water_uptake ⇒ land.fluxes
#         (gpp_farquhar, dark_respiration, net_photosynthesis) ⇒ land.diagnostics
#         (Ac, Aj, Vc_actual, J_actual) ⇒ land.diagnostics
#         (gs_Medlyn, phs_transpiration, ci_Pa) ⇒ land.diagnostics
#     end

#     return land
# end

# function cal_soil_hydrology(params::plantHydraulics_PHS, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         LAI ⇐ land.states
#         (soilW, ΔsoilW, cEco) ⇐ land.pools
#         (sp_θ_wp, θ_range_inv, θ_soil) ⇐ land.properties
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇐ land.properties
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇐ land.diagnostics
#         (ψ_soil, ψ_soil_matric) ⇐ land.diagnostics
#         (phs_root_spacing, β_root, RAI) ⇐ land.diagnostics
#         (root_surface_area, c_allocation, fine_root_fraction) ⇐ land.diagnostics
#         root_over ⇐ land.rootWaterEfficiency
#         unsat_k_model ⇐ land.models
#         z_zero ⇐ land.constants
#     end

#     Rsf = sum(root_surface_area)
#     froot_to_leaf = c_allocation[1]
#     lai = at_least_zero(LAI)
#     sai = at_least_zero(stem_to_leaf_area_ratio * lai)

#     @inbounds for sl in eachindex(soilW)

#         θ = (soilW[sl] + ΔsoilW[sl]) * D_soil_inv_mm[sl]
#         soil_potential = cal_soil_potential(params, θ, sp_θ_wp[sl], θ_range_inv[sl])

#         if root_over[sl] > zero(root_over[sl])
#             root_fraction = at_least_zero(root_surface_area[sl]) / Rsf
#             layer_head = _pos_Inf_not_NaN(soil_potential - D_soil_cum_m[sl])
#             root_spacing = cal_root_spacing(params, cEco[1] * fine_root_fraction, D_soil_m[sl], root_fraction)
#             k_soil_unsat = at_least_zero(unsatK(land, helpers, sl, unsat_k_model) * mm_2_m)
#             k_soil = _Boundary_not_Inf_NaN(k_soil_unsat / root_spacing, minimum_conductance)

#             ### TODO: it's different from A6 to A11 of CLM-PHS.
#             rai = at_least_zero((sai + lai) * root_fraction * froot_to_leaf)
#             root_stress = cal_vulnerability_curve(soil_potential, p50_root, shape_factor_root)
#             k_root = _Boundary_not_Inf_NaN(root_stress * rai * k_root_max / D_root_deno[sl], minimum_conductance)

#             soil_to_root = _soil_root_conductance(k_soil, k_root)

#         else
#             layer_head = soil_to_root = root_spacing = k_soil = k_root = k_soil_unsat = root_stress = rai = z_zero
#         end

#         @rep_elem θ ⇒ (θ_soil, sl, :soilW)
#         @rep_elem soil_potential ⇒ (ψ_soil_matric, sl, :soilW)
#         @rep_elem layer_head ⇒ (ψ_soil, sl, :soilW)
#         @rep_elem soil_to_root ⇒ (Κ_soil_root, sl, :soilW)
#         @rep_elem root_spacing ⇒ (phs_root_spacing, sl, :soilW)
#         @rep_elem k_soil ⇒ (Κ_soil, sl, :soilW)
#         @rep_elem k_root ⇒ (Κ_root, sl, :soilW)
#         @rep_elem k_soil_unsat ⇒ (Κ_soil_unsat, sl, :soilW)
#         @rep_elem root_stress ⇒ (β_root, sl, :soilW)
#         @rep_elem rai ⇒ (RAI, sl, :soilW)
#     end

#     @unpack_nt begin
#         (θ_soil) ⇒ land.diagnostics
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
#         (ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
#         (β_root, RAI, phs_root_spacing) ⇒ land.diagnostics
#     end
#     return land
# end

# function _SOLVE_Newton(params::plantHydraulics_PHS, forcing, land, helpers, initial, layer_head, layer_conductance, uptake_capacity, lai, sai, H_canopy)

#     @unpack_plantHydraulics_PHS params

#     ### Initialize the Newton solver
#     H_canopy = _Boundary_not_Inf_NaN(H_canopy, minimum_height)
#     x = _project_potentials(initial, H_canopy)
#     z_zero = zero(eltype(x))
#     flux_scale = max(abs(H_canopy), newton_residual_tolerance)
#     converged = false
#     ε_norm = oftype(H_canopy, Inf)

#     critaria = newton_residual_tolerance + newton_relative_tolerance * flux_scale

#     ### if LAI is too small, we assume that the plant is not transpiring and set the root potential to the value that would result in zero Tr.
#     if lai <= minimum_lai
#         root = _ψ_root_when_zero_demand(layer_head, layer_conductance, uptake_capacity, x[3])
#         solution = _project_potentials(
#             SVector{3,eltype(x)}(root - H_canopy, root - H_canopy, root),
#             H_canopy,
#         )

#         ε = _calculate_ε(
#             params, forcing, land, helpers, solution, layer_head, layer_conductance,
#             uptake_capacity, z_zero, z_zero, H_canopy,
#         )
#         ε_norm = _norm3(ε)

#         if !isfinite(ε_norm)
#             ε_norm = floatmax(typeof(ε_norm))
#         end
#         converged = ε_norm <= critaria
#         return solution, converged, 0, ε_norm
#     end

#     ### Newton solver loop
#     iterations = 0
#     for iteration in 1:_NEWTON_MAX_ITERATIONS
#         iterations = iteration
#         ε, jacobian = _jacobian_ε(
#             params, forcing, land, helpers, x, layer_head, layer_conductance,
#             uptake_capacity, lai, sai, H_canopy,
#         )
#         ε_norm = _norm3(ε)

#         ### if residuals is Inf or NaN, we break the loop
#         if !isfinite(ε_norm)
#             ε_norm = floatmax(typeof(ε_norm))
#             break
#         end

#         ### if residuals is lower than the tolerance, we break the loop and return the current solution
#         if ε_norm <= critaria
#             converged = true
#             break
#         end

#         ### if residuals is not lower than the tolerance, we calculate the Jacobian and solve for the next step
#         determinant = _Determinant(jacobian)
#         if !isfinite(determinant) || abs(determinant) <= oftype(determinant, 1.0e-24)
#             break
#         end

#         step = -_SOLVE_Matric(jacobian, ε, determinant)
#         step_norm = _norm3(step)

#         ### if the step is Inf or NaN, we break the loop
#         if !isfinite(step_norm)
#             break
#         end

#         if step_norm > newton_max_step
#             step *= newton_max_step / step_norm
#             step_norm = newton_max_step
#         end

#         damping = one(H_canopy)
#         candidate = x
#         candidate_norm = ε_norm

#         accepted = false
#         ### Backtracking line search to find a suitable damping factor >> LIKE gradient descent
#         # if you want better results, you can increase the number of backtracks and iterations, but it will take longer to converge
#         for _ in 1:_NEWTON_MAX_BACKTRACKS
#             candidate = _project_potentials(x + damping * step, H_canopy)
#             candidate_residual = _calculate_ε(
#                 params, forcing, land, helpers, candidate, layer_head, layer_conductance,
#                 uptake_capacity, lai, sai, H_canopy,
#             )
#             candidate_norm = _norm3(candidate_residual)

#             if isfinite(candidate_norm) && candidate_norm < ε_norm
#                 accepted = true
#                 break
#             end

#             ### lower the damping factor by half and try again
#             damping *= oftype(damping, 0.5)
#         end

#         if !accepted
#             damping = newton_min_damping
#             candidate = _project_potentials(x + damping * step, H_canopy)
#             candidate_residual = _calculate_ε(
#                 params, forcing, land, helpers, candidate, layer_head, layer_conductance,
#                 uptake_capacity, lai, sai, H_canopy,
#             )
#             candidate_norm = _norm3(candidate_residual)

#             if !isfinite(candidate_norm)
#                 candidate = x
#                 candidate_norm = ε_norm
#             end
#         end

#         x = candidate
#         ε_norm = candidate_norm

#         if damping * step_norm <= newton_step_tolerance
#             converged = ε_norm <= critaria
#             break
#         end
#     end

#     return x, converged, iterations, ε_norm
# end

# function _Determinant(matrix)

#     a, b, c = matrix[1, 1], matrix[1, 2], matrix[1, 3]
#     d, e, f = matrix[2, 1], matrix[2, 2], matrix[2, 3]
#     g, h, i = matrix[3, 1], matrix[3, 2], matrix[3, 3]

#     determinant = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
#     return isfinite(determinant) ? determinant : zero(determinant)
# end

# function _SOLVE_Matric(matrix, rhs, determinant=_Determinant(matrix))

#     a, b, c = matrix[1, 1], matrix[1, 2], matrix[1, 3]
#     d, e, f = matrix[2, 1], matrix[2, 2], matrix[2, 3]
#     g, h, i = matrix[3, 1], matrix[3, 2], matrix[3, 3]

#     y1, y2, y3 = rhs

#     if !isfinite(determinant) || iszero(determinant)
#         return zero(rhs)
#     end

#     x1 = _pos_Inf_not_NaN(
#         (y1 * (e * i - f * h) - b * (y2 * i - f * y3) + c * (y2 * h - e * y3)) / determinant,
#     )
#     x2 = _pos_Inf_not_NaN(
#         (a * (y2 * i - f * y3) - y1 * (d * i - f * g) + c * (d * y3 - y2 * g)) / determinant,
#     )
#     x3 = _pos_Inf_not_NaN(
#         (a * (e * y3 - y2 * h) - b * (d * y3 - y2 * g) + y1 * (d * h - e * g)) / determinant,
#     )

#     return SVector{3,typeof(x1)}(x1, x2, x3)
# end

# function _calculate_ε(params::plantHydraulics_PHS, forcing, land, helpers, x, layer_head, layer_conductance, uptake_capacity, lai, sai, H_canopy)

#     ### It's used to calculate the residuals (ε) without Jacobian matrix.
#     @unpack_plantHydraulics_PHS params

#     leaf, stem, root = x
#     z_zero = zero(root)

#     leaf_stress = cal_vulnerability_curve(leaf, p50_leaf, shape_factor_leaf)
#     ### TODO: update transpiration using fick law
#     _, _, _, _, _, _, _, gs, _ = cal_GPP_Farquhar(params, forcing, land, helpers, leaf_stress)
#     transpiration = cal_transpiration_Fick(params, forcing, land, helpers, gs) # mm d-1
#     transpiration = transpiration / 1e3 # m d-1

#     leaf_conductance = lai * k_leaf_max * cal_vulnerability_curve(stem, p50_leaf, shape_factor_leaf)
#     leaf_conductance = _non_negative_Finite(leaf_conductance)

#     stem_to_leaf = leaf_conductance * (stem - leaf)
#     stem_to_leaf = _pos_Inf_not_NaN(stem_to_leaf)

#     stem_conductance_scale = _non_negative_Finite(sai * k_stem_max / H_canopy)
#     stem_conductance = stem_conductance_scale * cal_vulnerability_curve(root, p50_stem, shape_factor_stem)
#     stem_conductance = _non_negative_Finite(stem_conductance)

#     root_to_stem = stem_conductance * (root - stem - H_canopy)
#     root_to_stem = _pos_Inf_not_NaN(root_to_stem)

#     ### soil to root fluxes
#     soil_to_root = z_zero
#     @inbounds for sl in eachindex(layer_head)
#         layer_flux, _ = cal_root_water_uptake(layer_head[sl], layer_conductance[sl], uptake_capacity[sl], root)
#         soil_to_root += layer_flux
#     end

#     return SVector{3,typeof(root)}(
#         _pos_Inf_not_NaN(transpiration - stem_to_leaf),
#         _pos_Inf_not_NaN(stem_to_leaf - root_to_stem),
#         _pos_Inf_not_NaN(root_to_stem - soil_to_root),
#     )
# end

# function _jacobian_ε(params::plantHydraulics_PHS, forcing, land, helpers, x, layer_head, layer_conductance, uptake_capacity, lai, sai, H_canopy)

#     ### it's used to calculate the Jacobian matrix of the residuals (ε), so that the Newton can be solved.
#     @unpack_plantHydraulics_PHS params

#     leaf, stem, root = x
#     z_zero = zero(root)

#     leaf_stress, dleaf_stress = cal_vulnerability_curve_derivative(leaf, p50_leaf, shape_factor_leaf)
#     ### TODO: update transpiration using fick law
#     _, _, _, _, _, _, _, gs, _ = cal_GPP_Farquhar(params, forcing, land, helpers, leaf_stress)
#     transpiration = cal_transpiration_Fick(params, forcing, land, helpers, gs) # mm d-1
#     transpiration = transpiration / 1e3 # m d-1
    
#     leaf_vulnerability, dleaf_vulnerability = cal_vulnerability_curve_derivative(stem, p50_leaf, shape_factor_leaf)
#     leaf_conductance = lai * k_leaf_max * leaf_vulnerability
#     leaf_conductance = _non_negative_Finite(leaf_conductance)

#     stem_to_leaf = leaf_conductance * (stem - leaf)
#     stem_to_leaf = _pos_Inf_not_NaN(stem_to_leaf)
    
#     stem_vulnerability, dstem_vulnerability = cal_vulnerability_curve_derivative(root, p50_stem, shape_factor_stem)

#     stem_conductance_scale = _non_negative_Finite(sai * k_stem_max / H_canopy)
#     ### lack of constraint on stem and root vulnerability curve
#     ### TODO: in CLM-PHS (Implementing plant hydraulics in the community land model, version 5), the stem vulnerability should be root vulnerability.
#     stem_conductance = stem_conductance_scale * stem_vulnerability
#     stem_conductance = _non_negative_Finite(stem_conductance)

#     root_to_stem = stem_conductance * (root - stem - H_canopy)
#     root_to_stem = _pos_Inf_not_NaN(root_to_stem)

#     ### deviations of leaf, stem, root
#     _, _, _, _, _, _, _, gs_dleaf, _ = cal_GPP_Farquhar(params, forcing, land, helpers, dleaf_stress)
#     dtranspiration_dleaf = cal_transpiration_Fick(params, forcing, land, helpers, gs_dleaf) # mm d-1
#     dtranspiration_dleaf = dtranspiration_dleaf / 1e3 # m d-1

#     dleaf_conductance_dstem = _pos_Inf_not_NaN(lai * k_leaf_max * dleaf_vulnerability)

#     dstem_to_leaf_dleaf = -leaf_conductance
#     dstem_to_leaf_dstem = leaf_conductance + dleaf_conductance_dstem * (stem - leaf)
#     dstem_to_leaf_dstem = _pos_Inf_not_NaN(dstem_to_leaf_dstem)

#     dstem_conductance_droot = stem_conductance_scale * dstem_vulnerability
#     dstem_conductance_droot = _pos_Inf_not_NaN(dstem_conductance_droot)

#     droot_to_stem_dstem = -stem_conductance
#     droot_to_stem_droot = stem_conductance + dstem_conductance_droot * (root - stem - H_canopy)
#     droot_to_stem_droot = _pos_Inf_not_NaN(droot_to_stem_droot)

#     ### soil to root fluxes and derivatives
#     soil_to_root = dsoil_to_root_droot = z_zero
#     @inbounds for sl in eachindex(layer_head)
#         bounded_flux, layer_derivative = cal_root_water_uptake(layer_head[sl], layer_conductance[sl], uptake_capacity[sl], root)
#         soil_to_root += bounded_flux
#         dsoil_to_root_droot += layer_derivative
#     end

#     ε = SVector{3,typeof(root)}(
#         _pos_Inf_not_NaN(transpiration - stem_to_leaf),
#         _pos_Inf_not_NaN(stem_to_leaf - root_to_stem),
#         _pos_Inf_not_NaN(root_to_stem - soil_to_root),
#     )

#     jacobian = SMatrix{3,3,typeof(root),9}(
#         _pos_Inf_not_NaN(dtranspiration_dleaf - dstem_to_leaf_dleaf), dstem_to_leaf_dleaf, z_zero,
#         -dstem_to_leaf_dstem, _pos_Inf_not_NaN(dstem_to_leaf_dstem - droot_to_stem_dstem), droot_to_stem_dstem,
#         z_zero, -droot_to_stem_droot, _pos_Inf_not_NaN(droot_to_stem_droot - dsoil_to_root_droot),
#     )

#     return ε, jacobian
# end

# function cal_root_water_uptake(head, conductance, uptake_capacity, root)

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
#             layer_flux, layer_derivative = cal_root_water_uptake(layer_head[sl], layer_conductance[sl], uptake_capacity[sl], root)
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

# function _project_potentials(x, H_canopy)

#     root = min(_not_Inf_NaN(x[3], zero(x[3])), zero(x[3]))
#     highest_stem = _pos_Inf_not_NaN(root - H_canopy)
#     stem = min(_not_Inf_NaN(x[2], highest_stem), highest_stem)
#     leaf = min(_not_Inf_NaN(x[1], stem), stem)

#     return SVector{3,typeof(root)}(leaf, stem, root)
# end

# function cal_vulnerability_curve(psi, psi50, shape_factor)

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

# function cal_vulnerability_curve_derivative(psi, psi50, shape_factor)

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

# function cal_soil_potential(params::plantHydraulics_PHS, θ, θ_wp, θ_range_inv)
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

# function cal_plant_hydraulic(params::plantHydraulics_PHS, forcing, land, helpers, transpiration)
#     @unpack_plantHydraulics_PHS params



#     psi_root = cal_root_water_potential(params, forcing, land, helpers)

#     psi_stem, beta_stem = cal_stem_water_potential(params, forcing, land, helpers, psi_root, transpiration)

#     psi_leaf, beta_leaf = cal_leaf_water_potential(params, forcing, land, helpers, psi_stem, transpiration)

#     return psi_root, psi_stem, psi_leaf, beta_stem, beta_leaf

# end

# function cal_leaf_water_potential(params::plantHydraulics_PHS, forcing, land, helpers, psi_stem, transpiration)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         LAI ⇐ land.states
#     end
#     Q_stem_2_leaf = transpiration # m d-1
#     beta_leaf_stem = cal_vulnerability_curve(psi_stem, p50_leaf, shape_factor_leaf)
#     if LAI > minimum_lai
#         leaf_conductance = k_leaf_max * beta_leaf_stem
#         psi_leaf = psi_stem - Q_stem_2_leaf / LAI / leaf_conductance
#     else
#         psi_leaf = psi_stem
#     end
#     beta_leaf = cal_vulnerability_curve(psi_leaf, p50_leaf_stress, shape_factor_leaf)
#     return psi_leaf, beta_leaf
# end

# function cal_stem_water_potential(params::plantHydraulics_PHS, forcing, land, helpers, psi_root, transpiration)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_canopy_height ⇐ forcing
#         LAI ⇐ land.states
#     end
#     H_canopy = f_canopy_height # m
#     Q_root_2_stem = transpiration # m d-1
#     beta_stem_root = cal_vulnerability_curve(psi_root, p50_stem, shape_factor_stem)
#     SAI = stem_to_leaf_area_ratio * LAI
#     if SAI > 0 && beta_stem_root > 0
#         stem_conductance = k_stem_max * beta_stem_root / H_canopy
#         psi_stem = psi_root - H_canopy - Q_root_2_stem / SAI / stem_conductance
#     else
#         psi_stem = psi_root - H_canopy
#     end
#     return psi_stem, beta_stem
# end

# function cal_root_water_potential(params::plantHydraulics_PHS, forcing, land, helpers, transpiration)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (Κ_soil_root, root_surface_area) ⇐ land.diagnostics
#         (z_zero, o_one) ⇐ land.constants
#         root_over ⇐ land.rootWaterEfficiency
#         (sp_θ_wp, θ_range_inv) ⇐ land.properties
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇐ land.properties
#     end

#     Q_soil_2_root = transpiration # m d-1
#     if abs(sum(Κ_soil_root[1])) == z_zero
#         psi_root = sum(psi_soil - soil_depth) / length(psi_soil)
#     else
#         Rsf = sum(root_surface_area)
#         num_root_layer = sum(root_over .> z_zero)
#         psi_root = z_zero
#         for sl in eachindex(num_root_layer)
#             root_fraction = at_least_zero(root_surface_area[sl]) / Rsf
#             θ = (soilW[sl] + ΔsoilW[sl]) * D_soil_inv_mm[sl]
#             psi_soil = cal_soil_potential(params, θ, sp_θ_wp[sl], θ_range_inv[sl])

#             psi_root_layer = (Κ_soil_root[sl] * (psi_soil[sl] - soil_depth[sl]) - Q_soil_2_root * root_fraction[sl]) / Κ_soil_root[sl]
#             psi_root_layer = _Boundary_not_Inf_NaN(psi_root_layer, oftype(psi_soil[sl], 1.0e-24))
#             psi_root += psi_root_layer
#         end
#         if !isreal(psi_root)
#             psi_root = sum(psi_soil * root_fraction)
#         end
#         psi_root = max(psi_root, -1000) # -10MPa to m = -1019.368
#         psi_root = min(z_zero, psi_root)
#     end
#     return psi_root
# end


# function cal_root_spacing(params::plantHydraulics_PHS, root_carbon, layer_thickness_m, root_fraction)
#     @unpack_plantHydraulics_PHS params
#     # The root carbon should be fine root carbon, not total root carbon.
#     numerator = root_carbon * root_fraction
#     denominator = biomass_to_carbon * root_density * pi * root_radius ^ 2 * layer_thickness_m
#     denominator = _Boundary_not_Inf_NaN(denominator, oftype(root_carbon, 1.0e-24))
#     root_length_density = _Boundary_not_Inf_NaN(numerator / denominator, min_root_length_density)
#     spacing = sqrt(inv(pi * root_length_density))
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
#     kc = kc25 * exp(dhac * (tk - tk_ref) / (tk_ref * k_R * tk))
#     ko = ko25 * exp(dhao * (tk - tk_ref) / (tk_ref * k_R * tk))
#     po = k_co * 1e-06 * patm
#     kmm = kc * (o_one + po / ko) # Pa
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
#     return phi_o
# end

# function cal_gamma_star(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_airT_day) ⇐ forcing
#     end
#     patm = f_psurf_day * 1e3 # kPa to Pa
#     tk = f_airT_day + deg_2_K # deg C to K
#     arrhenius_factor = exp(ha * (tk - tk_ref) / (tk_ref * k_R * tk)) # dimensionless
#     gamma_star = (gs25_0 * patm / k_Po) * arrhenius_factor # Pa
#     return gamma_star
# end

# function cal_Jmax_Vmax(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_airT_day ⇐ forcing
#     end
#     ### consider the effects of temperature on Vc and J
#     # according to arrhenius function to convert Vcmax25 and Jmax25 to Vcmax and Jmax at current temperature.
#     tk = f_airT_day + deg_2_K # deg C to K
#     arrhenius_factor = exp(ha * (tk - tk_ref) / (tk_ref * k_R * tk)) # dimensionless
#     Vcmax = Vcmax25 * arrhenius_factor # molC m-2 d-1
#     Jmax = Jmax25 * arrhenius_factor # molC m-2 d-1
#     return Jmax, Vcmax
# end

# @inline function cal_efficient_LAI(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         LAI ⇐ land.states
#     end
#     efficient_lai = 0.3 * LAI + 1.2
#     return efficient_lai
# end

# function cal_leaf_internal_CO2(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_VPD_day) ⇐ forcing
#         ambient_CO2 ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end
#     patm = f_psurf_day * 1e3 # kPa to Pa
#     ca = 1.0e-6 * ambient_CO2 * patm # ppm to Pa
#     ciNoCO2 = g1 / (g1 + sqrt(f_VPD_day)) # fraction, f_VPD_day should be in kPa.
#     ci = ciNoCO2 * ca # Pa
#     return ci
# end

# function cal_dark_respiration(params::plantHydraulics_PHS, forcing, land, helpers, Vcmax)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day) ⇐ forcing
#         ambient_CO2 ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end
#     # dark respiration occurs in 24 hours.
#     dark_respiration = rate_dark * Vcmax # mol C m-2 s-1
#     dark_respiration *= c_mol_mass * day_second # gC m-2 d-1
#     return dark_respiration
# end

# function cal_gs_Medlyn(params::plantHydraulics_PHS, forcing, land, helpers, net_photosynthesis, ca)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_VPD_day) ⇐ forcing
#         ambient_CO2 ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end
#     # unit: net_photosynthesis is molC m-2 s-1, ca is mol CO2 mol-1 air, f_VPD_day is kPa.
#     gs = g0 + (1 + g1 / sqrt(f_VPD_day)) * (net_photosynthesis / ca) # molC m-2 s-1 Pa-1
#     return gs
# end

# function cal_GPP_Farquhar(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_PAR, f_VPD_day) ⇐ forcing
#         (fAPAR) ⇐ land.states
#         ambient_CO2 ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end

#     con_1e6 = oftype(f_PAR, 1e6)
#     gamma_star = cal_gamma_star(params, forcing, land, helpers)
#     KM = cal_KM(params, forcing, land, helpers) # effective Michaelis–Menten coefficient K (Pa)
#     Jmax, Vcmax = cal_Jmax_Vmax(params, forcing, land, helpers) # mol C m-2 s-1
#     ci = cal_leaf_internal_CO2(params, forcing, land, helpers) # Pa

#     ### carboxylation-limited rate, Ac.
#     Vc_actual = Vcmax * leaf_stress # consider water stress on Vcmax, mol C m-2 s-1
#     co2_numerator = at_least_zero(ci - gamma_star)
#     Ac = Vc_actual * co2_numerator / (ci + KM) # mol C m-2 s-1

#     ### light-limited rate, Aj.
#     Iabs = f_PAR * fAPAR * par_ppfd * con_1e6 / day_second # absorbed irradiance, mol/m2/s
#     Phi_o = cal_Phi_o(params, forcing, land, helpers) # the intrinsic quantum-yield efficiency, dimensionless
#     numerator = 4 * Phi_o * Iabs
#     denominator = (numerator / Jmax) ^ 2 + o_one
#     J_actual = numerator / sqrt(denominator) # mol C m-2 s-1
#     Aj = ci > gamma_star ? J_actual * (ci - gamma_star) / (4 * ci + 8 * gamma_star) : z_zero # mol C m-2 s-1

#     ### consider the minimum of Ac and Aj as the GPP, mol C m-2 s-1
#     gpp_farquhar = min(Ac, Aj) # leaf scale

#     ### upscale to canopy scale using efficient LAI to consider clumping  effect.
#     efficient_lai = cal_efficient_LAI(params, forcing, land, helpers)
#     gpp_farquhar = gpp_farquhar * efficient_lai # mol C m-2 d-1, canopy scale
#     # Assumption: GPP is only occurs in daytime, and the daytime is 10 hours.
#     gpp_farquhar = gpp_farquhar * c_mol_mass * daytime_second # convert to g C m-2 d-1

#     ### canopy scale Ac and Aj
#     Ac = Ac * efficient_lai * c_mol_mass * daytime_second # g C m-2 d-1
#     Aj = Aj * efficient_lai * c_mol_mass * daytime_second # g C m-2 d-1

#     ### canopy conductance and dark respiration
#     ca = 1.0e-6 * ambient_CO2 # ppm to mol CO2 mol-1 air
#     dark_respiration = cal_dark_respiration(params, forcing, land, helpers, Vc_actual) # g C m-2 d-1
#     net_photosynthesis = gpp_farquhar - dark_respiration # g C m-2 d-1
#     gs = cal_gs_Medlyn(params, forcing, land, helpers, net_photosynthesis / c_mol_mass, ca) # mol C m-2 d-1 Pa-1
#     gs = at_least_zero(gs) # mol C m-2 d-1 Pa-1

#     return gpp_farquhar, Ac, Aj, Vc_actual, J_actual, dark_respiration, net_photosynthesis, gs, ci
# end

# function cal_transpiration_Fick(params::plantHydraulics_PHS, forcing, land, helpers, gs)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_VPD_day ⇐ forcing
#     end
#     ### unit: gs is molC m-2 s-1 Pa-1, VPD should be Pa.
#     vpd = at_least_zero(f_VPD_day) * 1000 # kPa to Pa
#     Tr_fick = diffusivity_ratio * gs * vpd # mol H2O m-2 s-1
#     ### Assumption: Tr is only occurs in daytime, and the daytime is 10 hours.
#     Tr_fick = Tr_fick * w_mol_mass * daytime_second / 1000  # convert to mm d-1
#     return Tr_fick
# end

# # function GPP_Fick(params::plantHydraulics_PHS, forcing, land, helpers, ci, gs)
# #     @unpack_plantHydraulics_PHS params
# #     @unpack_nt begin
# #         (f_psurf_day) ⇐ forcing
# #         ambient_CO2 ⇐ land.states
# #         (z_zero, o_one) ⇐ land.constants
# #     end
# #     patm = f_psurf_day * 1000 # kPa to Pa
# #     ca = 1.0e-6 * ambient_CO2 * patm # ppm to Pa
# #     ### ci is provided by the Newton solver here.
# #     gamma_star = cal_gamma_star(params, forcing, land, helpers) # CO2 compensation point, Pa
# #     gpp_fick = gamma_star < ci < ca  ? gs * (ca - ci) : z_zero # mol C m-2 d-1
# #     gpp_fick = gpp_fick * c_mol_mass # convert to g C m-2 d-1
# #     return gpp_fick 
# # end

# # function cal_gs_canopy(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)

# #     @unpack_plantHydraulics_PHS params
# #     @unpack_nt begin
# #         (f_psurf_day, f_airT_day) ⇐ forcing
# #         z_zero ⇐ land.constants
# #     end

# #     ### Canopy resistance, s m-1
# #     rs_c = cal_r_sc(params, forcing, land, helpers, leaf_stress) # s m-1

# #     ### convert to m2 s umol-1 CO2 -- based on the ideal gas law
# #     patm = f_psurf_day # kPa
# #     temp = f_airT_day + deg_2_K # deg C
# #     Rgas = k_R / 1000 # from J mol-1 K-1 to MJ mol-1 K-1
# #     rs = rs_c * Rgas * temp / (patm * 1e6) # m2 s umol-1 C Pa-1. 1e6 is also used to convert kPa to Pa.

# #     ### Canopy conductance
# #     gs_c = rs_c == r_cs_max ? z_zero : 1 / rs # umolC m-2 s-1 Pa-1
# #     # convert to molC m-2 day-1
# #     gs_c = gs_c * day_second / 1e6 # molC m-2 d-1

# #     return gs_c, rs, rs_c
# # end

# # function cal_r_sc(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)

# #     @unpack_plantHydraulics_PHS params
# #     @unpack_nt begin
# #         (f_VPD_day, f_airT_day, f_SW) ⇐ forcing
# #         LAI ⇐ land.states
# #         tolerance ⇐ helpers.numbers
# #         (z_zero, o_one) ⇐ land.constants
# #     end

# #     ### leaf_stress is provided by the Newton solver here.

# #     _, _, _, _, _, _, r_cs_min, _ = get_pft_value(params, forcing, land, helpers)

# #     # radiation stress
# #     R_solar = f_SW * 1e6 / day_second # shortwave radiation, convert MJ m-2 d-1  to W m-2
# #     f = 0.55 * 2 * (R_solar / (day_second * 1e-6)) / (R_sc * LAI)
# #     f1_rad = (f + r_cs_min / r_cs_max) / (f + o_one)

# #     # Temperature stress
# #     T = f_airT_day # deg C
# #     f2_T = (Tmin < T && T < Tmax) ? o_one - k_Temp * (Topt - T) ^ 2 : z_zero

# #     # VPD stress
# #     VPD = at_least_zero(f_VPD_day) # kPa
# #     f3_VPD = VPD > 4 ? z_zero : o_one - k_VPD * VPD

# #     # water stress -- based on PSi
# #     f4_water = leaf_stress

# #     # efficient LAI -- to consider clumping  effect
# #     F_s = 0.3 * LAI + 1.2

# #     # canopy resistance, s m-1
# #     denominator = LAI * f1_rad * f2_T * f3_VPD * f4_water
# #     r_sc = denominator == z_zero ? r_cs_max : r_cs_min * F_s / denominator
# #     r_sc = clamp.(r_sc, r_cs_min, r_cs_max)

# #     return r_sc
# # end

# # function get_pft_value(params::plantHydraulics_PHS, forcing, land, helpers)

# #     @unpack_plantHydraulics_PHS params
# #     @unpack_nt PFT ⇐ land.PFT

# #     PFT = Int(PFT)

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

# purpose(::Type{plantHydraulics_PHS}) = "Three-node, damped-Newton plant hydraulics with one-way, water-limited root uptake."

# @doc """

# $(getModelDocString(plantHydraulics_PHS))

# ---

# # Extended help

# Solves leaf, stem, and root water potentials simultaneously from three flux
# continuity equations. Soil-to-root fluxes are nonnegative and bounded by
# plant-available water, so roots can extract water but cannot supply it to soil.

# The previous time-step water potentials are used as the Newton initial guess.
# The solver reports convergence, iteration count, and the maximum flux residual.

# *Versions*
#  - 1.0 on 21.09.2026 [jzhou]
# """
# plantHydraulics_PHS
