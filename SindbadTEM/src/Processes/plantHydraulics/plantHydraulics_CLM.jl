# export plantHydraulics_CLM

# #! format: off
# @bounds @describe @units @timescale @with_kw struct plantHydraulics_CLM{T} <: plantHydraulics
#     # plant hydraulic traits, CLM5 PHS Weibull vulnerability curve: plc = 2^-((ψ/ψ50)^ck)
#     p50_leaf::T = -67.67 | (-500.0, -10.0) | "leaf water potential at 50 percent loss of conductance (also attenuates the stomatal demand)" | "m" | ""
#     p50_stem::T = -342.51 | (-1500.0, -10.0) | "stem water potential at 50 percent loss of conductance" | "m" | ""
#     p50_root::T = -30.0 | (-1000.0, -10.0) | "root and soil-root interface water potential at 50 percent loss of conductance" | "m" | ""
#     shape_factor_leaf::T = 1.98 | (0.5, 5.0) | "leaf PHS vulnerability-curve shape factor" | "MPa-1" | ""
#     shape_factor_stem::T = 1.98 | (0.5, 5.0) | "stem PHS vulnerability-curve shape factor" | "MPa-1" | ""
#     shape_factor_root::T = 0.8 | (0.5, 5.0) | "root PHS vulnerability-curve shape factor" | "MPa-1" | ""

#     # plant hydraulic conductances
#     k_leaf_max::T = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum stem-to-leaf conductance per unit leaf area" | "d-1" | ""
#     k_stem_max::T = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum root-to-stem hydraulic conductivity" | "m d-1" | ""
#     k_root_max::T = 1.73e-4 | (8.64e-6, 8.64e-2) | "maximum root hydraulic conductivity per unit root area and length" | "m d-1" | ""
#     minimum_conductance::T = 1.0e-11 | (0.0, 1.0) | "numerical floor of the soil and root conductances" | "d-1" | ""
#     minimum_root_potential::T = -1000.0 | (-1.0e4, -100.0) | "lower limit of the root water potential, -10 MPa = -1019 m" | "m" | ""
#     maximum_soil_root_resistance::T = 1.0e5 | (1.0e2, 1.0e9) | "soil-to-root resistance above which a soil layer is excluded from the root uptake" | "d m-1" | ""
#     minimum_water_stress::T = 1.0e-2 | (1.0e-6, 10.0) | "minimum vulnerability value for which the stem and leaf conductances are calculated" | "" | ""

#     # canopy and root structure
#     stem_to_leaf_area_ratio::T = 0.1 | (0.01, 0.9) | "stem area index to leaf area index ratio" | "" | ""
#     root_radius::T = 1.5e-3 | (1.0e-5, 1.0e-2) | "fine-root radius, used to infer the root length density from the SINDBAD root surface area" | "m" | ""
#     root_lateral_length::T = 0.25 | (1.0e-3, 10.0) | "coarse-root lateral length, CLM croot_lateral_length" | "m" | ""
#     minimum_lai::T = 1.0e-2 | (0.0, 1.0) | "minimum LAI for an active canopy" | "m2 m-2" | ""
#     minimum_canopy_height::T = 0.01 | (1.0e-3, 1.0) | "minimum canopy height used in the aerodynamic calculation" | "m" | ""
#     minimum_soil_potential::T = -5000.0 | (-1.0e5, -100.0) | "lower limit of the soil matric potential" | "m" | ""
#     canopy_dry_fraction::T = 1.0 | (0.0, 1.0) | "fraction of foliage that is dry and transpiring, CLM fdry" | "" | ""

#     # CLM5 photosynthesis (C3), umol units as in PhotosynthesisMod
#     Vcmax25::T = 5.0e-5 | (1.0e-5, 1.5e-4) | "Maximum rate of carboxylation, normalised to 25 deg C, at the top of the canopy (scaled by the canopy nitrogen profile)" | "molC m-2 s-1" | ""
#     Jmax25_Vcmax25_ratio::T = 1.67 | (1.5, 2.1) | "The ratio between the maximum electron transport rate, normalised to 25 ◦C to Vcmax25" | "dimensionless" | ""
#     tpu_vcmax_ratio::T = 0.167 | (0.05, 0.5) | "ratio of the triose phosphate utilization rate to Vcmax25" | "" | ""
#     rate_dark::T = 0.015 | (0.005, 0.05) | "dark-respiration rate per unit carboxylation capacity, CLM leaf_mr_vcm" | "" | ""
#     kn_slope::T = 0.00963 | (0.0, 0.1) | "slope of ln(kn) against Vcmax25, Lloyd et al. 2010" | "" | ""
#     kn_intercept::T = -2.43 | (-5.0, 0.0) | "intercept of ln(kn) against Vcmax25, Lloyd et al. 2010" | "" | ""
#     kc25::T = 39.97 | (1e-2, 1e7) | "Michaelis-Menten constant for CO2 at 25 deg C and the standard pressure k_Po" | "Pa" | ""
#     ko25::T = 27480.0 | (1e-2, 1e7) | "Michaelis-Menten constant for O2 at 25 deg C and the standard pressure k_Po" | "Pa" | ""
#     gs25_0::T = 4.332 | (4.0, 5.0) | "Photorespiratory compensation point at 25 deg C and the standard pressure k_Po" | "Pa" | ""
#     k_Po::T = 101325.0 | (1, 1e7) | "one standard ATM" | "Pa" | ""
#     k_co::T = 209476.0 | (1e-2, 1e7) | "O2 mole fraction of the air" | "ppm" | ""
#     dhac::T = 79430.0 | (1e-2, 1e7) | "Activation energy for Kc" | "J mol-1" | ""
#     dhao::T = 36380.0 | (1e-2, 1e7) | "Activation energy for Ko" | "J mol-1" | ""
#     ha::T = 37830.0 | (1e-2, 1e7) | "Activation energy for gamma star" | "J mol-1" | ""
#     vcmaxha::T = 72000.0 | (1e4, 2e5) | "activation energy of Vcmax" | "J mol-1" | ""
#     jmaxha::T = 50000.0 | (1e4, 2e5) | "activation energy of Jmax" | "J mol-1" | ""
#     tpuha::T = 72000.0 | (1e4, 2e5) | "activation energy of TPU" | "J mol-1" | ""
#     lmrha::T = 46390.0 | (1e4, 2e5) | "activation energy of the leaf maintenance respiration" | "J mol-1" | ""
#     Ed::T = 200000.0 | (1e5, 3e5) | "energy of de-activation of Vcmax, Jmax, and TPU" | "J mol-1" | ""
#     lmrhd::T = 150650.0 | (1e5, 3e5) | "deactivation energy of the leaf maintenance respiration" | "J mol-1" | ""
#     lmrse::T = 490.0 | (400.0, 600.0) | "entropy term of the leaf maintenance respiration deactivation" | "J mol-1 K-1" | ""
#     delta_S_intercept::T = 668.39 | (600.0, 700.0) | "intercept of the entropy of deactivation (Vcmax and TPU) against the acclimation temperature" | "J mol-1 K-1" | ""
#     delta_S_slope::T = 1.07 | (0.0, 2.0) | "slope of the entropy of deactivation (Vcmax and TPU) against the acclimation temperature" | "J mol-1 K-2" | ""
#     jmaxse_intercept::T = 659.70 | (600.0, 700.0) | "intercept of the Jmax entropy term against the acclimation temperature" | "J mol-1 K-1" | ""
#     jmaxse_slope::T = 0.75 | (0.0, 2.0) | "slope of the Jmax entropy term against the acclimation temperature" | "J mol-1 K-2" | ""
#     temp_month_min::T = 11.0 | (-10.0, 20.0) | "lower bound of the acclimation temperature (CLM t10, here the monthly air temperature) used in the temperature response" | "deg C" | ""
#     temp_month_max::T = 35.0 | (20.0, 50.0) | "upper bound of the acclimation temperature (CLM t10, here the monthly air temperature) used in the temperature response" | "deg C" | ""
#     fnps::T = 0.15 | (0.0, 0.5) | "fraction of light absorbed by non-photosynthetic pigments" | "" | ""
#     theta_psii::T = 0.7 | (0.1, 1.0) | "curvature of the electron transport response to light" | "" | ""
#     theta_cj::T = 0.98 | (0.1, 1.0) | "curvature of the Ac and Aj co-limitation" | "" | ""
#     theta_ip::T = 0.95 | (0.1, 1.0) | "curvature of the co-limitation with the product-limited rate" | "" | ""
#     par_ppfd::T = 4.6 | (0, 5) | "PAR to PPFD conversion factor, from W/m2 to umol/m2/s" | "" | ""
#     lmr_lai_factor::T = 0.2 | (0.0, 1.0) | "factor of the respiration reduction at low LAI" | "" | ""
#     lmr_lai_exponent::T = 3.218 | (0.0, 10.0) | "exponent of the respiration reduction at low LAI" | "m2 m-2" | ""
#     light_inhibition::T = 0.67 | (0.0, 1.0) | "light inhibition factor of the leaf respiration" | "" | ""

