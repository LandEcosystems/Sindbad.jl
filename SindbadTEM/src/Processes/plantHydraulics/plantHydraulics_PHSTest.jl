# export plantHydraulics_PHS

# using Roots

# _not_Inf_NaN(value, fallback) = isfinite(value) ? value : oftype(value, fallback)

# function _pos_Inf_not_NaN(value)
#     if isfinite(value)
#         return value
#     elseif isnan(value)
#         return zero(value)
#     end
#     return copysign(floatmax(typeof(value)), value)
# end

# _non_negative_Finite(value) = max(_pos_Inf_not_NaN(value), zero(value))

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

# @inline _field_svector(layers, ::Val{K}, ::Val{N}, ::Type{T}) where {K,N,T} = SVector{N,T}(ntuple(i -> T(layers[i][K]), Val(N)))

# struct RootPotentialLinear{T}
#     mode::Int  # 0: all soil-root conductances negligible, 1: layer weighted solution, 2: no valid layer
#     A::T
#     B::T
# end
# RootPotentialLinear(mode::Int, A, B) = RootPotentialLinear(mode, promote(A, B)...)

# #! format: off
# @bounds @describe @units @timescale @with_kw struct plantHydraulics_PHS{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36,T37,T38,T39,T40,T41,T42,T43,T44,T45,T46,T47,T48,T49,T50,T51,T52,T53,T54,T55,T56,T57,T58,T59,T60,T61,T62,T63,T64,T65,T66,T67,T68,T69,T70,T71,T72,T73,T74} <: plantHydraulics
#     # root params
#     root_radius::T1 = 1.5e-3 | (1.0e-5, 1.0e-2) | "fine-root radius used to infer root spacing from SINDBAD root surface area" | "m" | ""
#     biomass_to_carbon::T2 = 0.488 | (0.1, 1.0) | "root carbon per unit root dry biomass" | "gC gDM-1" | ""
#     root_density::T3 = 2.5e5 | (1.0e3, 1.0e6) | "root tissue dry-matter density" | "gDM m-3" | ""
#     root_lateral_length::T4 = 0.25 | (1.0e-3, 10.0) | "average coarse-root lateral length" | "m" | ""
#     stem_to_leaf_area_ratio::T5 = 0.1 | (0.01, 0.9) | "stem area index to leaf area index ratio" | "" | ""

#     # plant hydraulic traits
#     p50_leaf::T6 = -67.67 | (-500, -10.0) | "stem-to-leaf water potential at 50 percent conductivity loss" | "m" | ""
#     p50_stem::T7 = -342.51 | (-1500, -10.0) | "root-to-stem water potential at 50 percent conductivity loss" | "m" | ""
#     p50_root::T8 = -30.0 | (-1000, -10.0) | "soil-root water potential at 50 percent conductivity loss" | "m" | ""

#     # plant hydraulic vulnerability-curve factors
#     shape_factor_leaf::T9 = 1.98 | (0.5, 5.0) | "leaf PHS vulnerability-curve shape factor" | "MPa-1" | ""
#     shape_factor_stem::T10 = 1.98 | (0.5, 5.0) | "stem PHS vulnerability-curve shape factor" | "MPa-1" | ""
#     shape_factor_root::T11 = 0.8 | (0.5, 5.0) | "root PHS vulnerability-curve shape factor" | "MPa-1" | ""

#     # hydraulic conductance traits
#     k_root_max::T12 = 1.73e-4 | (8.64e-6, 8.64e-2) | "maximum root hydraulic conductivity" | "m d-1" | ""
#     k_stem_max::T13 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum stem hydraulic conductivity" | "m d-1" | ""
#     k_leaf_max::T14 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum leaf hydraulic conductance" | "d-1" | ""

#     # photosynthesis parameters
#     Jmax25_Vcmax25_ratio::T15 = 1.67 | (1.5, 2.1) | "The ratio between the maximum electron transport rate, normalised to 25 ◦C to Vcmax25" | "dimensionless" | ""
#     Vcmax25::T16 = 5e-5 | (1e-5, 1.5e-4) | "Maximum rate of carboxylation, normalised to 25 ◦C. Ratio between J/V is about 1.5 to 2.1." | "molC m-2 s-1" | ""

#     # dark-respiration
#     rate_dark::T17 = 0.01 | (0.005, 0.05) | "dark-respiration rate per unit carboxylation capacity" | "" | ""
#     k_Nitrogen::T18 = 0.2 | (0.1, 0.4) | "decay coefficient for nitrogen on dark respiration" | "" | ""

#     # photorespiratory compensation point  parameters
#     ha::T19 = 37830.0 | (1e-2, 1e7) | "Activation energy for gamma star" | "J mol-1" | ""
#     gs25_0::T20 = 4.332 | (4.0, 5.0) | "Photorespiratory compensation point" | "Pa" | ""

#     # Michaelis-Menten constants
#     k_co::T21 = 209476 | (1e-2, 1e7) | "Michaelis–Menten coefficient params" | "" | ""
#     dhac::T22 = 79430 | (1e-2, 1e7) | "Activation energy for Kc" | "J mol-1" | ""
#     dhao::T23 = 36380 | (1e-2, 1e7) | "Activation energy for Ko" | "J mol-1" | ""
#     kc25::T24 = 39.97 | (1e-2, 1e7) | "Michaelis-Menten constant for CO2 at 25C" | "Pa" | ""
#     ko25::T25 = 27480 | (1e-2, 1e7) | "Michaelis-Menten constant for O2 at 25C" | "Pa" | ""
#     Ed::T26 = 200000 | (1e-2, 1e7) | "energy of de-activation" | "J mol-1" | ""

#     # Medlyn gs model parameters
#     g0::T27 = 0.001 | (-0.05, 0.05) | "the minimum stomatal conductance, ranges are refer to Medlyn paper" | "mol m-2 s-1" | ""
#     g1::T28 = 3.0 | (1, 12.0) | "stomatal conductance parameter, ranges are refer to Medlyn paper" | "kPa^0.5" | ""
    
#     # constants
#     CL::T29 = 0.125 | (0.1, 0.8) | "maximum quantum yield of photosystem II in light-adapted leaves, for PAR to Iabs, refer to P model" | "" | ""
#     k_R::T30 = 8.3145 | (8, 9) | "universal gas constant" | "J mol-1 K-1" | ""
#     diffusivity_ratio::T31 = 1.6 | (-Inf, Inf) | "Ratio of the molecular diffusivities for water vapor and CO2" | "" | ""
#     k_Po::T32 = 101325.0 | (1, 1e7) | "one standard ATM" | "Pa" | ""
#     tk_ref::T33 = 298.15 | (298, 299) | "25 deg C in unit of K" | "" | ""
#     par_ppfd::T34 = 4.57 | (0, 5) | "PAR to PPFD conversion factor, from W/m2 to umol/m2/s" | "" | ""
#     Vw::T35 = 1.8e-5 | (1e-6, 1e-4) | "molar volume of water" | "m3 mol-1" | ""
#     epar::T36      = 2.1739e5 | (1e5, 3e5)    | "Energy content of PAR" | "J mol⁻¹" | ""

#     # soil evaporation params
#     c_p::T37 = 1.013 * 1e-03 | (-Inf, Inf) | "specific heat at constant pressure" | "MJ kg-1 K-1" | ""
#     ρ::T38 = 1.293 | (-Inf, Inf) | "density of air" | "kg m-3" | ""
#     k_von::T39 = 0.41 | (-Inf, Inf) | "von Karman's constant" | "" | ""
#     zow::T40 = 0.005 | (-Inf, Inf) | "roughness length" | "m" | ""
#     Fw::T41 = 5000 | (-Inf, Inf) | "the fetch at weather station" | "m" | ""
#     zw::T42 = 10.0 | (2, 100) | "height of tower" | "m" | ""
#     z_0g::T43 = 0.020 | (0.005, 0.2) | "roughness length of substrate ground" | "m" | ""
#     r_ss_min::T44 = 50 | (1e-2, 1e7) | "minimum soil resistance" | "s m-1" | ""
#     r_ss_max::T45 = 5000 | (1e-2, 1e7) | "maximum soil resistance" | "s m-1" | ""

#     # Iteration parameters
#     convergence_water_potential::T46 = 1e-3 | (1e-10, 1e0) | "0.001" | "" | ""
#     STEMMUS_max_iterations::T47 = 50 | (10, 1000) | "maximum number of iterations for STEMMUS" | "" | ""
#     convergence_ci::T48 = 1e-3 | (0.0, 1e0) | "tolerance of ci" | "Pa" | ""
#     ci_residual_tolerance::T49 = 1.0e-10 | (0.0, 1e0) | "tolerance of gpp difference" | "molC m-2 s-1" | ""
#     Ci_max_iterations::T50 = 50 | (10, 1000) | "maximum number of iterations for leaf intercellular CO2 concentration" | "" | ""
#     convergence_fw::T51 = 1e-3 | (1e-10, 1e0) | "0.001" | "" | ""
#     fw_max_iterations::T52 = 50 | (10, 1000) | "maximum number of iterations for leaf intercellular CO2 concentration" | "" | ""

