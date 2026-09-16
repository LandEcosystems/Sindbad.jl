export VegClassification
export vegClasses
export vegTypeName
export vegTypeCode
export vegTypeCanonicalName
export resolveVegClassification
export getParamsPerVegType
export getParamForVegType

"""
    VegClassification

Abstract supertype of the vegetation-type classification catalogs: one per real
data source or per derived grouping, each a literal transcription of that source's
own documented class table, plus its mapping onto the canonical vocabulary,
`Classification_SINDBAD`.

# Notes:
- One file per catalog, in this directory, listed at the bottom of this file.
- A catalog's crosswalk target is either a single canonical name (one-to-one, e.g.
  `Classification_MODIS_IGBP`) or a tuple of canonical names (one-to-many, e.g.
  `Classification_PlantForm` grouping many canonical classes into `:tree`/`:shrub`/
  `:herb`/`:unknown`).
- Catalogs subtype `SindbadTypes`, not `vegClass`: a catalog has no `define` and no
  parameters, so registering it as an approach would surface it as a broken one.
"""
abstract type VegClassification <: SindbadTypes end
purpose(::Type{VegClassification}) = "Abstract type for vegetation-type classification catalogs, one per real data source or derived grouping, each mapping onto the canonical SINDBAD vocabulary"

"""
    vegClasses(catalog)

Return a catalog's class table as a `Tuple` of `(name::Symbol => code::Int,
canonical_target)` entries, one per class, exactly as documented by the source for
`name`/`code`, plus the class(es) it maps onto in the canonical
`Classification_SINDBAD` vocabulary.

`canonical_target` is a single `Symbol` for a one-to-one catalog, or an `NTuple` of
`Symbol`s for a one-to-many grouping catalog (e.g. `Classification_PlantForm`).

Checked at load time by `validateVegTypeCrosswalks` and `validateVegTypeCoverage`
below.
"""
function vegClasses end

"""
    vegTypeName(catalog, code)

Resolve a numeric class code to its catalog name, erroring rather than silently
clamping when the code is not one of the catalog's own.
"""
function vegTypeName(::Type{T}, code) where {T <: VegClassification}
    for (name_code, _) in vegClasses(T)
        if last(name_code) == code
            return first(name_code)
        end
    end
    error("$(code) is not a valid vegetation-type code in $(nameof(T)). Valid codes: " *
          "$(last.(first.(vegClasses(T)))).")
end

"""
    vegTypeCode(catalog, name)

Resolve a catalog name to its numeric class code, erroring on an unknown name.
"""
function vegTypeCode(::Type{T}, name::Symbol) where {T <: VegClassification}
    for (name_code, _) in vegClasses(T)
        if first(name_code) == name
            return last(name_code)
        end
    end
    error("$(name) is not a known vegetation-type class of $(nameof(T)). Known classes: " *
          "$(first.(first.(vegClasses(T)))).")
end

"""
    vegTypeCanonicalName(catalog, code)

Resolve a numeric class code to its catalog's raw crosswalk target: the single
canonical name for a one-to-one catalog, or the tuple of canonical names for a
one-to-many catalog. Most callers want `resolveVegClassification` instead, which
resolves all the way to one class name regardless of catalog kind.
"""
function vegTypeCanonicalName(::Type{T}, code) where {T <: VegClassification}
    for (name_code, canonical_target) in vegClasses(T)
        if last(name_code) == code
            return canonical_target
        end
    end
    error("$(code) is not a valid vegetation-type code in $(nameof(T)). Valid codes: " *
          "$(last.(first.(vegClasses(T)))).")
end

"""
    resolveVegClassification(::Type{Classification}, canonical_name::Symbol)

Resolve a canonical `Classification_SINDBAD` name to `Classification`'s own class
name. Works uniformly whether `Classification`'s crosswalk targets are one-to-one
(including `Classification_SINDBAD` itself, true identity) or one-to-many
(`Classification_PlantForm`), since both reduce to "does this entry's target,
normalized to a tuple, contain `canonical_name`".

Errors, naming the classification and the unmatched name, if no class of
`Classification` covers `canonical_name`; see `validateVegTypeCoverage` for why this
should never fire once every catalog is included.

Walks `vegClasses(T)` by compile-time tail-recursion (`_resolveVegClassification`)
rather than a `for` loop: a one-to-many catalog's entries have differently-sized
target tuples, so a `for` loop's iteration variable has no single concrete type and
Julia falls back to allocating code. Recursing on `Base.tail` keeps the (always
`Symbol`) return type concrete.
"""
function resolveVegClassification(::Type{T}, canonical_name::Symbol) where {T <: VegClassification}
    return _resolveVegClassification(T, canonical_name, vegClasses(T))