#     # Medlyn stomatal conductance
#     g0::T = 1.0e-4 | (-0.05, 0.05) | "the minimum stomatal conductance, CLM medlynintercept = 100 umol m-2 s-1" | "mol m-2 s-1" | ""
#     g1::T = 4.45 | (1, 12.0) | "stomatal conductance parameter, CLM medlynslope" | "kPa^0.5" | ""
#     minimum_vpd::T = 0.05 | (1.0e-4, 1.0) | "minimum leaf-to-air vapor pressure deficit, CLM uses 50 Pa" | "kPa" | ""
#     minimum_gs::T = 1.0 | (1.0e-3, 100.0) | "lower bound of the stomatal conductance" | "umol m-2 s-1" | ""
#     diffusivity_ratio::T = 1.6 | (1.0, 2.0) | "ratio of the molecular diffusivities of water vapor and CO2 in the stomata" | "" | ""
#     boundary_co2_ratio::T = 1.4 | (1.0, 2.0) | "ratio of the molecular diffusivities of water vapor and CO2 in the leaf boundary layer" | "" | ""
#     minimum_cs::T = 1.0e-5 | (1e-8, 1e-2) | "lower bound of the leaf-surface CO2 partial pressure" | "Pa" | ""

#     # iteration parameters: ci, water stress, vegetation water potential
#     ci_initial_fraction::T = 0.7 | (0.1, 1.0) | "initial guess of ci as a fraction of the ambient CO2 partial pressure, CLM C3" | "" | ""
#     convergence_water_potential::T = 1e-3 | (1e-10, 1e0) | "tolerance of the leaf water potential in the iteration between the transpiration and the water potentials" | "m" | ""
#     STEMMUS_max_iterations::T = 50.0 | (10, 1000) | "maximum number of iterations between the transpiration and the plant water potentials" | "" | ""
#     psi_leaf_damping::T = 0.5 | (0.1, 1.0) | "weight of the new estimate in the leaf water potential update" | "" | ""
#     Ci_max_iterations::T = 30.0 | (10, 1000) | "maximum number of secant iterations for leaf intercellular CO2 concentration" | "" | ""
#     convergence_ci::T = 1.0e-3 | (0.0, 1e0) | "tolerance of ci" | "Pa" | ""
#     ci_residual_tolerance::T = 1.0e-4 | (1e-10, 1.0) | "absolute tolerance of the ci residual, CLM eps1" | "Pa" | ""

#     # leaf temperature iteration, CLM CanopyFluxes
#     Tleaf_max_iterations::T = 40.0 | (2.0, 200.0) | "maximum number of leaf temperature iterations, CLM itmax" | "" | ""
#     leaf_min_iterations::T = 2.0 | (1.0, 10.0) | "minimum number of leaf temperature iterations before convergence is tested, CLM itmin" | "" | ""
#     delmax::T = 1.0 | (0.1, 5.0) | "maximum change of the leaf temperature in one iteration" | "K" | ""
#     dtmin::T = 0.01 | (1e-6, 1.0) | "convergence limit of the leaf temperature change" | "K" | ""
#     dlemin::T = 0.1 | (1e-6, 10.0) | "convergence limit of the leaf latent heat flux change" | "W m-2" | ""
#     latent_flux_damping::T = 0.1 | (0.0, 1.0) | "factor applied to the leaf latent heat flux when its sign changes between iterations" | "" | ""

#     # aerodynamics and boundary layer, CLM CanopyFluxes and FrictionVelocity
#     z0m_ratio::T = 0.055 | (0.01, 0.2) | "ratio of the roughness length to the canopy height, CLM z0mr" | "" | ""
#     displacement_ratio::T = 0.67 | (0.3, 0.9) | "ratio of the displacement height to the canopy height, CLM displar" | "" | ""
#     z_ref::T = 10.0 | (2.0, 100.0) | "height of the wind and air measurement above the canopy top (z0m + displacement are added)" | "m" | ""
#     leaf_width::T = 0.04 | (0.001, 0.5) | "characteristic leaf width for the leaf boundary layer, CLM dleaf" | "m" | ""
#     boundary_layer_coefficient::T = 0.01 | (0.001, 0.1) | "coefficient of the leaf boundary-layer conductance, CLM cf" | "m s-0.5" | ""
#     minimum_wind_speed::T = 1.0 | (0.1, 5.0) | "minimum wind speed, CLM ur >= 1 m s-1" | "m s-1" | ""
#     zeta_m::T = 1.574 | (1.0, 3.0) | "transition point of the flux-gradient relation for the wind profile" | "" | ""
#     zeta_t::T = 0.465 | (0.1, 1.0) | "transition point of the flux-gradient relation for the temperature profile" | "" | ""
#     zeta_max_stable::T = 0.5 | (0.1, 10.0) | "maximum Monin-Obukhov zeta under stable conditions" | "" | ""
#     convective_height::T = 1000.0 | (100.0, 5000.0) | "convective boundary layer height, CLM zii" | "m" | ""
#     convective_beta::T = 1.0 | (0.1, 5.0) | "coefficient of the convective velocity, CLM beta" | "" | ""
#     ground_emissivity::T = 0.96 | (0.8, 1.0) | "ground emissivity used for the leaf longwave exchange, CLM emg" | "" | ""
#     canopy_extinction_mu::T = 1.0 | (0.1, 5.0) | "average inverse diffuse optical depth per unit leaf and stem area, CLM avmu" | "" | ""

#     # physical constants, CLM clm_varcon
#     k_von::T = 0.4 | (0.3, 0.5) | "von Karman constant" | "" | ""
#     g_acc::T = 9.80616 | (9.7, 9.9) | "gravitational acceleration" | "m s-2" | ""
#     cp::T = 1004.64 | (900.0, 1100.0) | "specific heat of dry air at constant pressure" | "J kg-1 K-1" | ""
#     R_air::T = 287.04 | (280.0, 290.0) | "gas constant of dry air" | "J kg-1 K-1" | ""
#     k_R::T = 8.31446 | (8, 9) | "universal gas constant" | "J mol-1 K-1" | ""
#     hvap::T = 2.501e6 | (2.4e6, 2.6e6) | "latent heat of vaporization" | "J kg-1" | ""
#     sigma_SB::T = 5.67e-8 | (5e-8, 6e-8) | "Stefan-Boltzmann constant" | "W m-2 K-4" | ""
#     rho_water::T = 1000.0 | (900.0, 1100.0) | "density of water" | "kg m-3" | ""
#     eps_ratio::T = 0.622 | (0.6, 0.65) | "ratio of the molar masses of water vapor and dry air" | "" | ""
#     vapor_correction::T = 0.378 | (0.3, 0.4) | "1 - eps_ratio, vapor pressure correction of the air density and specific humidity" | "" | ""
#     virtual_temperature_coef::T = 0.61 | (0.5, 0.7) | "coefficient of the virtual temperature" | "" | ""
#     esat_a::T = 0.6108 | (0.5, 0.7) | "saturation vapor pressure at 0 deg C in the Tetens equation" | "kPa" | ""
#     esat_b::T = 17.27 | (17.0, 18.0) | "slope coefficient of the Tetens equation" | "" | ""
#     esat_c::T = 237.3 | (200.0, 250.0) | "temperature offset of the Tetens equation" | "deg C" | ""
#     deg_2_K::T = 273.15 | (273.0, 274.0) | "conversion from deg C to K" | "" | ""
#     tk_ref::T = 298.15 | (298.0, 299.0) | "reference temperature of the photosynthesis temperature response, 25 deg C" | "K" | ""

#     # unit conversions
#     con_1e3::T = 1.0e3 | (1.0, 1.0e7) | "1,000, also the unit conversion from kPa to Pa" | "" | ""
#     mm_2_m::T = 1.0e-3 | (0.0, 1e7) | "unit conversion from mm to m" | "" | ""
#     m_to_MPa::T = 0.00980665 | (0.0, 1e7) | "unit conversion of water potential from m to MPa" | "" | ""
#     m_to_mm::T = 1.0e3 | (0.0, 1e7) | "unit conversion from m to mm" | "" | ""
#     con_1e6::T = 1.0e6 | (1.0, 1e7) | "1,000,000" | "" | ""
#     day_second::T = 86400.0 | (8.0e4, 9.0e4) | "seconds in a day" | "s" | ""
#     c_mol_mass::T = 12.011 | (12.0, 12.1) | "molar mass of carbon" | "g mol-1" | ""
# end
# #! format: on

# function define(params::plantHydraulics_CLM, forcing, land, helpers)
#     @unpack_plantHydraulics_CLM params
#     @unpack_nt begin
#         (f_alpha_van_Genuchten, f_eta_van_Genuchten) ⇐ forcing
#         soilW ⇐ land.pools
#         (z_zero, o_one) ⇐ land.constants
#     end

#     ### soil van Genuchten shape parameters
#     nvg = f_eta_van_Genuchten
#     avg = f_alpha_van_Genuchten
#     mvg = o_one - o_one / nvg

#     ### per-layer diagnostics, named as in plantHydraulics_PHS
#     phs_root_water_uptake = zero(soilW) # mm d-1, non-negative and limited by the available water
#     D_soil_inv_mm = zero(soilW)
#     D_soil_m = zero(soilW)
#     D_soil_cum_m = zero(soilW)
#     D_root_deno = zero(soilW)
#     θ_soil = zero(soilW)
#     θ_res = zero(soilW)
#     θ_sat = zero(soilW)
#     soil_saturation = zero(soilW)
#     ψ_soil = zero(soilW)
#     ψ_soil_matric = zero(soilW)
#     Κ_soil_root = zero(soilW)
#     Κ_soil = zero(soilW)
#     Κ_root = zero(soilW)
#     Κ_soil_unsat = zero(soilW)
#     RAI = zero(soilW)
#     fraction_root = zero(soilW)
#     β_root = zero(soilW)

