export Classification_MODIS_PFT

struct Classification_MODIS_PFT <: VegClassification end
purpose(::Type{Classification_MODIS_PFT}) = "MODIS MCD12Q1 Plant Functional Type legend (LC_Type5), 12 classes"

"""
    vegClasses(::Type{Classification_MODIS_PFT})

The Plant Functional Type legend, Table 7 of the MCD12Q1 user guide (Bonan,
2002), transcribed exactly as documented for the `name => code` half of each
entry.

Two classes have no clean 1:1 match onto the canonical `Classification_SINDBAD`
vocabulary (itself copied from IGBP):

- `Shrub`: IGBP splits shrubland by canopy closure
  (`Closed_Shrublands`/`Open_Shrublands`), which this legend does not. Mapped
  to `Open_Shrublands`.
- `Cereal_Croplands` and `Broadleaf_Croplands`: IGBP has one undifferentiated
  `Croplands` class; both map to it.
"""
vegClasses(::Type{Classification_MODIS_PFT}) = (
    (:Water_Bodies => 0, :Water_Bodies),
    (:Evergreen_Needleleaf_Trees => 1, :Evergreen_Needleleaf_Forests),
    (:Evergreen_Broadleaf_Trees => 2, :Evergreen_Broadleaf_Forests),
    (:Deciduous_Needleleaf_Trees => 3, :Deciduous_Needleleaf_Forests),
    (:Deciduous_Broadleaf_Trees => 4, :Deciduous_Broadleaf_Forests),
    (:Shrub => 5, :Open_Shrublands),
    (:Grass => 6, :Grasslands),
    (:Cereal_Croplands => 7, :Croplands),
    (:Broadleaf_Croplands => 8, :Croplands),
    (:Urban_and_Built_up_Lands => 9, :Urban_and_Built_up_Lands),
    (:Permanent_Snow_and_Ice => 10, :Permanent_Snow_and_Ice),
    (:Barren => 11, :Barren),
    (:Unclassified => 255, :Unclassified),
)
