export vegClassMap_MODIS_IGBP

struct vegClassMap_MODIS_IGBP <: vegClassMap end

vegTypeCatalog(::Type{vegClassMap_MODIS_IGBP}) = VegTypeCatalog_MODIS_IGBP
vegTypeClassification(::Type{vegClassMap_MODIS_IGBP}) = VegTypeCatalog_SINDBAD

purpose(::Type{vegClassMap_MODIS_IGBP}) = "Gets the vegetation type from IGBP-classified forcing data."

@doc """

$(getModelDocString(vegClassMap_MODIS_IGBP))

---

# Extended help

`land.states.veg_type` (set upstream by `vegDynamics_forcing`) is
interpreted against the MODIS IGBP legend (`VegTypeCatalog_MODIS_IGBP`) and resolved
to `VegTypeCatalog_SINDBAD`'s canonical vocabulary before being published as
`land.states.veg_type_name`, the single name every downstream vegetation-type-dependent
process reads. The IGBP-specific name is also published, as
`land.states.veg_type_name_source`, for provenance and output metadata only; no science
approach should read it. Vegetation type is time invariant, so it is resolved once in
`precompute`.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]
 - 2.0 on 10.09.2026 [skoirala]: split from the generic PFT_forcing into one
   approach per source catalog, resolving through SINDBAD's canonical PFT
   vocabulary instead of publishing a raw, catalog-ambiguous numeric code
 - 3.0 on 10.09.2026 [skoirala]: merged into the unified `vegTypes` process
   (was `PFT_forcing_MODIS_IGBP`); resolves through the two-step
   `vegTypeCatalog`/`vegTypeClassification` mechanism, defaulting to the
   canonical vocabulary (no grouping) -- see `vegTypes_MODIS_IGBP_PlantForm`
   for the grouped variant
 - 4.0 on 11.09.2026 [skoirala]: renamed from `vegTypes_forcing_MODIS_IGBP`
   and split out of its raw-code extraction (now `vegTypeDynamics_forcing`);
   reads `land.states.veg_type` instead of unpacking `forcing` directly
 - 5.0 on 12.09.2026 [skoirala]: `precompute` hoisted to the shared,
   generic `vegTypes.jl` (every approach did exactly the same thing, modulo
   the two traits declared above) -- this file now only declares those traits
 - 6.0 on 12.09.2026 [skoirala]: renamed from `vegTypes_MODIS_IGBP` (process
   `vegTypes` -> `vegClassMap`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`) -- see `vegClassMap_MODIS_IGBP_PlantForm` for the
   grouped variant
 - 7.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - skoirala
"""
vegClassMap_MODIS_IGBP
