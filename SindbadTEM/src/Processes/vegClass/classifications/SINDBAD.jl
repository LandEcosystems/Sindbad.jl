export Classification_SINDBAD

struct Classification_SINDBAD <: VegClassification end
purpose(::Type{Classification_SINDBAD}) = "SINDBAD's own canonical vegetation-type vocabulary, the one every vegetation-type-dependent science approach is written against"

"""
    vegClasses(::Type{Classification_SINDBAD})

SINDBAD's canonical vegetation-type classes: the one name set every downstream
science approach is written against. Copied from `Classification_MODIS_IGBP`
(same names, same codes), but kept as its own catalog so it is free to gain
classes IGBP does not have, while `MODIS_IGBP.jl` stays an exact transcription
of the MODIS document. Every other catalog's `vegClasses` crosswalks onto
these names; this catalog's own entries map onto themselves.
"""
vegClasses(::Type{Classification_SINDBAD}) = (
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
