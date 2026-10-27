export plantHydraulics_PHS

using Roots

_not_Inf_NaN(value, fallback) = isfinite(value) ? value : oftype(value, fallback)

function _pos_Inf_not_NaN(value)
    if isfinite(value)
        return value
    elseif isnan(value)
        return zero(value)
    end
    return copysign(floatmax(typeof(value)), value)
end

_non_negative_Finite(value) = max(_pos_Inf_not_NaN(value), zero(value))

function _soil_root_conductance(k1, k2)
    k1 = _non_negative_Finite(k1)
    k2 = _non_negative_Finite(k2)

    if iszero(k1) || iszero(k2)
        return zero(k1 + k2)
    end

    inverse_sum = inv(k1) + inv(k2)
    total_conductance = inv(inverse_sum)

    if isfinite(total_conductance)
        return total_conductance
    end

    low = min(k1, k2)
    high = max(k1, k2)

    return low / (one(low) + low / high)
end

_field_svector(layers, ::Val{K}, ::Val{N}, ::Type{T}) where {K,N,T} = SVector{N,T}(ntuple(i -> T(layers[i][K]), Val(N)))

struct RootPotentialLinear{T}
    mode::Int  # 0: all soil-root conductances negligible, 1: layer weighted solution, 2: no valid layer
    A::T
    B::T
end
RootPotentialLinear(mode::Int, A, B) = RootPotentialLinear(mode, promote(A, B)...)