#     # leaf energy balance (refer to SCOPE heatfluxes.m / ebal.m)
#     energy_balance_switch::T53 = 1.0 | (0.0, 1.0) | "solve leaf temperature from the energy balance (>0.5) or use air temperature + delta_T (<=0.5)" | "" | ""
#     leaf_width::T54 = 0.05 | (0.001, 0.5) | "characteristic leaf width for the leaf boundary layer" | "m" | ""
#     leaf_emissivity::T55 = 0.98 | (0.9, 1.0) | "leaf thermal emissivity" | "" | ""
#     sigma_SB::T56 = 5.670374e-8 | (5e-8, 6e-8) | "Stefan-Boltzmann constant" | "W m-2 K-4" | ""
#     Tleaf_max_iterations::T57 = 50 | (1, 100) | "maximum number of iterations between leaf temperature and photosynthesis-hydraulics" | "" | ""
#     convergence_Tleaf::T58 = 1e-2 | (1e-10, 1e0) | "tolerance of leaf temperature" | "K" | ""
#     Tleaf_damping::T59 = 0.9 | (0.1, 1.0) | "damping of the first leaf temperature update, as Wc in SCOPE ebal.m" | "" | ""
#     Tleaf_ebal_iterations::T60 = 20 | (1, 100) | "maximum number of Newton iterations of the leaf energy balance" | "" | ""

#     # boundary conditions
#     minimum_conductance::T61 = 1.0e-11 | (0.0, 1.0) | "numerical floor for hydraulic conductance" | "m d-1" | ""
#     minimum_lai::T62 = 1.0e-2 | (0.0, 1.0) | "minimum LAI" | "m2 m-2" | ""
#     minimum_water_stress::T63 = 1.0e-2 | (1.0e-6, 10.0) | "minimum water stress" | "" | ""

#     # unit conversions
#     mm_2_m::T64 = 1.0e-3 | (0.0, 1e7) | "unit conversion from mm to m" | "" | ""
#     m_to_mm::T65 = 1.0e3 | (0.0, 1e7) | "unit conversion from m to mm" | "" | ""
#     m_to_MPa::T66 = 0.00980665 | (0.0, 1e7) | "unit conversion of water potential from m to MPa" | "" | ""
#     deg_2_K::T67 = 273.15 | (1e-2, 1e7) | "convert deg C to K" | "" | ""
#     c_mol_mass::T68 = 12.0 | (1e-2, 1e7) | "molecular mass of carbon" | "g/mol" | ""
#     w_mol_mass::T69 = 18.0 | (1e-2, 1e7) | "molecular mass of water" | "g/mol" | ""
#     day_second::T70 = 86400 | (1e-2, 1e7) | "seconds in a day" | "s" | ""
#     con_1e6::T71 = 1e6 | (1e0, 1e7) | "1,000,000" | "" | ""
#     con_1e3::T72 = 1e3 | (1e0, 1e7) | "1,000" | "" | ""
#     con_1e_6::T73 = 1e-6 | (1e-10, 1e0) | "0.000001" | "" | ""
#     con_1e_3::T74 = 1e-3 | (1e-10, 1e0) | "0.001" | "" | ""

# end
# #! format: on

# function define(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_alpha_van_Genuchten, f_eta_van_Genuchten) ⇐ forcing
#         soilW ⇐ land.pools
#         (z_zero, o_one) ⇐ land.constants
#         plant_form ⇐ land.states
#     end

#     if plant_form in (:tree, :shrub)
#         fine_root_fraction = 0.141
#     elseif plant_form == :herb
#         fine_root_fraction = 0.885
#     else
#         fine_root_fraction = 0.15
#     end

#     phs_root_water_uptake = zero(soilW)

#     Κ_soil_root = zero(soilW)
#     Κ_soil = zero(soilW)
#     Κ_root = zero(soilW)
#     Κ_soil_unsat = zero(soilW)

#     RAI = zero(soilW)
#     fraction_root = zero(soilW) # fraction of root in each soil layer, unitless
#     β_root = zero(soilW) # soil water stress factor (0-1)

#     D_soil_inv_mm = zero(soilW)
#     D_soil_m = zero(soilW)
#     D_soil_cum_m = zero(soilW)
#     D_root_deno = zero(soilW)

#     θ_soil = zero(soilW) # in m3 m-3
#     θ_res = zero(soilW) # in m3 m-3
#     θ_sat = zero(soilW) # in m3 m-3
#     soil_saturation = zero(soilW) # in dimensionless

#     ψ_leaf_prev = p50_leaf # intial leaf water potential, m

#     ci_prev = gs_max = z_zero
#     root_total_conductance = root_conductance_weighted_head = root_total_capacity = highest_rooted_soil_head = z_zero
#     leaf_VPD = leaf_RH = leaf_actual_pressure = z_zero
#     leaf_saturated_pressure = air_saturated_pressure = air_actual_pressure = z_zero
#     temp_leaf_degC = temp_leaf_K = z_zero
#     leaf_temp_diff = z_zero # leaf temperature minus air temperature, deg C
#     temp_leaf_balance = z_zero
#     phs_transpiration_max = z_zero

#     # don't consider the soil depth gravity potential, only the matric potential, unit: m.
#     ψ_soil = zero(soilW)
#     ψ_soil_matric = zero(soilW)

#     ### VG soil hydraulic property
#     nvg = f_eta_van_Genuchten
#     avg = f_alpha_van_Genuchten
#     mvg = o_one - o_one / nvg

#     @pack_nt begin
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.diagnostics
#         (θ_soil, θ_res, θ_sat, soil_saturation) ⇒ land.diagnostics
#         (ψ_leaf_prev, ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
#         (root_total_conductance, root_conductance_weighted_head, root_total_capacity, highest_rooted_soil_head) ⇒ land.diagnostics
#         (RAI, fine_root_fraction, fraction_root, β_root) ⇒ land.diagnostics
#         (ci_prev, gs_max) ⇒ land.diagnostics
#         (leaf_VPD, leaf_RH, leaf_actual_pressure) ⇒ land.diagnostics
#         (leaf_saturated_pressure, air_saturated_pressure, air_actual_pressure) ⇒ land.diagnostics
#         (temp_leaf_degC, temp_leaf_K) ⇒ land.diagnostics
#         (leaf_temp_diff, temp_leaf_balance) ⇒ land.diagnostics
#         phs_transpiration_max ⇒ land.diagnostics
#         phs_root_water_uptake ⇒ land.fluxes
#         (nvg, avg, mvg) ⇒ land.diagnostics
#     end
#     return land
# end

# function precompute(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (soil_layer_thickness) ⇐ land.properties
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇐ land.diagnostics
#         (z_zero, o_one) ⇐ land.constants
#     end
#     depth_from_top_m = z_zero
#     for sl in eachindex(soil_layer_thickness)
#         thickness = soil_layer_thickness[sl]
#         thickness_m = thickness * mm_2_m
#         cumulative_depth_m = depth_from_top_m + thickness_m / 2 # middle point for gravity potential.
#         root_depth_denominator = root_lateral_length + cumulative_depth_m
#         @rep_elem inv(thickness) ⇒ (D_soil_inv_mm, sl, :soilW)
#         @rep_elem thickness_m ⇒ (D_soil_m, sl, :soilW)
#         @rep_elem cumulative_depth_m ⇒ (D_soil_cum_m, sl, :soilW)
#         @rep_elem root_depth_denominator ⇒ (D_root_deno, sl, :soilW)
#         depth_from_top_m += thickness_m
#     end
#     @pack_nt begin
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.diagnostics
#     end
#     return land
# end

# function compute(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_airT_day ⇐ forcing
#         leaf_temp_diff ⇐ land.diagnostics
#     end

#     land = cal_soil_hydrology(params, forcing, land, helpers)

#     ### initial guess of leaf temperature: leaf-air temperature difference of the previous time step (delta_T at the first step).
#     temp_leaf_degC = f_airT_day + leaf_temp_diff
#     land_phs = cal_PHS_Farquhar(params, forcing, land, helpers, temp_leaf_degC)

#     ### solve the leaf temperature (energy balance) together with photosynthesis, stomatal conductance and PHS.
#     ### The first update is a damped fixed-point step, later ones are secant steps on the residual (temp_leaf_balance - temp_leaf_degC).
#     if energy_balance_switch > 0.5
#         temp_prev = residual_prev = temp_leaf_degC
#         for iter in 1:Tleaf_max_iterations
#             land_phs = cal_leaf_energy_balance(params, forcing, land_phs, helpers)
#             residual = land_phs.diagnostics.temp_leaf_balance - temp_leaf_degC
#             abs(residual) < convergence_Tleaf && break

