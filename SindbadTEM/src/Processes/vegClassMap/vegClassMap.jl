export vegClassMap

abstract type vegClassMap <: LandEcosystem end

purpose(::Type{vegClassMap}) = "Vegetation-type classification of the pixel: resolves land.states.veg_type (set by vegDynamics) to a canonical name, then optionally crosswalks that into a coarser classification."

# Catalogs and their crosswalks are included explicitly before the approaches load,
# matching how cCycleBase.jl includes poolConfigurations.jl before its own approaches:
# includeApproaches globs vegClassMap_*.jl in this directory and does not descend, so it
# skips the mapSources/ subfolder.
include("mapSources/mapSources.jl")

"""
    resolvedVegTypeClassification(::Type{X}) where {X <: LandEcosystem}

Resolve the `vegTypeClassification` trait's `nothing` default (declared in `Types.jl`,
which cannot reference a concrete `VegTypeCatalog` subtype) to the canonical
vocabulary, `VegTypeCatalog_SINDBAD` -- the "no grouping" target every `vegClassMap`
approach resolves into unless it opts into a coarser one (e.g. a `_PlantForm` variant).
"""
resolvedVegTypeClassification(::Type{X}) where {X <: LandEcosystem} =
    something(vegTypeClassification(X), VegTypeCatalog_SINDBAD)

"""
    resolveVegType(::Type{X}, ::Type{Classification}, raw_code) where {X <: vegClassMap}

Shared resolution step for every `vegClassMap` approach, composed of two steps:

1. `raw_code` resolved against `X`'s own source catalog (`vegTypeCatalog(X)`) and its
   crosswalk to the canonical `VegTypeCatalog_SINDBAD` name (`veg_type_name_source` is the
   source catalog's own name for that code, kept for provenance/output metadata only)
   -- the source catalog is read off the approach type itself rather than repeated as
   a second literal beside the `vegTypeCatalog(::Type{X})` trait declaration.
2. The canonical name resolved against `Classification`'s own crosswalk
   (`vegTypeClassOf`), giving `veg_type_name`, the name every downstream science approach
   reads. This step is a no-op when `Classification` is `VegTypeCatalog_SINDBAD`
   itself, with no special case needed: `vegTypeClassOf` treats identity as a
   one-element grouping.

`raw_code` is `land.states.veg_type`, set upstream by a `vegDynamics`
approach -- no `vegClassMap` approach reads `forcing` or a parameter directly. Doesn't
return `raw_code`: it passes straight through unchanged, and `land.states.veg_type`
already holds it, so callers don't need to unpack it back out of here just to re-pack
the same value.

Errors (via `vegTypeName`/`vegTypeClassOf`) rather than clamps when a code or name is
not known, so a bad code or an uncovered class fails at the point it was produced
instead of silently aliasing to the wrong class further downstream.
"""
function resolveVegType(::Type{X}, ::Type{Classification}, raw_code) where
        {X <: vegClassMap, Classification <: VegTypeCatalog}
    SourceCatalog = vegTypeCatalog(X)
    veg_type_name_source = vegTypeName(SourceCatalog, raw_code)
    canonical_name = vegTypeCanonicalName(SourceCatalog, raw_code)
    canonical_name isa Symbol || error(
        "$(nameof(SourceCatalog)) is a grouping catalog (its own crosswalk target is " *
        "a tuple), so it cannot be used as the raw-code source of resolveVegType. " *
        "Source catalogs must crosswalk one-to-one onto VegTypeCatalog_SINDBAD.")
    veg_type_name = vegTypeClassOf(Classification, canonical_name)
    return veg_type_name, veg_type_name_source
end

"""
    define(params::vegClassMap, forcing, land, helpers)

Shared `define` for every `vegClassMap` approach: packs an instance of the approach's
resolved target classification into `land.vegClassMap`, so downstream consumers (e.g.
`vegQualityTraits_vegType`) can read back which classification is active and derive
their own per-classification default tables from it via `vegTypeCatalogFor`, without
each approach needing to repeat this. Mirrors `cCycleBase_GSI_PlantForm` packing
`c_model = cCycleBase_GSI_PlantForm()` into `land.models` for the same kind of
downstream dispatch.

Declared once here, generically over `vegClassMap`, rather than in each approach file,
since every approach does exactly this and nothing else at `define` time.
"""
function define(params::vegClassMap, forcing, land, helpers)
    veg_type_class_map = resolvedVegTypeClassification(typeof(params))()
    @pack_nt veg_type_class_map ⇒ land.vegClassMap
    return land
