export plantHydraulics_PHS

using StaticArrays: SMatrix, SVector

const _NEWTON_MAX_ITERATIONS = 50
const _NEWTON_MAX_BACKTRACKS = 8

_not_Inf_NaN(value, fallback) = isfinite(value) ? value : oftype(value, fallback)

function _pos_Inf_not_NaN(value)
    if isfinite(value)
        return value
    elseif isnan(value)
        return zero(value)
    end
    return copysign(floatmax(typeof(value)), value)
end

function _Boundary_not_Inf_NaN(value, floor)
    safe_floor = max(_not_Inf_NaN(floor, eps(typeof(floor))), eps(typeof(floor)))
    return max(_pos_Inf_not_NaN(value), safe_floor)
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

### highly recommended to use Ti, where i is the order of params. Because the type of each params can be different in this case, otherwise, the type of params will be promoted to the same type, which may cause some problems.
#! format: off
@bounds @describe @units @timescale @with_kw struct plantHydraulics_PHS{T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36,T37,T38,T39,T40,T41,T42,T43,T44,T45,T46,T47,T48,T49,T50,T51,T52,T53,T54,T55,T56,T57,T58,T59,T60,T61,T62,T63,T64,T65,T66,T67} <: plantHydraulics
    # root params
    root_radius::T1 = 1.5e-3 | (1.0e-5, 1.0e-2) | "fine-root radius used to infer root spacing from SINDBAD root surface area" | "m" | ""
    biomass_to_carbon::T2 = 0.488 | (0.1, 1.0) | "root carbon per unit root dry biomass" | "gC gDM-1" | ""
    root_density::T3 = 2.5e5 | (1.0e3, 1.0e6) | "root tissue dry-matter density" | "gDM m-3" | ""
    root_lateral_length::T4 = 0.25 | (1.0e-3, 10.0) | "average coarse-root lateral length" | "m" | ""
    stem_to_leaf_area_ratio::T5 = 0.1 | (0.01, 0.9) | "stem area index to leaf area index ratio" | "" | ""

    # plant hydraulic traits
    p50_leaf::T6 = -67.67 | (-500, -60.0) | "stem-to-leaf water potential at 50 percent conductivity loss" | "m" | ""
    p50_stem::T7 = -342.51 | (-1500, -50.0) | "root-to-stem water potential at 50 percent conductivity loss" | "m" | ""
    p50_root::T8 = -30.0 | (-1000, -20.0) | "soil-root water potential at 50 percent conductivity loss" | "m" | ""
    p50_leaf_stress::T9 = -150.0 | (-Inf, -1.0) | "leaf water potential at 50 percent transpiration loss" | "m" | ""

    # plant hydraulic vulnerability-curve factors
    shape_factor_leaf::T10 = 1.98 | (0.5, 10.0) | "leaf PHS vulnerability-curve shape factor" | "" | ""
    shape_factor_stem::T11 = 1.98 | (0.5, 6.0) | "stem PHS vulnerability-curve shape factor" | "" | ""
    shape_factor_root::T12 = 0.8 | (0.5, 6.0) | "root PHS vulnerability-curve shape factor" | "" | ""

    # hydraulic conductance traits
    k_root_max::T13 = 1.73e-4 | (8.64e-6, 8.64e-2) | "maximum root hydraulic conductivity" | "m d-1" | ""
    k_stem_max::T14 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum stem hydraulic conductivity" | "m d-1" | ""
    k_leaf_max::T15 = 3.46e-3 | (8.64e-6, 8.64e-2) | "maximum leaf hydraulic conductance" | "d-1" | ""

    # soil hydrology
    nvg::T16 = 1.56 | (1.1, 10.0) | "van Genuchten shape parameter" | "" | ""
    avg::T17 = 3.6 | (0.01, 100.0) | "van Genuchten inverse length parameter" | "m-1" | ""

    # Newton solvers
    newton_residual_tolerance::T18 = 1.0e-8 | (1.0e-14, 1.0e-2) | "absolute flux-balance tolerance" | "m d-1" | ""
    newton_relative_tolerance::T19 = 1.0e-6 | (1.0e-12, 1.0e-2) | "relative flux-balance tolerance" | "" | ""
    newton_step_tolerance::T20 = 1.0e-7 | (1.0e-12, 1.0) | "water-potential step tolerance" | "m" | ""
    newton_max_step::T21 = 50.0 | (1.0e-3, 1000.0) | "maximum Newton water-potential step" | "" | ""
    newton_min_damping::T22 = 1.0 / 256.0 | (1.0e-6, 1.0) | "minimum Newton line-search damping" | "" | ""

    # photosynthesis parameters
    Jmax25::T23 = 1e-4 | (2e-5, 3e-4) | "maximum electron transport rate, normalised to 25 ◦C" | "molC m-2 s-1" | ""
    Vcmax25::T24 = 5e-5 | (1e-5, 1.5e-4) | "Maximum rate of carboxylation, normalised to 25 ◦C. Ratio between J/V is about 1.5 to 2.1." | "molC m-2 s-1" | ""

    # dark-respiration
    rate_dark::T25 = 0.01 | (0.005, 0.05) | "dark-respiration rate per unit carboxylation capacity" | "" | ""

    # photorespiratory compensation point  parameters
    ha::T26 = 37830.0 | (1e-2, 1e7) | "Activation energy for gamma star" | "J mol-1" | ""
    gs25_0::T27 = 4.332 | (4.0, 5.0) | "Photorespiratory compensation point" | "Pa" | ""

    # Michaelis-Menten constants
    k_co::T28 = 209476 | (1e-2, 1e7) | "Michaelis–Menten coefficient params" | "" | ""
    dhac::T29 = 79430 | (1e-2, 1e7) | "Activation energy for Kc" | "J mol-1" | ""
    dhao::T30 = 36380 | (1e-2, 1e7) | "Activation energy for Ko" | "J mol-1" | ""
    kc25::T31 = 39.97 | (1e-2, 1e7) | "Michaelis-Menten constant for CO2 at 25C" | "Pa" | ""
    ko25::T32 = 27480 | (1e-2, 1e7) | "Michaelis-Menten constant for O2 at 25C" | "Pa" | ""

    # Medlyn gs model parameters
    g0::T33 = 0.001 | (-0.05, 0.05) | "the minimum stomatal conductance, ranges are refer to Medlyn paper" | "mol m-2 s-1" | ""
    g1::T34 = 3.0 | (1, 12.0) | "stomatal conductance parameter, ranges are refer to Medlyn paper" | "kPa^0.5" | ""
    
    # Jarvis gs model parameters
    R_sc::T35 = 100 | (1e-2, 1e3) | "scaling factor relevant to Solar radiation" | "W m-2" | ""
    r_cs_max::T36 = 5000 | (1e3, 1e7) | "maximum canopy resistance related to PFTs" | "s m-1" | ""
    Tmin::T37 = 0 | (-10, 5) | "minimum temperature for stomatal conductance" | "deg C" | ""
    Topt::T38 = 25 | (10, 40) | "optimal temperature for stomatal conductance" | "deg C" | ""
    Tmax::T39 = 40 | (30, 55) | "maximum temperature for stomatal conductance" | "deg C" | ""
    k_Temp::T40 = 0.0016 | (1e-4, 1e-1) | "temperature stress coefficient" | "unitless" | ""
    k_VPD::T41 = 0.25 | (0.1, 0.3) | "Jarvis VPD stressor params" | "" | ""
    
    # constants
    CL::T42 = 0.25 | (0.1, 0.8) | "maximum quantum yield of photosystem II in light-adapted leaves, for PAR to Iabs, refer to P model" | "" | ""
    k_R::T43 = 8.3145 | (8, 9) | "universal gas constant" | "J mol-1 K-1" | ""
    diffusivity_ratio::T44 = 1.6 | (-Inf, Inf) | "Ratio of the molecular diffusivities for water vapor and CO2" | "" | ""
    k_Po::T45 = 101325.0 | (1, 1e7) | "one standard ATM" | "Pa" | ""
    tk_ref::T46 = 298.15 | (298, 299) | "25 deg C in unit of K" | "" | ""

    # boundary conditions
    minimum_conductance::T47 = 1.0e-11 | (0.0, 1.0) | "numerical floor for hydraulic conductance" | "m d-1" | ""
    minimum_lai::T48 = 1.0e-3 | (0.0, 1.0) | "minimum LAI for solving the hydraulic network" | "m2 m-2" | ""
    minimum_height::T49 = 1.0e-3 | (1.0e-6, 10.0) | "minimum canopy height used in path-length scaling" | "m" | ""
    min_root_length_density::T50 = 1.0e-12 | (0.0, 1e7) | "root length-density floor used to avoid singular root spacing" | "m m-3" | ""
    minimum_froot_allocation::T51 = 0.001 | (0.0001, 1.0) | "minimum fine-root allocation factor" | "" | ""

    # unit conversions
    mm_2_m::T52 = 1.0e-3 | (0.0, 1e7) | "unit conversion from mm to m" | "" | ""
    m_to_mm::T53 = 1.0e3 | (0.0, 1e7) | "unit conversion from m to mm" | "" | ""
    m_to_MPa::T54 = 0.00980665 | (0.0, 1e7) | "unit conversion of water potential from m to MPa" | "" | ""
    deg_2_K::T55 = 273.15 | (1e-2, 1e7) | "Gamma star params, convert deg C to K" | "" | ""
    c_mol_mass::T56 = 12.0 | (1e-2, 1e7) | "molecular mass of carbon" | "g/mol" | ""
    w_mol_mass::T57 = 18.0 | (1e-2, 1e7) | "molecular mass of water" | "g/mol" | ""
    par_ppfd::T58 = 4.57 | (0, 5) | "PAR to PPFD conversion factor, from W/m2 to umol/m2/s" | "" | ""
    day_second::T59 = 86400 | (1e-2, 1e7) | "seconds in a day" | "s" | ""
    daytime_second::T60 = 36000 | (1e-2, 1e7) | "seconds in a daytime, assuming daytime has 10 hours" | "s" | ""

    # STEMMUS iteration parameters
    STEMMUS_max_iterations::T61 = 50 | (10, 1000) | "maximum number of iterations for STEMMUS" | "" | ""

    # Jarvis params -- additional
    r_cs_min::T62 = 100 | (1e1, 1e7) | "minimum canopy resistance related to PFTs" | "s m-1" | ""

    # soil hydrology params -- additional
    ψ_wp::T63 = -152.9 | (-1e3, -1) | "water potential at wilting point" | "m" | ""
    
    # conversion factors
    con_1e6::T64 = 1e6 | (1e0, 1e7) | "1,000,000" | "" | ""
    con_1e3::T65 = 1e3 | (1e0, 1e7) | "1,000" | "" | ""

    # dark respiration params -- additional
    k_Nitrogen::T66 = 0.2 | (0.1, 0.4) | "decay coefficient for nitrogen on dark respiration" | "" | ""

    # canopy light extinction params
    k_extinction::T67 = 0.5 | (0.3, 0.8) | "light extinction when upscaling leaf to canopy scale of photosynthesis" | "" | ""
