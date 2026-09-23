export plantHydraulics_STEMMUS

const _STEMMUS_PHS_MAX_ITERATIONS = 30

#! format: off
@bounds @describe @units @timescale @with_kw struct plantHydraulics_STEMMUS{T} <: plantHydraulics
    root_carbon::T = 1000.0 | (0.0, 10000.0) | "initial total root carbon used by STEMMUS-SCOPE" | "gC m-2" | ""
    biomass_to_carbon::T = 0.488 | (0.1, 1.0) | "root carbon per unit root dry biomass" | "gC gDM-1" | ""
    root_radius::T = 1.5e-3 | (1.0e-5, 1.0e-2) | "effective absorbing-root radius" | "m" | ""
    root_density::T = 2.5e5 | (1.0e3, 1.0e6) | "root tissue dry-matter density" | "gDM m-3" | ""
    root_distribution_beta::T = 0.943 | (0.8, 0.9999) | "Jackson root-distribution beta; 0.993 forest/wetland, 0.966 shrub, 0.943 crop/grass/savanna" | "" | ""
    stem_to_leaf_area_ratio::T = 0.1 | (0.0, 2.0) | "stem area index to leaf area index ratio" | "" | ""
    p50_leaf::T = -67.67 | (-1000.0, -1.0) | "stem-to-leaf vulnerability P50" | "m" | ""
    p50_stem::T = -342.51 | (-1000.0, -1.0) | "root-to-stem vulnerability P50" | "m" | ""
    p50_root::T = -300.0 | (-1000.0, -1.0) | "root vulnerability P50" | "m" | ""
    p50_leaf_stress::T = -150.0 | (-1000.0, -1.0) | "hard-coded final leaf-stress P50 in STEMMUS-SCOPE" | "m" | ""
    shape_factor_leaf::T = 1.98 | (0.01, 20.0) | "leaf vulnerability shape factor" | "" | ""
    shape_factor_stem::T = 1.98 | (0.01, 20.0) | "stem vulnerability shape factor" | "" | ""
    shape_factor_root::T = 1.98 | (0.01, 20.0) | "root vulnerability shape factor" | "" | ""
    hydraulic_curve::T = 3.0 | (1.0, 3.0) | "vulnerability curve: 1 CLM5, 2 ED2, 3 STEMMUS-PHS" | "" | ""
    k_root_max::T = 1.28e-7 * 86400 | (0.0, 1.0) | "maximum root hydraulic conductivity" | "m d-1" | ""
    k_stem_max::T = 3.88e-8 * 86400 | (0.0, 1.0) | "maximum stem hydraulic conductivity" | "m d-1" | ""
    k_leaf_max::T = 1.77e-10 * 86400 | (0.0, 1.0) | "maximum leaf hydraulic conductance" | "d-1" | ""
    root_lateral_length::T = 0.25 | (1.0e-3, 10.0) | "average coarse-root lateral length" | "m" | ""
    minimum_root_stress::T = 1.0e-2 | (0.0, 1.0) | "STEMMUS lower bound for root vulnerability" | "" | ""
    minimum_stem_stress::T = 1.0e-1 | (0.0, 1.0) | "STEMMUS lower bound for stem vulnerability" | "" | ""
    minimum_conductance::T = 1.0e-16 * 86400 | (0.0, 1.0e-3) | "STEMMUS conductance floor converted to daily units" | "d-1" | ""
    minimum_lai::T = 1.0e-6 | (0.0, 1.0) | "minimum LAI for hydraulic calculations" | "m2 m-2" | ""
    minimum_height::T = 1.0e-3 | (1.0e-6, 10.0) | "minimum canopy height" | "m" | ""
    minimum_root_length_density::T = 1.0e-12 | (0.0, Inf) | "root length-density floor" | "m m-3" | ""
    minimum_froot_to_leaf::T = 0.15 | (0.0, 1.0) | "minimum fine-root to leaf allocation ratio" | "" | ""
    maximum_froot_to_leaf::T = 0.30 | (0.0, 1.0) | "maximum fine-root to leaf allocation ratio" | "" | ""
    froot_lai_decay::T = 0.15 | (0.0, 10.0) | "LAI decay coefficient in froot2leaf" | "" | ""
    froot_allocation_scale::T = 0.9 | (0.0, 10.0) | "numerator coefficient in froot2leaf" | "" | ""
    froot_soil_stress_weight::T = 2.0 | (0.0, 20.0) | "soil-stress weight in froot2leaf" | "" | ""
    nvg::T = 1.56 | (1.01, 10.0) | "van Genuchten n" | "" | ""
    avg::T = 3.6 | (0.01, 100.0) | "van Genuchten alpha" | "m-1" | ""
    psi0::T = -0.33 | (-10.0, 0.0) | "reference potential in the STEMMUS-PHS logistic curve" | "MPa" | ""
    m_to_mpa::T = 9810 / 1.0e6 | (0.0, Inf) | "water-head to pressure conversion" | "MPa m-1" | ""
    root_potential_floor::T = -1000.0 | (-10000.0, 0.0) | "lower bound on root water potential" | "m" | ""
    soil_potential_floor::T = -5000.0 | (-10000.0, 0.0) | "lower bound on soil water potential" | "m" | ""
    water_potential_tolerance::T = 0.01 | (1.0e-6, 10.0) | "leaf-potential convergence tolerance" | "m" | ""
    water_potential_relaxation::T = 0.5 | (0.01, 1.0) | "leaf-potential relaxation factor" | "" | ""
    soil_stress_slope::T = 100.0 | (1.0, 1000.0) | "coefficient in the STEMMUS soil-water stress logistic" | "" | ""
    negative_uptake_floor::T = 1.0e-20 * 86400 * 1000 | (0.0, 1.0e-6) | "replacement for negative root uptake in daily units" | "mm d-1" | ""
    water_molar_mass::T = 0.01801528 | (0.018, 0.019) | "molar mass of water" | "kg mol-1" | ""
    carbon_molar_mass::T = 12.011 | (12.0, 12.1) | "molar mass of carbon" | "g mol-1" | ""
    seconds_per_day::T = 86400.0 | (8.0e4, 9.0e4) | "seconds per day" | "s d-1" | ""
    minimum_pressure::T = 1.0e-6 | (0.0, 1.0) | "minimum atmospheric pressure" | "kPa" | ""
    mm_to_m::T = 1.0e-3 | (0.0, Inf) | "millimetre to metre conversion" | "" | ""
    m_to_mm::T = 1.0e3 | (0.0, Inf) | "metre to millimetre conversion" | "" | ""