#     ### plant water status
#     ψ_leaf_prev = ψ_leaf = ψ_stem = ψ_root = z_zero
#     β_leaf = β_stem = gpp_f_soilW = z_zero

#     ### photosynthesis and stomata
#     ci_prev = ci_Pa = z_zero
#     gpp_farquhar = net_photosynthesis = Ac_gC = Aj_gC = Ac_mol_m2_s = Aj_mol_m2_s = Vc_actual = z_zero
#     Vcmax = Jmax = J_actual = KM = gamma_star = ca_Pa = ca_mol = patm = z_zero
#     dark_respiration = dark_respiration_mol = z_zero
#     gs_Medlyn = rs = ra = ustar = z_zero

#     ### transpiration
#     phs_transpiration = tran_gs = delta_tr = z_zero

#     ### leaf temperature, humidity, and energy
#     temp_leaf_degC = temp_leaf_K = leaf_temp_diff = temp_leaf_balance = z_zero
#     leaf_VPD = leaf_saturated_pressure = air_saturated_pressure = air_actual_pressure = z_zero
#     LE_canopy = H_canopy_flux = Rn_canopy = z_zero

#     ### diagnostics without a counterpart in plantHydraulics_PHS
#     clm_gb_mol = z_zero
#     clm_absorbed_par = clm_obukhov_length = clm_rb = clm_rah = z_zero
#     clm_leaf_iterations = clm_stress_iterations = 0
#     clm_hydraulic_converged = clm_ci_converged = clm_coupling_converged = false

#     @pack_nt begin
#         (nvg, avg, mvg) ⇒ land.diagnostics
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.diagnostics
#         (θ_soil, θ_res, θ_sat, soil_saturation) ⇒ land.diagnostics
#         (ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
#         (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
#         (RAI, fraction_root, β_root) ⇒ land.diagnostics
#         (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇒ land.diagnostics
#         (β_leaf, β_stem, gpp_f_soilW) ⇒ land.diagnostics
#         (ci_prev, ci_Pa) ⇒ land.diagnostics
#         (gpp_farquhar, net_photosynthesis, Ac_gC, Aj_gC, Ac_mol_m2_s, Aj_mol_m2_s, Vc_actual) ⇒ land.diagnostics
#         (Vcmax, Jmax, J_actual, KM, gamma_star, ca_Pa, ca_mol, patm) ⇒ land.diagnostics
#         (dark_respiration, dark_respiration_mol) ⇒ land.diagnostics
#         (gs_Medlyn, rs, ra, ustar) ⇒ land.diagnostics
#         (phs_transpiration, tran_gs, delta_tr) ⇒ land.diagnostics
#         (temp_leaf_degC, temp_leaf_K, leaf_temp_diff, temp_leaf_balance) ⇒ land.diagnostics
#         (leaf_VPD, leaf_saturated_pressure, air_saturated_pressure, air_actual_pressure) ⇒ land.diagnostics
#         (LE_canopy, H_canopy_flux, Rn_canopy) ⇒ land.diagnostics
#         clm_gb_mol ⇒ land.diagnostics
#         (clm_absorbed_par, clm_obukhov_length, clm_rb, clm_rah) ⇒ land.diagnostics
#         (clm_leaf_iterations, clm_stress_iterations) ⇒ land.diagnostics
#         (clm_hydraulic_converged, clm_ci_converged, clm_coupling_converged) ⇒ land.diagnostics
#         phs_root_water_uptake ⇒ land.fluxes
#     end
#     return land
# end

# function precompute(params::plantHydraulics_CLM, forcing, land, helpers)
#     @unpack_plantHydraulics_CLM params
#     @unpack_nt begin
#         soil_layer_thickness ⇐ land.properties
#         (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇐ land.diagnostics
#         z_zero ⇐ land.constants
#     end
#     depth_from_top_m = z_zero
#     for sl in eachindex(soil_layer_thickness)
#         thickness = soil_layer_thickness[sl]
#         thickness_m = thickness * mm_2_m
#         cumulative_depth_m = depth_from_top_m + thickness_m / 2 # middle point for gravity potential.
#         root_depth_denominator = root_lateral_length + cumulative_depth_m
#         thickness_inv = inv(thickness)
#         @rep_elem thickness_inv ⇒ (D_soil_inv_mm, sl, :soilW)
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

# function compute(params::plantHydraulics_CLM, forcing, land, helpers)
#     @unpack_plantHydraulics_CLM params
#     @unpack_nt begin
#         (f_rn, f_PAR, f_airT_day, f_daytime_seconds, f_canopy_height, f_month_air_temperature) ⇐ forcing
#         (LAI, fAPAR, ambient_CO2, PAW) ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end

#     ### Step 1: atmosphere, canopy structure, and radiation.
#     atm = _clm_atmosphere(params, forcing)
#     LAI_l = max(LAI, minimum_lai) # m2 m-2
#     SAI = stem_to_leaf_area_ratio * LAI_l # m2 m-2
#     H = max(f_canopy_height, minimum_canopy_height) # m

#     # as in plantHydraulics_PHS: net and photosynthetically active radiation are daytime means absorbed by the canopy, W m-2 ground.
#     Rn_ref = at_least_zero(f_rn) * con_1e6 / f_daytime_seconds * fAPAR
#     APAR = at_least_zero(f_PAR) * con_1e6 / f_daytime_seconds * fAPAR
#     par_leaf = APAR / LAI_l # mean absorbed PAR per unit leaf area, W m-2 leaf

#     cair = ambient_CO2 * oftype(o_one, 1e-6) * atm.P_Pa # Pa
#     oair = k_co / con_1e6 * atm.P_Pa # Pa

#     ### Step 2: soil-root hydraulics, as plantHydraulics_PHS: the root water potential is a linear function of the transpiration.
#     land = cal_soil_hydrology(params, forcing, land, helpers)
#     @unpack_nt begin
#         (Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
#         root_over ⇐ land.rootWaterEfficiency
#     end
#     rl = _root_potential_linear(params, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)

#     # the plant is active when there is canopy and at least one soil layer can take up water.
#     plant = (; LAI=LAI_l, SAI, H, LAI_hyd=LAI, rl, active=LAI > minimum_lai && rl.mode == 1, daytime_seconds=f_daytime_seconds)

#     ### Step 3: leaf temperature, ci, plant water potentials, and water stress.
#     sol = _clm_solve_canopy(params, atm, plant, Rn_ref, par_leaf, cair, oair, f_month_air_temperature)
#     gx = sol.gas
#     bio = sol.bio

#     ### Step 4: results, named as in plantHydraulics_PHS.
#     # leaf temperature and energy, W m-2 ground
#     temp_leaf_K = sol.Tv
#     temp_leaf_degC = sol.Tv - deg_2_K
#     leaf_temp_diff = temp_leaf_degC - f_airT_day
#     LE_canopy = sol.LE
#     H_canopy_flux = sol.H
#     Rn_canopy = sol.Rn
#     temp_leaf_balance = sol.Rn - sol.H - sol.LE # energy balance error of the leaf

#     # water potentials, m, and the vulnerability of the leaf and the stem, the water stress of Vcmax is the vulnerability of the leaf.
#     ψ_leaf = ψ_leaf_prev = gx.psi_leaf
#     ψ_stem = gx.psi_stem
#     ψ_root = gx.psi_root
#     β_leaf = cal_vulnerability_curve(params, ψ_leaf, p50_leaf, shape_factor_leaf)
#     β_stem = cal_vulnerability_curve(params, ψ_stem, p50_stem, shape_factor_stem)
#     gpp_f_soilW = β_leaf

#     # photosynthesis: the leaf rates are in umol m-2 s-1, the canopy rates in gC m-2 d-1 over the daytime.
#     ci_Pa = ci_prev = gx.ci
#     to_canopy_gC = LAI_l / con_1e6 * c_mol_mass * f_daytime_seconds
#     gpp_farquhar = gx.ag * to_canopy_gC
#     Ac_gC = gx.ac * to_canopy_gC
#     Aj_gC = gx.aj * to_canopy_gC
#     Ac_mol_m2_s = gx.ac / con_1e6
#     Aj_mol_m2_s = gx.aj / con_1e6
#     dark_respiration_mol = bio.lmr / con_1e6 # mol m-2 s-1, leaf
#     dark_respiration = bio.lmr * to_canopy_gC
#     net_photosynthesis = gpp_farquhar - dark_respiration
#     Vcmax = bio.vcmax / con_1e6
#     Jmax = bio.jmax / con_1e6
#     J_actual = bio.je / con_1e6
#     Vc_actual = Vcmax * β_leaf
#     KM = bio.kc * (1 + oair / bio.ko)
#     gamma_star = bio.gamma_star
#     ca_Pa = cair
#     ca_mol = ambient_CO2 / con_1e6
#     patm = atm.P_Pa

