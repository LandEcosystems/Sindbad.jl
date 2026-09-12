export VegTypeCatalog_MODIS_UMD

struct VegTypeCatalog_MODIS_UMD <: VegTypeCatalog end
purpose(::Type{VegTypeCatalog_MODIS_UMD}) = "MODIS MCD12Q1/MCD12C1 University of Maryland land cover legend (LC_Type2), 16 classes"

"""
    vegTypeClasses(::Type{VegTypeCatalog_MODIS_UMD})

The University of Maryland (UMD) legend, Table 4 of the MCD12Q1/MCD12C1 user
guide (Hansen et al., 2000), transcribed exactly as documented for the
`name => code` half of each entry. Classes 1-14 share their definitions
verbatim with the IGBP legend, so they map onto the identically named class
in the canonical `VegTypeCatalog_SINDBAD` vocabulary (itself copied from
IGBP). Two classes do not:

- `Non_Vegetated_Lands` (15) conflates IGBP's separate `Permanent_Snow_and_Ice`
  (15) and `Barren` (16) into one class. Mapped here to `:Barren`,
  **a placeholder that understates any snow/ice extent** -- confirm against
  the user's judgment or the literature before relying on it for calibration.
- `Water_Bodies` is class 0 here (IGBP has it as 17); the crosswalk maps the
  code, not the number, so this is unaffected.
"""
vegTypeClasses(::Type{VegTypeCatalog_MODIS_UMD}) = (
    (:Water_Bodies => 0, :Water_Bodies),
    (:Evergreen_Needleleaf_Forests => 1, :Evergreen_Needleleaf_Forests),
    (:Evergreen_Broadleaf_Forests => 2, :Evergreen_Broadleaf_Forests),
    (:Deciduous_Needleleaf_Forests => 3, :Deciduous_Needleleaf_Forests),
    (:Deciduous_Broadleaf_Forests => 4, :Deciduous_Broadleaf_Forests),
    (:Mixed_Forests => 5, :Mixed_Forests),
    (:Closed_Shrublands => 6, :Closed_Shrublands),
    (:Open_Shrublands => 7, :Open_Shrublands),
    (:Woody_Savannas => 8, :Woody_Savannas),
    (:Savannas => 9, :Savannas),
    (:Grasslands => 10, :Grasslands),
    (:Permanent_Wetlands => 11, :Permanent_Wetlands),
    (:Croplands => 12, :Croplands),
    (:Urban_and_Built_up_Lands => 13, :Urban_and_Built_up_Lands),
    (:Cropland_Natural_Vegetation_Mosaics => 14, :Cropland_Natural_Vegetation_Mosaics),
    (:Non_Vegetated_Lands => 15, :Barren),
    (:Unclassified => 255, :Unclassified),
)