end
#! format: on

function define(params::plantHydraulics_STEMMUS, forcing, land, helpers)
    @unpack_nt begin
        soilW ⇐ land.pools
        (z_zero, o_one) ⇐ land.constants
        f_canopy_height ⇐ forcing
    end

    stemmus_root_fraction = zero(soilW)
    stemmus_root_length_density = zero(soilW)
    stemmus_root_length_fraction = zero(soilW)
    stemmus_root_spacing = zero(soilW)
    stemmus_layer_thickness_m = zero(soilW)
    stemmus_cumulative_depth_m = zero(soilW)
    stemmus_inv_layer_thickness = zero(soilW)
    stemmus_inv_theta_range = zero(soilW)
    ψ_soil = zero(soilW)
    stemmus_layer_total_head = zero(soilW)
    Κ_unsat = zero(soilW)
    Κ_soil = zero(soilW)
    Κ_root = zero(soilW)
    Κ_soil_root = zero(soilW)
    stemmus_root_stress = zero(soilW)
    stemmus_root_area_index = zero(soilW)
    stemmus_root_water_uptake_raw = zero(soilW)
    stemmus_root_water_uptake = zero(soilW)
    stemmus_root_uptake_fraction = zero(soilW)

    canopy_height = max(f_canopy_height, params.minimum_height)
    ψ_leaf = -canopy_height
    ψ_stem = -canopy_height
    ψ_root = z_zero
    stemmus_leaf_stress = o_one
    stemmus_stem_stress = o_one
    stemmus_soil_water_stress = o_one
    stemmus_froot_to_leaf = params.minimum_froot_to_leaf
    stemmus_stem_area_index = z_zero
    Κ_root_stem = z_zero
    Κ_stem_leaf = z_zero
    stemmus_gpp = z_zero
    stemmus_transpiration = z_zero
    stemmus_stomatal_conductance_coupled = z_zero
    stemmus_canopy_conductance_coupled = z_zero
    stemmus_iterations = 0
    stemmus_converged = false
    gpp_f_soilW = o_one

    @pack_nt begin
        (stemmus_root_fraction, stemmus_root_length_density,
        stemmus_root_length_fraction, stemmus_root_spacing,
        stemmus_layer_thickness_m, stemmus_cumulative_depth_m,
        stemmus_inv_layer_thickness, stemmus_inv_theta_range) ⇒ land.properties
        (ψ_soil, stemmus_layer_total_head,
        Κ_unsat, Κ_soil,
        Κ_root, Κ_soil_root,
        stemmus_root_stress, stemmus_root_area_index,
        stemmus_root_uptake_fraction, ψ_leaf,
        ψ_stem, ψ_root,
        stemmus_leaf_stress, stemmus_stem_stress,
        stemmus_soil_water_stress, stemmus_froot_to_leaf,
        stemmus_stem_area_index, Κ_root_stem,
        Κ_stem_leaf, stemmus_gpp,
        stemmus_transpiration, stemmus_stomatal_conductance_coupled,
        stemmus_canopy_conductance_coupled, stemmus_iterations,
        stemmus_converged, gpp_f_soilW) ⇒ land.diagnostics
        (stemmus_root_water_uptake_raw,
        stemmus_root_water_uptake) ⇒ land.fluxes
    end
    return land