#             use_secant = iter > 1 && abs(residual) < abs(residual_prev) && abs(residual - residual_prev) > 1e-4
#             step = use_secant ? -residual * (temp_leaf_degC - temp_prev) / (residual - residual_prev) : Tleaf_damping * residual
#             temp_prev, residual_prev = temp_leaf_degC, residual
#             temp_leaf_degC += clamp(step, -10, 10)

#             ### warm start of the leaf water potential with the previous solution.
#             ψ_leaf_prev = land_phs.diagnostics.ψ_leaf_prev
#             @pack_nt ψ_leaf_prev ⇒ land.diagnostics
#             land_phs = cal_PHS_Farquhar(params, forcing, land, helpers, temp_leaf_degC)
#         end
#     end

#     land = cal_PHS_root_uptake(params, forcing, land_phs, helpers)
#     leaf_temp_diff = temp_leaf_degC - f_airT_day
#     @pack_nt leaf_temp_diff ⇒ land.diagnostics
#     return land
# end

# function _root_potential_linear(params::plantHydraulics_PHS, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     @unpack_plantHydraulics_PHS params
#     z_zero = zero(eltype(ψ_soil))
#     max_Ω = oftype(z_zero, 1e5) # d m-1, i.e, root absorb 0.01 mm H2O per day, which is too slow.

#     if all(k -> abs(k) <= minimum_conductance, Κ_soil_root)
#         return RootPotentialLinear(0, sum(ψ_soil) / length(ψ_soil), z_zero)
#     end

#     sum_w = z_zero
#     sum_a = z_zero
#     sum_b = z_zero
#     for sl in eachindex(ψ_soil)
#         if root_over[sl] > z_zero
#             Ω_sum = inv(Κ_soil[sl]) + inv(Κ_root[sl])
#             if !(root_surface_area[sl] == z_zero || Ω_sum > max_Ω || ψ_soil[sl] <= -5000)
#                 w = fraction_root[sl]
#                 sum_w += w
#                 sum_a += ψ_soil[sl] * w
#                 sum_b += Ω_sum * w / root_surface_area[sl] * w
#             end
#         end
#     end
#     if iszero(sum_w)
#         return RootPotentialLinear(2, z_zero, z_zero)
#     end
#     return RootPotentialLinear(1, sum_a / sum_w, sum_b / sum_w)
# end

# @inline function _root_water_potential(params::plantHydraulics_PHS, rl::RootPotentialLinear, Q)
#     @unpack_plantHydraulics_PHS params
#     z_zero = zero(rl.A)
#     if rl.mode == 0
#         return rl.A
#     elseif rl.mode == 2
#         return oftype(z_zero, -con_1e3)
#     end
#     psi_root = rl.A - rl.B * Q
#     if !isfinite(psi_root)
#         return oftype(z_zero, -con_1e3)
#     end
#     psi_root = max(psi_root, -con_1e3) # -10MPa to m = -1019.368
#     return min(z_zero, psi_root)
# end

# @inline function _stem_water_potential(params::plantHydraulics_PHS, H_canopy, LAI, psi_root, Q)
#     @unpack_plantHydraulics_PHS params
#     beta_stem_root = cal_vulnerability_curve(params, psi_root, p50_stem, shape_factor_stem)
#     SAI = stem_to_leaf_area_ratio * LAI
#     if LAI > minimum_lai && H_canopy > zero(H_canopy) && beta_stem_root > minimum_water_stress
#         stem_conductance = k_stem_max * beta_stem_root / H_canopy
#         return psi_root - H_canopy - Q / SAI / stem_conductance
#     end
#     return psi_root - H_canopy
# end

# @inline function _leaf_water_potential(params::plantHydraulics_PHS, LAI, psi_stem, Q)
#     @unpack_plantHydraulics_PHS params
#     beta_leaf_stem = cal_vulnerability_curve(params, psi_stem, p50_leaf, shape_factor_leaf)
#     if LAI > minimum_lai && beta_leaf_stem > minimum_water_stress
#         leaf_conductance = k_leaf_max * beta_leaf_stem
#         return psi_stem - Q / LAI / leaf_conductance
#     end
#     return psi_stem
# end

# @inline function _plant_hydraulic(params::plantHydraulics_PHS, rl, H_canopy, LAI, Q)
#     psi_root = _root_water_potential(params, rl, Q)
#     psi_stem = _stem_water_potential(params, H_canopy, LAI, psi_root, Q)
#     psi_leaf = _leaf_water_potential(params, LAI, psi_stem, Q)
#     return psi_root, psi_stem, psi_leaf
# end

# # root water potential in each layer, only needed once for the final solution.
# function _root_layer_potential(params::plantHydraulics_PHS, rl::RootPotentialLinear, Q, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     @unpack_plantHydraulics_PHS params
#     z_zero = zero(eltype(ψ_soil))
#     if rl.mode == 0
#         return ψ_soil
#     end
#     psi_root = rl.mode == 2 ? oftype(z_zero, NaN) : rl.A - rl.B * Q
#     if !isfinite(psi_root)
#         return SVector{length(ψ_soil),typeof(z_zero)}(ntuple(_ -> oftype(z_zero, -con_1e3), Val(length(ψ_soil))))
#     end
#     max_Ω = oftype(z_zero, 1e5)
#     vals = ntuple(Val(length(ψ_soil))) do sl
#         valid = root_over[sl] > z_zero
#         Ω_sum = inv(Κ_soil[sl]) + inv(Κ_root[sl])
#         if valid && !(root_surface_area[sl] == z_zero || Ω_sum > max_Ω || ψ_soil[sl] <= -5000)
#             ψ_soil[sl] - Ω_sum * (Q * fraction_root[sl]) / root_surface_area[sl]
#         else
#             z_zero
#         end
#     end
#     return SVector{length(ψ_soil),typeof(z_zero)}(vals)
# end

# @inline function _leaf_humidity_status(params::plantHydraulics_PHS, leaf_saturated_pressure, air_actual_pressure, temp_leaf_K, psi_leaf)
#     @unpack_plantHydraulics_PHS params
#     psi_leaf_Pa = psi_leaf * m_to_MPa * con_1e6 # convert m to MPa, and then to Pa, because J = Pa m3
#     kelvin_exponent = psi_leaf_Pa * Vw / (k_R * temp_leaf_K)
#     leaf_RH = clamp_zero_one(exp(kelvin_exponent))
#     leaf_actual_pressure = leaf_saturated_pressure * leaf_RH
#     leaf_VPD = at_least_zero(leaf_actual_pressure - air_actual_pressure)
#     return leaf_VPD, leaf_RH, leaf_actual_pressure
# end

# @inline function _gs_Medlyn(params::plantHydraulics_PHS, net_photosynthesis, ca, leaf_VPD)
#     @unpack_plantHydraulics_PHS params
#     if !isfinite(leaf_VPD) || leaf_VPD == zero(leaf_VPD)
#         return zero(leaf_VPD)
#     end
#     gs = g0 + (one(leaf_VPD) + g1 / sqrt(leaf_VPD)) * (net_photosynthesis / ca)
#     return at_least_zero(gs)
# end

# # Farquhar photosynthesis + Medlyn stomatal conductance on plain scalars; `fq` holds the per-day leaf constants.
# @inline function _GPP_Farquhar(params::plantHydraulics_PHS, fq, leaf_stress, ci, leaf_VPD)
#     @unpack_plantHydraulics_PHS params
#     co2_numerator = at_least_zero(ci - fq.gamma_star)
#     Vc_actual = fq.Vcmax * leaf_stress
#     Ac_mol_m2_s = Vc_actual * co2_numerator / (ci + fq.KM)
#     Aj_mol_m2_s = fq.J_actual * co2_numerator / (4 * ci + 8 * fq.gamma_star)
#     gross_photosynthesis_mol = min(Ac_mol_m2_s, Aj_mol_m2_s)
#     gpp_farquhar = gross_photosynthesis_mol * fq.efficient_lai * c_mol_mass * fq.f_daytime_seconds
#     net_photosynthesis = gpp_farquhar - fq.dark_respiration
#     net_photosynthesis_mol = gross_photosynthesis_mol - fq.dark_respiration_mol
#     gs = _gs_Medlyn(params, net_photosynthesis_mol, fq.ca_mol, leaf_VPD)
#     return gpp_farquhar, Ac_mol_m2_s, Aj_mol_m2_s, net_photosynthesis, net_photosynthesis_mol, Vc_actual, gs
# end

# @inline function _ci_residual(params::plantHydraulics_PHS, fq, leaf_stress, ci, leaf_VPD)
#     _, _, _, _, net_photosynthesis_mol, _, gs = _GPP_Farquhar(params, fq, leaf_stress, ci, leaf_VPD)
#     return oftype(ci, gs * (fq.ca_Pa - ci) / fq.patm - net_photosynthesis_mol)
# end