end
@inline function _resolveVegClassification(::Type{T}, canonical_name::Symbol, classes::Tuple) where {T}
    name_code, canonical_target = first(classes)
    targets = canonical_target isa Tuple ? canonical_target : (canonical_target,)
    canonical_name in targets && return first(name_code)
    return _resolveVegClassification(T, canonical_name, Base.tail(classes))
end
@inline function _resolveVegClassification(::Type{T}, canonical_name::Symbol, ::Tuple{}) where {T}
    error("$(canonical_name) is not covered by any class of $(nameof(T)). Known " *
          "classes: $(first.(first.(vegClasses(T)))).")
end

"""
    getParamsPerVegType(base_table::NamedTuple, ::Type{Classification})

Re-key a base table declared in `ParamsForVegClasses.jl` (always keyed by
`Classification_SINDBAD`'s canonical names) onto `Classification`'s own class names.
One-to-one entries (including `Classification_SINDBAD`, the identity case) pass the
base value through unchanged under the new name; one-to-many entries (e.g.
`Classification_PlantForm`'s `:tree`/`:shrub`/`:herb`/`:unknown`) get the unweighted
average of every canonical class the group's own `vegClasses` entry names. No
special-casing identity vs. grouping: both are "average over however many targets this
entry names."
"""
function getParamsPerVegType(base_table::NamedTuple, ::Type{Classification}) where {Classification <: VegClassification}
    names = Symbol[]
    vals = Float64[]
    for (name_code, canonical_target) in vegClasses(Classification)
        targets = canonical_target isa Tuple ? canonical_target : (canonical_target,)
        push!(names, first(name_code))
        push!(vals, sum(getproperty(base_table, t) for t in targets) / length(targets))
    end
    return NamedTuple{Tuple(names)}(Tuple(vals))
end

"""
    getParamForVegType(per_vegtype, veg_type_name, scalar)

Look up `veg_type_name` in a table already re-keyed by `getParamsPerVegType`,
and scale it by `scalar` (a bounded, optimizable parameter), matching the
scalar's numeric type via `oftype` so the result doesn't silently widen to
Float64.
"""
function getParamForVegType(per_vegtype, veg_type_name, scalar)
    return oftype(scalar, getproperty(per_vegtype, veg_type_name)) * scalar
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

For every `VegClassification` subtype, check that each of its `vegClasses` entries'
canonical target (or, for a one-to-many entry, every name in it) is actually one of
`Classification_SINDBAD`'s own names, erroring immediately (naming the offending
catalog and class) if not.

Run once, here, after every catalog file above is included, so a stale crosswalk
target fails at package load time instead of the first time that raw code shows up
in real data.
"""
function validateVegTypeCrosswalks()
    canonical_names = first.(first.(vegClasses(Classification_SINDBAD)))
    for T in subtypes(VegClassification)
        T === Classification_SINDBAD && continue
        for (name_code, canonical_target) in vegClasses(T)
            for one_target in (canonical_target isa Tuple ? canonical_target : (canonical_target,))
                if one_target ∉ canonical_names
                    error("$(nameof(T))'s class `$(first(name_code))` crosswalks to " *
                          "`$(one_target)`, which is not a class of the canonical " *
                          "Classification_SINDBAD (known classes: $(canonical_names)). " *
                          "Add it there, or fix the crosswalk in $(nameof(T)).")
                end
            end
        end
    end
    return nothing
end

"""
    validateVegTypeCoverage()

For every `VegClassification` subtype meant to serve as a *target* classification
(`Classification_SINDBAD` itself, and any one-to-many grouping catalog such as
`Classification_PlantForm`, identified by having at least one tuple crosswalk
target), check that every canonical class is covered by at least one of that
catalog's own classes, via `resolveVegClassification`, erroring immediately if not.

Not checked for the one-to-one source legends (`Classification_MODIS_*`): those are
legitimately coarser or narrower than the canonical vocabulary and are only ever
used as the raw-code *source* half of `resolveVegType`, never as its target.

The reverse of `validateVegTypeCrosswalks`: that catches a crosswalk target that
does not exist; this catches a canonical class no target classification reaches.
"""
function validateVegTypeCoverage()
    canonical_names = first.(first.(vegClasses(Classification_SINDBAD)))
    for T in subtypes(VegClassification)
        is_target_classification = T === Classification_SINDBAD ||
            any(canonical_target isa Tuple for (_, canonical_target) in vegClasses(T))
        is_target_classification || continue
        for canonical in canonical_names
            try
                resolveVegClassification(T, canonical)
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