end

function precompute(params::plantHydraulics_STEMMUS, forcing, land, helpers)
    @unpack_plantHydraulics_STEMMUS params
    @unpack_nt begin
        soilW ⇐ land.pools
        (sp_θ_fc, sp_θ_wp, soil_layer_thickness) ⇐ land.properties
        (stemmus_root_fraction, stemmus_root_length_density,
        stemmus_root_length_fraction, stemmus_root_spacing,
        stemmus_layer_thickness_m, stemmus_cumulative_depth_m,
        stemmus_inv_layer_thickness, stemmus_inv_theta_range) ⇐ land.properties
        z_zero ⇐ land.constants
    end

    beta = clamp(root_distribution_beta, oftype(root_distribution_beta, 0.8), oftype(root_distribution_beta, 0.9999))
    radius = max(root_radius, eps(typeof(root_radius)))
    root_cross_area = oftype(radius, pi) * radius ^ 2
    root_length_index = max(root_carbon, z_zero) /
        (max(biomass_to_carbon, eps(typeof(biomass_to_carbon))) *
        max(root_density, eps(typeof(root_density))) * root_cross_area)
    cumulative_depth_cm = z_zero
    previous_depth_cm = z_zero
    previous_thickness_cm = z_zero
    total_root_length_density = z_zero

    @inbounds for sl in eachindex(soilW)
        thickness_mm = max(soil_layer_thickness[sl], eps(typeof(soil_layer_thickness[sl])))
        thickness_m = thickness_mm * mm_to_m
        thickness_cm = thickness_mm * oftype(thickness_mm, 0.1)
        cumulative_depth_cm += thickness_cm
        root_fraction = if sl == firstindex(soilW)
            one(beta) - beta ^ (cumulative_depth_cm / 2)
        else
            beta ^ (previous_depth_cm - previous_thickness_cm / 2) -
                beta ^ (previous_depth_cm + thickness_cm / 2)
        end
        root_fraction = max(root_fraction, z_zero)
        root_length_density = max(
            root_length_index * root_fraction / thickness_m,
            minimum_root_length_density,
        )
        root_spacing = sqrt(inv(oftype(root_length_density, pi) * root_length_density))
        theta_range = max(sp_θ_fc[sl] - sp_θ_wp[sl], eps(typeof(sp_θ_fc[sl])))

        @rep_elem root_fraction ⇒ (stemmus_root_fraction, sl, :soilW)
        @rep_elem root_length_density ⇒ (stemmus_root_length_density, sl, :soilW)
        @rep_elem root_spacing ⇒ (stemmus_root_spacing, sl, :soilW)
        @rep_elem thickness_m ⇒ (stemmus_layer_thickness_m, sl, :soilW)
        @rep_elem cumulative_depth_cm / 100 ⇒ (stemmus_cumulative_depth_m, sl, :soilW)
        @rep_elem inv(thickness_mm) ⇒ (stemmus_inv_layer_thickness, sl, :soilW)
        @rep_elem inv(theta_range) ⇒ (stemmus_inv_theta_range, sl, :soilW)

        total_root_length_density += root_length_density
        previous_depth_cm = cumulative_depth_cm
        previous_thickness_cm = thickness_cm
    end

    denominator = max(total_root_length_density, eps(typeof(total_root_length_density)))
    @inbounds for sl in eachindex(soilW)
        fraction = stemmus_root_length_density[sl] / denominator
        @rep_elem fraction ⇒ (stemmus_root_length_fraction, sl, :soilW)
    end

    @pack_nt begin
        (stemmus_root_fraction, stemmus_root_length_density,
        stemmus_root_length_fraction, stemmus_root_spacing,
        stemmus_layer_thickness_m, stemmus_cumulative_depth_m,
        stemmus_inv_layer_thickness, stemmus_inv_theta_range) ⇒ land.properties
    end
    return land