# # Brent's method on a bracket [a, b] with f(a) * f(b) <= 0.
# function _brent_root(f::F, a, b, fa, fb, xatol, atol, maxiters) where {F}
#     c, fc = a, fa
#     d = e = b - a
#     for _ in 1:maxiters
#         if (fb > 0 && fc > 0) || (fb < 0 && fc < 0)
#             c, fc = a, fa
#             d = e = b - a
#         end
#         if abs(fc) < abs(fb)
#             a, b, c = b, c, b
#             fa, fb, fc = fb, fc, fb
#         end
#         tol = 2 * eps(abs(b)) + xatol / 2
#         xm = (c - b) / 2
#         if abs(xm) <= tol || abs(fb) <= atol
#             return b
#         end
#         if abs(e) >= tol && abs(fa) > abs(fb)
#             s = fb / fa
#             if a == c
#                 p = 2 * xm * s
#                 q = 1 - s
#             else
#                 q = fa / fc
#                 r = fb / fc
#                 p = s * (2 * xm * q * (q - r) - (b - a) * (r - 1))
#                 q = (q - 1) * (r - 1) * (s - 1)
#             end
#             q = p > 0 ? -q : q
#             p = abs(p)
#             if 2 * p < min(3 * xm * q - abs(tol * q), abs(e * q))
#                 e = d
#                 d = p / q
#             else
#                 d = xm
#                 e = d
#             end
#         else
#             d = xm
#             e = d
#         end
#         a, fa = b, fb
#         b += abs(d) > tol ? d : copysign(tol, xm)
#         fb = f(b)
#     end
#     return b
# end

# @inline function _ci_analytic(params::plantHydraulics_PHS, fq, leaf_stress, leaf_VPD, residual)
#     @unpack_plantHydraulics_PHS params
#     T = typeof(fq.ca_Pa)
#     (isfinite(leaf_VPD) && leaf_VPD > 0) || return T(NaN)
#     m = 1 + Float64(g1) / sqrt(Float64(leaf_VPD))
#     P, ca, cm = Float64(fq.patm), Float64(fq.ca_Pa), Float64(fq.ca_mol)
#     Γ, Rd, g0d = Float64(fq.gamma_star), Float64(fq.dark_respiration_mol), Float64(g0)
#     c0 = P - m * ca / cm
#     c1 = m / cm
#     best_ci, best_res = T(NaN), T(Inf)
#     for (V, K) in ((Float64(fq.Vcmax * leaf_stress), Float64(fq.KM)), (Float64(fq.J_actual) / 4, 2Γ))
#         a1 = V - Rd
#         b1 = -(V * Γ + Rd * K)
#         qa = a1 * c1 + g0d
#         qb = a1 * c0 + b1 * c1 - g0d * (ca - K)
#         qc = b1 * c0 - g0d * ca * K
#         disc = qb * qb - 4 * qa * qc
#         (disc >= 0 && qa != 0) || continue
#         q = -(qb + (qb >= 0 ? sqrt(disc) : -sqrt(disc))) / 2
#         for r in (q / qa, q == 0 ? NaN : qc / q)
#             if isfinite(r) && Γ <= r <= ca
#                 res = abs(residual(T(r)))
#                 if res < best_res
#                     best_ci, best_res = T(r), res
#                 end
#             end
#         end
#     end
#     return best_res < 1e-9 ? best_ci : T(NaN)
# end

# function _solve_ci_Pa(params::plantHydraulics_PHS, fq, leaf_stress, ci_prev, leaf_VPD)
#     @unpack_plantHydraulics_PHS params
#     ci_upper = fq.ca_Pa
#     ci_lower = fq.gamma_star

#     # Medlyn equation 13. 1. Medlyn, B. E. et al. Reconciling the optimal and empirical approaches to modelling stomatal conductance. Global Change Biology 17, 2134–2144 (2011).
#     if iszero(g0)
#         best_ci = fq.ca_Pa * (1 - diffusivity_ratio * sqrt(leaf_VPD) / (g1 + sqrt(leaf_VPD)))
#         return clamp(best_ci, fq.gamma_star, fq.ca_Pa)
#     end

#     residual = ci -> _ci_residual(params, fq, leaf_stress, ci, leaf_VPD)

#     ci_analytic = _ci_analytic(params, fq, leaf_stress, leaf_VPD, residual)
#     isnan(ci_analytic) || return ci_analytic

#     ϵ_lower = residual(ci_lower)
#     ϵ_upper = residual(ci_upper)

#     if abs(ϵ_lower) < ci_residual_tolerance
#         return ci_lower
#     elseif abs(ϵ_upper) < ci_residual_tolerance
#         return ci_upper
#     elseif ϵ_lower * ϵ_upper <= 0
#         return _brent_root(residual, ci_lower, ci_upper, ϵ_lower, ϵ_upper, convergence_ci, ci_residual_tolerance, Int(Ci_max_iterations))
#     end
#     return oftype(ci_lower, ci_prev)
# end

# @inline function _transpiration_Fick(params::plantHydraulics_PHS, f_daytime_seconds, patm, gs, leaf_VPD)
#     @unpack_plantHydraulics_PHS params
#     water_mole_fraction = isfinite(leaf_VPD) ? leaf_VPD * con_1e3 / patm : zero(leaf_VPD)
#     Tr_fick = diffusivity_ratio * gs * water_mole_fraction # molH2O m-2 s-1
#     return Tr_fick * w_mol_mass * f_daytime_seconds / con_1e3 # mm d-1
# end

# # damped fixed-point iteration of the leaf water potential for a given maximum transpiration.
# @inline function _solve_PHS(params::plantHydraulics_PHS, rl, H_canopy, LAI, Tr_max, ψ_leaf_act)
#     @unpack_plantHydraulics_PHS params
#     ψ_leaf_tmp = ψ_leaf_act
#     ψ_root = ψ_stem = ψ_leaf_tmp
#     transpiration = zero(Tr_max)
#     for _ in 1:STEMMUS_max_iterations
#         leaf_stress_tmp = cal_vulnerability_curve(params, ψ_leaf_tmp, p50_leaf, shape_factor_leaf)
#         transpiration = Tr_max * leaf_stress_tmp # m d-1
#         ψ_root, ψ_stem, ψ_leaf_tmp = _plant_hydraulic(params, rl, H_canopy, LAI, transpiration)
#         if abs(ψ_leaf_act - ψ_leaf_tmp) < convergence_water_potential
#             ψ_leaf_act = (ψ_leaf_act + ψ_leaf_tmp) * 0.5
#             break
#         end
#         ψ_leaf_act = (ψ_leaf_act + ψ_leaf_tmp) * 0.5
#     end
#     return ψ_leaf_act, ψ_root, ψ_stem, transpiration
# end

# function cal_PHS_Farquhar(params::plantHydraulics_PHS, forcing, land, helpers, temp_leaf_degC)
#     ### for farquhar and medlyn model, and to avoid duplicate calculations to increase model speed.
#     land = cal_Farquhar_info(params, forcing, land, helpers, temp_leaf_degC)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_daytime_seconds, f_canopy_height) ⇐ forcing
#         LAI ⇐ land.states
#         ψ_leaf_prev ⇐ land.diagnostics
#         root_over ⇐ land.rootWaterEfficiency
#         (z_zero, o_one) ⇐ land.constants
#         (ca_Pa, ca_mol, gamma_star, efficient_lai, patm) ⇐ land.diagnostics
#         (leaf_saturated_VPD, temp_leaf_degC, temp_leaf_K) ⇐ land.diagnostics
#         (leaf_saturated_pressure, air_actual_pressure) ⇐ land.diagnostics
#         (KM, J_actual, Vcmax, dark_respiration, dark_respiration_mol) ⇐ land.diagnostics
#         (Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
#     end

#     fq = (; Vcmax, KM, J_actual, gamma_star, ca_mol, ca_Pa, patm, efficient_lai, dark_respiration, dark_respiration_mol, f_daytime_seconds)
#     rl = _root_potential_linear(params, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     H_canopy = f_canopy_height

#     ci_prev = 0.7 * ca_Pa

#     plant_activity = cal_plant_activity(params, forcing, land, helpers)

#     if !plant_activity
#         """ deactive plant activity """
#         transpiration = Tr_max = z_zero
#         ψ_root, ψ_stem, ψ_leaf_act = _plant_hydraulic(params, rl, H_canopy, LAI, transpiration)
#         β_leaf_tmp = cal_vulnerability_curve(params, ψ_leaf_act, p50_leaf, shape_factor_leaf)
#         leaf_VPD, leaf_RH, leaf_actual_pressure = _leaf_humidity_status(params, leaf_saturated_pressure, air_actual_pressure, temp_leaf_K, ψ_leaf_act)
#         ci_unsat = ca_Pa
#         gs_max = gs_unsat = z_zero
#     else
#         """ active plant activity """
#         β_leaf_zero = -o_one
#         β_leaf_tmp = o_one

