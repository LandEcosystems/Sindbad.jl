export VegTypeCatalog
export vegTypeClasses
export vegTypeName
export vegTypeCode
export vegTypeCanonicalName
export vegTypeClassOf
export vegTypeCatalogFor

"""
    VegTypeCatalog

Abstract supertype of the vegetation-type classification catalogs: one per real data
source or per derived grouping, each a literal, undiverged transcription of that
source's own documented class table (or, for a grouping catalog, a table of which
canonical classes it lumps together), plus its mapping onto the canonical vocabulary.

# Notes:
- One file per catalog, in this directory, listed at the bottom of this file, the
  same convention `poolConfigurations/poolConfigurations.jl` uses for carbon pool
  structures.
- `VegTypeCatalog_SINDBAD` is the canonical catalog: the one name set every
  downstream science approach (the `_PER_VEGTYPE` tables in `ParamsForVegClasses.jl`,
  ...) is written against. It is copied from `VegTypeCatalog_MODIS_IGBP` (same names,
  same codes) since that is what SINDBAD's actual forcing sources use today, but kept
  separate so it can gain classes IGBP does not have without ever compromising
  `MODIS_IGBP.jl`'s job of staying an exact transcription of the MODIS document. Every
  other catalog's `vegTypeClasses` entry carries the `VegTypeCatalog_SINDBAD` class (or
  classes) each of its own classes maps onto; `VegTypeCatalog_SINDBAD`'s own entries
  map onto themselves.
- A catalog's crosswalk target is either a single canonical name (one-to-one, e.g.
  `VegTypeCatalog_MODIS_IGBP`) or a tuple of canonical names (one-to-many, e.g.
  `VegTypeCatalog_PlantForm` grouping many canonical classes into `:tree`/`:shrub`/
  `:herb`/`:unknown`). `vegTypeClassOf` and `vegTypeCatalogFor` handle both cases
  uniformly, normalizing a bare `Symbol` target to a one-element tuple.
- Catalogs subtype `SindbadTypes`, deliberately not `vegClassMap`, mirroring why
  `CarbonPoolConfiguration` subtypes `SindbadTypes` rather than `cCycleBase`: a
  catalog has no `define` and no parameters, so registering it as an approach would
  surface it as a broken one.
- `vegClassMap.jl` includes this file before `includeApproaches(vegClassMap, @__DIR__)` runs,
  so every catalog is defined before any `vegClassMap_*` approach that references one
  loads.
"""
abstract type VegTypeCatalog <: SindbadTypes end
purpose(::Type{VegTypeCatalog}) = "Abstract type for vegetation-type classification catalogs, one per real data source or derived grouping, each mapping onto the canonical SINDBAD vocabulary"

"""
    vegTypeClasses(catalog)

Return a catalog's class table as a `Tuple` of `(name::Symbol => code::Int,
canonical_target)` entries, one per class, exactly as documented by the source for
`name`/`code` and, in `canonical_target`, the class(es) this one maps onto in the
canonical `VegTypeCatalog_SINDBAD` vocabulary. Keeping a class's code and its
canonical target in the same entry, rather than in two separate tables, means they
cannot drift out of sync with each other as classes are added or reordered.

`canonical_target` is a single `Symbol` for a one-to-one catalog (every source
catalog, and `VegTypeCatalog_SINDBAD` itself, whose entries target themselves), or an
`NTuple` of `Symbol`s for a one-to-many grouping catalog (e.g.
`VegTypeCatalog_PlantForm`).

Every name in `canonical_target` is checked against `VegTypeCatalog_SINDBAD`'s own
names at load time (`validateVegTypeCrosswalks`, below), and every canonical name is
checked to be covered by every catalog (`validateVegTypeCoverage`, below) -- a
crosswalk naming a class the canonical list does not have, or a canonical class no
catalog covers, is a bug caught immediately, not a silent `KeyError` the first time
that class shows up in real data.
"""
function vegTypeClasses end

"""
    vegTypeName(catalog, code)

Resolve a numeric class code to its catalog name, erroring rather than silently
clamping when the code is not one of the catalog's own.
"""
function vegTypeName(::Type{T}, code) where {T <: VegTypeCatalog}
    for (name_code, _) in vegTypeClasses(T)
        if last(name_code) == code
            return first(name_code)
        end
    end
    error("$(code) is not a valid vegetation-type code in $(nameof(T)). Valid codes: " *
          "$(last.(first.(vegTypeClasses(T)))).")
end