end

function compute(params::plantHydraulics_STEMMUS, forcing, land, helpers)
    @unpack_plantHydraulics_STEMMUS params
    @unpack_nt begin
        (f_airT_day, f_VPD_day, f_psurf_day, f_canopy_height) ⇐ forcing
        (LAI, PAW, ambient_CO2) ⇐ land.states
        (soilW, ΔsoilW) ⇐ land.pools
        (sp_k_sat, sp_θ_sat, sp_θ_fc, sp_θ_wp) ⇐ land.properties
        (stemmus_root_length_density, stemmus_root_spacing,
        stemmus_cumulative_depth_m, stemmus_inv_layer_thickness,
        stemmus_inv_theta_range) ⇐ land.properties
        (ψ_soil, stemmus_layer_total_head,
        Κ_unsat, Κ_soil,
        Κ_root, Κ_soil_root,
        stemmus_root_stress, stemmus_root_area_index,
        stemmus_root_uptake_fraction, ψ_leaf) ⇐ land.diagnostics
        (gpp_demand, stemmus_stomatal_method,
        stemmus_ballberry_slope, stemmus_ballberry_intercept,
        stemmus_medlyn_slope, stemmus_medlyn_intercept,
        stemmus_minimum_vpd,
        stemmus_boundary_layer_conductance) ⇐ land.diagnostics
        (stemmus_root_water_uptake_raw,
        stemmus_root_water_uptake) ⇐ land.fluxes
        root_over ⇐ land.rootWaterEfficiency
        unsat_k_model ⇐ land.models
        (z_zero, o_one) ⇐ land.constants
    end

    lai = max(LAI, z_zero)
    canopy_height = max(f_canopy_height, minimum_height)
    stemmus_stem_area_index = stem_to_leaf_area_ratio * lai

    active_root_length = z_zero
    @inbounds for sl in eachindex(soilW)
        if root_over[sl] > zero(root_over[sl])
            active_root_length += stemmus_root_length_density[sl]
        end
    end
    active_root_length = max(active_root_length, eps(typeof(active_root_length)))

    stemmus_soil_water_stress = z_zero
    @inbounds for sl in eachindex(soilW)
        if root_over[sl] > zero(root_over[sl])
            θ = (soilW[sl] + ΔsoilW[sl]) * stemmus_inv_layer_thickness[sl]
            layer_stress = inv(
                o_one + exp(
                    (-soil_stress_slope * sp_θ_sat[sl]) *
                    (θ - (sp_θ_fc[sl] + sp_θ_wp[sl]) / 2),
                ),
            )
            root_weight = stemmus_root_length_density[sl] / active_root_length
            stemmus_soil_water_stress += root_weight * layer_stress
        end
    end
    stemmus_soil_water_stress = clamp(stemmus_soil_water_stress, z_zero, o_one)
    lai_term = exp(-froot_lai_decay * lai)
    stemmus_froot_to_leaf = froot_allocation_scale * lai_term /
        (lai_term + froot_soil_stress_weight * stemmus_soil_water_stress)
    stemmus_froot_to_leaf = clamp(
        stemmus_froot_to_leaf, minimum_froot_to_leaf, maximum_froot_to_leaf,
    )

    @inbounds for sl in eachindex(soilW)
        if root_over[sl] > zero(root_over[sl])
            θ = (soilW[sl] + ΔsoilW[sl]) * stemmus_inv_layer_thickness[sl]
            soil_potential = _stemmus_soil_potential(
                θ, sp_θ_wp[sl], stemmus_inv_theta_range[sl],
                nvg, avg, soil_potential_floor,
            )
            k_unsat = max(unsatK(land, helpers, sl, unsat_k_model) * mm_to_m, z_zero)
            k_sat = max(sp_k_sat[sl] * mm_to_m, z_zero)
            soil_conductance = max(
                min(k_sat, k_unsat) / max(stemmus_root_spacing[sl], eps(typeof(stemmus_root_spacing[sl]))),
                minimum_conductance,
            )
            root_stress = max(
                _stemmus_hydraulic_stress(
                    soil_potential, p50_root, shape_factor_root,
                    hydraulic_curve, psi0, m_to_mpa,
                ),
                minimum_root_stress,
            )
            root_fraction = stemmus_root_length_density[sl] / active_root_length
            root_area_index = (stemmus_stem_area_index + lai) *
                root_fraction * stemmus_froot_to_leaf
            root_conductance = max(
                root_stress * root_area_index * k_root_max /
                (root_lateral_length + stemmus_cumulative_depth_m[sl]),
                minimum_conductance,
            )
            soil_to_root = inv(inv(soil_conductance) + inv(root_conductance))
            layer_head = soil_potential - stemmus_cumulative_depth_m[sl]
        else
            soil_potential = z_zero
            k_unsat = z_zero
            soil_conductance = z_zero
            root_stress = z_zero
            root_area_index = z_zero
            root_conductance = z_zero
            soil_to_root = z_zero
            layer_head = z_zero
        end
        @rep_elem soil_potential ⇒ (ψ_soil, sl, :soilW)
        @rep_elem layer_head ⇒ (stemmus_layer_total_head, sl, :soilW)
        @rep_elem k_unsat ⇒ (Κ_unsat, sl, :soilW)
        @rep_elem soil_conductance ⇒ (Κ_soil, sl, :soilW)
        @rep_elem root_conductance ⇒ (Κ_root, sl, :soilW)
        @rep_elem soil_to_root ⇒ (Κ_soil_root, sl, :soilW)
        @rep_elem root_stress ⇒ (stemmus_root_stress, sl, :soilW)
        @rep_elem root_area_index ⇒ (stemmus_root_area_index, sl, :soilW)
    end

    relative_humidity = _stemmus_relative_humidity(f_airT_day, f_VPD_day)
    leaf_potential = min(ψ_leaf, -canopy_height)
    stemmus_converged = false
    stemmus_iterations = 0
    ψ_root = z_zero
    ψ_stem = -canopy_height
    stemmus_stem_stress = o_one
    Κ_root_stem = z_zero
    Κ_stem_leaf = z_zero
    stemmus_leaf_stress = _stemmus_hydraulic_stress(
        leaf_potential, p50_leaf_stress, shape_factor_leaf,
        hydraulic_curve, psi0, m_to_mpa,
    )
    stemmus_gpp = z_zero
    stemmus_transpiration = z_zero
    stemmus_stomatal_conductance_coupled = z_zero
    stemmus_canopy_conductance_coupled = z_zero

    for iteration in 1:_STEMMUS_PHS_MAX_ITERATIONS
        stemmus_iterations = iteration
        stemmus_gpp = max(gpp_demand, z_zero) * stemmus_leaf_stress
        leaf_assimilation = _stemmus_leaf_assimilation(
            stemmus_gpp, lai, minimum_lai, carbon_molar_mass, seconds_per_day,
        )
        stemmus_stomatal_conductance_coupled = _stemmus_stomatal_conductance(
            stemmus_stomatal_method, leaf_assimilation, ambient_CO2,
            f_VPD_day, relative_humidity, stemmus_ballberry_slope,
            stemmus_ballberry_intercept, stemmus_medlyn_slope,
            stemmus_medlyn_intercept, stemmus_minimum_vpd,
        )
        stemmus_transpiration, stemmus_canopy_conductance_coupled =
            _stemmus_transpiration_from_conductance(
                stemmus_stomatal_conductance_coupled,
                stemmus_boundary_layer_conductance,
                lai,
                f_VPD_day,
                f_psurf_day,
                water_molar_mass,
                seconds_per_day,
                minimum_pressure,
            )
        transpiration_m_per_day = stemmus_transpiration * mm_to_m
        (
            leaf_candidate,
            ψ_stem,
            ψ_root,
            stemmus_stem_stress,
            Κ_root_stem,
            Κ_stem_leaf,
        ) = _stemmus_component_water_potentials(
            params, transpiration_m_per_day, lai, stemmus_stem_area_index,
            canopy_height, active_root_length, root_over,
            stemmus_root_length_density, stemmus_layer_total_head,
            Κ_soil_root,
        )
        if !isfinite(leaf_candidate)
            leaf_candidate = -one(leaf_potential)
        end
        if abs(leaf_potential - leaf_candidate) < water_potential_tolerance
            stemmus_converged = true
            break
        end
        leaf_potential = water_potential_relaxation * leaf_candidate +
            (one(water_potential_relaxation) - water_potential_relaxation) * leaf_potential
        stemmus_leaf_stress = _stemmus_hydraulic_stress(
            leaf_potential, p50_leaf_stress, shape_factor_leaf,
            hydraulic_curve, psi0, m_to_mpa,
        )
    end

    ψ_leaf = leaf_potential
    stemmus_leaf_stress = clamp(
        _stemmus_hydraulic_stress(
            ψ_leaf, p50_leaf_stress,
            shape_factor_leaf, hydraulic_curve, psi0, m_to_mpa,
        ),
        z_zero, o_one,
    )
    gpp_f_soilW = stemmus_leaf_stress
    stemmus_gpp = max(gpp_demand, z_zero) * stemmus_leaf_stress

    total_uptake = z_zero
    @inbounds for sl in eachindex(soilW)
        if root_over[sl] > zero(root_over[sl])
            uptake_raw = Κ_soil_root[sl] *
                (stemmus_layer_total_head[sl] - ψ_root) * m_to_mm
            if !isfinite(uptake_raw)
                uptake_raw = z_zero
            elseif uptake_raw < z_zero
                uptake_raw = negative_uptake_floor
            end
            uptake = min(uptake_raw, max(PAW[sl], z_zero))
        else
            uptake_raw = z_zero
            uptake = z_zero
        end
        total_uptake += uptake
        @rep_elem uptake_raw ⇒ (stemmus_root_water_uptake_raw, sl, :soilW)
        @rep_elem uptake ⇒ (stemmus_root_water_uptake, sl, :soilW)
    end
    @inbounds for sl in eachindex(soilW)
        uptake_fraction = total_uptake > z_zero ?
            stemmus_root_water_uptake[sl] / total_uptake : z_zero
        @rep_elem uptake_fraction ⇒ (stemmus_root_uptake_fraction, sl, :soilW)
    end
    

    @pack_nt begin
        (ψ_soil, stemmus_layer_total_head,
        Κ_unsat, Κ_soil,
        Κ_root, Κ_soil_root,
        stemmus_root_stress, stemmus_root_area_index,
        stemmus_root_uptake_fraction, ψ_leaf,
        ψ_stem, ψ_root,
        stemmus_leaf_stress, stemmus_stem_stress,
        stemmus_soil_water_stress, stemmus_froot_to_leaf,
        stemmus_stem_area_index, Κ_root_stem,
        Κ_stem_leaf, stemmus_gpp,
        stemmus_transpiration, stemmus_stomatal_conductance_coupled,
        stemmus_canopy_conductance_coupled, stemmus_iterations,
        stemmus_converged, gpp_f_soilW) ⇒ land.diagnostics
        (stemmus_root_water_uptake_raw,
        stemmus_root_water_uptake) ⇒ land.fluxes
    end
    return land