#         ### STEP 1 : ci under saturated state. >> obtain gsmax, Emax
#         ci_saturated = _solve_ci_Pa(params, fq, β_leaf_tmp, ci_prev, leaf_saturated_VPD)
#         _, _, _, _, _, _, gs_max = _GPP_Farquhar(params, fq, β_leaf_tmp, ci_saturated, leaf_saturated_VPD) # leaf scale gs.
#         Tr_max = _transpiration_Fick(params, f_daytime_seconds, patm, gs_max, leaf_saturated_VPD) * mm_2_m * efficient_lai # canopy scale for PHS, m d-1.

#         ### STEP 2 : solve the PHS.
#         ψ_leaf_act, ψ_root, ψ_stem, transpiration = _solve_PHS(params, rl, H_canopy, LAI, Tr_max, ψ_leaf_prev)
#         β_leaf_tmp = cal_vulnerability_curve(params, ψ_leaf_act, p50_leaf, shape_factor_leaf)

#         leaf_VPD, leaf_RH, leaf_actual_pressure = _leaf_humidity_status(params, leaf_saturated_pressure, air_actual_pressure, temp_leaf_K, ψ_leaf_act)

#         ### STEP 3 : solve ci and gs under current water stress.
#         ci_unsat = _solve_ci_Pa(params, fq, β_leaf_tmp, ci_saturated, leaf_VPD)
#         _, _, _, _, _, _, gs_unsat = _GPP_Farquhar(params, fq, β_leaf_tmp, ci_unsat, leaf_VPD)

#         for _ in 1:fw_max_iterations
#             ### STEP 4 : convergent the water stress.
#             delta_β_leaf = β_leaf_zero - β_leaf_tmp
#             β_leaf_zero = β_leaf_tmp # update beta_leaf_zero for next iteration.
#             if abs(delta_β_leaf) < convergence_fw
#                 break
#             end

#             ### if water stress from two schemes are not convergent, update gsmax, and then re-convergence the PHS and ci.
#             if β_leaf_tmp > minimum_water_stress
#                 gs_max = gs_unsat / β_leaf_tmp
#             end

#             Tr_max = _transpiration_Fick(params, f_daytime_seconds, patm, gs_max, leaf_saturated_VPD) * mm_2_m * efficient_lai # canopy scale for PHS, m d-1.

#             ### solve the PHS
#             ψ_leaf_act, ψ_root, ψ_stem, transpiration = _solve_PHS(params, rl, H_canopy, LAI, Tr_max, ψ_leaf_act)
#             leaf_VPD, leaf_RH, leaf_actual_pressure = _leaf_humidity_status(params, leaf_saturated_pressure, air_actual_pressure, temp_leaf_K, ψ_leaf_act)

#             β_leaf_tmp = cal_vulnerability_curve(params, ψ_leaf_act, p50_leaf, shape_factor_leaf)
#             ci_unsat = _solve_ci_Pa(params, fq, β_leaf_tmp, ci_saturated, leaf_VPD)
#             _, _, _, _, _, _, gs_unsat = _GPP_Farquhar(params, fq, β_leaf_tmp, ci_unsat, leaf_VPD)
#         end
#     end

#     ### use solved leaf water potential
#     ψ_leaf = ψ_leaf_prev = ψ_leaf_act
#     ci_Pa = ci_prev = ci_unsat
#     β_leaf = gpp_f_soilW = β_leaf_tmp

#     ### calculate photosynthesis
#     if !plant_activity
#         gpp_farquhar = Ac_mol_m2_s = Aj_mol_m2_s = net_photosynthesis = Vc_actual = gs_Medlyn = z_zero
#     else
#         gpp_farquhar, Ac_mol_m2_s, Aj_mol_m2_s, net_photosynthesis, _, Vc_actual, gs_Medlyn = _GPP_Farquhar(params, fq, β_leaf, ci_Pa, leaf_VPD)
#     end
#     Ac_gC = Ac_mol_m2_s * efficient_lai * c_mol_mass * f_daytime_seconds # g C m-2 d-1
#     Aj_gC = Aj_mol_m2_s * efficient_lai * c_mol_mass * f_daytime_seconds # g C m-2 d-1

#     ### Tr
#     phs_transpiration = transpiration * con_1e3 # mm d-1, canopy scale
#     phs_transpiration_max = Tr_max * con_1e3 # mm d-1 for a saturated leaf

#     @pack_nt begin
#         (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇒ land.diagnostics
#         (β_leaf, gpp_f_soilW) ⇒ land.diagnostics
#         (gpp_farquhar, net_photosynthesis) ⇒ land.diagnostics
#         (Ac_gC, Aj_gC, Ac_mol_m2_s, Aj_mol_m2_s, Vc_actual) ⇒ land.diagnostics
#         (gs_Medlyn, gs_max, ci_Pa, ci_prev) ⇒ land.diagnostics
#         (leaf_VPD, leaf_RH, leaf_actual_pressure) ⇒ land.diagnostics
#         (phs_transpiration, phs_transpiration_max) ⇒ land.diagnostics
#     end
#     return land
# end

# function cal_plant_activity(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         LAI ⇐ land.states
#         root_over ⇐ land.rootWaterEfficiency
#         z_zero ⇐ land.constants
#         (Κ_soil_root, leaf_saturated_VPD, temp_leaf_degC) ⇐ land.diagnostics
#     end
#     active_soil_root = false
#     for sl in eachindex(root_over)
#         if root_over[sl] > z_zero && abs(Κ_soil_root[sl]) >= minimum_conductance ### the root layer with higher conductance than the minimum one.
#             active_soil_root = true
#         end
#     end
#     return LAI > minimum_lai && leaf_saturated_VPD > z_zero && active_soil_root && temp_leaf_degC > z_zero
# end

# # root water uptake and soil evaporation, only needed once for the final solution.
# function cal_PHS_root_uptake(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_canopy_height ⇐ forcing
#         (LAI, PAW) ⇐ land.states
#         phs_root_water_uptake ⇐ land.fluxes
#         root_over ⇐ land.rootWaterEfficiency
#         (Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
#         (ψ_root, phs_transpiration) ⇐ land.diagnostics
#     end

#     plant_activity = cal_plant_activity(params, forcing, land, helpers)
#     transpiration = phs_transpiration * mm_2_m # m d-1
#     rl = _root_potential_linear(params, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)

#     β_stem = clamp_zero_one(cal_vulnerability_curve(params, ψ_root, p50_stem, shape_factor_stem))
#     ψ_root_layer = _root_layer_potential(params, rl, transpiration, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     phs_root_water_uptake = _root_water_uptake_layers(params, plant_activity, root_over, PAW, Κ_soil_root, ψ_soil, root_surface_area, ψ_root_layer, phs_root_water_uptake)
#     phs_evaporation = cal_soil_evaporation(params, forcing, land, helpers)

#     @pack_nt begin
#         β_stem ⇒ land.diagnostics
#         phs_evaporation ⇒ land.diagnostics
#         phs_root_water_uptake ⇒ land.fluxes
#     end
#     return land
# end

# # Big-leaf daytime energy balance per unit ground area (after SCOPE heatfluxes.m and ebal.m): Rn = λE + H.
# # Tc is solved by Newton iteration with the same derivative as the Tc update in SCOPE ebal.m.
# function cal_leaf_energy_balance(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_rn, f_ws, f_airT_day, f_daytime_seconds) ⇐ forcing
#         (LAI, fAPAR) ⇐ land.states
#         (patm, efficient_lai, gs_Medlyn, ψ_leaf, air_actual_pressure, temp_leaf_degC) ⇐ land.diagnostics
#     end

#     cp = c_p * con_1e6 # J kg-1 K-1
#     air_K = f_airT_day + deg_2_K

#     ### net radiation absorbed by the canopy, W m-2 ground; radiation is assumed to fall in the daytime.
#     fc = fAPAR
#     Rn = at_least_zero(f_rn) * con_1e6 / f_daytime_seconds * fc
#     longwave_slope = fc * 4 * leaf_emissivity * sigma_SB * air_K ^ 3 # W m-2 K-1

#     ### aerodynamic resistance for heat, s m-1: above + within canopy + leaf boundary layer (per leaf area, scaled to ground).
#     _, r_aa, U_a = _aerodynamic_terms(params, forcing, land, helpers)
#     r_b = inv(0.01 * sqrt(U_a / leaf_width))
#     r_a = r_aa + r_b / efficient_lai

#     ### bulk stomatal resistance, s m-1 ground: leaf water vapour conductance (mol m-2 s-1) times molar volume (m3 mol-1).
#     gs_water = diffusivity_ratio * gs_Medlyn
#     r_s = gs_water > 0 ? inv(gs_water * k_R * air_K / patm * efficient_lai) : oftype(gs_water, Inf)