#! format: off
@bounds @describe @units @timescale @with_kw struct plantHydraulics_PHS{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36,T37,T38,T39,T40,T41,T42,T43,T44,T45,T46,T47,T48,T49,T50,T51,T52,T53,T54,T55,T56,T57,T58,T59,T60,T61,T62,T63,T64,T65,T66,T67,T68,T69,T70,T71,T72,T73,T74,T75,T76,T77,T78,T79,T80,T81,T82,T83,T84,T85,T86,T87,T88,T89,T90,T91,T92,T93,T94,T95,T96,T97,T98,T99,T100,T101,T102,T103,T104,T105,T106,T107,T108,T109,T110,T111,T112,T113,T114,T115,T116,T117,T118,T119,T120,T121,T122,T123,T124,T125,T126,T127,T128,T129,T130,T131,T132,T133} <: plantHydraulics
    # root params
    root_radius::T1 = 1.5e-3 | (1.0e-5, 1.0e-2) | "fine-root radius used to infer root spacing from SINDBAD root surface area" | "m" | ""
    biomass_to_carbon::T2 = 0.488 | (0.1, 1.0) | "root carbon per unit root dry biomass" | "gC gDM-1" | ""
    root_density::T3 = 2.5e5 | (1.0e3, 1.0e6) | "root tissue dry-matter density" | "gDM m-3" | ""
    root_lateral_length::T4 = 0.25 | (1.0e-3, 10.0) | "average coarse-root lateral length" | "m" | ""
    stem_to_leaf_area_ratio::T5 = 0.1 | (0.01, 0.9) | "stem area index to leaf area index ratio" | "" | ""

    # plant hydraulic traits
    p50_leaf::T6 = -67.67 | (-500, -10.0) | "stem-to-leaf water potential at 50 percent conductivity loss" | "m" | ""
    p50_stem::T7 = -342.51 | (-1500, -10.0) | "root-to-stem water potential at 50 percent conductivity loss" | "m" | ""
    p50_root::T8 = -30.0 | (-1000, -10.0) | "soil-root water potential at 50 percent conductivity loss" | "m" | ""

    # plant hydraulic vulnerability-curve factors
    shape_factor_leaf::T9 = 1.98 | (0.5, 5.0) | "leaf PHS vulnerability-curve shape factor" | "MPa-1" | ""
    shape_factor_stem::T10 = 1.98 | (0.5, 5.0) | "stem PHS vulnerability-curve shape factor" | "MPa-1" | ""
    shape_factor_root::T11 = 0.8 | (0.5, 5.0) | "root PHS vulnerability-curve shape factor" | "MPa-1" | ""

    # hydraulic conductance traits
    k_root_max::T12 = 1.73e-4 | (8.64e-6, 8.64e-2) | "maximum root hydraulic conductivity" | "m d-1" | ""
    k_stem_max::T13 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum stem hydraulic conductivity" | "m d-1" | ""
    k_leaf_max::T14 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum leaf hydraulic conductance" | "d-1" | ""

    # photosynthesis parameters
    Jmax25_Vcmax25_ratio::T15 = 1.67 | (1.5, 2.1) | "The ratio between the maximum electron transport rate, normalised to 25 ◦C to Vcmax25" | "dimensionless" | ""
    Vcmax25::T16 = 5e-5 | (1e-5, 1.5e-4) | "Maximum rate of carboxylation, normalised to 25 ◦C. Ratio between J/V is about 1.5 to 2.1." | "molC m-2 s-1" | ""

    # dark-respiration
    rate_dark::T17 = 0.01 | (0.005, 0.05) | "dark-respiration rate per unit carboxylation capacity" | "" | ""
    k_Nitrogen::T18 = 0.2 | (0.1, 0.4) | "decay coefficient for nitrogen on dark respiration" | "" | ""

    # photorespiratory compensation point  parameters
    ha::T19 = 37830.0 | (1e-2, 1e7) | "Activation energy for gamma star" | "J mol-1" | ""
    gs25_0::T20 = 4.332 | (4.0, 5.0) | "Photorespiratory compensation point" | "Pa" | ""

    # Michaelis-Menten constants
    k_co::T21 = 209476 | (1e-2, 1e7) | "Michaelis–Menten coefficient params" | "" | ""
    dhac::T22 = 79430 | (1e-2, 1e7) | "Activation energy for Kc" | "J mol-1" | ""
    dhao::T23 = 36380 | (1e-2, 1e7) | "Activation energy for Ko" | "J mol-1" | ""
    kc25::T24 = 39.97 | (1e-2, 1e7) | "Michaelis-Menten constant for CO2 at 25C" | "Pa" | ""
    ko25::T25 = 27480 | (1e-2, 1e7) | "Michaelis-Menten constant for O2 at 25C" | "Pa" | ""
    Ed::T26 = 200000 | (1e-2, 1e7) | "energy of de-activation" | "J mol-1" | ""

    # Medlyn gs model parameters
    g0::T27 = 0.001 | (-0.05, 0.05) | "the minimum stomatal conductance, ranges are refer to Medlyn paper" | "mol m-2 s-1" | ""
    g1::T28 = 3.0 | (1, 12.0) | "stomatal conductance parameter, ranges are refer to Medlyn paper" | "kPa^0.5" | ""
    
    # constants
    CL::T29 = 0.125 | (0.1, 0.8) | "maximum quantum yield of photosystem II in light-adapted leaves, for PAR to Iabs, refer to P model" | "" | ""
    k_R::T30 = 8.3145 | (8, 9) | "universal gas constant" | "J mol-1 K-1" | ""
    diffusivity_ratio::T31 = 1.6 | (-Inf, Inf) | "Ratio of the molecular diffusivities for water vapor and CO2" | "" | ""
    k_Po::T32 = 101325.0 | (1, 1e7) | "one standard ATM" | "Pa" | ""
    tk_ref::T33 = 298.15 | (298, 299) | "25 deg C in unit of K" | "" | ""
    par_ppfd::T34 = 4.57 | (0, 5) | "PAR to PPFD conversion factor, from W/m2 to umol/m2/s" | "" | ""
    Vw::T35 = 1.8e-5 | (1e-6, 1e-4) | "molar volume of water" | "m3 mol-1" | ""
    epar::T133 = 2.1739e5 | (1e5, 3e5) | "Energy content of PAR" | "J mol⁻¹" | ""

    # soil evaporation params
    c_p::T36 = 1.013 * 1e-03 | (-Inf, Inf) | "specific heat at constant pressure" | "MJ kg-1 K-1" | ""
    ρ::T37 = 1.293 | (-Inf, Inf) | "density of air" | "kg m-3" | ""
    k_von::T38 = 0.41 | (-Inf, Inf) | "von Karman's constant" | "" | ""
    zow::T39 = 0.005 | (-Inf, Inf) | "roughness length" | "m" | ""
    Fw::T40 = 5000 | (-Inf, Inf) | "the fetch at weather station" | "m" | ""
    zw::T41 = 10.0 | (2, 100) | "height of tower" | "m" | ""
    z_0g::T42 = 0.020 | (0.005, 0.2) | "roughness length of substrate ground" | "m" | ""
    r_ss_min::T43 = 50 | (1e-2, 1e7) | "minimum soil resistance" | "s m-1" | ""
    r_ss_max::T44 = 5000 | (1e-2, 1e7) | "maximum soil resistance" | "s m-1" | ""

    # canopy resistance parameters (refer to SCOPE resistances.m, zo_and_d.m)
    Cd::T45 = 0.3 | (0.01, 1.0) | "averaged drag coefficient for the vegetation" | "" | ""
    CR::T46 = 0.35 | (0.01, 1.0) | "drag coefficient for isolated tree" | "" | ""
    CD1::T47 = 20.6 | (1.0, 50.0) | "fitting parameter of zero-plane displacement" | "" | ""
    Psicor::T48 = 0.2 | (0.0, 1.0) | "roughness layer correction" | "" | ""
    CSSOIL::T49 = 0.01 | (0.001, 0.1) | "drag coefficient for soil" | "" | ""
    rbs::T50 = 10.0 | (0.0, 100.0) | "boundary layer resistance of soil" | "s m-1" | ""
    rwc::T51 = 0.0 | (0.0, 100.0) | "within-canopy aerodynamic resistance of the canopy" | "s m-1" | ""
    z_ref::T52 = 10.0 | (2.0, 100.0) | "measurement height of wind speed, raised to canopy height + 2 m if lower" | "m" | ""
    minimum_wind_speed::T53 = 0.2 | (0.0, 5.0) | "minimum wind speed used in the resistance calculation" | "m s-1" | ""
    maximum_resistance::T54 = 400.0 | (10.0, 1e4) | "upper limit of the aerodynamic resistances, to prevent unrealistically high values" | "s m-1" | ""
    minimum_canopy_height::T55 = 0.01 | (1e-3, 1.0) | "minimum canopy height used in the resistance calculation" | "m" | ""

    # Iteration parameters
    convergence_water_potential::T56 = 1e-3 | (1e-10, 1e0) | "0.001" | "" | ""
    STEMMUS_max_iterations::T57 = 50 | (10, 1000) | "maximum number of iterations for STEMMUS" | "" | ""
    convergence_ci::T58 = 1e-3 | (0.0, 1e0) | "tolerance of ci" | "Pa" | ""
    ci_residual_tolerance::T59 = 1.0e-10 | (0.0, 1e0) | "tolerance of gpp difference" | "molC m-2 s-1" | ""
    Ci_max_iterations::T60 = 50 | (10, 1000) | "maximum number of iterations for leaf intercellular CO2 concentration" | "" | ""
    convergence_fw::T61 = 1e-3 | (1e-10, 1e0) | "0.001" | "" | ""
    fw_max_iterations::T62 = 50 | (10, 1000) | "maximum number of iterations for leaf intercellular CO2 concentration" | "" | ""

    # leaf energy balance (refer to SCOPE heatfluxes.m / ebal.m)
    energy_balance_switch::T63 = 1.0 | (0.0, 1.0) | "solve leaf temperature from the energy balance (>0.5) or use air temperature + delta_T (<=0.5)" | "" | ""
    leaf_width::T64 = 0.05 | (0.001, 0.5) | "characteristic leaf width for the leaf boundary layer" | "m" | ""
    leaf_emissivity::T65 = 0.98 | (0.9, 1.0) | "leaf thermal emissivity" | "" | ""
    sigma_SB::T66 = 5.670374e-8 | (5e-8, 6e-8) | "Stefan-Boltzmann constant" | "W m-2 K-4" | ""
    Tleaf_max_iterations::T67 = 50 | (1, 100) | "maximum number of iterations between leaf temperature and photosynthesis-hydraulics" | "" | ""
    convergence_Tleaf::T68 = 1e-4 | (1e-10, 1e0) | "tolerance of energy error" | "W m-2" | ""
    Tleaf_damping::T69 = 1.0 | (0.1, 1.0) | "initial relaxation weight (Wc) of the leaf temperature update, as in SCOPE ebal.m" | "" | ""
    Tleaf_ebal_iterations::T70 = 20 | (1, 100) | "maximum number of Newton iterations of the leaf energy balance" | "" | ""

    # boundary conditions
    minimum_conductance::T71 = 1.0e-11 | (0.0, 1.0) | "numerical floor for hydraulic conductance" | "m d-1" | ""
    minimum_lai::T72 = 1.0e-2 | (0.0, 1.0) | "minimum LAI" | "m2 m-2" | ""
    minimum_water_stress::T73 = 1.0e-2 | (1.0e-6, 10.0) | "minimum water stress" | "" | ""

    # unit conversions
    mm_2_m::T74 = 1.0e-3 | (0.0, 1e7) | "unit conversion from mm to m" | "" | ""
    m_to_mm::T75 = 1.0e3 | (0.0, 1e7) | "unit conversion from m to mm" | "" | ""
    m_to_MPa::T76 = 0.00980665 | (0.0, 1e7) | "unit conversion of water potential from m to MPa" | "" | ""
    deg_2_K::T77 = 273.15 | (1e-2, 1e7) | "convert deg C to K" | "" | ""
    c_mol_mass::T78 = 12.0 | (1e-2, 1e7) | "molecular mass of carbon" | "g/mol" | ""
    w_mol_mass::T79 = 18.0 | (1e-2, 1e7) | "molecular mass of water" | "g/mol" | ""
    day_second::T80 = 86400 | (1e-2, 1e7) | "seconds in a day" | "s" | ""
    con_1e6::T81 = 1e6 | (1e0, 1e7) | "1,000,000" | "" | ""
    con_1e3::T82 = 1e3 | (1e0, 1e7) | "1,000" | "" | ""
    con_1e_6::T83 = 1e-6 | (1e-10, 1e0) | "0.000001" | "" | ""
    con_1e_3::T84 = 1e-3 | (1e-10, 1e0) | "0.001" | "" | ""

    # air and water physical constants (leaf energy balance)
    rhoa::T85 = 1.2047 | (1.0, 1.5) | "density of air" | "kg m-3" | ""
    cp::T86 = 1004.0 | (900.0, 1100.0) | "specific heat of dry air at constant pressure" | "J kg-1 K-1" | ""
    Mair::T87 = 28.9647 | (28.0, 30.0) | "molar mass of dry air" | "g mol-1" | ""
    g_acc::T88 = 9.81 | (9.7, 9.9) | "gravitational acceleration, used to convert water potential from m to J kg-1" | "m s-2" | ""
    kPa_2_hPa::T89 = 10.0 | (1.0, 100.0) | "unit conversion from kPa to hPa" | "" | ""
    lambda_0::T90 = 2.501 | (2.0, 3.0) | "latent heat of vaporization of water at 0 deg C" | "MJ kg-1" | ""
    lambda_slope::T91 = 0.002361 | (0.0, 0.01) | "temperature slope of the latent heat of vaporization" | "MJ kg-1 K-1" | ""
    esat_a::T92 = 0.6108 | (0.5, 0.7) | "saturation vapor pressure at 0 deg C in the Tetens equation" | "kPa" | ""
    esat_b::T93 = 17.27 | (17.0, 18.0) | "slope coefficient of the Tetens equation" | "" | ""
    esat_c::T94 = 237.3 | (200.0, 250.0) | "temperature offset of the Tetens equation" | "deg C" | ""

    # photosynthesis: light, quantum yield, and temperature response
    sw_to_ppfd::T95 = 2.04 | (1.5, 2.5) | "conversion from shortwave radiation to photosynthetic photon flux, Meek et al. (1984)" | "umol photon J-1" | ""
    phi_max::T96 = 0.125 | (0.05, 0.2) | "theoretical maximum of the intrinsic quantum yield" | "mol C mol-1 photon" | ""
    phi_T_a::T97 = 0.325 | (0.0, 1.0) | "intercept of the temperature function of the intrinsic quantum yield" | "" | ""
    phi_T_b::T98 = 0.022 | (0.0, 0.1) | "linear coefficient of the temperature function of the intrinsic quantum yield" | "K-1" | ""
    phi_T_c::T99 = 0.00034 | (0.0, 0.01) | "quadratic coefficient of the temperature function of the intrinsic quantum yield" | "K-2" | ""
    temp_month_min::T100 = 11.0 | (-10.0, 20.0) | "lower bound of the monthly air temperature used in the high-temperature deactivation" | "deg C" | ""
    temp_month_max::T101 = 35.0 | (20.0, 50.0) | "upper bound of the monthly air temperature used in the high-temperature deactivation" | "deg C" | ""
    delta_S_intercept::T102 = 668.39 | (600.0, 700.0) | "intercept of the entropy of deactivation" | "J mol-1 K-1" | ""
    delta_S_slope::T103 = 1.07 | (0.0, 2.0) | "slope of the entropy of deactivation with monthly air temperature" | "J mol-1 K-2" | ""
    temp_low_deactivation::T104 = 0.0 | (-10.0, 10.0) | "temperature below which photosynthesis is fully inhibited" | "deg C" | ""
    temp_low_ramp::T105 = 5.0 | (0.1, 20.0) | "temperature range over which the low-temperature inhibition is linearly released" | "K" | ""
    minimum_Jmax::T106 = 1.0e-12 | (0.0, 1.0e-6) | "threshold of Jmax below which the actual electron transport rate is set to zero" | "molC m-2 s-1" | ""

    # stomata
    maximum_stomatal_resistance::T107 = 1.0e6 | (1.0e3, 1.0e9) | "stomatal resistance used when stomatal conductance is zero (closed stomata)" | "s m-1" | ""

    # aerodynamic resistances (refer to SCOPE resistances.m)
    roughness_sublayer_factor::T108 = 2.5 | (1.0, 5.0) | "ratio of the top of the roughness sublayer to canopy height" | "" | ""
    measurement_height_offset::T109 = 2.0 | (0.0, 10.0) | "minimum height of the wind measurement above the canopy" | "m" | ""
    G1_min::T110 = 3.3 | (1.0, 10.0) | "lower limit of the roughness-length coefficient G1" | "" | ""
    rbc_coefficient::T111 = 70.0 | (10.0, 200.0) | "coefficient of the leaf boundary layer resistance, W&V Eq 31" | "s m-1 (m s-1)-0.5" | ""
    minimum_ustar::T112 = 0.001 | (1.0e-5, 0.1) | "minimum friction velocity" | "m s-1" | ""
    minimum_uh::T113 = 0.01 | (1.0e-4, 0.5) | "minimum wind speed at canopy height" | "m s-1" | ""
    soil_roughness_height::T114 = 0.01 | (1.0e-3, 0.1) | "height above the soil surface used for the within-canopy soil resistance" | "m" | ""
    L_unstable::T115 = -4.0 | (-100.0, 0.0) | "Obukhov length below which the unstable stability correction is applied" | "m" | ""
    L_stable::T116 = 4000.0 | (10.0, 1.0e5) | "Obukhov length above which the stable stability correction is applied" | "m" | ""
    stability_coef_unstable::T117 = 16.0 | (10.0, 25.0) | "coefficient of the Paulson stability functions for unstable conditions" | "" | ""
    stability_coef_stable::T118 = 5.0 | (3.0, 8.0) | "coefficient of the stability functions for stable conditions" | "" | ""

    # soil, root, and iteration boundaries
    minimum_soil_potential::T119 = -5000.0 | (-1.0e5, -100.0) | "lower limit of the soil matric potential" | "m" | ""
    minimum_root_potential::T120 = -1000.0 | (-1.0e4, -100.0) | "lower limit of the root water potential, -10 MPa = -1019 m" | "m" | ""
    maximum_soil_root_resistance::T121 = 1.0e5 | (1.0e2, 1.0e9) | "soil-to-root resistance above which a soil layer is excluded from the root uptake" | "d m-1" | ""
    fine_root_fraction_woody::T122 = 0.141 | (0.0, 1.0) | "fine-root fraction of trees and shrubs" | "" | ""
    fine_root_fraction_herb::T123 = 0.885 | (0.0, 1.0) | "fine-root fraction of herbaceous plants" | "" | ""
    fine_root_fraction_default::T124 = 0.15 | (0.0, 1.0) | "fine-root fraction of other plant forms" | "" | ""
    psi_leaf_damping::T125 = 0.5 | (0.1, 1.0) | "weight of the new estimate in the leaf water potential update" | "" | ""
    ci_initial_fraction::T126 = 0.7 | (0.1, 1.0) | "initial guess of Ci as a fraction of the ambient CO2 partial pressure" | "" | ""
    Tleaf_damping_5::T127 = 0.6 | (0.01, 1.0) | "relaxation weight of the leaf temperature update after Tleaf_relax_iter_1 iterations" | "" | ""
    Tleaf_damping_10::T128 = 0.4 | (0.01, 1.0) | "relaxation weight of the leaf temperature update after Tleaf_relax_iter_2 iterations" | "" | ""
    Tleaf_damping_30::T129 = 0.1 | (0.01, 1.0) | "relaxation weight of the leaf temperature update after Tleaf_relax_iter_3 iterations" | "" | ""
    Tleaf_relax_iter_1::T130 = 5 | (1, 100) | "iteration at which the first relaxation weight is applied" | "" | ""
    Tleaf_relax_iter_2::T131 = 10 | (1, 100) | "iteration at which the second relaxation weight is applied" | "" | ""
    Tleaf_relax_iter_3::T132 = 30 | (1, 100) | "iteration at which the third relaxation weight is applied" | "" | ""