#     # stomatal conductance of CO2 (mol m-2 s-1), stomatal resistance (s m-1), and aerodynamic resistance between the leaf and the air (s m-1)
#     gs_Medlyn = gx.gs / con_1e6 / diffusivity_ratio
#     rs = sol.rs
#     ra = sol.rah + sol.rb / (LAI_l + SAI)
#     ustar = sol.ustar

#     # humidity of the leaf and the air, kPa
#     leaf_VPD = sol.vpd
#     leaf_saturated_pressure = sol.es_leaf
#     air_saturated_pressure = atm.es_air
#     air_actual_pressure = atm.e_air

#     # transpiration, mm d-1: from the stomatal conductance (tran_gs) and from the root water uptake (phs_transpiration), which is
#     # shared by the soil layers and limited by the available water, as in plantHydraulics_PHS.
#     tran_gs = gx.Q * m_to_mm
#     wn, _, _ = _root_layer_weights(params, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     uptake = _root_water_uptake_layers(params, wn, gx.Q, PAW) # m d-1
#     phs_root_water_uptake = uptake * m_to_mm
#     phs_transpiration = sum(phs_root_water_uptake)
#     delta_tr = phs_transpiration - tran_gs

#     # diagnostics without a counterpart in plantHydraulics_PHS
#     clm_gb_mol = sol.gb_mol
#     clm_absorbed_par = APAR
#     clm_obukhov_length = sol.obu
#     clm_rb = sol.rb
#     clm_rah = sol.rah
#     clm_leaf_iterations = sol.iterations
#     clm_stress_iterations = gx.iterations
#     clm_hydraulic_converged = gx.hydraulic_converged
#     clm_ci_converged = gx.ci_converged
#     clm_coupling_converged = sol.converged && gx.hydraulic_converged

#     @pack_nt begin
#         (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇒ land.diagnostics
#         (β_leaf, β_stem, gpp_f_soilW) ⇒ land.diagnostics
#         (ci_prev, ci_Pa) ⇒ land.diagnostics
#         (gpp_farquhar, net_photosynthesis, Ac_gC, Aj_gC, Ac_mol_m2_s, Aj_mol_m2_s, Vc_actual) ⇒ land.diagnostics
#         (Vcmax, Jmax, J_actual, KM, gamma_star, ca_Pa, ca_mol, patm) ⇒ land.diagnostics
#         (dark_respiration, dark_respiration_mol) ⇒ land.diagnostics
#         (gs_Medlyn, rs, ra, ustar) ⇒ land.diagnostics
#         (phs_transpiration, tran_gs, delta_tr) ⇒ land.diagnostics
#         (temp_leaf_degC, temp_leaf_K, leaf_temp_diff, temp_leaf_balance) ⇒ land.diagnostics
#         (leaf_VPD, leaf_saturated_pressure, air_saturated_pressure, air_actual_pressure) ⇒ land.diagnostics
#         (LE_canopy, H_canopy_flux, Rn_canopy) ⇒ land.diagnostics
#         clm_gb_mol ⇒ land.diagnostics
#         (clm_absorbed_par, clm_obukhov_length, clm_rb, clm_rah) ⇒ land.diagnostics
#         (clm_leaf_iterations, clm_stress_iterations) ⇒ land.diagnostics
#         (clm_hydraulic_converged, clm_ci_converged, clm_coupling_converged) ⇒ land.diagnostics
#         phs_root_water_uptake ⇒ land.fluxes
#     end
#     return land
# end

# ### =========================
# # atmosphere: temperature, humidity, and density of the forcing air.
# ### =========================
# # saturation vapor pressure (kPa) and its derivative (kPa K-1), Tetens.
# function _clm_esat(params::plantHydraulics_CLM, T_C)
#     @unpack_plantHydraulics_CLM params
#     es = esat_a * exp(esat_b * T_C / (T_C + esat_c))
#     des = es * esat_b * esat_c / (T_C + esat_c)^2
#     return es, des
# end

# # saturation vapor pressure (kPa), saturation specific humidity (kg kg-1) and its derivative (kg kg-1 K-1), as CLM QSat.
# function _clm_qsat(params::plantHydraulics_CLM, T_C, P_kPa)
#     @unpack_plantHydraulics_CLM params
#     es, des = _clm_esat(params, T_C)
#     denominator = P_kPa - vapor_correction * es
#     qs = eps_ratio * es / denominator
#     dqs = eps_ratio * P_kPa / denominator^2 * des
#     return es, qs, dqs
# end

# function _clm_atmosphere(params::plantHydraulics_CLM, forcing)
#     @unpack_plantHydraulics_CLM params
#     @unpack_nt begin
#         (f_airT_day, f_VPD_day, f_psurf_day, f_ws) ⇐ forcing
#     end
#     Ta_K = f_airT_day + deg_2_K
#     P_kPa = f_psurf_day
#     P_Pa = P_kPa * con_1e3
#     es_air, _ = _clm_esat(params, f_airT_day)
#     e_air = at_least_zero(es_air - at_least_zero(f_VPD_day)) # kPa
#     q_air = eps_ratio * e_air / (P_kPa - vapor_correction * e_air) # kg kg-1
#     rho_air = (P_Pa - vapor_correction * e_air * con_1e3) / (R_air * Ta_K) # kg m-3
#     thv = Ta_K * (1 + virtual_temperature_coef * q_air) # virtual temperature of the forcing air, K
#     ur = max(f_ws, minimum_wind_speed) # m s-1
#     return (; Ta_K, P_kPa, P_Pa, es_air, e_air, q_air, rho_air, thv, ur)
# end

# ### =========================
# # aerodynamics: Monin-Obukhov similarity, as CLM FrictionVelocity.
# ### =========================
# function _clm_stability_momentum(zeta)
#     chik2 = sqrt(1 - 16 * zeta)
#     chik = sqrt(chik2)
#     return 2 * log((1 + chik) / 2) + log((1 + chik2) / 2) - 2 * atan(chik) + oftype(zeta, π) / 2
# end

# function _clm_stability_heat(zeta)
#     chik2 = sqrt(1 - 16 * zeta)
#     return 2 * log((1 + chik2) / 2)
# end

# # initial Monin-Obukhov length and wind speed, as CLM MoninObukIni.
# function _clm_monin_obukhov_init(params::plantHydraulics_CLM, atm, dthv, zldis, z0m)
#     @unpack_plantHydraulics_CLM params
#     wc = oftype(zldis, 0.5)
#     um = dthv >= zero(dthv) ? max(atm.ur, oftype(zldis, 0.1)) : sqrt(atm.ur^2 + wc^2)
#     rib = g_acc * zldis * dthv / (atm.thv * um^2)
#     if rib >= zero(rib)
#         zeta = rib * log(zldis / z0m) / (1 - 5 * min(rib, oftype(rib, 0.19)))
#         zeta = min(zeta_max_stable, max(zeta, oftype(zeta, 0.01)))
#     else
#         zeta = rib * log(zldis / z0m)
#         zeta = max(oftype(zeta, -100), min(zeta, oftype(zeta, -0.01)))
#     end
#     return um, zldis / zeta
# end

# # friction velocity and the heat/vapor transfer coefficient temp1 (= k_von / (ln(z/z0h) - psi_h)), as CLM FrictionVelocity.
# function _clm_friction_velocity(params::plantHydraulics_CLM, um, obu, zldis, z0m)
#     @unpack_plantHydraulics_CLM params
#     c_third = oftype(zldis, 0.333)
#     zeta = zldis / obu
#     if zeta < -zeta_m
#         ustar = k_von * um / (log(-zeta_m * obu / z0m) - _clm_stability_momentum(-zeta_m) + _clm_stability_momentum(z0m / obu) + oftype(zldis, 1.14) * ((-zeta)^c_third - zeta_m^c_third))
#     elseif zeta < zero(zeta)
#         ustar = k_von * um / (log(zldis / z0m) - _clm_stability_momentum(zeta) + _clm_stability_momentum(z0m / obu))
#     elseif zeta <= one(zeta)
#         ustar = k_von * um / (log(zldis / z0m) + 5 * zeta - 5 * z0m / obu)
#     else
#         ustar = k_von * um / (log(obu / z0m) + 5 - 5 * z0m / obu + (5 * log(zeta) + zeta - 1))
#     end

#     # CLM uses the same roughness length for momentum, heat, and vapor over vegetation.
#     z0h = z0m
#     if zeta < -zeta_t
#         temp1 = k_von / (log(-zeta_t * obu / z0h) - _clm_stability_heat(-zeta_t) + _clm_stability_heat(z0h / obu) + oftype(zldis, 0.8) * (zeta_t^(-c_third) - (-zeta)^(-c_third)))
#     elseif zeta < zero(zeta)
#         temp1 = k_von / (log(zldis / z0h) - _clm_stability_heat(zeta) + _clm_stability_heat(z0h / obu))
#     elseif zeta <= one(zeta)
#         temp1 = k_von / (log(zldis / z0h) + 5 * zeta - 5 * z0h / obu)
#     else
#         temp1 = k_von / (log(obu / z0h) + 5 - 5 * z0h / obu + (5 * log(zeta) + zeta - 1))
#     end
#     return ustar, temp1
# end