#     air_vapor_hPa = 10 * air_actual_pressure
#     psi_leaf_Pa = ψ_leaf * m_to_MPa * con_1e6
#     e_to_q = 0.622 / (patm / 100)

#     temp_leaf_balance = temp_leaf_degC
#     for _ in 1:Tleaf_ebal_iterations
#         leaf_K = temp_leaf_balance + deg_2_K
#         lambda = (2.501 - 0.002361 * temp_leaf_balance) * con_1e6 # J kg-1
#         leaf_vapor_hPa = 10 * cal_saturated_pressure(temp_leaf_balance) * min(exp(psi_leaf_Pa * Vw / (k_R * leaf_K)), 1) # Kelvin equation
#         vapor_slope = leaf_vapor_hPa * 17.27 * 237.3 / (temp_leaf_balance + 237.3) ^ 2 # hPa K-1

#         net_radiation = Rn - longwave_slope * (temp_leaf_balance - f_airT_day)
#         latent_heat = ρ * lambda * e_to_q * (leaf_vapor_hPa - air_vapor_hPa) / (r_a + r_s)
#         sensible_heat = ρ * cp * (temp_leaf_balance - f_airT_day) / r_a
#         energy_residual = net_radiation - latent_heat - sensible_heat
#         energy_slope = ρ * cp / r_a + ρ * lambda * e_to_q * vapor_slope / (r_a + r_s) + longwave_slope

#         delta_temp = clamp(energy_residual / energy_slope, -5, 5)
#         temp_leaf_balance += delta_temp
#         abs(delta_temp) < 1e-4 && break
#     end
#     temp_leaf_balance = clamp(temp_leaf_balance, f_airT_day - 10, f_airT_day + 20)
#     temp_leaf_balance = LAI > minimum_lai && isfinite(temp_leaf_balance) ? temp_leaf_balance : temp_leaf_degC
#     temp_leaf_balance = oftype(temp_leaf_degC, temp_leaf_balance)

#     @pack_nt temp_leaf_balance ⇒ land.diagnostics
#     return land
# end

# function _root_water_uptake_layers(params::plantHydraulics_PHS, plant_activity, root_over, PAW, Κ_soil_root, ψ_soil, root_surface_area, ψ_root_layer, template)
#     @unpack_plantHydraulics_PHS params
#     T = eltype(template)
#     vals = ntuple(Val(length(template))) do sl
#         if plant_activity && root_over[sl] > zero(eltype(root_over))
#             uptake_capacity = PAW[sl] * con_1e_3 # mm to m
#             rwu = at_least_zero(Κ_soil_root[sl] * root_surface_area[sl] * (ψ_soil[sl] - ψ_root_layer[sl]))
#             T(min(rwu, uptake_capacity) * m_to_mm)
#         else
#             zero(T)
#         end
#     end
#     return SVector{length(template),T}(vals)
# end

# function cal_soil_hydrology(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         LAI ⇐ land.states
#         (soilW, ΔsoilW) ⇐ land.pools
#         (D_soil_inv_mm, D_soil_cum_m, D_root_deno, D_soil_m) ⇐ land.diagnostics
#         (nvg, avg, mvg) ⇐ land.diagnostics
#         (root_surface_area, c_allocation) ⇐ land.diagnostics
#         sp_k_sat ⇐ land.properties
#         (f_thetar_van_Genuchten, f_thetas_van_Genuchten) ⇐ forcing
#         root_over ⇐ land.rootWaterEfficiency
#         z_zero ⇐ land.constants
#     end

#     Rsf = sum(root_surface_area)
#     froot_to_leaf = c_allocation[1]
#     sai = at_least_zero(stem_to_leaf_area_ratio * LAI)
#     vg = (; nvg, avg, mvg, θ_res=f_thetar_van_Genuchten, θ_sat=f_thetas_van_Genuchten)

#     layers = ntuple(Val(length(soilW))) do sl
#         _soil_layer_hydrology(eltype(soilW), params, vg, LAI, sai, Rsf, froot_to_leaf, z_zero,
#             soilW[sl], ΔsoilW[sl], D_soil_inv_mm[sl], D_soil_cum_m[sl], D_root_deno[sl], D_soil_m[sl],
#             sp_k_sat[sl], root_over[sl], root_surface_area[sl])
#     end

#     T = eltype(soilW)
#     N = length(soilW)
#     θ_soil = _field_svector(layers, Val(1), Val(N), T)
#     θ_res = _field_svector(layers, Val(2), Val(N), T)
#     θ_sat = _field_svector(layers, Val(3), Val(N), T)
#     soil_saturation = _field_svector(layers, Val(4), Val(N), T)
#     Κ_soil_root = _field_svector(layers, Val(5), Val(N), T)
#     Κ_soil = _field_svector(layers, Val(6), Val(N), T)
#     Κ_root = _field_svector(layers, Val(7), Val(N), T)
#     Κ_soil_unsat = _field_svector(layers, Val(8), Val(N), T)
#     ψ_soil = _field_svector(layers, Val(9), Val(N), T)
#     ψ_soil_matric = _field_svector(layers, Val(10), Val(N), T)
#     β_root = _field_svector(layers, Val(11), Val(N), T)
#     RAI = _field_svector(layers, Val(12), Val(N), T)
#     fraction_root = _field_svector(layers, Val(13), Val(N), T)

#     @pack_nt begin
#         (θ_soil, θ_res, θ_sat, soil_saturation) ⇒ land.diagnostics
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
#         (ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
#         (β_root, RAI, fraction_root) ⇒ land.diagnostics
#     end
#     return land
# end

# @inline function _soil_layer_hydrology(::Type{T}, params::plantHydraulics_PHS, vg, LAI, sai, Rsf, froot_to_leaf, z_zero, soilW_l, ΔsoilW_l, D_soil_inv_mm_l, D_soil_cum_m_l, D_root_deno_l, D_soil_m_l, k_sat_l, root_over_l, rsa_l) where {T}
#     @unpack_plantHydraulics_PHS params
#     θ = (soilW_l + ΔsoilW_l) * D_soil_inv_mm_l
#     soil_potential, theta_res, theta_sat, saturation = _soil_matric_potential(params, vg, θ)

#     if root_over_l > z_zero
#         root_fraction = rsa_l / Rsf
#         layer_head = _pos_Inf_not_NaN(soil_potential - D_soil_cum_m_l)
#         k_soil_unsat = k_sat_l * mm_2_m * sqrt(saturation) * (1 - (1 - saturation ^ (1 / vg.mvg)) ^ vg.mvg) ^ 2 # m d-1

#         ### soil conductance based on van-Genuchten model., m d-1
#         Ω_soil = sqrt(π / 2) * sqrt(root_radius * D_soil_m_l / rsa_l) / k_soil_unsat # m d-1
#         k_soil = isfinite(Ω_soil) ? max(inv(Ω_soil), minimum_conductance) : minimum_conductance

#         rai = at_least_zero((sai + LAI) * root_fraction * froot_to_leaf)
#         root_stress = cal_vulnerability_curve(params, soil_potential, p50_root, shape_factor_root) # 0-1
#         k_root = max(root_stress * k_root_max / D_root_deno_l, minimum_conductance)

#         soil_to_root = _soil_root_conductance(k_soil, k_root)
#     else
#         layer_head = soil_to_root = k_soil = k_root = k_soil_unsat = root_stress = root_fraction = rai = z_zero
#     end
#     return (T(θ), T(theta_res), T(theta_sat), T(saturation), T(soil_to_root), T(k_soil), T(k_root), T(k_soil_unsat), T(layer_head), T(soil_potential), T(root_stress), T(rai), T(root_fraction))
# end

# @inline function _soil_matric_potential(params::plantHydraulics_PHS, vg, θ)
#     θ_res = vg.θ_res
#     θ_sat = vg.θ_sat
#     saturation = clamp_zero_one((θ - θ_res) / (θ_sat - θ_res))
#     z_zero = zero(saturation)
#     o_one = one(saturation)

#     inverse_saturation = saturation ^ (-o_one / vg.mvg)
#     if !isfinite(inverse_saturation)
#         return oftype(z_zero, -5000), θ_res, θ_sat, saturation
#     end

#     pressure_term = max(inverse_saturation - o_one, z_zero)
#     ψ_soil_matric = -(pressure_term ^ (o_one / vg.nvg)) / vg.avg
#     if !isfinite(ψ_soil_matric)
#         return oftype(z_zero, -5000), θ_res, θ_sat, saturation
#     end
#     return clamp(ψ_soil_matric, -5000, z_zero), θ_res, θ_sat, saturation
# end

# function cal_soil_evaporation(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_rn, f_VPD_day) ⇐ forcing
#         LAI ⇐ land.states
#         k_extinction ⇐ land.diagnostics
#     end

#     # the net radiation flux into the soil surface, MJ m-2 d-1
#     available_energy_fraction = exp(-k_extinction * LAI)
#     R_n_s = f_rn * available_energy_fraction

