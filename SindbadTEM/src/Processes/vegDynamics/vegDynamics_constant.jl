export vegDynamics_constant

#! format: off
@bounds @describe @units @timescale @with_kw struct vegDynamics_constant{T1} <: vegDynamics
    veg_type::T1 = 1.0 | (1.0, 17.0) | "Vegetation type class, per SINDBAD's canonical vegetation-type vocabulary (VegTypeCatalog_SINDBAD)" | "class" | ""
end
#! format: on

function precompute(params::vegDynamics_constant, forcing, land, helpers)
    ## unpack parameters
    @unpack_vegDynamics_constant params

    veg_type = round(Int, veg_type)

    ## pack land variables
    @pack_nt veg_type ⇒ land.states
    return land
end

purpose(::Type{vegDynamics_constant}) = "Sets a uniform vegetation-type class code, given as a canonical vegetation-type class number."

@doc """

$(getModelDocString(vegDynamics_constant))

---

# Extended help

Unlike `vegDynamics_forcing`, this approach has no real data source to read a
raw code from, so `veg_type` is a calibratable parameter, rounded to the
nearest integer class number and published as-is. Pair with `vegClassMap_SINDBAD`,
which interprets a `vegDynamics_constant`-produced code directly against the
canonical `VegTypeCatalog_SINDBAD` vocabulary.

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
 - 5.0 on 11.09.2026 [skoirala]: split from `vegTypes_constant` into this,
   the raw-code half of the former approach -- catalog resolution moved to
   `vegTypes_SINDBAD`
 - 6.0 on 12.09.2026 [skoirala]: renamed from `vegTypeDynamics_constant`
   (process `vegTypeDynamics` -> `vegClassDynamics`, paired process
   `vegTypes` -> `vegClassMap`)
 - 7.0 on 12.09.2026 [skoirala]: process renamed again, `vegClassDynamics`
   -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - unknown [xxx]
"""
vegDynamics_constant