# # updated Monin-Obukhov length and wind speed from the canopy-air temperature and humidity, as in the CLM canopy iteration.
# function _clm_update_stability(params::plantHydraulics_CLM, atm, ustar, temp1, dth, dqh, zldis)
#     @unpack_plantHydraulics_CLM params
#     tstar = temp1 * dth
#     qstar = temp1 * dqh # CLM uses temp2 = temp1 when the forcing heights and roughness lengths are equal
#     thvstar = tstar * (1 + virtual_temperature_coef * atm.q_air) + virtual_temperature_coef * atm.Ta_K * qstar
#     zeta = zldis * k_von * g_acc * thvstar / (ustar^2 * atm.thv)
#     if zeta >= zero(zeta)
#         zeta = min(zeta_max_stable, max(zeta, oftype(zeta, 0.01)))
#         um = max(atm.ur, oftype(zeta, 0.1))
#     else
#         zeta = max(oftype(zeta, -100), min(zeta, oftype(zeta, -0.01)))
#         wc = convective_beta * (-g_acc * ustar * thvstar * convective_height / atm.thv)^oftype(zeta, 0.333)
#         um = sqrt(atm.ur^2 + wc^2)
#     end
#     return um, zldis / zeta
# end

# ### =========================
# # plant hydraulics, the methods of plantHydraulics_PHS for the parameters of plantHydraulics_CLM: the soil-root conductance, the vulnerability
# # curve, the root, stem, and leaf water potentials, and the root water uptake. The functions without parameters (RootPotentialLinear,
# # _soil_root_conductance, _field_svector, _share_uptake, _brent_root) are shared with plantHydraulics_PHS.
# ### =========================
# function cal_vulnerability_curve(params::plantHydraulics_CLM, psi, psi50, shape_factor)
#     @unpack_plantHydraulics_CLM params
#     ### sigmoid function
#     psi50 = psi50 * m_to_MPa
#     psi = psi * m_to_MPa
#     numerator = 1 + exp(shape_factor * psi50)
#     deminator = 1 + exp(shape_factor * (psi50 - psi))
#     stress = clamp_zero_one(numerator / deminator)
#     return stress
# end

# function cal_soil_hydrology(params::plantHydraulics_CLM, forcing, land, helpers)
#     @unpack_plantHydraulics_CLM params
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

# function _soil_layer_hydrology(::Type{T}, params::plantHydraulics_CLM, vg, LAI, sai, Rsf, froot_to_leaf, z_zero, soilW_l, ΔsoilW_l, D_soil_inv_mm_l, D_soil_cum_m_l, D_root_deno_l, D_soil_m_l, k_sat_l, root_over_l, rsa_l) where {T}
#     @unpack_plantHydraulics_CLM params
#     θ = (soilW_l + ΔsoilW_l) * D_soil_inv_mm_l
#     soil_potential, theta_res, theta_sat, saturation = _soil_matric_potential(params, vg, θ)

#     if root_over_l > z_zero
#         root_fraction = rsa_l / Rsf
#         layer_head = _pos_Inf_not_NaN(soil_potential - D_soil_cum_m_l)
#         k_soil_unsat = k_sat_l * mm_2_m * sqrt(saturation) * (1 - (1 - saturation ^ (1 / vg.mvg)) ^ vg.mvg) ^ 2 # m d-1

#         ### soil conductance based on van-Genuchten model., m d-1
#         Ω_soil = sqrt(oftype(root_radius, π) / 2) * sqrt(root_radius * D_soil_m_l / rsa_l) / k_soil_unsat # m d-1
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

# function _soil_matric_potential(params::plantHydraulics_CLM, vg, θ)
#     @unpack_plantHydraulics_CLM params
#     θ_res = vg.θ_res
#     θ_sat = vg.θ_sat
#     saturation = clamp_zero_one((θ - θ_res) / (θ_sat - θ_res))
#     z_zero = zero(saturation)
#     o_one = one(saturation)

#     inverse_saturation = saturation ^ (-o_one / vg.mvg)
#     if !isfinite(inverse_saturation)
#         return oftype(z_zero, minimum_soil_potential), θ_res, θ_sat, saturation
#     end

#     pressure_term = max(inverse_saturation - o_one, z_zero)
#     ψ_soil_matric = -(pressure_term ^ (o_one / vg.nvg)) / vg.avg
#     if !isfinite(ψ_soil_matric)
#         return oftype(z_zero, minimum_soil_potential), θ_res, θ_sat, saturation
#     end
#     return clamp(ψ_soil_matric, minimum_soil_potential, z_zero), θ_res, θ_sat, saturation
# end

# # normalized root weights of the soil layers: the fraction of the root surface area of the layers that can take up water, sums to 1 (or 0 if no layer can take up water).
# # also returns the soil-to-root resistance (soil + root) of each layer, d m-1, and the sum of the non-normalized weights.
# function _root_layer_weights(params::plantHydraulics_CLM, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     @unpack_plantHydraulics_CLM params
#     T = eltype(ψ_soil)
#     z_zero = zero(T)
#     N = length(ψ_soil)
#     max_Ω = oftype(z_zero, maximum_soil_root_resistance) # d m-1, i.e, root absorb 0.01 mm H2O per day, which is too slow.

#     Ω = SVector{N,T}(ntuple(Val(N)) do sl
#         inv(Κ_soil[sl]) + inv(Κ_root[sl])
#     end)
#     w_valid = SVector{N,T}(ntuple(Val(N)) do sl
#         valid = root_over[sl] > z_zero && root_surface_area[sl] > z_zero && Ω[sl] <= max_Ω && ψ_soil[sl] > minimum_soil_potential
#         valid ? T(fraction_root[sl]) : z_zero
#     end)
#     sum_w = sum(w_valid)
#     wn = iszero(sum_w) ? w_valid : w_valid / sum_w
#     return wn, Ω, sum_w
# end

# # root water potential as a linear function of the transpiration: ψ_root = A - B * Q.
# # Each layer takes up Q * wn[sl], so the layer root potential is ψ_soil - Ω * Q * wn / root_surface_area, and ψ_root is the weighted mean of them.
# function _root_potential_linear(params::plantHydraulics_CLM, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     @unpack_plantHydraulics_CLM params
#     z_zero = zero(eltype(ψ_soil))

#     if all(k -> abs(k) <= minimum_conductance, Κ_soil_root)
#         return RootPotentialLinear(0, sum(ψ_soil) / length(ψ_soil), z_zero)
#     end

#     wn, Ω, sum_w = _root_layer_weights(params, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
#     if iszero(sum_w)
#         return RootPotentialLinear(2, z_zero, z_zero)
#     end

#     sum_a = sum_b = z_zero
#     for sl in eachindex(ψ_soil)
#         if wn[sl] > z_zero
#             sum_a += ψ_soil[sl] * wn[sl]
#             sum_b += Ω[sl] * wn[sl] * wn[sl] / root_surface_area[sl]
#         end
#     end
#     return RootPotentialLinear(1, sum_a, sum_b)
# end

# # root water uptake of each soil layer, m d-1.
# # Demand Q is shared by the weights wn. A layer cannot take up more than its available water (PAW), and the shortage is shared by the layers that still have available water.
# # The sum of the uptake equals Q, unless the total available water of the rooted layers is smaller than Q.
# function _root_water_uptake_layers(params::plantHydraulics_CLM, wn, Q, PAW)
#     @unpack_plantHydraulics_CLM params
#     T = eltype(wn)
#     N = length(wn)
#     capacity = SVector{N,T}(ntuple(sl -> at_least_zero(T(PAW[sl])) * mm_2_m, Val(N))) # m d-1
#     uptake = zero(wn)
#     for _ in 1:N
#         remaining = Q - sum(uptake)
#         remaining > zero(T) || break
#         uptake_new = _share_uptake(wn, capacity, uptake, remaining)
#         uptake_new == uptake && break
#         uptake = uptake_new
#     end
#     return uptake
# end

# function _plant_hydraulic(params::plantHydraulics_CLM, rl, H_canopy, LAI, Q)
#     psi_root = _root_water_potential(params, rl, Q)
#     psi_stem = _stem_water_potential(params, H_canopy, LAI, psi_root, Q)
#     psi_leaf = _leaf_water_potential(params, LAI, psi_stem, Q)
#     return psi_root, psi_stem, psi_leaf
# end

# function _root_water_potential(params::plantHydraulics_CLM, rl, Q)
#     @unpack_plantHydraulics_CLM params
#     z_zero = zero(rl.A)
#     if rl.mode == 0
#         return rl.A
#     elseif rl.mode == 2
#         return oftype(z_zero, minimum_root_potential)
#     end
#     psi_root = rl.A - rl.B * Q
#     if !isfinite(psi_root)
#         return oftype(z_zero, minimum_root_potential)
#     end
#     psi_root = min(max(psi_root, minimum_root_potential), z_zero)
#     return psi_root
# end

# function _stem_water_potential(params::plantHydraulics_CLM, H_canopy, LAI, psi_root, Q)
#     @unpack_plantHydraulics_CLM params
#     beta_stem_root = cal_vulnerability_curve(params, psi_root, p50_stem, shape_factor_stem)
#     SAI = stem_to_leaf_area_ratio * LAI
#     if LAI > minimum_lai && H_canopy > zero(H_canopy) && beta_stem_root > minimum_water_stress
#         stem_conductance = k_stem_max * beta_stem_root / H_canopy
#         psi_stem = psi_root - H_canopy - Q / SAI / stem_conductance
#     else
#         psi_stem = psi_root - H_canopy
#     end
#     return psi_stem
# end