end
#! format: on

function define(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_alpha_van_Genuchten, f_eta_van_Genuchten) ⇐ forcing
        soilW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        plant_form ⇐ land.states
    end

    if plant_form in (:tree, :shrub)
        fine_root_fraction = fine_root_fraction_woody
    elseif plant_form == :herb
        fine_root_fraction = fine_root_fraction_herb
    else
        fine_root_fraction = fine_root_fraction_default
    end

    phs_root_water_uptake = zero(soilW)

    Κ_soil_root = zero(soilW)
    Κ_soil = zero(soilW)
    Κ_root = zero(soilW)
    Κ_soil_unsat = zero(soilW)

    RAI = zero(soilW)
    fraction_root = zero(soilW) # fraction of root in each soil layer, unitless
    β_root = zero(soilW) # soil water stress factor (0-1)

    D_soil_inv_mm = zero(soilW)
    D_soil_m = zero(soilW)
    D_soil_cum_m = zero(soilW)
    D_root_deno = zero(soilW)

    θ_soil = zero(soilW) # in m3 m-3
    θ_res = zero(soilW) # in m3 m-3
    θ_sat = zero(soilW) # in m3 m-3
    soil_saturation = zero(soilW) # in dimensionless

    ψ_leaf_prev = p50_leaf # intial leaf water potential, m

    ci_prev = gs_max = z_zero
    root_total_conductance = root_conductance_weighted_head = root_total_capacity = highest_rooted_soil_head = z_zero
    leaf_VPD = leaf_RH = leaf_actual_pressure = z_zero
    leaf_saturated_pressure = air_saturated_pressure = air_actual_pressure = z_zero
    temp_leaf_degC = temp_leaf_K = z_zero
    leaf_temp_diff = z_zero # leaf temperature minus air temperature, deg C
    temp_leaf_balance = z_zero
    phs_transpiration_max = z_zero
    LE_canopy = H_canopy_flux = Rn_canopy = z_zero # canopy energy fluxes, W m-2 ground

    # don't consider the soil depth gravity potential, only the matric potential, unit: m.
    ψ_soil = zero(soilW)
    ψ_soil_matric = zero(soilW)

    ### VG soil hydraulic property
    nvg = f_eta_van_Genuchten
    avg = f_alpha_van_Genuchten
    mvg = o_one - o_one / nvg

    @pack_nt begin
        (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.diagnostics
        (θ_soil, θ_res, θ_sat, soil_saturation) ⇒ land.diagnostics
        (ψ_leaf_prev, ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
        (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
        (root_total_conductance, root_conductance_weighted_head, root_total_capacity, highest_rooted_soil_head) ⇒ land.diagnostics
        (RAI, fine_root_fraction, fraction_root, β_root) ⇒ land.diagnostics
        (ci_prev, gs_max) ⇒ land.diagnostics
        (leaf_VPD, leaf_RH, leaf_actual_pressure) ⇒ land.diagnostics
        (leaf_saturated_pressure, air_saturated_pressure, air_actual_pressure) ⇒ land.diagnostics
        (temp_leaf_degC, temp_leaf_K) ⇒ land.diagnostics
        (leaf_temp_diff, temp_leaf_balance) ⇒ land.diagnostics
        phs_transpiration_max ⇒ land.diagnostics
        (LE_canopy, H_canopy_flux, Rn_canopy) ⇒ land.diagnostics
        phs_root_water_uptake ⇒ land.fluxes
        (nvg, avg, mvg) ⇒ land.diagnostics
    end
    return land
end

function precompute(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (soil_layer_thickness) ⇐ land.properties
        (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end
    depth_from_top_m = z_zero
    for sl in eachindex(soil_layer_thickness)
        thickness = soil_layer_thickness[sl]
        thickness_m = thickness * mm_2_m
        cumulative_depth_m = depth_from_top_m + thickness_m / 2 # middle point for gravity potential.
        root_depth_denominator = root_lateral_length + cumulative_depth_m
        @rep_elem inv(thickness) ⇒ (D_soil_inv_mm, sl, :soilW)
        @rep_elem thickness_m ⇒ (D_soil_m, sl, :soilW)
        @rep_elem cumulative_depth_m ⇒ (D_soil_cum_m, sl, :soilW)
        @rep_elem root_depth_denominator ⇒ (D_root_deno, sl, :soilW)
        depth_from_top_m += thickness_m
    end
    @pack_nt begin
        (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.diagnostics
    end
    return land
end

function compute(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_rn, f_ws, f_airT_day, f_daytime_seconds, f_canopy_height, f_VPD_day, f_psurf_day) ⇐ forcing
        (LAI, fAPAR) ⇐ land.states
        leaf_temp_diff ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end

    ### Initialize
    H_canopy = f_canopy_height # m
    temp_leaf_degC = f_airT_day + leaf_temp_diff
    LAI_l = max(LAI, minimum_lai) # m2 m-2, LAI used to convert between leaf and ground area
    rs = maximum_stomatal_resistance # s m-1, stomatal resistance, initialized to maximum value (closed stomata)

    # variables assigned inside the iteration loops but used after them have to be declared here.
    LE = H = z_zero
    transpiration = z_zero # m d-1, ground area
    e_to_q = lambda = z_zero
    ci_unsat = leaf_RH = leaf_actual_pressure = z_zero

    ### Step 1: calculate resistances, soil hydrology, and Farquhar info.
    ustar, uz0, rai, rar, rac, rws, rbc, raa, rawc, raws = cal_resistances(params, forcing, land, helpers)
    land = cal_soil_hydrology(params, forcing, land, helpers)
    @unpack_nt begin
        (Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
        root_over ⇐ land.rootWaterEfficiency
    end
    rl = _root_potential_linear(params, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)

    # at least one soil layer can take up water.
    root_active = rl.mode == o_one

    # initial water potentials: no transpiration flow (soil water potential and gravity only).
    ψ_root, ψ_stem, ψ_leaf_tmp = _plant_hydraulic(params, rl, H_canopy, LAI, z_zero)
    ψ_leaf_act = ψ_leaf_tmp
    β_leaf = cal_vulnerability_curve(params, ψ_leaf_act, p50_leaf, shape_factor_leaf)

    land = cal_Farquhar_info(params, forcing, land, helpers, temp_leaf_degC)
    @unpack_nt begin
        (ca_Pa, ca_mol, gamma_star, efficient_lai, patm) ⇐ land.diagnostics
        (leaf_saturated_VPD, air_actual_pressure) ⇐ land.diagnostics
        (KM, J_actual, Vcmax, dark_respiration, dark_respiration_mol) ⇐ land.diagnostics
        (Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
        root_over ⇐ land.rootWaterEfficiency
    end
    fq = (; Vcmax, KM, J_actual, gamma_star, ca_mol, ca_Pa, patm, efficient_lai, dark_respiration, dark_respiration_mol, f_daytime_seconds)

    # the plant is active when there is canopy and at least one soil layer can take up water.
    plant_active = LAI > minimum_lai && root_active

    ### Step 2: calculate canopy NET radiation, W m-2.
    # As in SCOPE, the energy balance, aerodynamic resistance (ra) and stomatal resistance (rs) are for ONE LEAF (per m2 of leaf area).
    # Net radiation absorbed by the canopy is per m2 of ground, so it is divided by LAI for the leaf balance, and the leaf fluxes are multiplied by LAI to get ground-area fluxes.
    Rn_canopy = at_least_zero(f_rn) * con_1e6 / f_daytime_seconds * fAPAR # W m-2 ground
    Rn_leaf = Rn_canopy / LAI_l # W m-2 leaf

    ### Step 3: solve energy balance model.
    ci_prev = ci_initial_fraction * ca_Pa
    leaf_VPD = leaf_saturated_VPD

    ra = (LAI + 1) * (raa + rawc) # s m-1, same as rac in SCOPE ebal.m
    Wc = Tleaf_damping

    # for an inactive plant (no canopy, or no root that can take up water), no leaf energy balance is solved: leaf temperature equals air temperature and no transpiration.
    n_Tleaf_iterations = plant_active ? Int(Tleaf_max_iterations) : z_zero
    for iter in 1:n_Tleaf_iterations

        ### Step 3.1: solve ci.
        ci_unsat = _solve_ci_Pa(params, fq, β_leaf, ci_prev, leaf_VPD)
        ci_prev = ci_unsat

        ### Step 3.2: calculate Farquhar photosynthesis and stomatal conductance.
        # gs_Medlyn is the conductance for CO2, mol m-2 s-1. Water vapor conductance is diffusivity_ratio times larger.
        _, _, _, _, _, _, gs_Medlyn = _GPP_Farquhar(params, fq, β_leaf, ci_unsat, leaf_VPD)

        rs = gs_Medlyn > z_zero ? rhoa / (Mair * con_1e_3) / (diffusivity_ratio * gs_Medlyn) : maximum_stomatal_resistance # mol m-2 s-1 to s m-1

        for _ in 1:Int(STEMMUS_max_iterations)
            ### Step 3.3: calculate leaf latent and heat fluxes.
            LE, H, transpiration, e_to_q, lambda = cal_latent_heat_fluxes(params, forcing, land, helpers, temp_leaf_degC, ψ_leaf_tmp, ra, rs)

            ### Step 3.4: solve PHS, the leaf transpiration (mm d-1, per m2 leaf) is scaled to whole canopy (m d-1).
            transpiration = transpiration * LAI_l * con_1e_3 # m d-1
            ψ_root, ψ_stem, ψ_leaf_tmp = _plant_hydraulic(params, rl, H_canopy, LAI, transpiration)

            if abs(ψ_leaf_act - ψ_leaf_tmp) < convergence_water_potential
                ψ_leaf_act = ψ_leaf_act + psi_leaf_damping * (ψ_leaf_tmp - ψ_leaf_act)
                break
            end
            ψ_leaf_act = ψ_leaf_act + psi_leaf_damping * (ψ_leaf_tmp - ψ_leaf_act)
        end

        ### Step 3.5: calcualte energy balance, W m-2 leaf.
        ϵ = Rn_leaf - LE - H

        # convergence: the energy balance error of the canopy (W m-2 ground) is smaller than the tolerance.
        if abs(ϵ) * LAI_l < convergence_Tleaf
            break
        end

        if iter == Tleaf_relax_iter_1
            Wc = Tleaf_damping_5
        elseif iter == Tleaf_relax_iter_2
            Wc = Tleaf_damping_10
        elseif iter == Tleaf_relax_iter_3
            Wc = Tleaf_damping_30
        end

        ### Step 3.6: Estimate new leaf temperature.
        leaf_saturated_pressure = cal_saturated_pressure(params, temp_leaf_degC) # kPa
        sh = leaf_saturated_pressure * kPa_2_hPa * esat_b * esat_c / (esat_c + temp_leaf_degC)^2 # slope of the saturation vapor pressure, hPa K-1
        demonator = ((rhoa * cp) / ra + rhoa * lambda * e_to_q * sh / (ra + rs) + 4 * leaf_emissivity * sigma_SB * (temp_leaf_degC + deg_2_K)^3)
        temp_leaf_degC = temp_leaf_degC + Wc * ϵ / demonator

        ### Step 3.7: Update leaf VPD and β_leaf.
        leaf_saturated_pressure = cal_saturated_pressure(params, temp_leaf_degC)
        leaf_VPD, leaf_RH, leaf_actual_pressure = _leaf_humidity_status(params, leaf_saturated_pressure, air_actual_pressure, temp_leaf_degC + deg_2_K, ψ_leaf_act)
        β_leaf = cal_vulnerability_curve(params, ψ_leaf_act, p50_leaf, shape_factor_leaf)

        ### Step 3.8: Update Farquhar info.
        land = cal_Farquhar_info(params, forcing, land, helpers, temp_leaf_degC)
        @unpack_nt begin
            (ca_Pa, ca_mol, gamma_star, efficient_lai, patm) ⇐ land.diagnostics
            leaf_saturated_VPD ⇐ land.diagnostics
            (KM, J_actual, Vcmax, dark_respiration, dark_respiration_mol) ⇐ land.diagnostics
            (Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
            root_over ⇐ land.rootWaterEfficiency
        end
        fq = (; Vcmax, KM, J_actual, gamma_star, ca_mol, ca_Pa, patm, efficient_lai, dark_respiration, dark_respiration_mol, f_daytime_seconds)

    end

    ### Step 4: Record results.
    # Tleaf and Tair.
    leaf_temp_diff = temp_leaf_degC - f_airT_day

    # water potential
    ψ_leaf = ψ_leaf_prev = ψ_leaf_act
    ci_Pa = ci_prev = plant_active ? ci_unsat : ci_prev
    gpp_f_soilW = β_leaf
    β_stem = cal_vulnerability_curve(params, ψ_stem, p50_stem, shape_factor_stem)

    # calculate photosynthesis.
    gpp_farquhar, Ac_mol_m2_s, Aj_mol_m2_s, net_photosynthesis, _, Vc_actual, gs_Medlyn = _GPP_Farquhar(params, fq, β_leaf, ci_Pa, leaf_VPD)
    Ac_gC = Ac_mol_m2_s * efficient_lai * c_mol_mass * f_daytime_seconds # g C m-2 d-1
    Aj_gC = Aj_mol_m2_s * efficient_lai * c_mol_mass * f_daytime_seconds # g C m-2 d-1

    ### Tr
    gs_canopy = 1 / (rs + ra) # m s-1, canopy scale
    tran_gs = gs_canopy * LAI * f_VPD_day / f_psurf_day # m s-1
    rho_w = 1000.0 # kg m-3, density of water
    c_air = rhoa / (Mair * con_1e_3) # mol m-3, concentration of air
    m_H2O = 0.018 # kg mol-1, molecular mass of water
    tran_gs = tran_gs * c_air * m_H2O / rho_w * con_1e3 * f_daytime_seconds # mm d-1, canopy scale

    phs_transpiration = transpiration * con_1e3 # mm d-1, canopy scale
    delta_tr = phs_transpiration - tran_gs # mm d-1, canopy scale

    # energy fluxes of the canopy, W m-2 ground.
    LE_canopy = LE * LAI_l
    H_canopy_flux = H * LAI_l

    @pack_nt begin
        (rs, ra, ustar, uz0, rai, rar, rac, rws, rbc, raa, rawc, raws) ⇒ land.diagnostics
        (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇒ land.diagnostics
        (β_leaf, gpp_f_soilW, β_stem) ⇒ land.diagnostics
        (gpp_farquhar, net_photosynthesis) ⇒ land.diagnostics
        (Ac_gC, Aj_gC, Ac_mol_m2_s, Aj_mol_m2_s, Vc_actual) ⇒ land.diagnostics
        (gs_Medlyn, gs_canopy, ci_Pa, ci_prev) ⇒ land.diagnostics
        (leaf_VPD, leaf_RH, leaf_actual_pressure) ⇒ land.diagnostics
        (phs_transpiration, tran_gs, delta_tr) ⇒ land.diagnostics
        (LE_canopy, H_canopy_flux, Rn_canopy) ⇒ land.diagnostics
        leaf_temp_diff ⇒ land.diagnostics
    end

    ### RWU, needs ψ_root and phs_transpiration in land.diagnostics.
    land = cal_PHS_root_uptake(params, forcing, land, helpers)
    return land
end

### =========================
# define the activity of plant.
### =========================
function cal_plant_activity(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
        root_over ⇐ land.rootWaterEfficiency
        z_zero ⇐ land.constants
        (Κ_soil_root, leaf_saturated_VPD, temp_leaf_degC) ⇐ land.diagnostics
    end
    active_soil_root = false
    for sl in eachindex(root_over)
        if root_over[sl] > z_zero && abs(Κ_soil_root[sl]) >= minimum_conductance ### the root layer with higher conductance than the minimum one.
            active_soil_root = true
        end
    end
    return LAI > minimum_lai && leaf_saturated_VPD > z_zero && active_soil_root && temp_leaf_degC > z_zero
end

### =========================
# calcualte areodynamic resistance.
### =========================
function cal_resistances(params::plantHydraulics_PHS, forcing, land, helpers, L=Inf)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_canopy_height, f_ws) ⇐ forcing
        LAI ⇐ land.states
    end

    u = max(f_ws, minimum_wind_speed) # m s-1
    LAI = max(LAI, minimum_lai) # m2 m-2
    h = max(f_canopy_height, minimum_canopy_height) # m
    L = oftype(h, L) # Obukhov length, m. The default Inf is Float64 and would promote all resistances (type instability) in Float32 runs.

    ### derived parameters
    zr = roughness_sublayer_factor * h # top of roughness sublayer, bottom of inertial sublayer, m
    n = Cd * LAI / (2 * k_von ^ 2) # dimensionless wind extinction coefficient, W&V Eq 33

    ### roughness length and zero-plane displacement, Verhoef et al. (1997)
    sq = sqrt(CD1 * LAI / 2)
    G1 = max(G1_min, inv(sqrt(CSSOIL + CR * LAI / 2)))
    d = h * (1 - (1 - exp(-sq)) / sq)
    z0m = (h - d) * exp(-k_von * G1 + Psicor)
    z = max(z_ref, h + measurement_height_offset) # measurement height has to be above the canopy, m

    ### stability corrections for non-neutral conditions
    pm_z = _psi_momentum(params, z - d, L)
    ph_z = _psi_heat(params, z - d, L)
    pm_h = _psi_momentum(params, h - d, L)
    ph_zr = z >= zr ? _psi_heat(params, zr - d, L) : ph_z
    phs_zr = _phi_star(params, zr, zr, d, L)
    phs_h = _phi_star(params, h, zr, d, L)

    ustar = max(minimum_ustar, k_von * u / (log((z - d) / z0m) - pm_z)) # W&V Eq 30
    Kh = k_von * ustar * (zr - d) # W&V Eq 35, neutral as in resistances.m

    ### wind speed at height h and z0m + d
    uh = max(ustar / k_von * (log((h - d) / z0m) - pm_h), minimum_uh)
    uz0 = uh * exp(n * ((z0m + d) / h - 1)) # W&V Eq 32

    ### resistances, (e^x - 1) / (e^x + 1) = tanh(x / 2)
    x_z0 = n * (z0m + d) / h
    x_soil = n * soil_roughness_height / h
    rai = z > zr ? (log((z - d) / (zr - d)) - ph_z + ph_zr) / (k_von * ustar) : zero(ustar) # W&V Eq 41
    rar = (zr - h) / (zr - d) / (k_von * ustar) - phs_zr + phs_h # W&V Eq 39
    rac = h * sinh(n) / (n * Kh) * (log(tanh(n / 2)) - log(tanh(x_z0 / 2))) # W&V Eq 42
    rws = h * sinh(n) / (n * Kh) * (log(tanh(x_z0 / 2)) - log(tanh(x_soil / 2))) # W&V Eq 43
    rbc = rbc_coefficient / LAI * sqrt(leaf_width / uz0) # W&V Eq 31, but slightly different

    raa = min(maximum_resistance, rai + rar + rac) # above the canopy
    rawc = min(maximum_resistance, rwc + rbc) # within the canopy (canopy)
    raws = min(maximum_resistance, rws + rbs) # within the canopy (soil)

    return ustar, uz0, rai, rar, rac, rws, rbc, raa, rawc, raws
end

# stability correction for momentum, Paulson (1970)
function _psi_momentum(params::plantHydraulics_PHS, z, L)
    @unpack_plantHydraulics_PHS params
    if L < L_unstable
        # unstable
        x = sqrt(sqrt(1 - stability_coef_unstable * z / L)) # fourth root, without a Float64 literal exponent
        return 2 * log((1 + x) / 2) + log((1 + x ^ 2) / 2) - 2 * atan(x) + oftype(x, π) / 2
    elseif L > L_stable
        # stable
        return -stability_coef_stable * z / L
    end
    return zero(z)
end

# stability correction for heat, Paulson (1970)
function _psi_heat(params::plantHydraulics_PHS, z, L)
    @unpack_plantHydraulics_PHS params
    if L < L_unstable
        # unstable
        x = sqrt(sqrt(1 - stability_coef_unstable * z / L)) # fourth root, without a Float64 literal exponent
        return 2 * log((1 + x ^ 2) / 2)
    elseif L > L_stable
        # stable
        return -stability_coef_stable * z / L
    end
    return zero(z)
end

# roughness sublayer correction, phi star
function _phi_star(params::plantHydraulics_PHS, z, zR, d, L)
    @unpack_plantHydraulics_PHS params
    if L < L_unstable
        # unstable
        x = sqrt(sqrt(1 - stability_coef_unstable * z / L)) # fourth root, without a Float64 literal exponent
        return (z - d) / (zR - d) * (x ^ 2 - 1) / (x ^ 2 + 1)
    elseif L > L_stable
        # stable
        return -stability_coef_stable * z / L
    end
    return zero(z)
end

### =========================
# calcualte soil hydrology.
### =========================
function cal_soil_hydrology(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        (D_soil_inv_mm, D_soil_cum_m, D_root_deno, D_soil_m) ⇐ land.diagnostics
        (nvg, avg, mvg) ⇐ land.diagnostics
        (root_surface_area, c_allocation) ⇐ land.diagnostics
        sp_k_sat ⇐ land.properties
        (f_thetar_van_Genuchten, f_thetas_van_Genuchten) ⇐ forcing
        root_over ⇐ land.rootWaterEfficiency
        z_zero ⇐ land.constants
    end

    Rsf = sum(root_surface_area)
    froot_to_leaf = c_allocation[1]
    sai = at_least_zero(stem_to_leaf_area_ratio * LAI)
    vg = (; nvg, avg, mvg, θ_res=f_thetar_van_Genuchten, θ_sat=f_thetas_van_Genuchten)

    layers = ntuple(Val(length(soilW))) do sl
        _soil_layer_hydrology(eltype(soilW), params, vg, LAI, sai, Rsf, froot_to_leaf, z_zero,
            soilW[sl], ΔsoilW[sl], D_soil_inv_mm[sl], D_soil_cum_m[sl], D_root_deno[sl], D_soil_m[sl],
            sp_k_sat[sl], root_over[sl], root_surface_area[sl])
    end

    T = eltype(soilW)
    N = length(soilW)
    θ_soil = _field_svector(layers, Val(1), Val(N), T)
    θ_res = _field_svector(layers, Val(2), Val(N), T)
    θ_sat = _field_svector(layers, Val(3), Val(N), T)
    soil_saturation = _field_svector(layers, Val(4), Val(N), T)
    Κ_soil_root = _field_svector(layers, Val(5), Val(N), T)
    Κ_soil = _field_svector(layers, Val(6), Val(N), T)
    Κ_root = _field_svector(layers, Val(7), Val(N), T)
    Κ_soil_unsat = _field_svector(layers, Val(8), Val(N), T)
    ψ_soil = _field_svector(layers, Val(9), Val(N), T)
    ψ_soil_matric = _field_svector(layers, Val(10), Val(N), T)
    β_root = _field_svector(layers, Val(11), Val(N), T)
    RAI = _field_svector(layers, Val(12), Val(N), T)
    fraction_root = _field_svector(layers, Val(13), Val(N), T)

    @pack_nt begin
        (θ_soil, θ_res, θ_sat, soil_saturation) ⇒ land.diagnostics
        (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
        (ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
        (β_root, RAI, fraction_root) ⇒ land.diagnostics
    end
    return land
end

function _soil_layer_hydrology(::Type{T}, params::plantHydraulics_PHS, vg, LAI, sai, Rsf, froot_to_leaf, z_zero, soilW_l, ΔsoilW_l, D_soil_inv_mm_l, D_soil_cum_m_l, D_root_deno_l, D_soil_m_l, k_sat_l, root_over_l, rsa_l) where {T}
    @unpack_plantHydraulics_PHS params
    θ = (soilW_l + ΔsoilW_l) * D_soil_inv_mm_l
    soil_potential, theta_res, theta_sat, saturation = _soil_matric_potential(params, vg, θ)

    if root_over_l > z_zero
        root_fraction = rsa_l / Rsf
        layer_head = _pos_Inf_not_NaN(soil_potential - D_soil_cum_m_l)
        k_soil_unsat = k_sat_l * mm_2_m * sqrt(saturation) * (1 - (1 - saturation ^ (1 / vg.mvg)) ^ vg.mvg) ^ 2 # m d-1

        ### soil conductance based on van-Genuchten model., m d-1
        Ω_soil = sqrt(oftype(root_radius, π) / 2) * sqrt(root_radius * D_soil_m_l / rsa_l) / k_soil_unsat # m d-1
        k_soil = isfinite(Ω_soil) ? max(inv(Ω_soil), minimum_conductance) : minimum_conductance

        rai = at_least_zero((sai + LAI) * root_fraction * froot_to_leaf)
        root_stress = cal_vulnerability_curve(params, soil_potential, p50_root, shape_factor_root) # 0-1
        k_root = max(root_stress * k_root_max / D_root_deno_l, minimum_conductance)

        soil_to_root = _soil_root_conductance(k_soil, k_root)
    else
        layer_head = soil_to_root = k_soil = k_root = k_soil_unsat = root_stress = root_fraction = rai = z_zero
    end
    return (T(θ), T(theta_res), T(theta_sat), T(saturation), T(soil_to_root), T(k_soil), T(k_root), T(k_soil_unsat), T(layer_head), T(soil_potential), T(root_stress), T(rai), T(root_fraction))
end

function _soil_matric_potential(params::plantHydraulics_PHS, vg, θ)
    @unpack_plantHydraulics_PHS params
    θ_res = vg.θ_res
    θ_sat = vg.θ_sat
    saturation = clamp_zero_one((θ - θ_res) / (θ_sat - θ_res))
    z_zero = zero(saturation)
    o_one = one(saturation)

    inverse_saturation = saturation ^ (-o_one / vg.mvg)
    if !isfinite(inverse_saturation)
        return oftype(z_zero, minimum_soil_potential), θ_res, θ_sat, saturation
    end

    pressure_term = max(inverse_saturation - o_one, z_zero)
    ψ_soil_matric = -(pressure_term ^ (o_one / vg.nvg)) / vg.avg
    if !isfinite(ψ_soil_matric)
        return oftype(z_zero, minimum_soil_potential), θ_res, θ_sat, saturation
    end
    return clamp(ψ_soil_matric, minimum_soil_potential, z_zero), θ_res, θ_sat, saturation
end

### =========================
# calcualte Farquhar information.
### =========================
function cal_KM(params::plantHydraulics_PHS, forcing, land, helpers, patm, tk)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        o_one ⇐ land.constants
    end
    ### This function is used to calculate The effective Michaelis–Menten coefficient K (Pa) of RuBisCO-limited photosynthesis.
    kc = kc25 * exp(dhac * (tk - tk_ref) / (tk_ref * k_R * tk))
    ko = ko25 * exp(dhao * (tk - tk_ref) / (tk_ref * k_R * tk))
    po = k_co * con_1e_6 * patm
    kmm = kc * (o_one + po / ko) # Pa
    return kmm
end

function cal_Phi_o(params::plantHydraulics_PHS, forcing, land, helpers, temp_leaf_degC)
    @unpack_plantHydraulics_PHS params
    ### This function is used to calculate the intrinsic quantum yield (φ0(T), mol C/mol photon).
    f_T = phi_T_a + phi_T_b * temp_leaf_degC - phi_T_c * temp_leaf_degC ^ 2 # dimensionless
    phi_o = at_least_zero(CL * f_T) # dimensionless
    phi_o = min(phi_o, phi_max) # theoretical maximum value of φ0(T) is 0.125.
    return phi_o
end

function cal_Arrhenius_Factor(params::plantHydraulics_PHS, forcing, land, helpers, patm, tk)
    @unpack_plantHydraulics_PHS params
    arrhenius_factor = exp(ha * (tk - tk_ref) / (tk_ref * k_R * tk)) # dimensionless
    return arrhenius_factor
end

function cal_Deactivation_High_Temp(params::plantHydraulics_PHS, forcing, land, helpers, tk)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        f_month_air_temperature ⇐ forcing
    end
    # in CLM4.5, it is the monthly mean temperature in deg C.
    temp_month_C = min(max(f_month_air_temperature, temp_month_min), temp_month_max)
    delta_S = delta_S_intercept - delta_S_slope * temp_month_C # entropy of de-activation, J mol-1 K-1.
    deactivation_high_temp = (1 + exp((tk_ref * delta_S - Ed) / (tk_ref * k_R))) / (1 + exp((tk * delta_S - Ed) / (tk * k_R)))
    return deactivation_high_temp
end

function cal_Deactivation_Low_Temp(params::plantHydraulics_PHS, forcing, land, helpers, tk)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (z_zero, o_one) ⇐ land.constants
    end
    ### consider the inhibition effects of low temperature.
    temp_low = deg_2_K + temp_low_deactivation # zero degree C
    temp_high = temp_low + temp_low_ramp # five degree C above temp_low
    if tk < temp_low
        deactivation_low_temp = z_zero
    elseif tk > temp_high
        deactivation_low_temp = o_one
    else
        deactivation_low_temp = (tk - temp_low) / (temp_high - temp_low)
    end
    return deactivation_low_temp
end

function cal_gamma_star(params::plantHydraulics_PHS, forcing, land, helpers, arrhenius_factor, patm)
    @unpack_plantHydraulics_PHS params
    gamma_star = (gs25_0 * patm / k_Po) * arrhenius_factor # Pa
    return gamma_star
end

function cal_Jmax_Vmax(params::plantHydraulics_PHS, forcing, land, helpers, arrhenius_factor, deactivation_high_temp, deactivation_low_temp)
    @unpack_plantHydraulics_PHS params
    Vcmax = Vcmax25 * arrhenius_factor * deactivation_high_temp * deactivation_low_temp # molC m-2 s-1
    Jmax25 = Vcmax25 * Jmax25_Vcmax25_ratio # molC m-2 s-1
    Jmax = Jmax25 * arrhenius_factor * deactivation_high_temp * deactivation_low_temp # molC m-2 s-1
    return Jmax, Vcmax
end

function cal_efficient_LAI(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
        k_extinction ⇐ land.diagnostics
        (z_zero, o_one) ⇐ land.constants
    end
    ### based on beer-lambert law.
    efficient_lai = (o_one - exp(-k_extinction * LAI)) / k_extinction # dimensionless
    return efficient_lai
end

function cal_CO2_Pa(params::plantHydraulics_PHS, forcing, land, helpers, patm, tk)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        ambient_CO2 ⇐ land.states
    end
    ca = con_1e_6 * ambient_CO2 * patm # ppm to Pa
    ca_mol = con_1e_6 * ambient_CO2 # ppm to mol CO2 mol-1 air
    return ca, ca_mol
end

function cal_dark_respiration(params::plantHydraulics_PHS, forcing, land, helpers, Vcmax)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
    end
    # dark respiration occurs in 24 hours.
    # leaf scale
    dark_respiration_mol = rate_dark * Vcmax # mol C m-2 s-1
    dark_respiration = dark_respiration_mol * c_mol_mass * day_second # gC m-2 d-1

    # upscale to canopy scale
    factor_LAI_Nitrogen = (1 - exp(-k_Nitrogen * LAI)) / k_Nitrogen # dimensionless
    dark_respiration = dark_respiration * factor_LAI_Nitrogen # gC m-2 d-1
    return dark_respiration, factor_LAI_Nitrogen, dark_respiration_mol
end

function cal_saturated_pressure(params::plantHydraulics_PHS, Temperature)
    @unpack_plantHydraulics_PHS params
    saturated_pressure = esat_a * exp(esat_b * Temperature / (Temperature + esat_c)) # kPa
    return saturated_pressure
end

function cal_Farquhar_info(params::plantHydraulics_PHS, forcing, land, helpers, temp_leaf_degC)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_SW, f_VPD_day, f_daytime_seconds) ⇐ forcing
        (ambient_CO2, LAI, fAPAR) ⇐ land.states
        (f_psurf_day, f_airT_day) ⇐ forcing
        (z_zero, o_one) ⇐ land.constants
    end

    patm = f_psurf_day * con_1e3 # kPa to Pa
    temp_leaf_K = temp_leaf_degC + deg_2_K # K

    ### leaf scale should use leaf temperature, not air temperature.
    arrhenius_factor = cal_Arrhenius_Factor(params, forcing, land, helpers, patm, temp_leaf_K) # dimensionless
    deactivation_high_temp = cal_Deactivation_High_Temp(params, forcing, land, helpers, temp_leaf_K) # dimensionless
    deactivation_low_temp = cal_Deactivation_Low_Temp(params, forcing, land, helpers, temp_leaf_K) # dimensionless

    KM = cal_KM(params, forcing, land, helpers, patm, temp_leaf_K) # effective Michaelis–Menten coefficient K (Pa)
    Jmax, Vcmax = cal_Jmax_Vmax(params, forcing, land, helpers, arrhenius_factor, deactivation_high_temp, deactivation_low_temp) # mol C m-2 s-1
    gamma_star = cal_gamma_star(params, forcing, land, helpers, arrhenius_factor, patm) # Pa
    ca_Pa, ca_mol = cal_CO2_Pa(params, forcing, land, helpers, patm, temp_leaf_K)
    efficient_lai = cal_efficient_LAI(params, forcing, land, helpers)
    Phi_o = cal_Phi_o(params, forcing, land, helpers, temp_leaf_degC) # the intrinsic quantum-yield efficiency, dimensionless

    ### Light-limited rate, Aj.
    SW_W_m2 = at_least_zero(f_SW * con_1e6 / day_second) # W m-2
    Iabs = at_least_zero(fAPAR * SW_W_m2 * sw_to_ppfd) # umol photon m-2 s-1
    Iabs = Iabs * con_1e_6 # mol photon m-2 s-1
    numerator = 4 * Phi_o * Iabs # mol C m-2 s-1
    denominator = (numerator / Jmax) ^ 2 + o_one
    J_actual = Jmax > minimum_Jmax ? numerator / sqrt(denominator) : z_zero # mol C m-2 s-1

    # Leaf VPD is calculated based on Kelvin equation to consider the effects of leaf water potential.
    air_saturated_pressure = cal_saturated_pressure(params, f_airT_day) # kPa
    leaf_saturated_pressure = cal_saturated_pressure(params, temp_leaf_degC) # kPa
    air_actual_pressure = at_least_zero(air_saturated_pressure - at_least_zero(f_VPD_day)) # kPa
    leaf_saturated_VPD = at_least_zero(leaf_saturated_pressure - air_actual_pressure) # kPa

    dark_respiration, factor_LAI_Nitrogen_dark_respiration, dark_respiration_mol = cal_dark_respiration(params, forcing, land, helpers, Vcmax)

    @pack_nt begin
        (KM, patm) ⇒ land.diagnostics
        (arrhenius_factor, deactivation_high_temp, deactivation_low_temp) ⇒ land.diagnostics
        (Jmax, Vcmax, J_actual) ⇒ land.diagnostics
        (gamma_star, ca_Pa, ca_mol) ⇒ land.diagnostics
        efficient_lai ⇒ land.diagnostics
        (leaf_saturated_pressure, air_saturated_pressure, air_actual_pressure, leaf_saturated_VPD) ⇒ land.diagnostics
        (temp_leaf_degC, temp_leaf_K) ⇒ land.diagnostics
        (Iabs, Phi_o) ⇒ land.diagnostics
        (dark_respiration, factor_LAI_Nitrogen_dark_respiration, dark_respiration_mol) ⇒ land.diagnostics
    end
end

### =========================
# calcualte RWU in each layers.
### =========================
function cal_PHS_root_uptake(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        PAW ⇐ land.states
        root_over ⇐ land.rootWaterEfficiency
        (Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area) ⇐ land.diagnostics
        (ψ_root, phs_transpiration) ⇐ land.diagnostics
    end

    # the transpiration demand of the canopy is taken up from the soil layers with the normalized root weights, each layer is limited by its available water, and the shortage is taken from the other layers.
    # the transpiration is then equal to the total root water uptake.
    Q = phs_transpiration * mm_2_m # m d-1
    wn, _, _ = _root_layer_weights(params, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
    uptake = _root_water_uptake_layers(params, wn, Q, PAW) # m d-1
    phs_root_water_uptake = uptake * m_to_mm # mm d-1
    phs_transpiration = sum(uptake) * m_to_mm # mm d-1, water-limited transpiration = total root water uptake

    β_stem = clamp_zero_one(cal_vulnerability_curve(params, ψ_root, p50_stem, shape_factor_stem))

    @pack_nt begin
        (β_stem, phs_transpiration) ⇒ land.diagnostics
        phs_root_water_uptake ⇒ land.fluxes
    end
    return land
end

# normalized root weights of the soil layers: the fraction of the root surface area of the layers that can take up water, sums to 1 (or 0 if no layer can take up water).
# also returns the soil-to-root resistance (soil + root) of each layer, d m-1, and the sum of the non-normalized weights.
function _root_layer_weights(params::plantHydraulics_PHS, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
    @unpack_plantHydraulics_PHS params
    T = eltype(ψ_soil)
    z_zero = zero(T)
    N = length(ψ_soil)
    max_Ω = oftype(z_zero, maximum_soil_root_resistance) # d m-1, i.e, root absorb 0.01 mm H2O per day, which is too slow.

    Ω = SVector{N,T}(ntuple(Val(N)) do sl
        inv(Κ_soil[sl]) + inv(Κ_root[sl])
    end)
    w_valid = SVector{N,T}(ntuple(Val(N)) do sl
        valid = root_over[sl] > z_zero && root_surface_area[sl] > z_zero && Ω[sl] <= max_Ω && ψ_soil[sl] > minimum_soil_potential
        valid ? T(fraction_root[sl]) : z_zero
    end)
    sum_w = sum(w_valid)
    wn = iszero(sum_w) ? w_valid : w_valid / sum_w
    return wn, Ω, sum_w
end

# root water potential as a linear function of the transpiration: ψ_root = A - B * Q.
# Each layer takes up Q * wn[sl], so the layer root potential is ψ_soil - Ω * Q * wn / root_surface_area, and ψ_root is the weighted mean of them.
function _root_potential_linear(params::plantHydraulics_PHS, Κ_soil_root, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
    @unpack_plantHydraulics_PHS params
    z_zero = zero(eltype(ψ_soil))

    if all(k -> abs(k) <= minimum_conductance, Κ_soil_root)
        return RootPotentialLinear(0, sum(ψ_soil) / length(ψ_soil), z_zero)
    end

    wn, Ω, sum_w = _root_layer_weights(params, Κ_soil, Κ_root, ψ_soil, fraction_root, root_surface_area, root_over)
    if iszero(sum_w)
        return RootPotentialLinear(2, z_zero, z_zero)
    end

    sum_a = sum_b = z_zero
    for sl in eachindex(ψ_soil)
        if wn[sl] > z_zero
            sum_a += ψ_soil[sl] * wn[sl]
            sum_b += Ω[sl] * wn[sl] * wn[sl] / root_surface_area[sl]
        end
    end
    return RootPotentialLinear(1, sum_a, sum_b)
end

# root water uptake of each soil layer, m d-1.
# Demand Q is shared by the weights wn. A layer cannot take up more than its available water (PAW), and the shortage is shared by the layers that still have available water.
# The sum of the uptake equals Q, unless the total available water of the rooted layers is smaller than Q.
function _root_water_uptake_layers(params::plantHydraulics_PHS, wn, Q, PAW)
    @unpack_plantHydraulics_PHS params
    T = eltype(wn)
    N = length(wn)
    capacity = SVector{N,T}(ntuple(sl -> at_least_zero(T(PAW[sl])) * mm_2_m, Val(N))) # m d-1
    uptake = zero(wn)
    for _ in 1:N
        remaining = Q - sum(uptake)
        remaining > zero(T) || break
        uptake_new = _share_uptake(wn, capacity, uptake, remaining)
        uptake_new == uptake && break
        uptake = uptake_new
    end
    return uptake
end

function _share_uptake(wn::SVector{N,T}, capacity, uptake, remaining) where {N,T}
    z_zero = zero(T)
    w_open = SVector{N,T}(ntuple(sl -> (wn[sl] > z_zero && uptake[sl] < capacity[sl]) ? wn[sl] : z_zero, Val(N)))
    sum_open = sum(w_open)
    iszero(sum_open) && return uptake
    return SVector{N,T}(ntuple(sl -> min(uptake[sl] + remaining * w_open[sl] / sum_open, capacity[sl]), Val(N)))
end

### =========================
# Solve leaf intercellular CO2 concentration (ci) in Pa, and Farquhar & Medlyn modules.
### =========================
function _solve_ci_Pa(params::plantHydraulics_PHS, fq, leaf_stress, ci_prev, leaf_VPD)
    @unpack_plantHydraulics_PHS params
    ci_upper = fq.ca_Pa
    ci_lower = fq.gamma_star

    # Medlyn equation 13.
    if iszero(g0)
        best_ci = fq.ca_Pa * (1 - diffusivity_ratio * sqrt(leaf_VPD) / (g1 + sqrt(leaf_VPD)))
        return clamp(best_ci, fq.gamma_star, fq.ca_Pa)
    end

    residual = ci -> _ci_residual(params, fq, leaf_stress, ci, leaf_VPD)

    ϵ_lower = residual(ci_lower)
    ϵ_upper = residual(ci_upper)

    if abs(ϵ_lower) < ci_residual_tolerance
        best_ci = ci_lower
        return best_ci
    elseif abs(ϵ_upper) < ci_residual_tolerance
        best_ci = ci_upper
        return best_ci
    elseif ϵ_lower * ϵ_upper <= 0
        best_ci = _brent_root(residual, ci_lower, ci_upper, ϵ_lower, ϵ_upper, convergence_ci, ci_residual_tolerance, Int(Ci_max_iterations))
        return best_ci
    end
    
    return oftype(ci_lower, ci_prev)
end

function _ci_residual(params::plantHydraulics_PHS, fq, leaf_stress, ci, leaf_VPD)
    _, _, _, _, net_photosynthesis_mol, _, gs = _GPP_Farquhar(params, fq, leaf_stress, ci, leaf_VPD)
    return oftype(ci, gs * (fq.ca_Pa - ci) / fq.patm - net_photosynthesis_mol)
end

function _GPP_Farquhar(params::plantHydraulics_PHS, fq, leaf_stress, ci, leaf_VPD)
    @unpack_plantHydraulics_PHS params
    co2_numerator = at_least_zero(ci - fq.gamma_star)
    Vc_actual = fq.Vcmax * leaf_stress
    Ac_mol_m2_s = Vc_actual * co2_numerator / (ci + fq.KM)
    Aj_mol_m2_s = fq.J_actual * co2_numerator / (4 * ci + 8 * fq.gamma_star)
    gross_photosynthesis_mol = min(Ac_mol_m2_s, Aj_mol_m2_s)
    gpp_farquhar = gross_photosynthesis_mol * fq.efficient_lai * c_mol_mass * fq.f_daytime_seconds
    net_photosynthesis = gpp_farquhar - fq.dark_respiration
    net_photosynthesis_mol = gross_photosynthesis_mol - fq.dark_respiration_mol
    gs = _gs_Medlyn(params, net_photosynthesis_mol, fq.ca_mol, leaf_VPD)
    return gpp_farquhar, Ac_mol_m2_s, Aj_mol_m2_s, net_photosynthesis, net_photosynthesis_mol, Vc_actual, gs
end

function _gs_Medlyn(params::plantHydraulics_PHS, net_photosynthesis, ca, leaf_VPD)
    @unpack_plantHydraulics_PHS params
    if !isfinite(leaf_VPD) || leaf_VPD == zero(leaf_VPD)
        return zero(leaf_VPD)
    end
    gs = g0 + (one(leaf_VPD) + g1 / sqrt(leaf_VPD)) * (net_photosynthesis / ca)
    return at_least_zero(gs)
end

# Brent's method on a bracket [a, b] with f(a) * f(b) <= 0.
function _brent_root(f::F, a, b, fa, fb, xatol, atol, maxiters) where {F}
    c, fc = a, fa
    d = e = b - a
    for _ in 1:maxiters
        if (fb > 0 && fc > 0) || (fb < 0 && fc < 0)
            c, fc = a, fa
            d = e = b - a
        end
        if abs(fc) < abs(fb)
            a, b, c = b, c, b
            fa, fb, fc = fb, fc, fb
        end
        tol = 2 * eps(abs(b)) + xatol / 2
        xm = (c - b) / 2
        if abs(xm) <= tol || abs(fb) <= atol
            return b
        end
        if abs(e) >= tol && abs(fa) > abs(fb)
            s = fb / fa
            if a == c
                p = 2 * xm * s
                q = 1 - s
            else
                q = fa / fc
                r = fb / fc
                p = s * (2 * xm * q * (q - r) - (b - a) * (r - 1))
                q = (q - 1) * (r - 1) * (s - 1)
            end
            q = p > 0 ? -q : q
            p = abs(p)
            if 2 * p < min(3 * xm * q - abs(tol * q), abs(e * q))
                e = d
                d = p / q
            else
                d = xm
                e = d
            end
        else
            d = xm
            e = d
        end
        a, fa = b, fb
        b += abs(d) > tol ? d : copysign(tol, xm)
        fb = f(b)
    end
    return b
end

function cal_vulnerability_curve(params::plantHydraulics_PHS, psi, psi50, shape_factor)
    @unpack_plantHydraulics_PHS params
    ### sigmoid function
    psi50 = psi50 * m_to_MPa
    psi = psi * m_to_MPa
    numerator = 1 + exp(shape_factor * psi50)
    deminator = 1 + exp(shape_factor * (psi50 - psi))
    stress = clamp_zero_one(numerator / deminator)
    return stress
end

function _plant_hydraulic(params::plantHydraulics_PHS, rl, H_canopy, LAI, Q)
    psi_root = _root_water_potential(params, rl, Q)
    psi_stem = _stem_water_potential(params, H_canopy, LAI, psi_root, Q)
    psi_leaf = _leaf_water_potential(params, LAI, psi_stem, Q)
    return psi_root, psi_stem, psi_leaf
end

function _root_water_potential(params::plantHydraulics_PHS, rl::RootPotentialLinear, Q)
    @unpack_plantHydraulics_PHS params
    z_zero = zero(rl.A)
    if rl.mode == 0
        return rl.A
    elseif rl.mode == 2
        return oftype(z_zero, minimum_root_potential)
    end
    psi_root = rl.A - rl.B * Q
    if !isfinite(psi_root)
        return oftype(z_zero, minimum_root_potential)
    end
    psi_root = min(max(psi_root, minimum_root_potential), z_zero)
    return psi_root
end

function _stem_water_potential(params::plantHydraulics_PHS, H_canopy, LAI, psi_root, Q)
    @unpack_plantHydraulics_PHS params
    beta_stem_root = cal_vulnerability_curve(params, psi_root, p50_stem, shape_factor_stem)
    SAI = stem_to_leaf_area_ratio * LAI
    if LAI > minimum_lai && H_canopy > zero(H_canopy) && beta_stem_root > minimum_water_stress
        stem_conductance = k_stem_max * beta_stem_root / H_canopy
        psi_stem = psi_root - H_canopy - Q / SAI / stem_conductance
    else
        psi_stem = psi_root - H_canopy
    end
    return psi_stem
end

function _leaf_water_potential(params::plantHydraulics_PHS, LAI, psi_stem, Q)
    @unpack_plantHydraulics_PHS params
    beta_leaf_stem = cal_vulnerability_curve(params, psi_stem, p50_leaf, shape_factor_leaf)
    if LAI > minimum_lai && beta_leaf_stem > minimum_water_stress
        leaf_conductance = k_leaf_max * beta_leaf_stem
        psi_leaf = psi_stem - Q / LAI / leaf_conductance
    else
        psi_leaf = psi_stem
    end
    return psi_leaf
end

### =========================
# calculate leaf wetness state.
### =========================
function _leaf_humidity_status(params::plantHydraulics_PHS, leaf_saturated_pressure, air_actual_pressure, temp_leaf_K, psi_leaf)
    @unpack_plantHydraulics_PHS params

    # 9.81 is the gravitational acceleration in m/s^2, and we multiply it by psi_leaf to convert from m to J/kg.
    psi_leaf_J_kg = psi_leaf * g_acc # convert m to J/kg
    kelvin_exponent = (psi_leaf_J_kg * w_mol_mass * con_1e_3) / (k_R * temp_leaf_K)

    leaf_RH = clamp_zero_one(exp(kelvin_exponent)) # dimensionless, 0-1.
    leaf_actual_pressure = leaf_saturated_pressure * leaf_RH # kPa
    leaf_VPD = at_least_zero(leaf_actual_pressure - air_actual_pressure) # kPa.
    return leaf_VPD, leaf_RH, leaf_actual_pressure
end

### =========================
# calculate leaf latent and sensible heat fluxes.
### =========================
function cal_latent_heat_fluxes(params::plantHydraulics_PHS, forcing, land, helpers, Tleaf, psi_leaf_m, ra, rs)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_psurf_day, f_airT_day, f_daytime_seconds) ⇐ forcing
        (leaf_saturated_pressure, air_actual_pressure) ⇐ land.diagnostics
    end
    # ra is aerodynamic resistance for heat, s m-1.
    # all fluxes are per m2 of leaf area, as in SCOPE heatfluxes.m.
    # rs is stomatal resistance, s m-1.

    # patm is the atmospheric pressure in hPa.
    patm = f_psurf_day * kPa_2_hPa # kPa to hPa
    e_to_q = w_mol_mass / Mair / patm # the conversion factor from vapor pressure to specific humidity, kg kg-1 hPa-1.

    Tleaf_K = Tleaf + deg_2_K
    lambda = (lambda_0 - lambda_slope * Tleaf) * con_1e6 # J kg-1
    _, _, e_leaf = _leaf_humidity_status(params, leaf_saturated_pressure, air_actual_pressure, Tleaf_K, psi_leaf_m) # eleaf should be in hPa. but here is in kPa.
    e_leaf = e_leaf * kPa_2_hPa # kPa to hPa

    qi = e_leaf * e_to_q
    qa = kPa_2_hPa * air_actual_pressure * e_to_q # vapor pressure of the air, kPa to hPa, and then to specific humidity, kg kg-1.

    LE = rhoa / (ra + rs) * lambda * (qi - qa) # W m-2
    H = rhoa * cp / ra * (Tleaf - f_airT_day) # W m-2

    transpiration = LE / lambda * f_daytime_seconds # kg m-2 s-1 (= mm s-1) over the daytime seconds, mm d-1 (per m2 leaf)

    return LE, H, transpiration, e_to_q, lambda
end

### =========================
# solve energy balance.
### =========================




purpose(::Type{plantHydraulics_PHS}) = "Farquhar-Medlyn-Fick-PHS model framework."

@doc """

$(getModelDocString(plantHydraulics_PHS))

---

# Extended help

# Model assumptions
 1. Vcmax should not consider the effects of water stress, because water stress mainly affects the stomatal closureness, not the dark respiration.
 2. when upscale to canopy scale, we should consider the effects of nitrogen limitation on dark respiration.
 3. A stable atmospheric boundary layer.

# References
 ### cal_Deactivation_High_Temp
1. Bernacchi, C. J., Pimen℡, C. & Long, S. P. In vivo temperature response functions of parameters required to model RuBP-limited photosynthesis. Plant, Cell & Environment 26, 1419–1430 (2003).
2. Kattge, J. & Knorr, W. Temperature acclimation in a biochemical model of photosynthesis: A reanalysis of data from 36 species. Plant, Cell & Environment 30, 1176–1190 (2007).

### cal_Deactivation_Low_Temp
1. Stettz, S. G. et al. Resolving temperature limitation on spring productivity in an evergreen conifer forest using a model–data fusion framework. Biogeosciences 19, 541–558 (2022).

 ### cal_Farquhar_info -- Iabs
 1. Ren, Y. et al. Incorporating the Acclimation of Photosynthesis and Leaf Respiration in the Noah-MP Land Surface Model: Model Development and Evaluation. Journal of Advances in Modeling Earth Systems 17, e2024MS004599 (2025).
 2. Meek, D. W., Hatfield, J. L., Howell, T. A., Idso, S. B. & Reginato, R. J. A generalized relationship between photosynthetically active radiation and solar radiation. Agronomy Journal 76, 939–945 (1984).

 ### cal_vulnerability_curve
 1. Alléon, J. et al. Plant hydraulic architecture for a mechanistic representation of soil-plant-atmosphere water transfer in the land surface model ORCHIDEE (r9107). Journal of Advances in Modeling Earth Systems 17, e2024MS004869 (2025).

 ### _solve_ci_Pa
 1. Medlyn, B. E. et al. Reconciling the optimal and empirical approaches to modelling stomatal conductance. Global Change Biology 17, 2134–2144 (2011).



*Versions*
 - 1.0 on 21.09.2026 [jzhou]
 - 1.1 on 05.10.2026 [jzhou]
 - 1.2 on 18.10.2026 [jzhou]: leaf temperature from the leaf energy balance (after SCOPE)
"""
plantHydraulics_PHS
