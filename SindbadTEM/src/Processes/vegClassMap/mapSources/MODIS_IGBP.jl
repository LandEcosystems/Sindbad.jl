export VegTypeCatalog_MODIS_IGBP

struct VegTypeCatalog_MODIS_IGBP <: VegTypeCatalog end
purpose(::Type{VegTypeCatalog_MODIS_IGBP}) = "MODIS MCD12Q1/MCD12C1 IGBP land cover legend (LC_Type1), 17 classes"

"""
    vegTypeClasses(::Type{VegTypeCatalog_MODIS_IGBP})

The IGBP land cover legend, Table 3 of the MCD12Q1/MCD12C1 user guide
(Sulla-Menashe & Friedl, 2018), transcribed exactly as documented for the
`name => code` half of each entry. Every class here has the identically
named class in the canonical `VegTypeCatalog_SINDBAD` vocabulary (which was
itself copied from this legend) as its crosswalk target -- a true identity
mapping today, kept explicit rather than assumed so it is checked the same
way as every other catalog's crosswalk (see `validateVegTypeCrosswalks`).
"""
vegTypeClasses(::Type{VegTypeCatalog_MODIS_IGBP}) = (
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
    (:Permanent_Snow_and_Ice => 15, :Permanent_Snow_and_Ice),
    (:Barren => 16, :Barren),
    (:Water_Bodies => 17, :Water_Bodies),
    (:Unclassified => 255, :Unclassified),
)
