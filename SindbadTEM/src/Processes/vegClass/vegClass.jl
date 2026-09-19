export vegClass

abstract type vegClass <: LandEcosystem end

purpose(::Type{vegClass}) = "Vegetation-type classification of the pixel: resolves land.states.veg_type (set by vegDynamics) to a canonical name, then optionally crosswalks that into a coarser classification."

# Catalogs and their crosswalks are included explicitly before the approaches load,
# matching how cCycleBase.jl includes poolConfigurations.jl before its own approaches:
# includeApproaches globs vegClass_*.jl in this directory and does not descend, so it
# skips the mapSources/ subfolder.
include("classifications/classifications.jl")

"""
    resolvedVegClassification(::Type{X}) where {X <: LandEcosystem}

Resolve the `vegTypeClassification` trait's `nothing` default (declared in `Types.jl`,
which cannot reference a concrete `VegClassification` subtype) to the canonical
vocabulary, `Classification_SINDBAD` -- the "no grouping" target every `vegClass`
approach resolves into unless it opts into a coarser one (e.g. a `_PlantForm` variant).
"""
resolvedVegClassification(::Type{X}) where {X <: LandEcosystem} =
    something(vegTypeClassification(X), Classification_SINDBAD)

"""
    resolveVegType(::Type{X}, ::Type{Classification}, raw_code) where {X <: vegClass}

Shared resolution step for every `vegClass` approach, in two steps:

1. `raw_code` resolved against `X`'s own source catalog (`vegTypeCatalog(X)`) and its
   crosswalk to the canonical `Classification_SINDBAD` name; `veg_type_name_source`
   is the source catalog's own name for that code, kept for provenance only.
2. The canonical name resolved against `Classification`'s own crosswalk
   (`resolveVegClassification`), giving `veg_type_name`, the name every downstream
   science approach reads. A no-op when `Classification` is `Classification_SINDBAD`
   itself.

`raw_code` is `land.states.veg_type`, set upstream by a `vegDynamics` approach; no
`vegClass` approach reads `forcing` or a parameter directly.

Errors, rather than clamps, when a code or name is not known, so a bad code fails at
the point it was produced instead of silently aliasing to the wrong class.
"""
function resolveVegType(::Type{X}, ::Type{Classification}, raw_code) where
        {X <: vegClass, Classification <: VegClassification}
    SourceCatalog = vegTypeCatalog(X)
    veg_type_name_source = vegTypeName(SourceCatalog, raw_code)
    canonical_name = vegTypeCanonicalName(SourceCatalog, raw_code)
    canonical_name isa Symbol || error(
        "$(nameof(SourceCatalog)) is a grouping catalog (its own crosswalk target is " *
        "a tuple), so it cannot be used as the raw-code source of resolveVegType. " *
        "Source catalogs must crosswalk one-to-one onto Classification_SINDBAD.")
    veg_type_name = resolveVegClassification(Classification, canonical_name)
    return veg_type_name, veg_type_name_source
end

"""
    define(params::vegClass, forcing, land, helpers)

Shared `define` for every `vegClass` approach: packs an instance of the approach's
resolved target classification into `land.vegClass`, so downstream consumers (e.g.
`vegQualityTraits_vegType`) can read back which classification is active and derive
their own per-classification default tables from it via `getParamsPerVegType`.

Declared once here, generically over `vegClass`, since every approach does exactly
this and nothing else at `define` time.
"""
function define(params::vegClass, forcing, land, helpers)
    veg_type_class_map = resolvedVegClassification(typeof(params))()
    @pack_nt veg_type_class_map ⇒ land.vegClass
    return land
end

"""
    precompute(params::vegClass, forcing, land, helpers)

Shared `precompute` for every `vegClass` approach: resolves `land.states.veg_type`
via `resolveVegType`, against the approach's own `vegTypeCatalog` and resolved target
classification, and packs the result back into `land.states`.

Declared once here, generically over `vegClass`, since the two traits
(`vegTypeCatalog`, `vegTypeClassification`) are the only thing that ever varies
between approaches.
"""
function precompute(params::vegClass, forcing, land, helpers)
    ## unpack land
    @unpack_nt veg_type ⇐ land.states

    veg_type_name, veg_type_name_source = resolveVegType(
        typeof(params), resolvedVegClassification(typeof(params)), veg_type)

    ## pack land variables
    @pack_nt (veg_type_name, veg_type_name_source) ⇒ land.states
    return land
end

includeApproaches(vegClass, @__DIR__)

@doc """
    $(getModelDocString(vegClass))

---

# Extended help

Resolves the raw vegetation-classification code that `vegDynamics` published to
`land.states.veg_type` and, optionally, groups the result into a coarser
classification, writing `land.states.veg_type_name` (plus `veg_type_name_source` for
provenance) that every downstream science approach reads. `vegClass` never reads
`forcing` or a parameter itself; obtaining the raw code is `vegDynamics`'s job.

Each concrete approach declares two traits: `vegTypeCatalog`, the source catalog its
raw code is interpreted against, and `vegTypeClassification`, the target
classification to crosswalk into (defaulting to `Classification_SINDBAD`, i.e. no
grouping, when unset). A `_PlantForm`-suffixed approach (e.g.
`vegClass_MODIS_IGBP_PlantForm`) is the same resolution with `vegTypeClassification`
set to `Classification_PlantForm` instead.

**Known limitation**: because `land.states.veg_type_name` is a single field, one
experiment cannot combine a consumer that expects the fine canonical vocabulary
(e.g. `vegQualityTraits_vegType`) with one that expects a grouped classification
(e.g. `cCycleBase_GSI_PlantForm`/`_MGMT`) in the same run.

*Versions*
 - 1.0 on 10.09.2026 [skoirala]: merged from the former `PFT` and `plantForm`
   processes into one, with a formal one-to-many crosswalk mechanism
   (`Classification_PlantForm`) replacing `plantForm_PFT`'s inline grouping table
 - 2.0 on 11.09.2026 [skoirala]: split raw-code extraction out into the new
   `vegTypeDynamics` process; `vegTypes` approaches now depend only on
   `land.states.veg_type`, never on `forcing`, and are named after their
   source catalog alone (e.g. `vegTypes_MODIS_BGC`, was
   `vegTypes_forcing_MODIS_BGC`)
 - 3.0 on 12.09.2026 [skoirala]: renamed from `vegTypes` to `vegClass`
   (paired process `vegTypeDynamics` -> `vegClassDynamics`)
 - 4.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClass`)

*Created by*
 - skoirala
"""
vegClass
