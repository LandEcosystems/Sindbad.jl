export cFireCombustionCompleteness_vanDerWerf2006

@with_kw struct cFireCombustionCompleteness_vanDerWerf2006{T1, T2, T3, T4, T5, T6, T7} <: cFireCombustionCompleteness
    # fire combustion completeness parameters for stems, leaf; for the metabolic and structural parts of fine leaf litter (fcc_leaf_litter_m, fcc_leaf_litter_s)< for the coarse woody debris (literSlow) and for the organic soil layer (sol)
    fcc_stem::T1 = [0.2f0, 0.3f0, 0.0f0, 1.0f0] # min, max, prev, current
    fcc_leaf::T2 = [0.8f0, 1.0f0, 0.0f0, 1.0f0]
    fcc_leaf_litter_m::T3 = [0.9f0, 1.0f0, 0.1f0, 0.9f0]
    fcc_leaf_litter_s::T4 = [0.9f0, 1.0f0, 0.1f0, 0.9f0]
    # fcc_sol::T5 = [0.9f0, 1.0f0, 0.1f0, 0.9f0] # we don't burnt organic soil
    fcc_sol::T5 = [0.0f0, 0.0f0, 0.0f0, 1.0f0]
    fcc_root::T6 = [0.0f0, 0.0f0, 0.0f0, 1.0f0]
    fcc_cwd::T7 = [0.5f0, 0.6f0, 0.4f0, 0.6f0]
end

function define(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    # @unpack_cFireCombustionCompleteness_vanDerWerf2006 params
    ## instantiate variables
    @unpack_nt begin
        cEco ⇐ land.pools
        zix ⇐ helpers.pools
    end

    c_fire_ccMax = zero.(cEco)
    c_fire_ccMin = zero.(cEco)
    c_Fire_cci = zero.(cEco)
    c_Fire_cc_fW = zero.(cEco)
    # create CombustionCompletenessArray for each pool in zix
    cc_lut = (
        :cVegRoot => :fcc_root,
        :cVegWood => :fcc_stem,
        :cVegReserve => :fcc_stem,
        :cVegLeaf => :fcc_leaf,
        :cLitFast => :fcc_leaf_litter_m,
        :cLitSlow => :fcc_cwd,
        :cSoilSlow => :fcc_sol,
        )

    for (k,v) in cc_lut
        zix_keys = getproperty(zix, k)
        imin, imax, _, _ = getproperty(params, v) # min, max, prev, current
        # c_fire_ccMax[[zix_keys...]] .= imax
        # c_fire_ccMin[[zix_keys...]] .= imin
        for izix in zix_keys
            @rep_elem imax ⇒ (c_fire_ccMax, izix, :cEco)
            @rep_elem imin ⇒ (c_fire_ccMin, izix, :cEco)
        end
    end

    ## pack land variables
    @pack_nt begin
        (c_fire_ccMin, c_fire_ccMax, c_Fire_cci, c_Fire_cc_fW) ⇒ land.diagnostics
    end
    return land
end

function compute(params::cFireCombustionCompleteness_vanDerWerf2006, forcing, land, helpers)
    @unpack_cFireCombustionCompleteness_vanDerWerf2006 params
    ## unpack land variables
    @unpack_nt begin
        (c_fire_ccMin, c_fire_ccMax, c_Fire_cci, c_Fire_cc_fW ) ⇐ land.diagnostics
        gpp_f_soilW ⇐ land.diagnostics
        zix ⇐ helpers.pools
        soilW ⇐ land.pools
        ∑w_sat ⇐ land.properties
        (z_zero, o_one) ⇐ land.constants
    end

    totalSoilW = at_least_zero(totalS(soilW))
    soilW_nor = at_most_one(totalSoilW / ∑w_sat)

    # for all soil pools c_Fire_cc_fW = soilW_nor
    for zixSoil in (zix.cLit, zix.cSoil)
        for izix in zixSoil
            @rep_elem soilW_nor ⇒ (c_Fire_cc_fW, izix, :cEco)
        end
    end
    # for all veg pools c_Fire_cc_fW = gpp_f_soilW
    for zixVeg in zix.cVeg
        @rep_elem gpp_f_soilW ⇒ (c_Fire_cc_fW, zixVeg, :cEco)
    end

    # for all cEco pools
    for zix_idx in zix.cEco
        cci = (c_fire_ccMax[zix_idx] - c_fire_ccMin[zix_idx]) * (o_one - c_Fire_cc_fW[zix_idx]) + c_fire_ccMin[zix_idx]
        @rep_elem cci ⇒ (c_Fire_cci, zix_idx, :cEco)
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

*Created by*
  - Nuno | nunocarvalhais
"""
cFireCombustionCompleteness_vanDerWerf2006