#     Δ, λ, γ = cal_model_params(params, forcing, land, helpers)
#     r_a, r_s = cal_areodynamic_resistance(params, forcing, land, helpers)

#     numerator = Δ * R_n_s + (ρ * c_p * f_VPD_day / r_a) * day_second
#     demominator = Δ + γ * (1 + r_s / r_a)
#     lambda_Es = numerator / demominator # MJ m-2 d-1
#     evaporation = lambda_Es / λ # mm d-1

#     return evaporation
# end

# function cal_model_params(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_airT_day) ⇐ forcing
#     end

#     # Air temperature, deg C
#     Ta = f_airT_day
#     # Atmospheric pressure, kPa
#     patm = f_psurf_day

#     # the slope of the saturated vapor pressure‐temperature curve
#     Δ = 4098 * (0.6108 * exp(17.27 * Ta / (Ta + 237.3))) / ((Ta + 237.3) ^ 2) # kPa K-1, check
#     # # dynamic latent heat of vapourization of water
#     λ = 2.501 - 0.002361 * Ta # MJ kg-1
#     # psychrometric constant
#     γ = 0.00163 * patm / λ # kPa K-1, check

#     return Δ, λ, γ
# end

# function cal_areodynamic_resistance(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt Κ_soil ⇐ land.diagnostics
#     r_as, r_aa, _ = _aerodynamic_terms(params, forcing, land, helpers)
#     r_a = r_as + r_aa # approximate total soil-to-reference aerodynamic resistance

#     ### soil resistance, s m-1
#     r_s = inv(Κ_soil[1]) # d m-1
#     r_s = r_s * day_second # s m-1
#     r_s = clamp(r_s, r_ss_min, r_ss_max)
#     return r_a, r_s
# end

# # r_as: substrate to canopy source height; r_aa: canopy source height to reference height (s m-1); U_a: wind speed at reference height (m s-1).
# function _aerodynamic_terms(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_canopy_height, f_ws) ⇐ forcing
#         LAI ⇐ land.states
#     end
#     # wind speed at the weather station, m s-1
#     U_w = at_least_zero(f_ws) # m s-1
#     z_b = 0.334 * Fw ^ 0.875 * zow ^ 0.125 # check

#     # canopy height, m
#     h_c = at_least_zero(f_canopy_height) # m
#     d_p = 0.63 * h_c # the “preferred” zero plane displacement, m
#     Z_0 = 0.13 * h_c # the “preferred” roughness length, m
#     z_a = h_c + 2.0 # the reference height (m), 2 m above vegetation

#     if h_c <= 1
#         z_0c = 0.13 * h_c
#         n = 2.5
#     elseif h_c < 10
#         z_0c = 0.139 * h_c - 0.009 * h_c ^ 2
#         n = 2.306 + 0.194 * h_c
#     else
#         z_0c = 0.05 * h_c
#         n = 4.25
#     end

#     if h_c > 0
#         C_d = ((-1 + exp(0.909 - 3.03 * z_0c / h_c)) ^ 4) / 4
#     else
#         C_d = 1.4 / con_1e3
#     end

#     if LAI > 4
#         d_0 = h_c - z_0c / 0.3
#     else
#         d_0 = 1.1 * h_c * log(1 + (C_d * LAI) ^ 0.25)
#     end

#     # Wind speed at reference height, m s-1
#     z_0 = min(0.3 * (h_c - d_0), z_0g + 0.3 * h_c * (C_d * LAI) ^ 0.5)
#     U_a = U_w * log(z_b / zow) / log(z_b / z_0) / log(zw / zow) * log((z_a - d_0) / z_0)

#     U_star = k_von * U_a / log((z_a - d_0) / z_0)
#     K_h = k_von * U_star * (h_c - d_0)

#     ### Aerodynamic resistance between substrate and canopy source height, s m-1
#     r_as = h_c * exp(n) / n / K_h * (exp(-n * z_0g / h_c) - exp(-n * (Z_0 + d_p) / h_c))

#     # Aerodynamic resistance above canopy, s m-1
#     r_above = log((z_a - d_0) / (h_c - d_0)) /
#             (k_von * U_star)

#     # Aerodynamic resistance within canopy, s m-1
#     r_within = h_c / (n * K_h) *
#             expm1(n * (1 - (Z_0 + d_p) / h_c))

#     # From canopy source height to reference height
#     r_aa = r_above + r_within

#     return r_as, r_aa, U_a
# end

# """ CLM5 is too sensitive, use sigmoid or STEMMUS-SCOPE one. """
# function cal_vulnerability_curve(params::plantHydraulics_PHS, psi, psi50, shape_factor)
#     @unpack_plantHydraulics_PHS params

#     ### sigmoid function
#     # refer to: 1. Alléon, J. et al. Plant hydraulic architecture for a mechanistic representation of soil-plant-atmosphere water transfer in the land surface model ORCHIDEE (r9107). Journal of Advances in Modeling Earth Systems 17, e2024MS004869 (2025).
#     # be care of the unit.
#     psi50 = psi50 * m_to_MPa
#     psi = psi * m_to_MPa
#     numerator = 1 + exp(shape_factor * psi50)
#     deminator = 1 + exp(shape_factor * (psi50 - psi))
#     stress = clamp_zero_one(numerator / deminator)

#     return stress
# end

# function cal_KM(params::plantHydraulics_PHS, forcing, land, helpers, patm, tk)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         o_one ⇐ land.constants
#     end
#     ### This function is used to calculate The effective Michaelis–Menten coefficient K (Pa) of RuBisCO-limited photosynthesis.
#     kc = kc25 * exp(dhac * (tk - tk_ref) / (tk_ref * k_R * tk))
#     ko = ko25 * exp(dhao * (tk - tk_ref) / (tk_ref * k_R * tk))
#     po = k_co * con_1e_6 * patm
#     kmm = kc * (o_one + po / ko) # Pa
#     return kmm
# end

# function cal_Phi_o(params::plantHydraulics_PHS, forcing, land, helpers, temp_leaf_degC)
#     @unpack_plantHydraulics_PHS params
#     ### This function is used to calculate the intrinsic quantum yield (φ0(T), mol C/mol photon).
#     f_T = 0.325 + 0.022 * temp_leaf_degC - 0.00034 * temp_leaf_degC ^ 2 # dimensionless
#     phi_o = at_least_zero(CL * f_T) # dimensionless
#     phi_o = min(phi_o, 0.125) # theoretical maximum value of φ0(T) is 0.125.
#     return phi_o
# end

# function cal_Arrhenius_Factor(params::plantHydraulics_PHS, forcing, land, helpers, patm, tk)
#     @unpack_plantHydraulics_PHS params
#     arrhenius_factor = exp(ha * (tk - tk_ref) / (tk_ref * k_R * tk)) # dimensionless
#     return arrhenius_factor
# end

# function cal_Deactivation_High_Temp(params::plantHydraulics_PHS, forcing, land, helpers, tk)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_month_air_temperature ⇐ forcing
#     end
#     ### Refer to 1. Bernacchi, C. J., Pimen℡, C. & Long, S. P. In vivo temperature response functions of parameters required to model RuBP-limited photosynthesis. Plant, Cell & Environment 26, 1419–1430 (2003).
#     # But in CLM4.5, it is the monthly mean temperature in deg C.
#     temp_month_C = min(max(f_month_air_temperature, 11), 35)
#     delta_S = 668.39 - 1.07 * temp_month_C # entropy of de-activation, J mol-1 K-1. To consider the effect of temperature accmilation. Refer to: 1. Kattge, J. & Knorr, W. Temperature acclimation in a biochemical model of photosynthesis: A reanalysis of data from 36 species. Plant, Cell & Environment 30, 1176–1190 (2007).
#     deactivation_high_temp = (1 + exp((tk_ref * delta_S - Ed) / (tk_ref * k_R))) / (1 + exp((tk * delta_S - Ed) / (tk * k_R)))
#     return deactivation_high_temp
# end

# function cal_Deactivation_Low_Temp(params::plantHydraulics_PHS, forcing, land, helpers, tk)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (z_zero, o_one) ⇐ land.constants
#     end
#     ### consider the inhibition effects of low temperature.
#     # tk should be in K.
#     # Reference: 1. Stettz, S. G. et al. Resolving temperature limitation on spring productivity in an evergreen conifer forest using a model–data fusion framework. Biogeosciences 19, 541–558 (2022).

#     temp_low = deg_2_K # zero degree C
#     temp_high = deg_2_K + 5 # five degree C
#     if tk < temp_low
#         deactivation_low_temp = z_zero
#     elseif tk > temp_high
#         deactivation_low_temp = o_one
#     else
#         deactivation_low_temp = (tk - temp_low) / (temp_high - temp_low)
#     end
#     return deactivation_low_temp
# end