# function _leaf_water_potential(params::plantHydraulics_CLM, LAI, psi_stem, Q)
#     @unpack_plantHydraulics_CLM params
#     beta_leaf_stem = cal_vulnerability_curve(params, psi_stem, p50_leaf, shape_factor_leaf)
#     if LAI > minimum_lai && beta_leaf_stem > minimum_water_stress
#         leaf_conductance = k_leaf_max * beta_leaf_stem
#         psi_leaf = psi_stem - Q / LAI / leaf_conductance
#     else
#         psi_leaf = psi_stem
#     end
#     return psi_leaf
# end

# ### =========================
# # leaf biochemistry at the leaf temperature, CLM5 PhotosynthesisMod (C3).
# ### =========================
# function _clm_ft(params::plantHydraulics_CLM, tl, activation_energy)
#     @unpack_plantHydraulics_CLM params
#     return exp(activation_energy / (k_R * tk_ref) * (1 - tk_ref / tl))
# end

# function _clm_fth(params::plantHydraulics_CLM, tl, hd, se, scale_factor)
#     @unpack_plantHydraulics_CLM params
#     return scale_factor / (1 + exp((-hd + se * tl) / (k_R * tl)))
# end

# function _clm_fth25(params::plantHydraulics_CLM, hd, se)
#     @unpack_plantHydraulics_CLM params
#     return 1 + exp((-hd + se * tk_ref) / (k_R * tk_ref))
# end

# # canopy-mean leaf properties of the big leaf: the Vcmax25, Jmax25, TPU25, and respiration at the top of the canopy are scaled by the
# # canopy-integrated nitrogen profile exp(-kn * L), where kn is derived from Vcmax25 as in CLM.
# function _clm_leaf_biochemistry(params::plantHydraulics_CLM, Tv, t_accl_C, LAI, par_leaf, P_Pa)
#     @unpack_plantHydraulics_CLM params
#     t_accl = clamp(t_accl_C, temp_month_min, temp_month_max)

#     Vcmax25_umol = Vcmax25 * con_1e6 # umol m-2 s-1
#     kn = exp(kn_slope * Vcmax25_umol + kn_intercept)
#     kn_lai = kn * LAI
#     nscaler = kn_lai > oftype(kn_lai, 1e-6) ? (1 - exp(-kn_lai)) / kn_lai : one(kn_lai)

#     vcmax25 = Vcmax25_umol * nscaler
#     jmax25 = Jmax25_Vcmax25_ratio * vcmax25
#     tpu25 = tpu_vcmax_ratio * vcmax25
#     lmr25 = vcmax25 * rate_dark

#     vcmaxse = delta_S_intercept - delta_S_slope * t_accl
#     jmaxse = jmaxse_intercept - jmaxse_slope * t_accl
#     vcmaxc = _clm_fth25(params, Ed, vcmaxse)
#     jmaxc = _clm_fth25(params, Ed, jmaxse)
#     tpuc = _clm_fth25(params, Ed, vcmaxse)
#     lmrc = _clm_fth25(params, lmrhd, lmrse)

#     vcmax = vcmax25 * _clm_ft(params, Tv, vcmaxha) * _clm_fth(params, Tv, Ed, vcmaxse, vcmaxc)
#     jmax = jmax25 * _clm_ft(params, Tv, jmaxha) * _clm_fth(params, Tv, Ed, jmaxse, jmaxc)
#     tpu = tpu25 * _clm_ft(params, Tv, tpuha) * _clm_fth(params, Tv, Ed, vcmaxse, tpuc)
#     lmr = lmr25 * _clm_ft(params, Tv, lmrha) * _clm_fth(params, Tv, lmrhd, lmrse, lmrc)
#     lmr = lmr * min(lmr_lai_factor * exp(lmr_lai_exponent * LAI), one(lmr))

#     # kc, ko, and the compensation point scale with the air pressure, Pa.
#     pressure_ratio = P_Pa / k_Po
#     kc = kc25 * pressure_ratio * _clm_ft(params, Tv, dhac)
#     ko = ko25 * pressure_ratio * _clm_ft(params, Tv, dhao)
#     gamma_star = gs25_0 * pressure_ratio * _clm_ft(params, Tv, ha)

#     # no photosynthetic capacity without light, as CLM at night.
#     daylight = par_leaf > zero(par_leaf)
#     if daylight
#         # electron transport rate, non-rectangular hyperbola of the absorbed photon flux and Jmax.
#         qabs = (1 - fnps) / 2 * par_leaf * par_ppfd
#         r1, r2 = _clm_quadratic_roots(theta_psii, -(qabs + jmax), qabs * jmax)
#         je = min(r1, r2)
#         lmr = lmr * light_inhibition
#     else
#         vcmax = tpu = je = zero(vcmax)
#     end
#     return (; vcmax, jmax, tpu, lmr, kc, ko, gamma_star, je)
# end

# # roots of a x^2 + b x + c = 0, as CLM quadratic.
# function _clm_quadratic_roots(a, b, c)
#     discriminant = max(b^2 - 4 * a * c, zero(b))
#     q = b >= zero(b) ? -(b + sqrt(discriminant)) / 2 : -(b - sqrt(discriminant)) / 2
#     r1 = q / a
#     r2 = iszero(q) ? zero(q) : c / q
#     return r1, r2
# end

# ### =========================
# # Farquhar photosynthesis, Medlyn stomatal conductance, and ci.
# ### =========================
# # the water stress b (the vulnerability of the leaf, as plantHydraulics_PHS) scales Vcmax; the leaf respiration is not scaled.
# function _clm_farquhar(params::plantHydraulics_CLM, bio, oair, ci, b)
#     @unpack_plantHydraulics_CLM params
#     z_zero = zero(ci)
#     ci_gap = max(ci - bio.gamma_star, z_zero)
#     ac = b * bio.vcmax * ci_gap / (ci + bio.kc * (1 + oair / bio.ko))
#     aj = bio.je * ci_gap / (4 * ci + 8 * bio.gamma_star)
#     ap = 3 * bio.tpu

#     r1, r2 = _clm_quadratic_roots(theta_cj, -(ac + aj), ac * aj)
#     ai = min(r1, r2)
#     r1, r2 = _clm_quadratic_roots(theta_ip, -(ai + ap), ai * ap)
#     ag = max(z_zero, min(r1, r2))
#     an = ag - bio.lmr
#     return ag, an, ac, aj, ap
# end

# # Medlyn conductance (umol m-2 s-1) from the net assimilation, solving the quadratic of CLM ci_func_PHS.
# function _clm_medlyn_gs(params::plantHydraulics_CLM, an, cair, P_Pa, gb_mol, vpd)
#     @unpack_plantHydraulics_CLM params
#     if an < zero(an)
#         return max(g0 * con_1e6, minimum_gs)
#     end
#     cs = max(cair - boundary_co2_ratio / gb_mol * an * P_Pa, minimum_cs)
#     term = diffusivity_ratio * an / (cs / P_Pa * con_1e6) # mol m-2 s-1
#     bquad = -(2 * (g0 + term) + (g1 * term)^2 / (gb_mol / con_1e6 * vpd))
#     cquad = g0^2 + (2 * g0 + term * (1 - g1^2 / vpd)) * term
#     r1, r2 = _clm_quadratic_roots(one(bquad), bquad, cquad)
#     return max(r1, r2) * con_1e6
# end

# # CLM5 ci_func_PHS: f(ci) = ci - (cair - an * P * (1.4 gs + 1.6 gb) / (gb * gs)), a function of the assimilation and conductance at ci.
# function _clm_ci_function(params::plantHydraulics_CLM, bio, leaf, ci, b)
#     @unpack_plantHydraulics_CLM params
#     ag, an, ac, aj, ap = _clm_farquhar(params, bio, leaf.oair, ci, b)
#     gs = _clm_medlyn_gs(params, an, leaf.cair, leaf.P_Pa, leaf.gb_mol, leaf.vpd)
#     if an < zero(an)
#         fval = zero(an) # CLM exits the iteration with gs at its minimum.
#     elseif gs > zero(gs)
#         fval = ci - leaf.cair + an * leaf.P_Pa * (boundary_co2_ratio * gs + diffusivity_ratio * leaf.gb_mol) / (leaf.gb_mol * gs)
#     else
#         fval = ci - leaf.cair
#     end
#     return fval, gs, ag, an, ac, aj, ap
# end

# # CLM5 hybrid solver for ci: secant iterations, switched to Brent's method once the root is bracketed.
# function _clm_solve_ci(params::plantHydraulics_CLM, bio, leaf, b, ci_guess)
#     @unpack_plantHydraulics_CLM params
#     ci_upper = leaf.cair
#     ci_lower = oftype(leaf.cair, 1e-3)
#     fci = ci -> _clm_ci_function(params, bio, leaf, ci, b)[1]

