export cFireCombustionCompleteness_vanDerWerf2006

#! format: off
@bounds @describe @units @timescale @with_kw struct cFireCombustionCompleteness_vanDerWerf2006{T1, T2, T3, T4, T5} <: cFireCombustionCompleteness
    fire_cc_scalar::T1 = 1.0 | (0.5, 2.0) | "scalar for the per-pool fire combustion completeness (ccMin/ccMax)" | "-" | ""
    soil_burn_depth_max::T2 = 0.1 | (0.0, 1.0) | "maximum burn depth of non-peat organic soil" | "m" | ""
    peat_burn_depth_max::T3 = 0.3 | (0.0, 5.0) | "maximum burn depth of peat" | "m" | ""
    peat_porosity_threshold::T4 = 0.8 | (0.0, 1.0) | "porosity threshold used to diagnose peat-like soil" | "-" | ""
    peat_min_burn_fraction::T5 = 0.5 | (0.0, 1.0) | "minimum fraction of the peat burnable depth consumed" | "-" | ""
end
#! format: on

function define(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    ## instantiate variables
    @unpack_nt begin
        cEco ⇐ land.pools
        c_model ⇐ land.models
    end

    c_Fire_cci = zero.(cEco)
    fire_cc_table = fireCCTable(c_model)
    fire_aboveground_fraction_table = abovegroundFractionTable(c_model)

    ## pack land variables
    @pack_nt begin
        (c_Fire_cci, fire_cc_table, fire_aboveground_fraction_table) ⇒ land.diagnostics
    end
    return land
end

function precompute(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    ## unpack parameters
    @unpack_cFireCombustionCompleteness_vanDerWerf2006 params

    ## unpack land variables
    @unpack_nt begin
        cEco ⇐ land.pools
        soilW ⇐ land.pools
        gpp_f_soilW ⇐ land.diagnostics
        (fire_cc_table, fire_aboveground_fraction_table) ⇐ land.diagnostics
        zix ⇐ helpers.pools
        zix_cHeterotrophic ⇐ land.cCycleBase
        (w_sat, ∑w_sat, soil_layer_thickness) ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    c_fire_ccMax = zero.(cEco)
    c_fire_ccMin = zero.(cEco)
    c_fire_cc_weight = zero.(cEco)
    c_fire_aboveground_fraction = zero.(cEco)
    c_Fire_cc_fW = zero.(cEco)
    frac_exposed = one.(cEco)

    ## calculate variables
    (c_fire_ccMin, c_fire_ccMax, c_fire_cc_weight) = getFireCCFromParams(c_fire_ccMin, c_fire_ccMax, c_fire_cc_weight, fire_cc_table, fire_cc_scalar, helpers)
    c_fire_aboveground_fraction = getAbovegroundFractionFromParams(c_fire_aboveground_fraction, fire_aboveground_fraction_table, helpers)

    totalSoilW = at_least_zero(totalS(soilW))
    soilW_nor = at_most_one(totalSoilW / ∑w_sat)
    for izix in zix_cHeterotrophic
        @rep_elem soilW_nor ⇒ (c_Fire_cc_fW, izix)
    end
    for zixVeg in zix.cVeg
        @rep_elem gpp_f_soilW ⇒ (c_Fire_cc_fW, zixVeg)
    end

    peat_porosity = zero(w_sat[1])
    depth = zero(peat_burn_depth_max)
    for sl in eachindex(soil_layer_thickness)
        Δzi = soil_layer_thickness[sl]
        Δzi_peat = min(Δzi, at_least_zero(peat_burn_depth_max - depth))
        θ_sat = Δzi > z_zero ? w_sat[sl] / Δzi : z_zero
        peat_porosity += θ_sat * Δzi_peat
        depth += Δzi_peat
    end
    peat_porosity = depth > z_zero ? peat_porosity / depth : z_zero
    peat = peat_porosity >= peat_porosity_threshold ? o_one : z_zero

    soil_depth = sum(soil_layer_thickness)
    f_soil = soil_depth > z_zero ? at_most_one(soil_burn_depth_max / soil_depth) : z_zero
    f_peat = soil_depth > z_zero ? at_most_one(peat_burn_depth_max / soil_depth) : z_zero

    for izix in zix.cEco
        f_ag = c_fire_aboveground_fraction[izix]
        @rep_elem f_ag + (o_one - f_ag) * f_soil ⇒ (frac_exposed, izix)
    end
    for izix in zix.cMic
        f_ag = c_fire_aboveground_fraction[izix]
        f_bg = at_least_zero(f_soil + peat * (f_peat - f_soil))
        @rep_elem f_ag + (o_one - f_ag) * f_bg ⇒ (frac_exposed, izix)
    end
    for izix in zix.cSoil
        f_ag = c_fire_aboveground_fraction[izix]
        @rep_elem f_ag + (o_one - f_ag) * peat * f_peat ⇒ (frac_exposed, izix)
    end

    ## pack land variables
    @pack_nt begin
        (c_fire_ccMin, c_fire_ccMax, c_fire_cc_weight, c_fire_aboveground_fraction, c_Fire_cc_fW, frac_exposed, peat) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    @unpack_cFireCombustionCompleteness_vanDerWerf2006 params
    ## unpack land variables
    @unpack_nt begin
        (c_fire_ccMin, c_fire_ccMax, c_Fire_cci, c_Fire_cc_fW, c_fire_cc_weight, c_fire_aboveground_fraction, frac_exposed, peat) ⇐ land.diagnostics
        gpp_f_soilW ⇐ land.diagnostics
        zix ⇐ helpers.pools
        soilW ⇐ land.pools
        ∑w_sat ⇐ land.properties
        o_one ⇐ land.constants
        zix_cHeterotrophic ⇐ land.cCycleBase
    end

    totalSoilW = at_least_zero(totalS(soilW))
    soilW_nor = at_most_one(totalSoilW / ∑w_sat)

    # for all litter/soil/microbial pools c_Fire_cc_fW = soilW_nor
    for izix in zix_cHeterotrophic
        weight = c_fire_cc_weight[izix]
        fW = weight * soilW_nor + (o_one - weight) * c_Fire_cc_fW[izix]
        @rep_elem fW ⇒ (c_Fire_cc_fW, izix)
    end
    # for all veg pools c_Fire_cc_fW = gpp_f_soilW
    for zixVeg in zix.cVeg
        @rep_elem gpp_f_soilW ⇒ (c_Fire_cc_fW, zixVeg)
    end

    # for all cEco pools
    for zix_idx in zix.cEco
        fW = c_Fire_cc_fW[zix_idx]
        cci = (c_fire_ccMax[zix_idx] - c_fire_ccMin[zix_idx]) * (o_one - fW) + c_fire_ccMin[zix_idx]
        f_ag = c_fire_aboveground_fraction[zix_idx]
        f_burn = o_one - fW
        if zix_idx ∈ zix.cMic || zix_idx ∈ zix.cSoil
            f_burn += peat * peat_min_burn_fraction * fW
        end
        f_exp = f_ag + (frac_exposed[zix_idx] - f_ag) * f_burn
        @rep_elem cci * f_exp ⇒ (c_Fire_cci, zix_idx)
    end

    # ## pack land variables
    @pack_nt begin
        (c_Fire_cci, c_Fire_cc_fW) ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFireCombustionCompleteness_vanDerWerf2006}) = "Uses the van der Werf et al. (2006) method to calculate combustion completeness."