# function cal_gamma_star(params::plantHydraulics_PHS, forcing, land, helpers, arrhenius_factor, patm)
#     @unpack_plantHydraulics_PHS params
#     gamma_star = (gs25_0 * patm / k_Po) * arrhenius_factor # Pa
#     return gamma_star
# end

# function cal_Jmax_Vmax(params::plantHydraulics_PHS, forcing, land, helpers, arrhenius_factor, deactivation_high_temp, deactivation_low_temp)
#     @unpack_plantHydraulics_PHS params
#     ### consider the effects of temperature on Vcmax and Jmax
#     # according to arrhenius function to convert Vcmax25 and Jmax25 to Vcmax and Jmax at current temperature.
#     Vcmax = Vcmax25 * arrhenius_factor * deactivation_high_temp * deactivation_low_temp # molC m-2 s-1
#     Jmax25 = Vcmax25 * Jmax25_Vcmax25_ratio # molC m-2 s-1
#     Jmax = Jmax25 * arrhenius_factor * deactivation_high_temp * deactivation_low_temp # molC m-2 s-1
#     return Jmax, Vcmax
# end

# function cal_efficient_LAI(params::plantHydraulics_PHS, forcing, land, helpers)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         LAI ⇐ land.states
#         k_extinction ⇐ land.diagnostics
#         (z_zero, o_one) ⇐ land.constants
#     end
#     ### based on beer-lambert law.
#     efficient_lai = (o_one - exp(-k_extinction * LAI)) / k_extinction # dimensionless
#     return efficient_lai
# end

# function cal_CO2_Pa(params::plantHydraulics_PHS, forcing, land, helpers, patm, tk)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         ambient_CO2 ⇐ land.states
#     end
#     ca = con_1e_6 * ambient_CO2 * patm # ppm to Pa
#     ca_mol = con_1e_6 * ambient_CO2 # ppm to mol CO2 mol-1 air
#     return ca, ca_mol
# end

# function cal_dark_respiration(params::plantHydraulics_PHS, forcing, land, helpers, Vcmax)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         f_rg ⇐ forcing          # Incoming radiation (MJ/m²/d)
#         LAI ⇐ land.states
#     end
#     # dark respiration occurs in 24 hours.
#     # leaf scale
#     ### Important: Vcmax should not consider the effects of water stress, because water stress mainly affects the stomatal closureness, not the dark respiration. CLM5 & CABLE also do not consider the effects of water stress on dark respiration.
#     ### some field observations also found that water stress has no significant effect on dark respiration, but GPP is significantly reduced.

#     dark_respiration_mol = rate_dark * Vcmax # mol C m-2 s-1
#     dark_respiration = dark_respiration_mol * c_mol_mass * day_second # gC m-2 d-1

#     ### Important: when upscale to canopy scale, we should consider the effects of nitrogen limitation on dark respiration.
#     # upscale to canopy scale
#     factor_LAI_Nitrogen = (1 - exp(-k_Nitrogen * LAI)) / k_Nitrogen # dimensionless
#     dark_respiration = dark_respiration * factor_LAI_Nitrogen # gC m-2 d-1
#     return dark_respiration, factor_LAI_Nitrogen, dark_respiration_mol
# end

# function cal_saturated_pressure(Temperature)
#     saturated_pressure = 0.6108 * exp(17.27 * Temperature / (Temperature + 237.3)) # kPa
#     return saturated_pressure
# end

# function cal_Farquhar_info(params::plantHydraulics_PHS, forcing, land, helpers, temp_leaf_degC)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_SW, f_VPD_day, f_daytime_seconds) ⇐ forcing
#         (ambient_CO2, LAI, fAPAR) ⇐ land.states
#         (f_psurf_day, f_airT_day) ⇐ forcing
#         (z_zero, o_one) ⇐ land.constants
#     end

#     patm = f_psurf_day * con_1e3 # kPa to Pa
#     temp_leaf_K = temp_leaf_degC + deg_2_K # K

#     ### leaf scale should use leaf temperature, not air temperature.
#     arrhenius_factor = cal_Arrhenius_Factor(params, forcing, land, helpers, patm, temp_leaf_K) # dimensionless
#     deactivation_high_temp = cal_Deactivation_High_Temp(params, forcing, land, helpers, temp_leaf_K) # dimensionless
#     deactivation_low_temp = cal_Deactivation_Low_Temp(params, forcing, land, helpers, temp_leaf_K) # dimensionless

#     KM = cal_KM(params, forcing, land, helpers, patm, temp_leaf_K) # effective Michaelis–Menten coefficient K (Pa)
#     Jmax, Vcmax = cal_Jmax_Vmax(params, forcing, land, helpers, arrhenius_factor, deactivation_high_temp, deactivation_low_temp) # mol C m-2 s-1
#     gamma_star = cal_gamma_star(params, forcing, land, helpers, arrhenius_factor, patm) # Pa
#     ca_Pa, ca_mol = cal_CO2_Pa(params, forcing, land, helpers, patm, temp_leaf_K)
#     efficient_lai = cal_efficient_LAI(params, forcing, land, helpers)
#     Phi_o = cal_Phi_o(params, forcing, land, helpers, temp_leaf_degC) # the intrinsic quantum-yield efficiency, dimensionless

#     ### Light-limited rate, Aj.
#     # one W m-2 of sunlight is roughly 4.57 µmol m-2 s-1 of full spectrum sunlight.
#     # f_SW: shortwave radiation, W/m2; fAPAR: fraction of absorbed photosynthetically active radiation, dimensionless; 2.04: conversion factor from W/m2 to µmol photon m-2 s-1.
#     # convert MJ/m2/d to W/m2: 1 MJ/m2/d = 1e6 J/m2/d / 86400 s/d = 11.574 W/m2.
#     SW_W_m2 = at_least_zero(f_SW * con_1e6 / day_second) # W m-2
#     # Refer to 1. Ren, Y. et al. Incorporating the Acclimation of Photosynthesis and Leaf Respiration in the Noah-MP Land Surface Model: Model Development and Evaluation. Journal of Advances in Modeling Earth Systems 17, e2024MS004599 (2025).
#     # 2.04 is refer to: 1. Meek, D. W., Hatfield, J. L., Howell, T. A., Idso, S. B. & Reginato, R. J. A generalized relationship between photosynthetically active radiation and solar radiation. Agronomy Journal 76, 939–945 (1984).
#     Iabs = at_least_zero(fAPAR * SW_W_m2 * 2.04) # umol photon m-2 s-1
#     Iabs = Iabs * con_1e_6 # mol photon m-2 s-1
#     numerator = 4 * Phi_o * Iabs # mol C m-2 s-1
#     denominator = (numerator / Jmax) ^ 2 + o_one
#     J_actual = Jmax > 1e-12 ? numerator / sqrt(denominator) : z_zero # mol C m-2 s-1

#     # Leaf VPD is calculated based on Kelvin equation to consider the effects of leaf water potential.
#     air_saturated_pressure = cal_saturated_pressure(f_airT_day) # kPa
#     leaf_saturated_pressure = cal_saturated_pressure(temp_leaf_degC) # kPa
#     air_actual_pressure = at_least_zero(air_saturated_pressure - at_least_zero(f_VPD_day)) # kPa
#     leaf_saturated_VPD = at_least_zero(leaf_saturated_pressure - air_actual_pressure) # kPa

#     dark_respiration, factor_LAI_Nitrogen_dark_respiration, dark_respiration_mol = cal_dark_respiration(params, forcing, land, helpers, Vcmax)

#     @pack_nt begin
#         (KM, patm) ⇒ land.diagnostics
#         (arrhenius_factor, deactivation_high_temp, deactivation_low_temp) ⇒ land.diagnostics
#         (Jmax, Vcmax, J_actual) ⇒ land.diagnostics
#         (gamma_star, ca_Pa, ca_mol) ⇒ land.diagnostics
#         efficient_lai ⇒ land.diagnostics
#         (leaf_saturated_pressure, air_saturated_pressure, air_actual_pressure, leaf_saturated_VPD) ⇒ land.diagnostics
#         (temp_leaf_degC, temp_leaf_K) ⇒ land.diagnostics
#         (Iabs, Phi_o) ⇒ land.diagnostics
#         (dark_respiration, factor_LAI_Nitrogen_dark_respiration, dark_respiration_mol) ⇒ land.diagnostics
#     end
# end

# purpose(::Type{plantHydraulics_PHS}) = "Farquhar-Medlyn-Fick-PHS model framework."

# @doc """

# $(getModelDocString(plantHydraulics_PHS))

# ---

# # Extended help

# *Versions*
#  - 1.0 on 21.09.2026 [jzhou]
#  - 1.1 on 05.10.2026 [jzhou]
#  - 1.2 on 18.10.2026 [jzhou]: leaf temperature from the leaf energy balance (after SCOPE)
# """
# plantHydraulics_PHS
