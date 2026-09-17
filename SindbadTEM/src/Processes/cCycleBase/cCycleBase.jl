export cCycleBase, adjustPackPoolComponents, cCycleBaseZixGroups
# ---------
export LIT_FRAC_LIGNIN_PER_VEGTYPE
export LIT_CN_RATIO_PER_VEGTYPE
export CVEG_ROOTFINE_AGE_PER_VEGTYPE
export CVEG_LEAF_AGE_PER_VEGTYPE
export CVEG_ROOTCOARSE_AGE_PER_VEGTYPE
export CVEG_WOOD_AGE_PER_VEGTYPE
# ---------
abstract type cCycleBase <: LandEcosystem end

purpose(::Type{cCycleBase}) = "Defines the base properties of the carbon cycle components. For example, components of carbon pools, their turnover rates, and flow matrix."

"""
    adjustPackPoolComponents(land, helpers, ::cCycleBase)

Scatter the combined `cEco` vector back into every component pool it is built from,
and pack the results into `land.pools`.

Defined once for every `cCycleBase` approach. `setComponentFromMainPool` generates
the unrolled scatter from the pool names an experiment actually configured, so an
approach that adds, drops or renames a pool needs no method of its own.

`all_components` is every key of the element's `zix` except `cEco` itself, which is
both the main pools and the leaf pools.
"""
function adjustPackPoolComponents(land, helpers, ::cCycleBase)
    return setComponentFromMainPool(land, helpers,
        helpers.pools.vals.self.cEco,
        helpers.pools.vals.all_components.cEco,
        helpers.pools.vals.zix.cEco)
end

"""
    cCycleBaseZixGroups(helpers)
Get the zix for the groups relevant for different models of carbon cycle.
"""
function cCycleBaseZixGroups(helpers)
    # zix for the carbon cycle...
    zix_cVeg = helpers.pools.zix.cVeg
    zix_cLit = helpers.pools.zix.cLit
    zix_cMic = helpers.pools.zix.cMic
    zix_cSoil = helpers.pools.zix.cSoil
    zix_cProducts = helpers.pools.zix.cProducts

    zix_cNonVeg = (zix_cLit..., zix_cMic..., zix_cSoil...)
    zix_cNatural = (zix_cVeg..., zix_cLit..., zix_cMic..., zix_cSoil...)
    zix_cHeterotrophic = (zix_cLit..., zix_cMic..., zix_cSoil...)

    return zix_cNonVeg, zix_cNatural, zix_cHeterotrophic, zix_cProducts
end

#  The default average ages per vegetation pool

"""
    LIT_FRAC_LIGNIN_PER_VEGTYPE

Lignin fraction of litter, per canonical vegetation type
(`Classification_SINDBAD`) name. Fixed data, not a parameter; calibration
happens through `lit_frac_lignin_scalar` in `vegQualityTraits_vegType`
instead.

Transcribed from the legacy 12-element `lit_frac_lignin_per_PFT` array, keyed
to `Classification_MODIS_PFT` position order. IGBP classes with no
counterpart in the 12-class source are gap-filled by the same judgment calls
documented in `vegClasses(::Type{Classification_MODIS_PFT})`.
"""
const LIT_FRAC_LIGNIN_PER_VEGTYPE = (;
    Evergreen_Needleleaf_Forests = 0.2,
    Evergreen_Broadleaf_Forests = 0.22,
    Deciduous_Needleleaf_Forests = 0.25,
    Deciduous_Broadleaf_Forests = 0.2,
    Mixed_Forests = 0.2,
    Closed_Shrublands = 0.15,
    Open_Shrublands = 0.15,
    Woody_Savannas = 0.1,
    Savannas = 0.1,
    Grasslands = 0.1,
    Permanent_Wetlands = 0.1,
    Croplands = 0.2,
    Urban_and_Built_up_Lands = 0.15,
    Cropland_Natural_Vegetation_Mosaics = 0.2,
    Permanent_Snow_and_Ice = 0.15,
    Barren = 0.1,
    Water_Bodies = 0.2,
    Unclassified = 0.1,
)