#     x1 = clamp(ci_guess, ci_lower, ci_upper)
#     x0 = clamp(oftype(x1, 0.99) * x1, ci_lower, ci_upper)
#     x0 == x1 && (x0 = x1 / 2)
#     f0 = fci(x0)
#     f1 = fci(x1)
#     ci = x1
#     converged = false
#     best_x, best_f = abs(f0) < abs(f1) ? (x0, abs(f0)) : (x1, abs(f1))
#     for _ in 1:Int(Ci_max_iterations)
#         if abs(f1) < ci_residual_tolerance
#             ci, converged = x1, true
#             break
#         elseif abs(f0) < ci_residual_tolerance
#             ci, converged = x0, true
#             break
#         end
#         dx = f1 == f0 ? (x1 + x0) / 2 - x1 : -f1 * (x1 - x0) / (f1 - f0)
#         x_next = clamp(x1 + dx, ci_lower, ci_upper)
#         x_next == x1 && break # stalled at a bound without a root
#         x0, f0 = x1, f1
#         x1 = x_next
#         f1 = fci(x1)
#         if abs(f1) < best_f
#             best_x, best_f = x1, abs(f1)
#         end
#         if abs(x1 - x0) < convergence_ci || abs(f1) < ci_residual_tolerance
#             ci, converged = x1, true
#             break
#         end
#         if f1 * f0 < zero(f0)
#             ci = _brent_root(fci, x0, x1, f0, f1, convergence_ci, ci_residual_tolerance, Int(Ci_max_iterations))
#             converged = true
#             break
#         end
#         ci = best_x
#     end
#     ci = max(ci, ci_lower)
#     fval, gs, ag, an, ac, aj, ap = _clm_ci_function(params, bio, leaf, ci, b)
#     return (; ci, gs, ag, an, ac, aj, ap, fval, converged)
# end

# ### =========================
# # transpiration demand and the coupling of ci, transpiration, plant water potentials, and water stress.
# ### =========================
# # transpiration demand (m s-1, per ground area) at the stomatal conductance gs (umol m-2 s-1), CLM getqflx.
# function _clm_transpiration_demand(leaf, gs)
#     gs > zero(gs) || return zero(gs)
#     return leaf.Dq * leaf.gb_mol * gs / (leaf.gb_mol + gs)
# end

# # CLM5 hybrid_PHS structure with the water stress of plantHydraulics_PHS. The water stress b is the vulnerability curve of the leaf water
# # potential and scales Vcmax. For a given b, ci and the stomatal conductance are solved; the stomatal conductance gives the transpiration,
# # the transpiration gives the root, stem, and leaf water potentials, and the leaf water potential gives the new b. The leaf water potential is
# # relaxed with psi_leaf_damping, as in plantHydraulics_PHS.
# function _clm_gas_exchange(params::plantHydraulics_CLM, bio, leaf, plant, psi_leaf0, ci_guess)
#     @unpack_plantHydraulics_CLM params
#     psi_leaf = psi_leaf0
#     b = cal_vulnerability_curve(params, psi_leaf, p50_leaf, shape_factor_leaf)
#     sol = _clm_solve_ci(params, bio, leaf, b, ci_guess)
#     hydraulic_converged = !plant.active
#     iterations = 0

#     for iter in 1:(plant.active ? Int(STEMMUS_max_iterations) : 0)
#         iterations = iter
#         sol = _clm_solve_ci(params, bio, leaf, b, sol.ci)
#         Q = _clm_transpiration_demand(leaf, sol.gs) * plant.daytime_seconds # m d-1
#         _, _, psi_leaf_new = _plant_hydraulic(params, plant.rl, plant.H, plant.LAI_hyd, Q)
#         hydraulic_converged = abs(psi_leaf - psi_leaf_new) < convergence_water_potential
#         psi_leaf = psi_leaf + psi_leaf_damping * (psi_leaf_new - psi_leaf)
#         b = cal_vulnerability_curve(params, psi_leaf, p50_leaf, shape_factor_leaf)
#         hydraulic_converged && break
#     end

#     # ci, conductance, transpiration, and potentials of the final water stress.
#     sol = _clm_solve_ci(params, bio, leaf, b, sol.ci)
#     Q = _clm_transpiration_demand(leaf, sol.gs) * plant.daytime_seconds # m d-1
#     psi_root, psi_stem, psi_leaf_Q = _plant_hydraulic(params, plant.rl, plant.H, plant.LAI_hyd, Q)
#     return (; ci=sol.ci, gs=sol.gs, b, ag=sol.ag, an=sol.an, ac=sol.ac, aj=sol.aj, ap=sol.ap,
#         psi_leaf=psi_leaf_Q, psi_stem, psi_root, Q, ci_converged=sol.converged, hydraulic_converged, iterations)
# end

# ### =========================
# # leaf temperature iteration, CLM5 CanopyFluxes.
# ### =========================
# # The leaf temperature is updated with one Newton step of the linearised leaf energy balance per iteration, while the aerodynamic
# # resistances (Monin-Obukhov), the photosynthesis, ci, stomatal conductance, and hydraulic stress are re-evaluated at the new
# # temperature. The iteration stops when two consecutive temperature changes are below dtmin and the latent heat flux change
# # is below dlemin. Ground sensible and latent heat are not part of the canopy-air exchange: SINDBAD has no soil temperature
# # in this process and soil evaporation is a separate process.
# function _clm_solve_canopy(params::plantHydraulics_CLM, atm, plant, Rn_ref, par_leaf, cair, oair, t_accl_C)
#     @unpack_plantHydraulics_CLM params
#     LAI = plant.LAI
#     SAI = plant.SAI
#     z_zero = zero(atm.Ta_K)
#     o_one = one(atm.Ta_K)

#     z0m = z0m_ratio * plant.H
#     displa = displacement_ratio * plant.H
#     zldis = z_ref + z0m # reference height above the displacement height, m
#     emv = 1 - exp(-(LAI + SAI) / canopy_extinction_mu)
#     bir = -(2 - emv - ground_emissivity) * sigma_SB # W m-2 K-4
#     Ta = atm.Ta_K

#     Tv = Ta
#     taf = Ta
#     qaf = atm.q_air
#     um, obu = _clm_monin_obukhov_init(params, atm, (taf - atm.Ta_K) * (1 + virtual_temperature_coef * qaf), zldis, z0m)
#     obuold = z_zero
#     nmozsgn = 0
#     del = z_zero
#     efeb = z_zero

#     _, _, psi_leaf = _plant_hydraulic(params, plant.rl, plant.H, plant.LAI_hyd, z_zero) # without transpiration
#     ci = ci_initial_fraction * cair

#     # results of the last iteration; without an active canopy there is no gas exchange and no transpiration.
#     psi_root, psi_stem, _ = _plant_hydraulic(params, plant.rl, plant.H, plant.LAI_hyd, z_zero)
#     gx = (; ci, gs=z_zero, b=cal_vulnerability_curve(params, psi_leaf, p50_leaf, shape_factor_leaf), ag=z_zero, an=z_zero, ac=z_zero, aj=z_zero, ap=z_zero,
#         psi_leaf, psi_stem, psi_root, Q=z_zero, ci_converged=true, hydraulic_converged=true, iterations=0)
#     bio = _clm_leaf_biochemistry(params, Tv, t_accl_C, LAI, par_leaf, atm.P_Pa)
#     es_leaf = atm.es_air
#     vpd = max(es_leaf - atm.e_air, minimum_vpd)
#     rs = atm.P_Pa / (k_R * Ta) * con_1e6 / minimum_gs # s m-1, closed stomata
#     ustar = temp1 = rb = rah = z_zero
#     efe = E_evap = E_hyd = H_flux = Rn = z_zero
#     gb_mol = z_zero
#     iterations = 0
#     converged = !plant.active # an inactive canopy has nothing to iterate

#     n_iter = plant.active ? Int(Tleaf_max_iterations) + 1 : 0
#     for iter in 1:n_iter
#         iterations = iter
#         tlbef = Tv
#         del2 = del

#         ### aerodynamic resistances.
#         ustar, temp1 = _clm_friction_velocity(params, um, obu, zldis, z0m)
#         ram1 = um / ustar^2
#         rah = inv(temp1 * ustar)
#         raw = rah
#         uaf = um * sqrt(inv(ram1 * um))
#         rb = inv(boundary_layer_coefficient / (sqrt(uaf) * sqrt(leaf_width)) * uaf)

#         ### humidity at the leaf and in the canopy air.
#         es_leaf, qsatl, qsatldT = _clm_qsat(params, tlbef - deg_2_K, atm.P_kPa)
#         cf_gas = atm.P_Pa / (k_R * Ta) * con_1e6 # umol m-3, CLM conversion between conductance in m s-1 and umol m-2 s-1
#         gb_mol = cf_gas / rb
#         e_af = min(atm.P_kPa * qaf / eps_ratio, es_leaf)
#         vpd = max(es_leaf - e_af, minimum_vpd)
#         delta_q = qsatl - qaf
#         Dq = delta_q > z_zero ? atm.rho_air / rho_water * delta_q * canopy_dry_fraction * (LAI + SAI) / cf_gas : z_zero

