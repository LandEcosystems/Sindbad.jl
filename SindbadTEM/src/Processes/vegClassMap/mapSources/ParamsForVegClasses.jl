export LIT_FRAC_LIGNIN_PER_VEGTYPE
export LIT_CN_RATIO_PER_VEGTYPE
export CVEG_ROOTFINE_AGE_PER_VEGTYPE
export CVEG_LEAF_AGE_PER_VEGTYPE
export CVEG_ROOTCOARSE_AGE_PER_VEGTYPE
export CVEG_WOOD_AGE_PER_VEGTYPE



"""
    LIT_FRAC_LIGNIN_PER_VEGTYPE

Lignin fraction of litter, per canonical vegetation type
(`VegTypeCatalog_SINDBAD`) name. Fixed data, not a parameter -- calibration
happens through `lit_frac_lignin_scalar` in `vegQualityTraits_vegType` instead.

Transcribed from the legacy 12-element `lit_frac_lignin_per_PFT` array (values
`[0.2, 0.2, 0.22, 0.25, 0.2, 0.15, 0.1, 0.0, 0.2, 0.15, 0.15, 0.1]`), which was
keyed to `VegTypeCatalog_MODIS_PFT` position order (array position `i` = code
`i - 1`). Each entry below cites the source position it came from; entries
citing another canonical name's value are IGBP classes with no counterpart in
the 12-class source and are filled via the same judgment calls documented in
`vegTypeClasses(::Type{VegTypeCatalog_MODIS_PFT})` -- placeholders to confirm,
not calibrated values in their own right:

- `Evergreen_Needleleaf_Forests`..`Deciduous_Broadleaf_Forests`,
  `Open_Shrublands`, `Grasslands`, `Urban_and_Built_up_Lands`,
  `Permanent_Snow_and_Ice`, `Barren`, `Water_Bodies`: direct, from source
  positions 2, 3, 4, 5, 6, 7, 10, 11, 12, 1 respectively.
- `Croplands`: from position 9 (`Broadleaf_Croplands`, 0.2). Position 8
  (`Cereal_Croplands`, 0.0 -- the "no lignin" class the original docstring
  referenced) has no separate representation once both collapse onto IGBP's
  one `Croplands` class, and is dropped here.
- `Mixed_Forests`: `Deciduous_Broadleaf_Forests`'s value.
- `Closed_Shrublands`: `Open_Shrublands`'s value.
- `Woody_Savannas`, `Savannas`, `Permanent_Wetlands`: `Grasslands`'s value.
- `Cropland_Natural_Vegetation_Mosaics`: `Croplands`'s value.
- `Unclassified`: `Barren`'s value, a defensive default for missing/QA-flagged
  pixels rather than a scientific claim.
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
(`VegTypeCatalog_SINDBAD`) name. Fixed data, not a parameter -- calibration
happens through `lit_CN_ratio_scalar` in `vegQualityTraits_vegType` instead.

Transcribed the same way as `LIT_FRAC_LIGNIN_PER_VEGTYPE` from the legacy
`lit_CN_ratio_per_PFT` array (values
`[40.0, 50.0, 65.0, 80.0, 50.0, 50.0, 50.0, 0.0, 65.0, 50.0, 50.0, 40.0]`);
see that constant's docstring for the source-position and gap-fill notes,
which apply identically here (position 8, `Cereal_Croplands` = 0.0, is
likewise dropped once collapsed onto `Croplands`).
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
(`VegTypeCatalog_SINDBAD`) name. Fixed data, not a parameter -- calibration
happens through `rootfine_age_scalar` in `cCycleBase_CASA` (and the
equivalent `k_c_root_scalar` in the GSI-family `cCycleBase` approaches)
instead.

Drives vegetation-organ turnover at runtime: `cCycleBase_CASA`'s `define`
re-keys this table (via `vegTypeCatalogFor`) onto whichever classification
the experiment's `vegClassMap` approach resolved into, and `precompute` looks up
the current pixel's `land.states.veg_type_name` in it for `cVegRootFine`'s
turnover time. `cCycleBase_GSI`/`_GSI_PlantForm`/`_GSI_PlantForm_MGMT` do the
same for their single, undifferentiated `cVegRoot` pool.

Transcribed from the legacy 12-element array (values `[1.8, 1.2, 1.2, 5.0,
1.8, 1.0, 1.0, 0.0, 1.0, 2.8, 1.0, 1.0]`), keyed to `VegTypeCatalog_MODIS_PFT`
position order (array position `i` = code `i - 1`). See
`LIT_FRAC_LIGNIN_PER_VEGTYPE` for the full source-position and gap-fill
convention this follows; `Croplands` here is 1.0 from position 9
(`Broadleaf_Croplands`), with position 8 (`Cereal_Croplands`, 0.0) dropped
once both collapse onto IGBP's single `Croplands` class.
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
(`VegTypeCatalog_SINDBAD`) name. Fixed data, not a parameter -- calibration
happens through `leaf_age_scalar` in `cCycleBase_CASA` (and the equivalent
`k_c_leaf_scalar` in the GSI-family `cCycleBase` approaches) instead.

Presently a plain alias of `CVEG_ROOTFINE_AGE_PER_VEGTYPE` (the legacy
`cVegRootFine_age_per_PFT` and `cVegLeaf_age_per_PFT` arrays were identical),
kept as its own name rather than folded into one table so leaf and fine-root
turnover can diverge later without another refactor. See
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`'s docstring for how it is consumed at
runtime -- the same `define`/`precompute` pattern applies here.
"""
const CVEG_LEAF_AGE_PER_VEGTYPE = CVEG_ROOTFINE_AGE_PER_VEGTYPE

"""
    CVEG_ROOTCOARSE_AGE_PER_VEGTYPE

Mean age (turnover time, years) of coarse roots, per canonical vegetation
type (`VegTypeCatalog_SINDBAD`) name. Fixed data, not a parameter --
calibration happens through `rootcoarse_age_scalar` in `cCycleBase_CASA`
instead.

Drives vegetation-organ turnover at runtime the same way
`CVEG_ROOTFINE_AGE_PER_VEGTYPE` does, for `cCycleBase_CASA`'s
`cVegRootCoarse` pool.

Transcribed the same way as `CVEG_ROOTFINE_AGE_PER_VEGTYPE` from the legacy
12-element array (values `[41.0, 58.0, 58.0, 42.0, 27.0, 25.0, 25.0, 0.0,
5.5, 40.0, 1.0, 40.0]`); see that constant's docstring for the
source-position and gap-fill notes, which apply identically here
(`Croplands` = 5.5 from position 9, position 8 dropped).
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
(`VegTypeCatalog_SINDBAD`) name. Fixed data, not a parameter -- calibration
happens through `wood_age_scalar` in `cCycleBase_CASA` (and the equivalent
`k_c_wood_scalar` in the GSI-family `cCycleBase` approaches) instead.

Presently a plain alias of `CVEG_ROOTCOARSE_AGE_PER_VEGTYPE` (the legacy
`cVegRootCoarse_age_per_PFT` and `cVegWood_age_per_PFT` arrays were
identical), kept as its own name rather than folded into one table so wood
and coarse-root turnover can diverge later without another refactor. See
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`'s docstring for how it is consumed at
runtime -- the same `define`/`precompute` pattern applies here.
"""
const CVEG_WOOD_AGE_PER_VEGTYPE = CVEG_ROOTCOARSE_AGE_PER_VEGTYPE