"""
    LIT_CN_RATIO_PER_VEGTYPE

Carbon-to-nitrogen ratio of litter, per canonical vegetation type
(`Classification_SINDBAD`) name. Fixed data, not a parameter; calibration
happens through `lit_CN_ratio_scalar` in `vegQualityTraits_vegType` instead.

Transcribed the same way as `LIT_FRAC_LIGNIN_PER_VEGTYPE`, from the legacy
`lit_CN_ratio_per_PFT` array.
"""
const LIT_CN_RATIO_PER_VEGTYPE = (;
    Evergreen_Needleleaf_Forests = 50.0,
    Evergreen_Broadleaf_Forests = 65.0,
    Deciduous_Needleleaf_Forests = 80.0,
    Deciduous_Broadleaf_Forests = 50.0,
    Mixed_Forests = 50.0,
    Closed_Shrublands = 50.0,
    Open_Shrublands = 50.0,
    Woody_Savannas = 50.0,
    Savannas = 50.0,
    Grasslands = 50.0,
    Permanent_Wetlands = 50.0,
    Croplands = 65.0,
    Urban_and_Built_up_Lands = 50.0,
    Cropland_Natural_Vegetation_Mosaics = 65.0,
    Permanent_Snow_and_Ice = 50.0,
    Barren = 40.0,
    Water_Bodies = 40.0,
    Unclassified = 40.0,
)

"""
    CVEG_ROOTFINE_AGE_PER_VEGTYPE

Mean age (turnover time, years) of fine roots, per canonical vegetation type
(`Classification_SINDBAD`) name. Fixed data, not a parameter; calibration
happens through `k_c_rootfine_scalar` in `cCycleBase_CASA` (and the
equivalent `k_c_root_scalar` in the GSI-family `cCycleBase` approaches)
instead.

`cCycleBase_CASA`'s `define` re-keys this table (via `getParamsPerVegType`)
onto the experiment's resolved `vegClass` classification, and `precompute`
looks up the pixel's `land.states.veg_type_name` in it for `cVegRootFine`'s
turnover time. `cCycleBase_GSI`/`_GSI_PlantForm`/`_MGMT` do the same for
their single, undifferentiated `cVegRoot` pool.

Transcribed from the legacy 12-element array, keyed to
`Classification_MODIS_PFT` position order; see `LIT_FRAC_LIGNIN_PER_VEGTYPE`
for the gap-fill convention.
"""
const CVEG_ROOTFINE_AGE_PER_VEGTYPE = (;
    Evergreen_Needleleaf_Forests = 1.2,
    Evergreen_Broadleaf_Forests = 1.2,
    Deciduous_Needleleaf_Forests = 5.0,
    Deciduous_Broadleaf_Forests = 1.8,
    Mixed_Forests = 1.8,
    Closed_Shrublands = 1.0,
    Open_Shrublands = 1.0,
    Woody_Savannas = 1.0,
    Savannas = 1.0,
    Grasslands = 1.0,
    Permanent_Wetlands = 1.0,
    Croplands = 1.0,
    Urban_and_Built_up_Lands = 2.8,
    Cropland_Natural_Vegetation_Mosaics = 1.0,
    Permanent_Snow_and_Ice = 1.0,
    Barren = 1.0,
    Water_Bodies = 1.8,
    Unclassified = 1.0,
)

"""
    CVEG_LEAF_AGE_PER_VEGTYPE

Mean age (turnover time, years) of leaves, per canonical vegetation type
(`Classification_SINDBAD`) name. Fixed data, not a parameter; calibration
happens through `k_c_leaf_scalar` in `cCycleBase_CASA` (and the equivalent
`k_c_leaf_scalar` in the GSI-family `cCycleBase` approaches) instead.

A plain alias of `CVEG_ROOTFINE_AGE_PER_VEGTYPE` (the legacy
`cVegRootFine_age_per_PFT` and `cVegLeaf_age_per_PFT` arrays were identical),
kept as its own name so leaf and fine-root turnover can diverge later. See
`CVEG_ROOTFINE_AGE_PER_VEGTYPE` for how it is consumed at runtime.
"""
const CVEG_LEAF_AGE_PER_VEGTYPE = CVEG_ROOTFINE_AGE_PER_VEGTYPE

