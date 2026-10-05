export Classification_PlantForm

struct Classification_PlantForm <: VegClassification end
purpose(::Type{Classification_PlantForm}) = "Groups the canonical vegetation-type vocabulary into tree/shrub/herb plant forms, one-to-many"

"""
    vegClasses(::Type{Classification_PlantForm})

Groups `Classification_SINDBAD`'s canonical classes into a coarse plant-form
split: `:tree`, `:shrub`, `:herb`, and `:unknown` for every canonical class
none of the three science groups covers. This is the one-to-many crosswalk
example: each entry's target is a tuple of several canonical names, not one.

`:unknown` is an explicit, load-time-validated catch-all (checked by
`validateVegTypeCoverage`) for `Water_Bodies`, `Urban_and_Built_up_Lands`,
`Permanent_Snow_and_Ice`, `Barren`, and `Unclassified`.

The numeric code half of each entry is vestigial here: nothing decodes a raw
"plant-form code" from forcing data, and no approach resolves a constant
against this catalog. Kept only for shape-consistency with every other
`VegClassification`.
"""
vegClasses(::Type{Classification_PlantForm}) = (
    (:tree => 1, (:Evergreen_Needleleaf_Forests, :Evergreen_Broadleaf_Forests,
                  :Deciduous_Needleleaf_Forests, :Deciduous_Broadleaf_Forests,
                  :Mixed_Forests, :Woody_Savannas, :Savannas)),
    (:shrub => 2, (:Closed_Shrublands, :Open_Shrublands)),
    (:herb => 3, (:Grasslands, :Permanent_Wetlands, :Croplands,
                  :Cropland_Natural_Vegetation_Mosaics)),
    (:unknown => 4, (:Water_Bodies, :Urban_and_Built_up_Lands,
                     :Permanent_Snow_and_Ice, :Barren, :Unclassified)),
)
