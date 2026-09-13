export vegClass_MODIS_LAI

struct vegClass_MODIS_LAI <: vegClass end

vegTypeCatalog(::Type{vegClass_MODIS_LAI}) = Classification_MODIS_LAI
vegTypeClassification(::Type{vegClass_MODIS_LAI}) = Classification_SINDBAD

purpose(::Type{vegClass_MODIS_LAI}) = "Gets the vegetation type from LAI/fPAR-biome-classified forcing data."

@doc """

$(getModelDocString(vegClass_MODIS_LAI))

---

# Extended help

Same as [`vegClass_MODIS_IGBP`](@ref), interpreting `land.states.veg_type`
against the LAI/fPAR biome legend (`Classification_MODIS_LAI`) instead of IGBP. Pair
with `vegDynamics_forcing`, which sets `veg_type` from `f_pft`.

*References*

*Versions*
 - 1.0 on 10.09.2026 [skoirala]
 - 2.0 on 10.09.2026 [skoirala]: merged into the unified `vegTypes` process
   (was `PFT_forcing_MODIS_LAI`)
 - 3.0 on 11.09.2026 [skoirala]: renamed from `vegTypes_forcing_MODIS_LAI` and
   split out of its raw-code extraction (now `vegTypeDynamics_forcing`); reads
   `land.states.veg_type` instead of unpacking `forcing` directly
 - 4.0 on 12.09.2026 [skoirala]: `precompute` hoisted to the shared,
   generic `vegTypes.jl` (every approach did exactly the same thing, modulo
   the two traits declared above) -- this file now only declares those traits
 - 5.0 on 12.09.2026 [skoirala]: renamed from `vegTypes_MODIS_LAI` (process
   `vegTypes` -> `vegClass`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`)
 - 6.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClass`)

*Created by*
 - skoirala
"""
vegClass_MODIS_LAI