"""
    CVEG_ROOTCOARSE_AGE_PER_VEGTYPE

Mean age (turnover time, years) of coarse roots, per canonical vegetation
type (`Classification_SINDBAD`) name. Fixed data, not a parameter;
calibration happens through `k_c_rootcoarse_scalar` in `cCycleBase_CASA`
instead.

Drives vegetation-compartment turnover at runtime the same way
`CVEG_ROOTFINE_AGE_PER_VEGTYPE` does, for `cCycleBase_CASA`'s
`cVegRootCoarse` pool. Transcribed the same way, from the legacy 12-element
array.
"""
const CVEG_ROOTCOARSE_AGE_PER_VEGTYPE = (;
    Evergreen_Needleleaf_Forests = 58.0,
    Evergreen_Broadleaf_Forests = 58.0,
    Deciduous_Needleleaf_Forests = 42.0,
    Deciduous_Broadleaf_Forests = 27.0,
    Mixed_Forests = 27.0,
    Closed_Shrublands = 25.0,
    Open_Shrublands = 25.0,
    Woody_Savannas = 25.0,
    Savannas = 25.0,
    Grasslands = 25.0,
    Permanent_Wetlands = 25.0,
    Croplands = 5.5,
    Urban_and_Built_up_Lands = 40.0,
    Cropland_Natural_Vegetation_Mosaics = 5.5,
    Permanent_Snow_and_Ice = 1.0,
    Barren = 40.0,
    Water_Bodies = 41.0,
    Unclassified = 40.0,
)

"""
    CVEG_WOOD_AGE_PER_VEGTYPE

Mean age (turnover time, years) of wood, per canonical vegetation type
(`Classification_SINDBAD`) name. Fixed data, not a parameter; calibration
happens through `k_c_wood_scalar` in `cCycleBase_CASA` (and the equivalent
`k_c_wood_scalar` in the GSI-family `cCycleBase` approaches) instead.

A plain alias of `CVEG_ROOTCOARSE_AGE_PER_VEGTYPE` (the legacy
`cVegRootCoarse_age_per_PFT` and `cVegWood_age_per_PFT` arrays were
identical), kept as its own name so wood and coarse-root turnover can
diverge later. See `CVEG_ROOTFINE_AGE_PER_VEGTYPE` for how it is consumed at
runtime.
"""
const CVEG_WOOD_AGE_PER_VEGTYPE = CVEG_ROOTCOARSE_AGE_PER_VEGTYPE

"""
    C_REMAIN_PER_VEGTYPE

default minimum remaining carbon content (gC/m2) of each vegetation pool after fire or site disturbance, per canonical vegetation type (`Classification_SINDBAD`) name.

These numbers are ingested by cCycleBase and scaled by a scalar parameter that can be optimized in a calibration run. 
"""
const C_REMAIN_PER_VEGTYPE = (;
    Evergreen_Needleleaf_Forests = 100.0,
    Evergreen_Broadleaf_Forests = 100.0,
    Deciduous_Needleleaf_Forests = 100.0,
    Deciduous_Broadleaf_Forests = 100.0,
    Mixed_Forests = 100.0,
    Closed_Shrublands = 50.0,
    Open_Shrublands = 50.0,
    Woody_Savannas = 50.0,
    Savannas = 50.0,
    Grasslands = 10.0,
    Permanent_Wetlands = 10.0,
    Croplands = 10.0,
    Urban_and_Built_up_Lands = 0.0,
    Cropland_Natural_Vegetation_Mosaics = 50.0,
    Permanent_Snow_and_Ice = 0.0,
    Barren = 0.0,
    Water_Bodies = 0.0,
    Unclassified = 0.0,
)

# Pool structures and flow topologies the approaches below declare against. One file
# per structure in that folder; this entry point pulls them in. Included explicitly
# because includeApproaches globs `cCycleBase_*.jl` here and does not descend.
include("poolConfigurations/poolConfigurations.jl")

includeApproaches(cCycleBase, @__DIR__)

@doc """ 
	$(getModelDocString(cCycleBase))
"""
cCycleBase