"""
    vegTypeCode(catalog, name)

Resolve a catalog name to its numeric class code, erroring on an unknown name.
"""
function vegTypeCode(::Type{T}, name::Symbol) where {T <: VegTypeCatalog}
    for (name_code, _) in vegTypeClasses(T)
        if first(name_code) == name
            return last(name_code)
        end
    end
    error("$(name) is not a known vegetation-type class of $(nameof(T)). Known classes: " *
          "$(first.(first.(vegTypeClasses(T)))).")
end

"""
    vegTypeCanonicalName(catalog, code)

Resolve a numeric class code to its catalog's raw crosswalk target, i.e. the single
canonical name for a one-to-one catalog, or the tuple of canonical names for a
one-to-many catalog. Most callers want `vegTypeClassOf` instead, which resolves all
the way to one class name regardless of which kind of catalog is involved.

Only ever called with a one-to-one `SourceCatalog` in practice (`resolveVegType`
never resolves a raw code against a grouping catalog like `VegTypeCatalog_PlantForm`
-- see its own docstring), so unlike `vegTypeClassOf`, this one has no one-to-many
call site to be allocation-free for: its return type genuinely varies (a bare
`Symbol` for one catalog's entries, an `NTuple` for another's), so no amount of
restructuring the walk makes it uniformly-typed. Left as a plain loop.
"""
function vegTypeCanonicalName(::Type{T}, code) where {T <: VegTypeCatalog}
    for (name_code, canonical_target) in vegTypeClasses(T)
        if last(name_code) == code
            return canonical_target
        end
    end
    error("$(code) is not a valid vegetation-type code in $(nameof(T)). Valid codes: " *
          "$(last.(first.(vegTypeClasses(T)))).")
end

"""
    vegTypeClassOf(::Type{Classification}, canonical_name::Symbol)

Resolve a canonical `VegTypeCatalog_SINDBAD` name to `Classification`'s own class
name. Works uniformly whether `Classification`'s crosswalk targets are one-to-one
(including `VegTypeCatalog_SINDBAD` itself, whose own entries target themselves --
true identity) or one-to-many (`VegTypeCatalog_PlantForm`), since both cases reduce to
"does this entry's target, normalized to a tuple, contain `canonical_name`". This is
what lets `resolveVegType` compose a source catalog's resolution with a second,
independently selected classification without a special case for the identity
target.

Errors, naming the classification and the unmatched name, if no class of
`Classification` covers `canonical_name` -- see `validateVegTypeCoverage` for why this
should never fire once every catalog is included.

Walks `vegTypeClasses(T)` by compile-time tail-recursion (`_vegTypeClassOf`) rather
than a `for` loop. For a one-to-many catalog like `VegTypeCatalog_PlantForm`, each
entry's target tuple has a different length (`:tree`'s 7 names vs `:shrub`'s 2), so a
`for` loop's iteration variable has no single concrete type across entries and Julia
falls back to type-unstable, allocating code -- confirmed via `@code_warntype`
(`Body::ANY`) and a real `precompute` allocation on every `_PlantForm` approach.
Every entry's actual *return* value (`first(name_code)`) is a plain `Symbol`
regardless of the entry, though, so recursing on `Base.tail` of the classes tuple
(one fully specialized compiled method per recursion depth) keeps that return type
concrete while still letting each depth's own `canonical_target` type vary freely.
"""
function vegTypeClassOf(::Type{T}, canonical_name::Symbol) where {T <: VegTypeCatalog}
    return _vegTypeClassOf(T, canonical_name, vegTypeClasses(T))
end
@inline function _vegTypeClassOf(::Type{T}, canonical_name::Symbol, classes::Tuple) where {T}
    name_code, canonical_target = first(classes)
    targets = canonical_target isa Tuple ? canonical_target : (canonical_target,)
    canonical_name in targets && return first(name_code)
    return _vegTypeClassOf(T, canonical_name, Base.tail(classes))
end
@inline function _vegTypeClassOf(::Type{T}, canonical_name::Symbol, ::Tuple{}) where {T}
    error("$(canonical_name) is not covered by any class of $(nameof(T)). Known " *
          "classes: $(first.(first.(vegTypeClasses(T)))).")
end

"""
    vegTypeCatalogFor(base_table::NamedTuple, ::Type{Classification})

Re-key a base table declared in `ParamsForVegClasses.jl` (always keyed by
`VegTypeCatalog_SINDBAD`'s canonical names) onto `Classification`'s own class names.
One-to-one entries (including `VegTypeCatalog_SINDBAD`, the identity case) pass the
base value through unchanged under the new name; one-to-many entries (e.g.
`VegTypeCatalog_PlantForm`'s `:tree`/`:shrub`/`:herb`/`:unknown`) get the unweighted
average of every canonical class the group's own `vegTypeClasses` entry names. No
special-casing identity vs. grouping: both are "average over however many targets this
entry names."
"""
function vegTypeCatalogFor(base_table::NamedTuple, ::Type{Classification}) where {Classification <: VegTypeCatalog}
    names = Symbol[]
    vals = Float64[]
    for (name_code, canonical_target) in vegTypeClasses(Classification)
        targets = canonical_target isa Tuple ? canonical_target : (canonical_target,)
        push!(names, first(name_code))
        push!(vals, sum(getproperty(base_table, t) for t in targets) / length(targets))
    end
    return NamedTuple{Tuple(names)}(Tuple(vals))
