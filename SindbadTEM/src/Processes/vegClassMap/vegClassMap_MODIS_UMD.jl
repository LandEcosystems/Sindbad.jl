export vegClassMap_MODIS_UMD

struct vegClassMap_MODIS_UMD <: vegClassMap end

vegTypeCatalog(::Type{vegClassMap_MODIS_UMD}) = VegTypeCatalog_MODIS_UMD
vegTypeClassification(::Type{vegClassMap_MODIS_UMD}) = VegTypeCatalog_SINDBAD

purpose(::Type{vegClassMap_MODIS_UMD}) = "Gets the vegetation type from UMD-classified forcing data."

@doc """

$(getModelDocString(vegClassMap_MODIS_UMD))

---

# Extended help

Same as [`vegClassMap_MODIS_IGBP`](@ref), interpreting `land.states.veg_type`
against the University of Maryland legend (`VegTypeCatalog_MODIS_UMD`) instead of
IGBP. Pair with `vegDynamics_forcing`, which sets `veg_type` from `f_pft`.

*References*

*Versions*
 - 1.0 on 10.09.2026 [skoirala]
 - 2.0 on 10.09.2026 [skoirala]: merged into the unified `vegTypes` process
   (was `PFT_forcing_MODIS_UMD`)
 - 3.0 on 11.09.2026 [skoirala]: renamed from `vegTypes_forcing_MODIS_UMD` and
   split out of its raw-code extraction (now `vegTypeDynamics_forcing`); reads
   `land.states.veg_type` instead of unpacking `forcing` directly
 - 4.0 on 12.09.2026 [skoirala]: `precompute` hoisted to the shared,
   generic `vegTypes.jl` (every approach did exactly the same thing, modulo
   the two traits declared above) -- this file now only declares those traits
 - 5.0 on 12.09.2026 [skoirala]: renamed from `vegTypes_MODIS_UMD` (process
   `vegTypes` -> `vegClassMap`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`)
 - 6.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - skoirala
"""
vegClassMap_MODIS_UMD
