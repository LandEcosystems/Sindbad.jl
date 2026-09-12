export vegClassMap_SINDBAD

struct vegClassMap_SINDBAD <: vegClassMap end

vegTypeCatalog(::Type{vegClassMap_SINDBAD}) = VegTypeCatalog_SINDBAD
vegTypeClassification(::Type{vegClassMap_SINDBAD}) = VegTypeCatalog_SINDBAD

purpose(::Type{vegClassMap_SINDBAD}) = "Resolves a vegetation-type code already given in SINDBAD's own canonical vocabulary."

@doc """

$(getModelDocString(vegClassMap_SINDBAD))

---

# Extended help

Unlike `vegClassMap_MODIS_*`, this approach has no real data source to interpret
`land.states.veg_type` against, so it is written directly in terms of SINDBAD's
canonical vegetation-type vocabulary (`VegTypeCatalog_SINDBAD`) rather than needing one
variant per source catalog: the code is resolved via `resolveVegType`, which for this
catalog is always the identity (`veg_type_name` and `veg_type_name_source` are always equal
here). Pair with `vegDynamics_constant`, which produces a `VegTypeCatalog_SINDBAD`-
coded `veg_type`.

*References*

*Versions*
 - 1.0 on 18.11.2019 [ttraut]: cleaned up the code
 - 2.0 on 10.09.2026 [skoirala]: resolved through the PFT catalog machinery
   instead of publishing a raw numeric code with no declared classification
 - 3.0 on 10.09.2026 [skoirala]: collapsed the five catalog-specific variants
   back into one approach, written directly against the canonical
   PFTCatalog_SINDBAD_PFT vocabulary, since this approach has no real data
   source to interpret a raw code against
 - 4.0 on 10.09.2026 [skoirala]: merged into the unified `vegTypes` process
   (was `PFT_constant`), resolving through the two-step
   `vegTypeCatalog`/`vegTypeClassification` mechanism
 - 5.0 on 11.09.2026 [skoirala]: renamed from `vegTypes_constant` and split
   out of its raw-code extraction (now `vegTypeDynamics_constant`); reads
   `land.states.veg_type` instead of a parameter directly
 - 6.0 on 12.09.2026 [skoirala]: `precompute` hoisted to the shared,
   generic `vegTypes.jl` (every approach did exactly the same thing, modulo
   the two traits declared above) -- this file now only declares those traits
 - 7.0 on 12.09.2026 [skoirala]: renamed from `vegTypes_SINDBAD` (process
   `vegTypes` -> `vegClassMap`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`)
 - 8.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - unknown [xxx]
"""
vegClassMap_SINDBAD