end
#! format: on

function define(params::plantHydraulics_PHS, forcing, land, helpers)

    @unpack_nt begin
        f_canopy_height ⇐ forcing
        soilW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        plant_form ⇐ land.states
    end

    if plant_form in (:tree, :shrub)
        fine_root_fraction = 0.141
    elseif plant_form == :herb
        fine_root_fraction = 0.885
    else
        fine_root_fraction = 0.15
    end

    phs_root_water_uptake = zero(soilW)
    phs_transpiration = z_zero
    phs_root_spacing = zero(soilW)

    Κ_soil_root = zero(soilW)
    Κ_soil = zero(soilW)
    Κ_root = zero(soilW)
    Κ_soil_unsat = zero(soilW)
    
    RAI = zero(soilW)

    D_soil_inv_mm = zero(soilW)
    D_soil_m = zero(soilW)
    D_soil_cum_m = zero(soilW)
    D_root_deno = zero(soilW)

    H_canopy = f_canopy_height # canopy height, m

    ψ_leaf_prev = -H_canopy # intial leaf water potential, m
    ψ_leaf = -H_canopy
    ψ_stem = -H_canopy
    ψ_root = z_zero
    ψ_soil = zero(soilW)
    ψ_soil_matric = zero(soilW) # don't consider the soil depth gravity potential, only the matric potential, unit: m.

    θ_soil = θ_res = soil_saturation = zero(soilW) # in m3 m-3
    fraction_root = zero(soilW) # fraction of root in each soil layer, unitless

    β_root = zero(soilW) # soil water stress factor (0-1)

    ε_solver = z_zero
    ITERARIONS = z_zero
    CONVERGED = false
    
    @pack_nt begin
        (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.properties
        ((θ_soil, θ_res, soil_saturation)) ⇒ land.properties
        (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root, ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
        β_root ⇒ land.diagnostics
        (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
        (RAI, phs_root_spacing, fine_root_fraction, fraction_root) ⇒ land.diagnostics
        phs_transpiration ⇒ land.diagnostics
        phs_root_water_uptake ⇒ land.fluxes
        (ε_solver, ITERARIONS, CONVERGED) ⇒ land.diagnostics
    end
    return land
end

function precompute(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        soilW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        (sp_θ_sat, sp_θ_wp, soil_layer_thickness) ⇐ land.properties
        (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇐ land.properties
    end
    @inbounds for sl in eachindex(soilW)
        thickness = soil_layer_thickness[sl]
        thickness_m = thickness * mm_2_m
        cumulative_depth_m = sum(soil_layer_thickness[1:sl-1]) * mm_2_m + thickness_m / 2 # middle point for gravity potential.
        root_depth_denominator = root_lateral_length + cumulative_depth_m

        @rep_elem inv(thickness) ⇒ (D_soil_inv_mm, sl, :soilW)
        @rep_elem thickness_m ⇒ (D_soil_m, sl, :soilW)
        @rep_elem cumulative_depth_m ⇒ (D_soil_cum_m, sl, :soilW)
        @rep_elem root_depth_denominator ⇒ (D_root_deno, sl, :soilW)
    end
    @pack_nt begin
        (D_soil_inv_mm, D_soil_m, D_soil_cum_m, D_root_deno) ⇒ land.properties
    end
    return land
end

function compute(params::plantHydraulics_PHS, forcing, land, helpers)

    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        f_canopy_height ⇐ forcing
        (LAI, PAW) ⇐ land.states
        (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇐ land.diagnostics
        phs_root_water_uptake ⇐ land.fluxes
        root_over ⇐ land.rootWaterEfficiency
        (z_zero, o_one) ⇐ land.constants
        (ε_solver, ITERARIONS, CONVERGED) ⇐ land.diagnostics
    end

    land = cal_soil_hydrology(params, forcing, land, helpers)
    convergence_water_potential = 1e-3

    ### solve the plant hydraulics network
    ψ_leaf_tmp = ψ_leaf_prev
    for iteration in 1:STEMMUS_max_iterations

        leaf_stress = cal_vulnerability_curve(ψ_leaf_tmp, p50_leaf, shape_factor_leaf)
        _, _, _, _, _, _, _, gs, _, _, _, _ = cal_GPP_Farquhar(params, forcing, land, helpers, leaf_stress)
        transpiration = cal_transpiration_Fick(params, forcing, land, helpers, gs) * mm_2_m # m d-1

        _, _, ψ_leaf_tmp = cal_plant_hydraulic(params, forcing, land, helpers, transpiration)
        if isnan(ψ_leaf_tmp) || !isreal(ψ_leaf_tmp)
            ψ_leaf_tmp = -1
        end

        ε_solver = abs(ψ_leaf - ψ_leaf_tmp)
        ITERARIONS = iteration
        CONVERGED = ε_solver < convergence_water_potential

        if CONVERGED
            break
        end

        ### TODO: why using the middle value as the next guess? 
        ψ_leaf = (ψ_leaf + ψ_leaf_tmp) * 0.5
    end

    ψ_leaf_prev = ψ_leaf

    ### use solved leaf water potential
    β_leaf = cal_vulnerability_curve(ψ_leaf, p50_leaf, shape_factor_leaf)

    gpp_farquhar, Ac, Aj, Vc_actual, J_actual, dark_respiration, net_photosynthesis, gs_Medlyn, ci_Pa, Jmax, Vcmax, factor_LAI_Nitrogen_dark_respiration = cal_GPP_Farquhar(params, forcing, land, helpers, β_leaf)
    phs_transpiration = cal_transpiration_Fick(params, forcing, land, helpers, gs_Medlyn) # mm d-1

    transpiration = phs_transpiration * mm_2_m # m d-1
    ψ_root, ψ_stem, ψ_leaf = cal_plant_hydraulic(params, forcing, land, helpers, transpiration)
    β_stem = cal_vulnerability_curve(ψ_root, p50_stem, shape_factor_stem)
    β_stem = clamp_zero_one(β_stem)
    gpp_f_soilW = β_leaf

    @inbounds for sl in eachindex(phs_root_water_uptake)
        if root_over[sl] > z_zero
            rwu_m_per_day = cal_root_water_uptake(params, forcing, land, helpers, sl, ψ_root)
        else
            rwu_m_per_day = z_zero
        end
        uptake = rwu_m_per_day * m_to_mm
        @rep_elem uptake ⇒ (phs_root_water_uptake, sl, :soilW)
    end

    @pack_nt begin
        (ψ_leaf_prev, ψ_leaf, ψ_stem, ψ_root) ⇒ land.diagnostics
        (β_leaf, β_stem, gpp_f_soilW) ⇒ land.diagnostics
        phs_root_water_uptake ⇒ land.fluxes
        (gpp_farquhar, dark_respiration, net_photosynthesis) ⇒ land.diagnostics
        factor_LAI_Nitrogen_dark_respiration ⇒ land.diagnostics
        (Ac, Aj) ⇒ land.diagnostics
        (Jmax, Vcmax, Vc_actual, J_actual) ⇒ land.diagnostics
        (gs_Medlyn, phs_transpiration, ci_Pa) ⇒ land.diagnostics
        (ε_solver, ITERARIONS, CONVERGED) ⇒ land.diagnostics
    end
    return land
end

function cal_soil_hydrology(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        (θ_soil, θ_res, soil_saturation) ⇐ land.properties
        (sp_θ_wp, sp_θ_sat, sp_k_sat) ⇐ land.properties
        (D_soil_inv_mm, D_soil_cum_m, D_root_deno, D_soil_m) ⇐ land.properties
        (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇐ land.diagnostics
        (ψ_soil, ψ_soil_matric) ⇐ land.diagnostics
        (phs_root_spacing, β_root, RAI, fraction_root) ⇐ land.diagnostics
        (root_surface_area, c_allocation) ⇐ land.diagnostics
        root_surface_area_fraction ⇐ land.properties
        root_over ⇐ land.rootWaterEfficiency
        unsat_k_model ⇐ land.models
        (z_zero, o_one) ⇐ land.constants
    end

    Rsf = sum(root_surface_area)
    froot_to_leaf = c_allocation[1]
    lai = at_least_zero(LAI)
    sai = at_least_zero(stem_to_leaf_area_ratio * lai)

    @inbounds for sl in eachindex(soilW)
        θ = (soilW[sl] + ΔsoilW[sl]) * D_soil_inv_mm[sl]
        soil_potential, theta_res, saturation = cal_soil_matric_potential(params, forcing, land, helpers, θ, sl)

        if root_over[sl] > z_zero
            root_fraction = root_surface_area[sl] / Rsf
            layer_head = _pos_Inf_not_NaN(soil_potential - D_soil_cum_m[sl])
            root_spacing = cal_root_spacing(params, forcing, land, helpers, root_fraction, sl)
            k_soil_unsat = cal_soil_unsat(params, forcing, land, helpers, θ, sl) # m d-1

            ### soil conductance, m d-1
            ### NOTES: unsaturated conductance is not equal to soil conductance
            # k_soil = max(k_soil_unsat / root_spacing, minimum_conductance)
            Ω_soil = sqrt(π / 2) * sqrt(root_radius * D_soil_m[sl] / root_surface_area[sl]) / k_soil_unsat # m d-1
            k_soil = 1 / Ω_soil
            k_soil = max(k_soil, minimum_conductance) 

            ### TODO: it's different from A6 to A11 of CLM-PHS. -- Done!
            rai = at_least_zero((sai + lai) * root_fraction * froot_to_leaf)
            root_stress = cal_vulnerability_curve(soil_potential, p50_root, shape_factor_root) # 0-1
            # k_root = max(root_stress * rai * k_root_max / D_root_deno[sl], minimum_conductance)
            k_root = max(root_stress * k_root_max / D_root_deno[sl], minimum_conductance) # follow CLM's algorithm

            soil_to_root = _soil_root_conductance(k_soil, k_root)

            # if soil_potential == -5000
            #     soil_to_root = z_zero
            # else
            #     soil_to_root = o_one / (o_one / k_soil + o_one / k_root)
            # end

        else
            layer_head = soil_to_root = root_spacing = k_soil = k_root = k_soil_unsat = root_stress = root_fraction = rai = z_zero
        end

        @rep_elem θ ⇒ (θ_soil, sl, :soilW)
        @rep_elem theta_res ⇒ (θ_res, sl, :soilW)
        @rep_elem saturation ⇒ (soil_saturation, sl, :soilW)
        @rep_elem soil_to_root ⇒ (Κ_soil_root, sl, :soilW)
        @rep_elem k_soil ⇒ (Κ_soil, sl, :soilW)
        @rep_elem k_root ⇒ (Κ_root, sl, :soilW)
        @rep_elem k_soil_unsat ⇒ (Κ_soil_unsat, sl, :soilW)
        @rep_elem layer_head ⇒ (ψ_soil, sl, :soilW)
        @rep_elem soil_potential ⇒ (ψ_soil_matric, sl, :soilW)
        @rep_elem root_stress ⇒ (β_root, sl, :soilW)
        @rep_elem rai ⇒ (RAI, sl, :soilW)
        @rep_elem root_spacing ⇒ (phs_root_spacing, sl, :soilW)
        @rep_elem root_fraction ⇒ (fraction_root, sl, :soilW)
    end

    @pack_nt begin
        (θ_soil, θ_res, soil_saturation) ⇒ land.diagnostics
        (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇒ land.diagnostics
        (ψ_soil, ψ_soil_matric) ⇒ land.diagnostics
        (β_root, RAI, phs_root_spacing, fraction_root) ⇒ land.diagnostics
    end
    return land
end

function cal_soil_unsat(params::plantHydraulics_PHS, forcing, land, helpers, θ, sl)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (sp_θ_wp, sp_θ_sat, sp_k_sat) ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end
    # soil hydraulic property
    θ_res, cvg = cal_residual_moisture(params, forcing, land, helpers, sl)

    saturated_degree = clamp((θ - θ_res) / (sp_θ_sat[sl] - θ_res), z_zero, o_one)
    k_soil_unsat = sp_k_sat[sl] * mm_2_m * sqrt(saturated_degree) * (1 - (1 - saturated_degree ^ (1 / cvg)) ^ cvg) ^ 2
    return k_soil_unsat
end

function cal_residual_moisture(params::plantHydraulics_PHS, forcing, land, helpers, sl)

    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (sp_θ_wp, sp_θ_sat) ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end
    ### calculate residual soil moisture content based on van Genuchten model.
    cvg = o_one - o_one / nvg
    F_wp = (o_one + (avg * abs(ψ_wp))^nvg) ^ (-cvg)
    θ_res = (sp_θ_wp[sl] - F_wp * sp_θ_sat[sl]) / (o_one - F_wp)
    θ_res = clamp(θ_res, z_zero, sp_θ_wp[sl])
    return θ_res, cvg
end

function cal_soil_matric_potential(params::plantHydraulics_PHS, forcing, land, helpers, θ, sl)

    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        sp_θ_sat ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    θ_res, cvg = cal_residual_moisture(params, forcing, land, helpers, sl)
    saturation = clamp((θ - θ_res) / (sp_θ_sat[sl] - θ_res), z_zero, o_one)
    inverse_saturation = saturation ^ (-o_one / cvg)
    if !isfinite(inverse_saturation)
        return -5000, θ_res, saturation
    end
    pressure_term = max(inverse_saturation - o_one, z_zero)
    ψ_soil_matric = -(pressure_term ^ (o_one / nvg)) / avg
    if !isfinite(ψ_soil_matric)
        return -5000, θ_res, saturation
    end
    ψ_soil_matric = clamp(ψ_soil_matric, -5000, z_zero)
    return ψ_soil_matric, θ_res, saturation
end

function cal_plant_hydraulic(params::plantHydraulics_PHS, forcing, land, helpers, transpiration)
    psi_root = cal_root_water_potential(params, forcing, land, helpers, transpiration)
    psi_stem = cal_stem_water_potential(params, forcing, land, helpers, psi_root, transpiration)
    psi_leaf = cal_leaf_water_potential(params, forcing, land, helpers, psi_stem, transpiration)
    return psi_root, psi_stem, psi_leaf
end

function cal_vulnerability_curve(psi, psi50, shape_factor)
    z_zero = zero(psi50)
    o_one = one(psi50)
    if psi >= z_zero
        return o_one
    elseif !isfinite(psi)
        return z_zero
    end
    ratio = _non_negative_Finite(psi / psi50)
    ratio_power = ratio ^ shape_factor
    if !isfinite(ratio_power)
        return z_zero
    end
    stress = exp2(-ratio_power)
    return stress
end

function cal_leaf_water_potential(params::plantHydraulics_PHS, forcing, land, helpers, psi_stem, transpiration)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
    end
    Q_stem_2_leaf = transpiration # m d-1
    beta_leaf_stem = cal_vulnerability_curve(psi_stem, p50_leaf, shape_factor_leaf)
    # @show Q_stem_2_leaf, beta_leaf_stem, psi_stem
    if LAI > minimum_lai && beta_leaf_stem > 0
        leaf_conductance = k_leaf_max * beta_leaf_stem
        psi_leaf = psi_stem - Q_stem_2_leaf / LAI / leaf_conductance
        # @show LAI, leaf_conductance
        # @show Q_stem_2_leaf / LAI / leaf_conductance
        # @show psi_leaf
    else
        psi_leaf = psi_stem
        # @show "small LAI" psi_leaf
    end
    return psi_leaf
end

function cal_stem_water_potential(params::plantHydraulics_PHS, forcing, land, helpers, psi_root, transpiration)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        f_canopy_height ⇐ forcing
        LAI ⇐ land.states
    end
    H_canopy = f_canopy_height # m
    Q_root_2_stem = transpiration # m d-1
    beta_stem_root = cal_vulnerability_curve(psi_root, p50_stem, shape_factor_stem)
    SAI = stem_to_leaf_area_ratio * LAI
    # @show Q_root_2_stem, beta_stem_root
    # @show psi_root, SAI
    if LAI > minimum_lai && beta_stem_root > 0 && H_canopy > 0
        stem_conductance = k_stem_max * beta_stem_root / H_canopy
        psi_stem = psi_root - H_canopy - Q_root_2_stem / SAI / stem_conductance
        # @show stem_conductance, Q_root_2_stem / SAI / stem_conductance
        # @show psi_root - H_canopy
        # @show psi_stem
    else
        psi_stem = psi_root - H_canopy
        # @show "small LAI or canopy height" psi_stem
    end
    return psi_stem
end

function cal_root_water_potential(params::plantHydraulics_PHS, forcing, land, helpers, transpiration)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (Κ_soil_root, Κ_soil, Κ_root, Κ_soil_unsat) ⇐ land.diagnostics
        (ψ_soil_matric, ψ_soil, fraction_root, RAI, root_surface_area) ⇐ land.diagnostics
        soilW ⇐ land.pools
        root_over ⇐ land.rootWaterEfficiency
        (D_soil_cum_m, soil_layer_thickness) ⇐ land.properties
        z_zero ⇐ land.constants
    end

    # max_Ω = 1e6 # d m-1, i.e, root absorb 0.001 mm H2O per day, which is too slow.
    max_Ω = 1e5 # d m-1, i.e, root absorb 0.01 mm H2O per day, which is too slow.
    Q_soil_2_root = transpiration # m d-1
    if abs(sum(Κ_soil_root[1])) == z_zero
        psi_root = sum(ψ_soil) / length(soilW)
        # @show "no soil to root conductance" psi_root, sum(ψ_soil)
    else
        num_root_layer = sum(root_over .> z_zero)
        psi_root = z_zero
        for sl in 1:num_root_layer
            ### VOM's algorithm
            Ω_soil = 1 / Κ_soil[sl] # m d-1
            Ω_root = 1 / Κ_root[sl]
            if root_surface_area[sl] == z_zero || (Ω_soil + Ω_root) > max_Ω
                psi_root_layer = z_zero # no root, no psi
                # @show sl, "no root or resistance is too large in this layer when calculating root water potential"
            else
                psi_root_layer = ψ_soil[sl] - (Ω_soil + Ω_root) * (Q_soil_2_root * fraction_root[sl]) / root_surface_area[sl]
                # @show sl, root_surface_area[sl], fraction_root[sl]
                # @show sl, ψ_soil[sl], Ω_soil, Ω_root
                # @show sl, Q_soil_2_root, Q_soil_2_root * fraction_root[sl]
                # @show sl, (Q_soil_2_root * fraction_root[sl]) / root_surface_area[sl]
                # @show sl, (Ω_soil + Ω_root) * (Q_soil_2_root * fraction_root[sl]) / root_surface_area[sl]
            end

            ### CLM's algorithm
            # psi_root_layer = ψ_soil[sl] - (Q_soil_2_root * fraction_root[sl]) / (Κ_soil_root[sl] * RAI[sl])

            ### STEMMUS's algorithm
            # psi_root_layer = (Κ_soil_root[sl] * ψ_soil[sl] - Q_soil_2_root * fraction_root[sl]) / Κ_soil_root[sl]

            # fraction_root is too small.
            psi_root += psi_root_layer * fraction_root[sl]

            # @show sl, psi_root_layer, psi_root
            
            # @show ψ_soil[sl], Κ_soil_root[sl], Q_soil_2_root * fraction_root[sl], Κ_soil_root[sl] * (ψ_soil_matric[sl] - D_soil_cum_m[sl]), (Κ_soil_root[sl] * (ψ_soil_matric[sl] - D_soil_cum_m[sl]) - Q_soil_2_root * fraction_root[sl])
        end
        if !isreal(psi_root)
            psi_root = sum(ψ_soil * fraction_root)
            # @show "complex root water potential" psi_root
        end
        if !isfinite(psi_root)
            return -con_1e3
        end
        psi_root = max(psi_root, -con_1e3) # -10MPa to m = -1019.368
        psi_root = min(z_zero, psi_root)
        # @show psi_root
    end
    return psi_root
end

function cal_root_water_uptake(params::plantHydraulics_PHS, forcing, land, helpers, sl, ψ_root)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        Κ_soil_root ⇐ land.diagnostics
        ψ_soil ⇐ land.diagnostics
        PAW ⇐ land.states
        z_zero ⇐ land.constants
    end

    uptake_capacity = PAW[sl] * mm_2_m # convert mm to m
    soil_water_head = ψ_soil[sl]
    soil_2_root_conductance = Κ_soil_root[sl]

    # root water potential should be in m
    root_water_uptake = at_least_zero(soil_2_root_conductance * (soil_water_head - ψ_root))
    root_water_uptake = min(root_water_uptake, uptake_capacity) # m d-1
    return root_water_uptake
end

function cal_root_spacing(params::plantHydraulics_PHS, forcing, land, helpers, root_fraction, sl)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        cEco ⇐ land.pools
        fine_root_fraction ⇐ land.diagnostics
        D_soil_m ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    # The root carbon should be fine root carbon, not total root carbon.
    root_carbon = cEco[1] * fine_root_fraction
    layer_thickness_m = D_soil_m[sl] # soil layer thickness in m

    numerator = root_carbon * root_fraction
    denominator = biomass_to_carbon * root_density * pi * root_radius ^ 2 * layer_thickness_m
    denominator = _Boundary_not_Inf_NaN(denominator, oftype(root_carbon, 1.0e-24))

    root_length_density = _Boundary_not_Inf_NaN(numerator / denominator, min_root_length_density)
    spacing = sqrt(inv(pi * root_length_density))
    root_space = _Boundary_not_Inf_NaN(spacing, oftype(root_carbon, 1.0e-12))
    return root_space
end

function cal_KM(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_psurf_day, f_airT_day) ⇐ forcing
        (z_zero, o_one) ⇐ land.constants
    end
    ### This function is used to calculate The effective Michaelis–Menten coefficient K (Pa) of RuBisCO-limited photosynthesis.
    patm = f_psurf_day * 1e3 # kPa to Pa
    tk = f_airT_day + deg_2_K # deg C to K
    kc = kc25 * exp(dhac * (tk - tk_ref) / (tk_ref * k_R * tk))
    ko = ko25 * exp(dhao * (tk - tk_ref) / (tk_ref * k_R * tk))
    po = k_co * 1e-06 * patm
    kmm = kc * (o_one + po / ko) # Pa
    return kmm
end

function cal_Phi_o(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        f_airT_day ⇐ forcing
    end
    ### This function is used to calculate the intrinsic quantum yield (φ0(T), mol mol−1).
    f_T = 0.325 + 0.022 * f_airT_day - 0.00034 * f_airT_day ^ 2 # dimensionless
    phi_o = CL * f_T # dimensionless
    return phi_o
end

function cal_gamma_star(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_psurf_day, f_airT_day) ⇐ forcing
    end
    patm = f_psurf_day * 1e3 # kPa to Pa
    tk = f_airT_day + deg_2_K # deg C to K
    arrhenius_factor = exp(ha * (tk - tk_ref) / (tk_ref * k_R * tk)) # dimensionless
    gamma_star = (gs25_0 * patm / k_Po) * arrhenius_factor # Pa
    return gamma_star
end

function cal_Jmax_Vmax(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        f_airT_day ⇐ forcing
    end
    ### consider the effects of temperature on Vc and J
    # according to arrhenius function to convert Vcmax25 and Jmax25 to Vcmax and Jmax at current temperature.
    tk = f_airT_day + deg_2_K # deg C to K
    arrhenius_factor = exp(ha * (tk - tk_ref) / (tk_ref * k_R * tk)) # dimensionless
    Vcmax = Vcmax25 * arrhenius_factor # molC m-2 d-1
    Jmax = Jmax25 * arrhenius_factor # molC m-2 d-1
    return Jmax, Vcmax
end

function cal_efficient_LAI(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        LAI ⇐ land.states
    end
    ### based on beer-lambert law, the effective LAI is calculated as follows:
    efficient_lai = (1 - exp(-k_extinction * LAI)) / k_extinction # dimensionless
    # efficient_lai = 0.3 * LAI + 1.2
    return efficient_lai
end

function cal_leaf_internal_CO2(params::plantHydraulics_PHS, forcing, land, helpers)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_psurf_day, f_VPD_day) ⇐ forcing
        ambient_CO2 ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end
    patm = f_psurf_day * 1e3 # kPa to Pa
    ca = 1.0e-6 * ambient_CO2 * patm # ppm to Pa
    ciNoCO2 = g1 / (g1 + sqrt(f_VPD_day)) # fraction, f_VPD_day should be in kPa.
    ci = ciNoCO2 * ca # Pa
    return ci
end

function cal_dark_respiration(params::plantHydraulics_PHS, forcing, land, helpers, Vcmax)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_psurf_day) ⇐ forcing
        (ambient_CO2, LAI) ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end
    # dark respiration occurs in 24 hours.
    # leaf scale

    ### Important: Vcmax should not consider the effects of water stress, because water stress mainly affects the stomatal closureness, not the dark respiration. CLM5 & CABLE also do not consider the effects of water stress on dark respiration.
    ### some field observations also found that water stress has no significant effect on dark respiration, but GPP is significantly reduced.
    dark_respiration = rate_dark * Vcmax # mol C m-2 s-1
    dark_respiration *= c_mol_mass * day_second # gC m-2 d-1

    # upscale to canopy scale
    ### Important: when upscale to canopy scale, we should consider the effects of nitrogen limitation on dark respiration.
    factor_LAI_Nitrogen = (1 - exp(-k_Nitrogen * LAI)) / k_Nitrogen # dimensionless
    dark_respiration = dark_respiration * factor_LAI_Nitrogen # gC m-2 d-1

    return dark_respiration, factor_LAI_Nitrogen
end

function cal_gs_Medlyn(params::plantHydraulics_PHS, forcing, land, helpers, net_photosynthesis, ca)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_VPD_day) ⇐ forcing
        ambient_CO2 ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end
    # unit: net_photosynthesis is molC m-2 s-1, ca is mol CO2 mol-1 air, f_VPD_day is kPa.
    gs = g0 + (1 + g1 / sqrt(f_VPD_day)) * (net_photosynthesis / ca) # molC m-2 s-1 Pa-1
    # @show gs, net_photosynthesis
    # @show (1 + g1 / sqrt(f_VPD_day)) * (net_photosynthesis / ca)
    return gs
end

function cal_GPP_Farquhar(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_PAR, f_VPD_day) ⇐ forcing
        (fAPAR, ambient_CO2) ⇐ land.states
        (z_zero, o_one) ⇐ land.constants
    end

    gamma_star = cal_gamma_star(params, forcing, land, helpers)
    KM = cal_KM(params, forcing, land, helpers) # effective Michaelis–Menten coefficient K (Pa)
    Jmax, Vcmax = cal_Jmax_Vmax(params, forcing, land, helpers) # mol C m-2 s-1
    ci = cal_leaf_internal_CO2(params, forcing, land, helpers) # Pa

    ### carboxylation-limited rate, Ac.
    Vc_actual = Vcmax * leaf_stress # mol C m-2 s-1
    co2_numerator = at_least_zero(ci - gamma_star)
    Ac = Vc_actual * co2_numerator / (ci + KM) # mol C m-2 s-1

    ### light-limited rate, Aj.
    Iabs = f_PAR * fAPAR * par_ppfd * con_1e6 / day_second # absorbed irradiance, mol/m2/s
    Phi_o = cal_Phi_o(params, forcing, land, helpers) # the intrinsic quantum-yield efficiency, dimensionless
    numerator = 4 * Phi_o * Iabs
    denominator = (numerator / Jmax) ^ 2 + o_one
    J_actual = numerator / sqrt(denominator) # mol C m-2 s-1
    Aj = ci > gamma_star ? J_actual * (ci - gamma_star) / (4 * ci + 8 * gamma_star) : z_zero # mol C m-2 s-1

    gpp_farquhar = min(Ac, Aj)
    efficient_lai = cal_efficient_LAI(params, forcing, land, helpers)
    gpp_farquhar = gpp_farquhar * efficient_lai * c_mol_mass * daytime_second # g C m-2 d-1
    Ac = Ac * efficient_lai * c_mol_mass * daytime_second # g C m-2 d-1
    Aj = Aj * efficient_lai * c_mol_mass * daytime_second # g C m-2 d-1

    ca = 1.0e-6 * ambient_CO2 # ppm to mol CO2 mol-1 air
    dark_respiration, factor_LAI_Nitrogen = cal_dark_respiration(params, forcing, land, helpers, Vcmax)
    net_photosynthesis = gpp_farquhar - dark_respiration
    net_photosynthesis_mol = net_photosynthesis / c_mol_mass / day_second
    gs = cal_gs_Medlyn(params, forcing, land, helpers, net_photosynthesis_mol, ca)
    gs = at_least_zero(gs)

    return gpp_farquhar, Ac, Aj, Vc_actual, J_actual, dark_respiration, net_photosynthesis, gs, ci, Jmax, Vcmax, factor_LAI_Nitrogen
end

function cal_transpiration_Fick(params::plantHydraulics_PHS, forcing, land, helpers, gs)
    @unpack_plantHydraulics_PHS params
    @unpack_nt begin
        (f_psurf_day, f_VPD_day) ⇐ forcing
    end
    ### unit: gs is molC m-2 s-1, VPD should be Pa.
    patm = f_psurf_day * con_1e3 # kPa to Pa
    vpd = at_least_zero(f_VPD_day) * con_1e3 # kPa to Pa
    # vpd / patm is used to calculate mole fraction of water vapor in the air.
    mole_fraction = vpd / patm # mol H2O mol-1 air

    Tr_fick = diffusivity_ratio * gs * mole_fraction # mol H2O m-2 s-1
    Tr_fick = Tr_fick * w_mol_mass * daytime_second / con_1e3 # mm d-1
    return Tr_fick
end

# function GPP_Fick(params::plantHydraulics_PHS, forcing, land, helpers, ci, gs)
#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day) ⇐ forcing
#         ambient_CO2 ⇐ land.states
#         (z_zero, o_one) ⇐ land.constants
#     end
#     patm = f_psurf_day * con_1e3 # kPa to Pa
#     ca = 1.0e-6 * ambient_CO2 * patm # ppm to Pa
#     ### ci is provided by the Newton solver here.
#     gamma_star = cal_gamma_star(params, forcing, land, helpers) # CO2 compensation point, Pa
#     gpp_fick = gamma_star < ci < ca  ? gs * (ca - ci) : z_zero # mol C m-2 d-1
#     gpp_fick = gpp_fick * c_mol_mass # convert to g C m-2 d-1
#     return gpp_fick 
# end

# function cal_gs_Jarvis(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_psurf_day, f_airT_day) ⇐ forcing
#         z_zero ⇐ land.constants
#     end

#     ### Canopy resistance, s m-1
#     rs_c = cal_r_sc(params, forcing, land, helpers, leaf_stress) # s m-1

#     ### convert to m2 s umol-1 CO2 -- based on the ideal gas law
#     patm = f_psurf_day # kPa
#     temp = f_airT_day + deg_2_K # deg C
#     Rgas = k_R / con_1e3 # from J mol-1 K-1 to MJ mol-1 K-1
#     rs = rs_c * Rgas * temp / (patm * 1e6) # m2 s umol-1 C Pa-1. 1e6 is also used to convert kPa to Pa.

#     ### Canopy conductance
#     # gs_c = rs_c == r_cs_max ? z_zero : 1 / rs # umolC m-2 s-1
#     gs_c = 1 / rs # umolC m-2 s-1
#     # convert to molC m-2 day-1
#     gs_c = gs_c * day_second / 1e6 # molC m-2 d-1

#     return gs_c
# end

# function cal_r_sc(params::plantHydraulics_PHS, forcing, land, helpers, leaf_stress)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt begin
#         (f_VPD_day, f_airT_day, f_SW) ⇐ forcing
#         LAI ⇐ land.states
#         tolerance ⇐ helpers.numbers
#         (z_zero, o_one) ⇐ land.constants
#     end

#     ### leaf_stress is provided by the Newton solver here.

#     # _, _, _, _, _, _, _, _ = get_pft_value(params, forcing, land, helpers)

#     # radiation stress
#     R_solar = f_SW * 1e6 / day_second # shortwave radiation, convert MJ m-2 d-1  to W m-2
#     f = 0.55 * 2 * (R_solar / (day_second * 1e-6)) / (R_sc * LAI)
#     f1_rad = (f + r_cs_min / r_cs_max) / (f + o_one)

#     # Temperature stress
#     T = f_airT_day # deg C
#     f2_T = (Tmin < T && T < Tmax) ? o_one - k_Temp * (Topt - T) ^ 2 : z_zero

#     # VPD stress
#     VPD = at_least_zero(f_VPD_day) # kPa
#     f3_VPD = VPD > 4 ? z_zero : o_one - k_VPD * VPD

#     # water stress -- based on PSi
#     f4_water = leaf_stress

#     # efficient LAI -- to consider clumping  effect
#     F_s = 0.3 * LAI + 1.2

#     # canopy resistance, s m-1
#     denominator = LAI * f1_rad * f2_T * f3_VPD * f4_water
#     r_sc = denominator == z_zero ? r_cs_max : r_cs_min * F_s / denominator
#     r_sc = clamp(r_sc, r_cs_min, r_cs_max)

#     return r_sc
# end

# function get_pft_value(params::plantHydraulics_PHS, forcing, land, helpers)

#     @unpack_plantHydraulics_PHS params
#     @unpack_nt PFT ⇐ land.PFT

#     PFT = Int(PFT)

#     # only includes PFTs from 1-12
#     LAI_max = [5.5, 7, 3.3, 7, 5.7, 4.6, 3, 1.5, 0.9, 1.8, 6, 7] 
#     w_max = [0.001, 0.05, 0.001, 0.08, 0.04, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01]
#     h_c_min = [17, 30, 17, 25, 20, 1.5, 1, 0.8, 0.1, 0.05, 0.05, 0]
#     h_c_max = [17, 30, 17, 25, 20, 1.5, 1, 0.8, 0.8, 0.8, 1.0, 0.8]
#     k_VPD = [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.155, 0.00, 0.23]
#     z_0g = [0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.005]
#     r_cs_min = [125, 150, 150, 100, 125, 150, 100, 70, 70, 40, 100, 40] # s m-1
#     Cr = [0.45, 0.59, 0.45, 0.59, 0.59, 0.56, 0.56, 0.5, 0.5, 0.5, 0.0, 0.62]

#     return LAI_max[PFT], w_max[PFT], h_c_min[PFT], h_c_max[PFT], k_VPD[PFT], z_0g[PFT], r_cs_min[PFT], Cr[PFT]
# end

purpose(::Type{plantHydraulics_PHS}) = "Three-node, damped-Newton plant hydraulics with one-way, water-limited root uptake."

@doc """

$(getModelDocString(plantHydraulics_PHS))

---

# Extended help

Solves leaf, stem, and root water potentials simultaneously from three flux
continuity equations. Soil-to-root fluxes are nonnegative and bounded by
plant-available water, so roots can extract water but cannot supply it to soil.

The previous time-step water potentials are used as the Newton initial guess.
The solver reports convergence, iteration count, and the maximum flux residual.

*Versions*
 - 1.0 on 21.09.2026 [jzhou]
"""
plantHydraulics_PHS
