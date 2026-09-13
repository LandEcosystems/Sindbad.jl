export vegClass_MODIS_PFT

struct vegClass_MODIS_PFT <: vegClass end

vegTypeCatalog(::Type{vegClass_MODIS_PFT}) = Classification_MODIS_PFT
vegTypeClassification(::Type{vegClass_MODIS_PFT}) = Classification_SINDBAD

purpose(::Type{vegClass_MODIS_PFT}) = "Gets the vegetation type from Plant-Functional-Type-classified (MCD12Q1 Type 5) forcing data."

@doc """

$(getModelDocString(vegClass_MODIS_PFT))

---

# Extended help

Same as [`vegClass_MODIS_IGBP`](@ref), interpreting `land.states.veg_type`
against the MODIS PFT legend (`Classification_MODIS_PFT`, after Bonan (2002)) instead
of IGBP. `veg_type_name` (canonical, `Classification_SINDBAD`-keyed) and `veg_type_name_source`
(this legend's own name) generally differ here: see
`vegClasses(::Type{Classification_MODIS_PFT})` for the
`Shrub`/`Cereal_Croplands`/`Broadleaf_Croplands` classes that collapse onto a
single canonical class. Pair with `vegDynamics_forcing`, which sets
`veg_type` from `f_pft`.

*References*

*Versions*
 - 1.0 on 10.09.2026 [skoirala]
 - 2.0 on 10.09.2026 [skoirala]: merged into the unified `vegTypes` process
   (was `PFT_forcing_MODIS_PFT`)
 - 3.0 on 11.09.2026 [skoirala]: renamed from `vegTypes_forcing_MODIS_PFT` and
   split out of its raw-code extraction (now `vegTypeDynamics_forcing`); reads
   `land.states.veg_type` instead of unpacking `forcing` directly
 - 4.0 on 12.09.2026 [skoirala]: `precompute` hoisted to the shared,
   generic `vegTypes.jl` (every approach did exactly the same thing, modulo
   the two traits declared above) -- this file now only declares those traits
 - 5.0 on 12.09.2026 [skoirala]: renamed from `vegTypes_MODIS_PFT` (process
   `vegTypes` -> `vegClass`, paired process `vegTypeDynamics` ->
   `vegClassDynamics`)
 - 6.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClass`)

*Created by*
 - skoirala
"""
vegClass_MODIS_PFT
