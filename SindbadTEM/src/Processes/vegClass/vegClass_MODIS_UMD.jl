export vegClass_MODIS_UMD

struct vegClass_MODIS_UMD <: vegClass end

vegTypeCatalog(::Type{vegClass_MODIS_UMD}) = Classification_MODIS_UMD
vegTypeClassification(::Type{vegClass_MODIS_UMD}) = Classification_SINDBAD

purpose(::Type{vegClass_MODIS_UMD}) = "Gets the vegetation type from UMD-classified forcing data."

@doc """

$(getModelDocString(vegClass_MODIS_UMD))

---

# Extended help

Same as [`vegClass_MODIS_IGBP`](@ref), interpreting `land.states.veg_type`
against the University of Maryland legend (`Classification_MODIS_UMD`) instead of
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
   `vegTypes` -> `vegClass`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`)
 - 6.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClass`)

*Created by*
 - skoirala
"""
vegClass_MODIS_UMD
