export VegTypeCatalog_MODIS_LAI

struct VegTypeCatalog_MODIS_LAI <: VegTypeCatalog end
purpose(::Type{VegTypeCatalog_MODIS_LAI}) = "MODIS MCD12Q1 Leaf Area Index biome legend (LC_Type3), 11 classes"

"""
    vegTypeClasses(::Type{VegTypeCatalog_MODIS_LAI})

The LAI/fPAR biome legend, Table 5 of the MCD12Q1 user guide (Myneni et al.,
2002), transcribed exactly as documented for the `name => code` half of each
entry. The forest, savanna, urban and water classes map directly onto the
canonical `VegTypeCatalog_SINDBAD` name of the same meaning (itself copied
from IGBP). Three do not, and are placeholders needing the same
literature/user confirmation as the other catalogs' non-direct mappings:

- `Grasslands`: this legend's own definition explicitly includes "cereal
  croplands," so mapping it to IGBP's `Grasslands` alone silently drops
  whatever cereal-crop signal this class carries with no way to separate it
  back out.
- `Shrublands`: IGBP splits shrubland by canopy closure
  (`Closed_Shrublands`/`Open_Shrublands`), which this legend does not.
  Mapped to `Open_Shrublands` as a default.
- `Non_Vegetated_Lands`: conflates barren ground with permanent snow/ice.
  Mapped to `Barren`, understating any snow/ice extent.
"""
vegTypeClasses(::Type{VegTypeCatalog_MODIS_LAI}) = (
    (:Water_Bodies => 0, :Water_Bodies),
    (:Grasslands => 1, :Grasslands),
    (:Shrublands => 2, :Open_Shrublands),
    (:Broadleaf_Croplands => 3, :Croplands),
    (:Savannas => 4, :Savannas),
    (:Evergreen_Broadleaf_Forests => 5, :Evergreen_Broadleaf_Forests),
    (:Deciduous_Broadleaf_Forests => 6, :Deciduous_Broadleaf_Forests),
    (:Evergreen_Needleleaf_Forests => 7, :Evergreen_Needleleaf_Forests),
    (:Deciduous_Needleleaf_Forests => 8, :Deciduous_Needleleaf_Forests),
    (:Non_Vegetated_Lands => 9, :Barren),
    (:Urban_and_Built_up_Lands => 10, :Urban_and_Built_up_Lands),
    (:Unclassified => 255, :Unclassified),
)