end

@inline function _stemmus_soil_potential(
    θ, θ_wp, inverse_theta_range, nvg, avg, potential_floor,
)
    relative_saturation = clamp(
        (θ - θ_wp) * inverse_theta_range,
        oftype(θ, 1.0e-12), one(θ),
    )
    mvg = one(θ) - one(θ) / nvg
    potential = -((relative_saturation ^ (-one(θ) / mvg) - one(θ)) ^
        (one(θ) / nvg)) / avg
    return clamp(potential, potential_floor, zero(potential))
end

@inline function _stemmus_hydraulic_stress(
    potential, p50, shape_factor, curve, psi0, m_to_mpa,
)
    potential = min(potential, zero(potential))
    p50 = min(p50, -eps(typeof(p50)))
    ratio = max(potential / p50, zero(potential))
    stress = if curve < oftype(curve, 1.5)
        2 ^ (-(ratio ^ shape_factor))
    elseif curve < oftype(curve, 2.5)
        inv(one(potential) + ratio ^ shape_factor)
    else
        potential_mpa = potential * m_to_mpa
        p50_mpa = p50 * m_to_mpa
        exponent = -shape_factor * psi0 * (potential_mpa - p50_mpa)
        inv(one(potential) + exp(clamp(exponent, oftype(exponent, -700), oftype(exponent, 700))))
    end
    return clamp(stress, zero(stress), one(stress))