end

"""
    precompute(params::vegClassMap, forcing, land, helpers)

Shared `precompute` for every `vegClassMap` approach: resolves `land.states.veg_type`
via `resolveVegType`, against the approach's own `vegTypeCatalog` (read off
`typeof(params)` inside `resolveVegType`) and its resolved target classification
(`resolvedVegTypeClassification(typeof(params))`, the same trait lookup `define` uses),
and packs the result back into `land.states`.

Declared once here, generically over `vegClassMap`, rather than in each approach file,
since every approach does exactly this and nothing else at `precompute` time -- the two
traits (`vegTypeCatalog`, `vegTypeClassification`) are the only thing that ever varies
between approaches.
"""
function precompute(params::vegClassMap, forcing, land, helpers)
    ## unpack land
    @unpack_nt veg_type ⇐ land.states

    veg_type_name, veg_type_name_source = resolveVegType(
        typeof(params), resolvedVegTypeClassification(typeof(params)), veg_type)

    ## pack land variables
    @pack_nt (veg_type_name, veg_type_name_source) ⇒ land.states
    return land
end

includeApproaches(vegClassMap, @__DIR__)

@doc """
    $(getModelDocString(vegClassMap))

---

# Extended help

Resolves the raw vegetation-classification code that `vegDynamics` published to
`land.states.veg_type` and, optionally, groups the result into a coarser
classification, writing `land.states.veg_type_name` (plus `veg_type_name_source` for
provenance) that every downstream science approach reads. `vegClassMap` never reads
`forcing` or a parameter itself -- obtaining the raw code, whether from forcing or a
constant, is `vegDynamics`'s job, run earlier in the model's process order.

Each concrete approach declares two traits: `vegTypeCatalog`, the source catalog its
raw code (`land.states.veg_type`) is interpreted against (a forcing legend, or
the canonical vocabulary itself when paired with `vegDynamics_constant`), and
`vegTypeClassification`, the target classification to crosswalk into (defaulting to
`VegTypeCatalog_SINDBAD`, i.e. no grouping, when unset). A `_PlantForm`-suffixed
approach (e.g. `vegClassMap_MODIS_IGBP_PlantForm`) is the same resolution with
`vegTypeClassification` set to `VegTypeCatalog_PlantForm` instead -- composition via a
second small approach file, rather than a second `model_structure.json` field or a
struct type parameter, since neither fits how approaches are otherwise selected in
this codebase.

**Known limitation**: because `land.states.veg_type_name` is a single field, one experiment
cannot combine a consumer that expects the fine canonical vocabulary (e.g.
`vegQualityTraits_vegType`, `runoffSaturationExcess_Bergstroem1992VegFractionPFT`) with
one that expects a grouped
classification (e.g. `cCycleBase_GSI_PlantForm`/`_MGMT`) in the same run. Pick a
`vegClassMap` approach whose target classification matches every downstream consumer
selected alongside it.

*Versions*
 - 1.0 on 10.09.2026 [skoirala]: merged from the former `PFT` and `plantForm`
   processes into one, with a formal one-to-many crosswalk mechanism
   (`VegTypeCatalog_PlantForm`) replacing `plantForm_PFT`'s inline grouping table
 - 2.0 on 11.09.2026 [skoirala]: split raw-code extraction out into the new
   `vegTypeDynamics` process; `vegTypes` approaches now depend only on
   `land.states.veg_type`, never on `forcing`, and are named after their
   source catalog alone (e.g. `vegTypes_MODIS_BGC`, was
   `vegTypes_forcing_MODIS_BGC`)
 - 3.0 on 12.09.2026 [skoirala]: renamed from `vegTypes` to `vegClassMap`
   (paired process `vegTypeDynamics` -> `vegClassDynamics`)
 - 4.0 on 12.09.2026 [skoirala]: paired process renamed again,
   `vegClassDynamics` -> `vegDynamics` (too easily confused with `vegClassMap`)

*Created by*
 - skoirala
"""
vegClassMap