#         ### photosynthesis, ci, stomatal conductance, hydraulic stress, and water stress at the current leaf temperature.
#         bio = _clm_leaf_biochemistry(params, tlbef, t_accl_C, LAI, par_leaf, atm.P_Pa)
#         leaf = (; cair, oair, P_Pa=atm.P_Pa, vpd, gb_mol, Dq)
#         gx = _clm_gas_exchange(params, bio, leaf, plant, psi_leaf, ci)
#         psi_leaf = gx.psi_leaf
#         ci = gx.ci

#         ### conductances of the canopy air.
#         wta = inv(rah)
#         wtl = (LAI + SAI) / rb
#         wtshi = inv(wta + wtl)
#         wta0 = wta * wtshi # air
#         wtl0 = wtl * wtshi # leaf

#         E_hyd = at_least_zero(gx.Q) / plant.daytime_seconds * rho_water # kg m-2 s-1, transpiration
#         rs = cf_gas / gx.gs # s m-1
#         rppdry = canopy_dry_fraction * rb / (rb + rs)
#         efpot = atm.rho_air * wtl * delta_q
#         rpp = efpot > z_zero ? min(rppdry, E_hyd / efpot) : o_one

#         wtlq = (LAI + SAI) / rb * rpp
#         wtaq = inv(raw)
#         wtsqi = inv(wtaq + wtlq)
#         wtlq0 = wtlq * wtsqi
#         wtaq0 = wtaq * wtsqi

#         ### leaf energy balance, linearised in the leaf temperature.
#         dc1 = atm.rho_air * cp * wtl
#         dc2 = hvap * atm.rho_air * wtlq
#         efsh = dc1 * wta0 * (tlbef - Ta)
#         efe = dc2 * wtaq0 * (qsatl - atm.q_air)

#         # the latent heat flux is limited when its sign changes between iterations.
#         erre = z_zero
#         if efe * efeb < z_zero
#             efeold = efe
#             efe = latent_flux_damping * efeold
#             erre = efe - efeold
#         end

#         net_radiation = Rn_ref + bir * (tlbef^4 - Ta^4)
#         dt_veg = (net_radiation - efsh - efe) / (-4 * bir * tlbef^3 + dc1 * wta0 + dc2 * wtaq0 * qsatldT)
#         Tv = tlbef + dt_veg
#         del = abs(dt_veg)
#         err = z_zero
#         if del > delmax
#             dt_veg = delmax * dt_veg / del
#             Tv = tlbef + dt_veg
#             err = Rn_ref + bir * (tlbef^3 * (tlbef + 4 * dt_veg) - Ta^4) - (efsh + dc1 * wta0 * dt_veg) - (efe + dc2 * wtaq0 * qsatldT * dt_veg)
#         end

#         ### fluxes from the leaf to the canopy air; the evaporation cannot exceed the plant transpiration (no canopy water).
#         efpot_new = atm.rho_air * wtl * (wtaq0 * (qsatl + qsatldT * dt_veg) - wtaq0 * atm.q_air)
#         E_evap = rpp * efpot_new
#         ecidif = max(z_zero, E_evap - E_hyd)
#         E_evap = min(E_evap, E_hyd)
#         # the energy of both limits is added to the sensible heat.
#         H_flux = efsh + dc1 * wta0 * dt_veg + err + erre + hvap * ecidif

#         ### canopy air temperature, humidity, and stability for the next iteration.
#         _, qsatl_new, _ = _clm_qsat(params, Tv - deg_2_K, atm.P_kPa)
#         taf = wta0 * Ta + wtl0 * Tv
#         qaf = wtlq0 * qsatl_new + wtaq0 * atm.q_air
#         um, obu = _clm_update_stability(params, atm, ustar, temp1, Ta - taf, atm.q_air - qaf, zldis)
#         if obuold * obu < z_zero
#             nmozsgn += 1
#         end
#         if nmozsgn >= 4
#             obu = zldis / oftype(zldis, -0.01)
#         end
#         obuold = obu

#         ### convergence of the leaf temperature and the latent heat flux.
#         if iter > Int(leaf_min_iterations)
#             dele = abs(efe - efeb)
#             efeb = efe
#             det = max(del, del2)
#             if det < dtmin && dele < dlemin
#                 converged = true
#                 break
#             end
#         end
#     end

#     Rn = Rn_ref + bir * (Tv^4 - Ta^4)
#     LE = hvap * E_evap
#     return (; Tv, gas=gx, bio, Rn, LE, H=H_flux, ustar, obu, rb, rah, rs, vpd, es_leaf, gb_mol, iterations, converged)
# end

# purpose(::Type{plantHydraulics_CLM}) = "CLM5 leaf temperature and ci with the plant hydraulic system (PHS) and the water stress of plantHydraulics_PHS, for a single big leaf."

# @doc """

# $(getModelDocString(plantHydraulics_CLM))

# ---

# # Extended help

# The process takes the leaf temperature iteration, the aerodynamics, the photosynthesis, the stomatal conductance, and the ci solution from
# CLM5 (`CanopyFluxesMod`, `PhotosynthesisMod`), and the plant hydraulic system and the water stress from `plantHydraulics_PHS`, for a single
# big leaf at the daily time step. All quantities are daytime means; the daily fluxes are the daytime-mean rates times `f_daytime_seconds`.
# The names of the parameters and the outputs follow `plantHydraulics_PHS`, so that `gpp_PHS`, `transpiration_PHS`, and `rootWaterUptake_PHS`
# can be used with this process.

# # Solution procedure
#  1. The soil-root conductance of each layer is the soil (van Genuchten) and the root conductance in series, and the root water potential is a
#     linear function of the transpiration, `ψ_root = A - B Q` (`cal_soil_hydrology`, `_root_potential_linear` of PHS).
#  2. Leaf temperature (outer loop, CLM `ITERATION`). Per iteration: Monin-Obukhov aerodynamics, then the gas exchange at the current leaf
#     temperature, then one Newton step of the linearised leaf energy balance limited to `delmax`, then the canopy-air temperature,
#     humidity, and stability. It stops when two consecutive temperature changes are below `dtmin` and the latent heat change is below `dlemin`.
#  3. Gas exchange (CLM `hybrid_PHS` structure, PHS water stress). The water stress `β_leaf` is the vulnerability curve of the leaf water potential and
#     scales Vcmax. For a given `β_leaf`, ci is solved (secant iterations, then Brent's method, on `ci - cair + an P (1.4 gs + 1.6 gb) / (gb gs)`) and gs
#     follows the Medlyn model; gs gives the transpiration, the transpiration gives the root, stem, and leaf water potentials
#     (`_plant_hydraulic` of PHS), and the leaf water potential, relaxed with `psi_leaf_damping`, gives the new `β_leaf`. The loop stops when the
#     leaf water potential changes by less than `convergence_water_potential`.
#  4. The root water uptake of each layer is the transpiration shared by the root weights and limited by the available water (`PAW`), as in PHS.

# # Differences to CLM5
#  - One big leaf instead of sunlit and shaded leaves; Vcmax25 at the top of the canopy is scaled by the canopy-integrated nitrogen profile.
#  - C3 photosynthesis and Medlyn stomatal conductance only.
#  - The plant hydraulic system and the water stress are those of PHS (sigmoid vulnerability curves of the leaf, stem, and root, linear root potential,
#    no Newton solution of the continuum, no hydraulic redistribution), not the CLM5 Weibull curves and `calcstress`. The water stress scales Vcmax only.
#  - Net radiation of the canopy is the SINDBAD forcing `f_rn` times `fAPAR`, taken at `T_leaf = T_air`; the leaf temperature changes it with the
#    longwave term `bir (T_leaf^4 - T_air^4)` of CLM.
#  - No ground sensible and latent heat in the canopy air, and no canopy water: the interception is a separate process.
#  - The hydraulics use the transpiration spread over the day (m d-1), as `plantHydraulics_PHS`.

# # Functions shared with plantHydraulics_PHS
#  The functions that need the parameters (`cal_vulnerability_curve`, `cal_soil_hydrology`, `_soil_layer_hydrology`, `_soil_matric_potential`,
#  `_root_layer_weights`, `_root_potential_linear`, `_root_water_uptake_layers`, `_plant_hydraulic`, `_root_water_potential`, `_stem_water_potential`,
#  `_leaf_water_potential`) are methods of the same functions for `plantHydraulics_CLM`, with the same logic. The functions without parameters
#  (`RootPotentialLinear`, `_soil_root_conductance`, `_field_svector`, `_share_uptake`, `_brent_root`, `_pos_Inf_not_NaN`) are defined in the PHS file.

# # References
#  1. Kennedy, D. et al. Implementing plant hydraulics in the Community Land Model, version 5. Journal of Advances in Modeling Earth Systems 11, 485-513 (2019).
#  2. Lawrence, D. M. et al. The Community Land Model Version 5: Description of new features, benchmarking, and impact of forcing uncertainty. Journal of Advances in Modeling Earth Systems 11, 4245-4287 (2019).
#  3. Medlyn, B. E. et al. Reconciling the optimal and empirical approaches to modelling stomatal conductance. Global Change Biology 17, 2134-2144 (2011).
#  4. Bonan, G. B. et al. Improving canopy processes in the Community Land Model version 4 (CLM4) using global flux fields empirically inferred from FLUXNET data. Journal of Geophysical Research 116, G02014 (2011).

# *Versions*
#  - 1.0 on 28.10.2026 [jzhou]
# """
# plantHydraulics_CLM