end

# One file per catalog, listed rather than globbed so only files meant to load do.
# SINDBAD (the canonical vocabulary) is included after every source catalog since
# validateVegTypeCrosswalks below needs every catalog, including it, defined first;
# PlantForm is included last since it groups canonical names and so validates against
# SINDBAD.
include("MODIS_IGBP.jl")
include("MODIS_UMD.jl")
include("MODIS_LAI.jl")
include("MODIS_BGC.jl")
include("MODIS_PFT.jl")
include("SINDBAD.jl")
include("PlantForm.jl")

"""
    validateVegTypeCrosswalks()

For every `VegTypeCatalog` subtype, check that each of its `vegTypeClasses` entries'
canonical target (or, for a one-to-many entry, every name in it) is actually one of
`VegTypeCatalog_SINDBAD`'s own names, erroring immediately (naming the offending
catalog and class) if not.

Run once, here, after every catalog file above is included, so a typo'd or stale
crosswalk target -- e.g. after a class is renamed or removed from
`VegTypeCatalog_SINDBAD` but a source catalog's crosswalk still names the old one --
fails at package load time instead of the first time that specific raw code shows up
in real data.
"""
function validateVegTypeCrosswalks()
    canonical_names = first.(first.(vegTypeClasses(VegTypeCatalog_SINDBAD)))
    for T in subtypes(VegTypeCatalog)
        T === VegTypeCatalog_SINDBAD && continue
        for (name_code, canonical_target) in vegTypeClasses(T)
            for one_target in (canonical_target isa Tuple ? canonical_target : (canonical_target,))
                if one_target ∉ canonical_names
                    error("$(nameof(T))'s class `$(first(name_code))` crosswalks to " *
                          "`$(one_target)`, which is not a class of the canonical " *
                          "VegTypeCatalog_SINDBAD (known classes: $(canonical_names)). " *
                          "Add it there, or fix the crosswalk in $(nameof(T)).")
                end
            end
        end
    end
    return nothing
end

"""
    validateVegTypeCoverage()

For every `VegTypeCatalog` subtype meant to serve as a *target* classification (the
canonical `VegTypeCatalog_SINDBAD` vocabulary itself, and any one-to-many grouping
catalog such as `VegTypeCatalog_PlantForm` -- identified by having at least one tuple
crosswalk target, since that is what distinguishes a grouping/classification catalog
from a one-to-one source legend), check that every canonical class is covered by at
least one of that catalog's own classes, via `vegTypeClassOf`, erroring immediately
(naming the catalog and the uncovered class) if not.

Deliberately **not** checked for the one-to-one source legends (`VegTypeCatalog_MODIS_*`):
those are legitimately coarser or narrower than the canonical vocabulary -- that is the
whole point of a crosswalk -- and are only ever used as the raw-code *source* half of
`resolveVegType`, never as its target `Classification`, so an uncovered canonical class
there is not a bug.

This is the reverse of `validateVegTypeCrosswalks`: that check catches a crosswalk
target that does not exist; this one catches a canonical class no target
classification's crosswalk ever reaches. It is what forces a grouping catalog like
`VegTypeCatalog_PlantForm` to declare an explicit catch-all group (e.g. `:unknown`) for
every canonical class its science groups do not otherwise cover, rather than leaving
that gap to surface as a runtime error (or a silent fallback) the first time a pixel
resolves to it.
"""
function validateVegTypeCoverage()
    canonical_names = first.(first.(vegTypeClasses(VegTypeCatalog_SINDBAD)))
    for T in subtypes(VegTypeCatalog)
        is_target_classification = T === VegTypeCatalog_SINDBAD ||
            any(canonical_target isa Tuple for (_, canonical_target) in vegTypeClasses(T))
        is_target_classification || continue
        for canonical in canonical_names
            try
                vegTypeClassOf(T, canonical)
            catch
                error("$(nameof(T)) has no class covering canonical vegetation type " *
                      "`$(canonical)`. Add it to an existing group, or add its own " *
                      "1:1 entry.")
            end
        end
    end
    return nothing
end

validateVegTypeCrosswalks()
validateVegTypeCoverage()

include("ParamsForVegClasses.jl")
