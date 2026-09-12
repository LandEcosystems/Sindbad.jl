export vegDynamics_forcing

struct vegDynamics_forcing <: vegDynamics end

function precompute(params::vegDynamics_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_pft ⇐ forcing

    veg_type = f_pft[1]

    ## pack land variables
    @pack_nt veg_type ⇒ land.states
    return land
end

function compute(params::vegDynamics_forcing, forcing, land, helpers)
    ## unpack forcing
    @unpack_nt f_pft ⇐ forcing

    veg_type = f_pft[1]

    ## pack land variables
    @pack_nt veg_type ⇒ land.states
    return land
end

purpose(::Type{vegDynamics_forcing}) = "Gets the raw vegetation-type class code from forcing data, independent of which legend it was classified against."

@doc """

$(getModelDocString(vegDynamics_forcing))

---

# Extended help

The raw vegetation-type class code is taken from the `f_pft` forcing variable and
published, unchanged, as `land.states.veg_type` -- no catalog interpretation
happens here, so one approach covers every `vegClassMap_MODIS_*` source legend: which
legend the code is drawn from is entirely a `vegClassMap`-side concern
(`vegTypeCatalog`), not this process's. `f_pft` is indexed with `[1]` rather than used
bare since real forcing pipelines publish a spatial-only variable like this as a
one-element array per pixel, not a bare scalar; indexing a true scalar with `[1]`
(e.g. in this package's own synthetic test fixtures) is a no-op, so the same code
handles both without a special case. Vegetation type is time invariant, so it is read
once in `precompute`.

*References*

*Versions*
 - 1.0 on 04.09.2026 [skoirala]
 - 2.0 on 10.09.2026 [skoirala]: split from the generic PFT_forcing into one
   approach per source catalog, resolving through SINDBAD's canonical PFT
   vocabulary instead of publishing a raw, catalog-ambiguous numeric code
 - 3.0 on 10.09.2026 [skoirala]: merged into the unified `vegTypes` process
   (was `PFT_forcing_MODIS_IGBP`); resolves through the two-step
   `vegTypeCatalog`/`vegTypeClassification` mechanism
 - 4.0 on 11.09.2026 [skoirala]: split raw-code extraction into the new
   `vegTypeDynamics` process (was `vegTypes_forcing_MODIS_IGBP`)
 - 5.0 on 11.09.2026 [skoirala]: collapsed the five per-source-catalog
   dynamics approaches (`vegTypeDynamics_forcing_MODIS_{BGC,IGBP,LAI,PFT,UMD}`)
   back into this one -- raw-code extraction never actually depended on which
   catalog the code is interpreted against, only `vegTypes` does
 - 6.0 on 12.09.2026 [skoirala]: renamed from `vegTypeDynamics_forcing`
   (process `vegTypeDynamics` -> `vegClassDynamics`, paired process
   `vegTypes` -> `vegClassMap`)
 - 7.0 on 12.09.2026 [skoirala]: process renamed again, `vegClassDynamics`
   -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - skoirala
"""
vegDynamics_forcing