end

function _stemmus_component_water_potentials(
    params::plantHydraulics_STEMMUS, transpiration, lai, sai,
    canopy_height, active_root_length, root_over, root_length_density,
    layer_head, soil_to_root_conductance,
)
    @unpack_plantHydraulics_STEMMUS params
    root_potential = zero(transpiration)
    @inbounds for sl in eachindex(layer_head)
        if root_over[sl] > zero(root_over[sl])
            root_fraction = root_length_density[sl] / active_root_length
            conductance = max(soil_to_root_conductance[sl], minimum_conductance)
            layer_root_potential = (
                conductance * layer_head[sl] - transpiration * root_fraction
            ) / conductance
            root_potential += layer_root_potential * root_fraction
        end
    end
    root_potential = clamp(root_potential, root_potential_floor, zero(root_potential))
    stem_stress = max(
        _stemmus_hydraulic_stress(
            root_potential, p50_stem, shape_factor_stem,
            hydraulic_curve, psi0, m_to_mpa,
        ),
        minimum_stem_stress,
    )
    if sai > minimum_lai
        root_to_stem_conductance = k_stem_max / canopy_height * stem_stress
        stem_potential = root_potential - canopy_height -
            transpiration / sai / root_to_stem_conductance
    else
        root_to_stem_conductance = zero(root_potential)
        stem_potential = root_potential - canopy_height
    end
    stem_to_leaf_stress = _stemmus_hydraulic_stress(
        stem_potential, p50_leaf, shape_factor_leaf,
        hydraulic_curve, psi0, m_to_mpa,
    )
    if lai > minimum_lai && stem_to_leaf_stress > zero(stem_to_leaf_stress)
        stem_to_leaf_conductance = k_leaf_max * stem_to_leaf_stress
        leaf_potential = stem_potential - transpiration / lai / stem_to_leaf_conductance
    else
        stem_to_leaf_conductance = zero(stem_potential)
        leaf_potential = stem_potential
    end
    return (
        leaf_potential, stem_potential, root_potential, stem_stress,
        root_to_stem_conductance, stem_to_leaf_conductance,
    )
end

purpose(::Type{plantHydraulics_STEMMUS}) =
    "Direct daily port of the STEMMUS-SCOPE PHS root-stem-leaf hydraulic pathway."

@doc """
$(getModelDocString(plantHydraulics_STEMMUS))

This approach follows the STEMMUS-SCOPE root-property, soil-resistance,
soil-stress, plant-water-potential, and PHS energy-balance routines. It retains
the original root-spacing equation, fine-root allocation, series soil-root
conductance, 30-step relaxed leaf-potential iteration, vulnerability curves,
and replacement of negative root uptake.

SINDBAD has daily forcing and no SCOPE sunlit/shaded radiative-transfer state.
The gas-exchange closure therefore uses one effective canopy leaf: hydraulic
stress scales daily GPP demand, Ball-Berry or Medlyn determines stomatal
conductance, and conductance plus daily VPD determines transpiration. Raw
STEMMUS uptake is retained separately; the applied flux is additionally
limited by layer plant-available water to protect the daily water balance.
"""
plantHydraulics_STEMMUS