@doc """

$(getModelDocString(cFireCombustionCompleteness_vanDerWerf2006))

---

# Extended help

Combustion completeness is resolved from the fixed per-pool-name table of the
active `cCycleBase` pool configuration. `getFireCCFromParams` scatters
`ccMin`, `ccMax`, and the autoregressive moisture weight to the configured
pool indices, while `getAbovegroundFractionFromParams` scatters the fraction
of each pool that is aboveground.

Live vegetation uses `gpp_f_soilW`; litter, microbial, and soil pools use the
common soil-water scalar. The previous heterotrophic-pool moisture state is
initialized from the current soil-water scalar in `precompute` and updated
with each pool's table weight in `compute`.

Belowground exposure is limited by `soil_burn_depth_max`. Peat-like soils are
diagnosed from depth-weighted hydraulic porosity, calculated from `w_sat /
soil_layer_thickness` over at most `peat_burn_depth_max`. Microbial pools can
use the deeper peat exposure when peat is diagnosed; slow/old soil carbon is
exposed only in peat. Peat burning retains `peat_min_burn_fraction` of the
maximum exposed depth under wet conditions.

*Versions*
 - 1.0 [nunocarvalhais]: original hardcoded per-compartment struct and `cc_lut`
 - 2.0 on 15.09.2026 [skoirala]: generalized onto `cCycleBase`'s
   fixed-table-plus-bounded-scalar pattern, fixing the CASA pool-shape
   mismatch and extending soil-water scaling to microbial pools

*Created by*
  - Nuno | nunocarvalhais
"""
cFireCombustionCompleteness_vanDerWerf2006

