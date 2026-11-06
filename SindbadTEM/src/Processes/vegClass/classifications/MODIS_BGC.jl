export Classification_MODIS_BGC

struct Classification_MODIS_BGC <: VegClassification end
purpose(::Type{Classification_MODIS_BGC}) = "MODIS MCD12Q1 BIOME-Biogeochemical Cycles legend (LC_Type4), 9 classes"

"""
    vegClasses(::Type{Classification_MODIS_BGC})

The BIOME-BGC legend, Table 6 of the MCD12Q1 user guide (Running et al.,
2004), transcribed exactly as documented for the `name => code` half of each
entry. Every vegetated class is defined by leaf-habit/phenology alone with no
canopy-height or cover threshold, so each conflates trees and shrubs of the
same phenology into one class, coarser than the canonical
`Classification_SINDBAD` split.

- `Evergreen_Needleleaf_Vegetation`, `Evergreen_Broadleaf_Vegetation`,
  `Deciduous_Needleleaf_Vegetation`, `Deciduous_Broadleaf_Vegetation`: mapped
  to the correspondingly named IGBP forest class.
- `Annual_Broadleaf_Vegetation` ("at least 60% cultivated broadleaf crops"):
  mapped to `Croplands`.
- `Annual_Grass_Vegetation` (explicitly "including cereal croplands"): mapped
  to `Grasslands`.
- `Non_Vegetated_Lands`: conflates barren ground with permanent snow/ice.
  Mapped to `Barren`.
"""
vegClasses(::Type{Classification_MODIS_BGC}) = (
    (:Water_Bodies => 0, :Water_Bodies),
    (:Evergreen_Needleleaf_Vegetation => 1, :Evergreen_Needleleaf_Forests),
    (:Evergreen_Broadleaf_Vegetation => 2, :Evergreen_Broadleaf_Forests),
    (:Deciduous_Needleleaf_Vegetation => 3, :Deciduous_Needleleaf_Forests),
    (:Deciduous_Broadleaf_Vegetation => 4, :Deciduous_Broadleaf_Forests),
    (:Annual_Broadleaf_Vegetation => 5, :Croplands),
    (:Annual_Grass_Vegetation => 6, :Grasslands),
    (:Non_Vegetated_Lands => 7, :Barren),
    (:Urban_and_Built_up_Lands => 8, :Urban_and_Built_up_Lands),
    (:Unclassified => 255, :Unclassified),
)
