export vegClassMap_MODIS_IGBP_PlantForm

struct vegClassMap_MODIS_IGBP_PlantForm <: vegClassMap end

vegTypeCatalog(::Type{vegClassMap_MODIS_IGBP_PlantForm}) = VegTypeCatalog_MODIS_IGBP
vegTypeClassification(::Type{vegClassMap_MODIS_IGBP_PlantForm}) = VegTypeCatalog_PlantForm

purpose(::Type{vegClassMap_MODIS_IGBP_PlantForm}) = "Gets the vegetation type from IGBP-classified forcing data, grouped into tree/shrub/herb plant forms."

@doc """

$(getModelDocString(vegClassMap_MODIS_IGBP_PlantForm))

---

# Extended help

Identical to [`vegClassMap_MODIS_IGBP`](@ref) except its target classification is
`VegTypeCatalog_PlantForm` instead of the canonical vocabulary, so `land.states.veg_type_name`
holds `:tree`/`:shrub`/`:herb`/`:unknown` rather than one of the 18 canonical classes.
Replaces the former `plantForm_PFT` approach's grouping step, now expressed as data on
`VegTypeCatalog_PlantForm` (`vegTypeClasses`) rather than logic inside this file. Pairs
with the same `vegDynamics_forcing` as the plain `vegClassMap_MODIS_IGBP` -- the raw
code is identical, only the target classification differs.

Select this approach (rather than the plain `vegClassMap_MODIS_IGBP`) when the downstream
`cCycleBase` approach is `cCycleBase_GSI_PlantForm`/`_MGMT`, which reads
`land.states.veg_type_name` grouped this way. Do not combine it with a consumer that expects
the fine canonical vocabulary (`vegQualityTraits_vegType`,
`runoffSaturationExcess_Bergstroem1992VegFractionPFT`) -- see `vegClassMap`'s own
docstring for this limitation.

*References*

*Versions*
 - 1.0 on 10.09.2026 [skoirala]: new, replacing the former separate
   `PFT_forcing_MODIS_IGBP` + `plantForm_PFT` two-process pipeline
 - 2.0 on 11.09.2026 [skoirala]: renamed from
   `vegTypes_forcing_MODIS_IGBP_PlantForm` and split out of its raw-code
   extraction (now `vegTypeDynamics_forcing`); reads
   `land.states.veg_type` instead of unpacking `forcing` directly
 - 3.0 on 12.09.2026 [skoirala]: `precompute` hoisted to the shared,
   generic `vegTypes.jl` (every approach did exactly the same thing, modulo
   the two traits declared above) -- this file now only declares those traits
 - 4.0 on 12.09.2026 [skoirala]: renamed from `vegTypes_MODIS_IGBP_PlantForm`
   (process `vegTypes` -> `vegClassMap`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`)
 - 5.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - skoirala
"""
vegClassMap_MODIS_IGBP_PlantForm
