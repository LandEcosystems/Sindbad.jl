"""
`SindbadTEM.TEMTypes`

Submodule that groups all core TEM type definitions and shared abstract types
used across the terrestrial ecosystem model (TEM) implementation, including
`SindbadTypes`, and `LandEcosystem`.

This module is the primary entry point for **type-level** building blocks of
SINDBAD TEM processes and models.
"""
module TEMTypes
    using ..SindbadTEM
    import ..SindbadTEM: purpose

    export SindbadTypes
    abstract type SindbadTypes end
    purpose(::Type{SindbadTypes}) = "Abstract type for all Julia types in SINDBAD models, frameworks and modules that are re-exported by Sindbad"

    # ------------------------- land ecosystem type ------------------------------------------------------------
    export LandEcosystem
    abstract type LandEcosystem <: SindbadTypes end

    purpose(T::Type{LandEcosystem}) = nameof(T) == :LandEcosystem ? "Abstract type for all SINDBAD land ecosystem models/approaches" : "Purpose of a SINDBAD land ecosystem model/approach. Add `purpose(::Type{$(nameof(T))}) = \"the_purpose\"` in `$(nameof(T)).jl` file to define the specific purpose of the model/approach"

    function purpose(T::Type{<:LandEcosystem}) 
        foreach(subtypes(T)) do subtype
            subsubtype = subtypes(subtype)
            if isempty(subsubtype)
                purpose(subtype)    
            else
                purpose.(subsubtype)
            end
        end
    end

    purpose(T::LandEcosystem) = purpose(typeof(T))

    # ------------------------- carbon pool configuration traits -----------------------------------------------
    # Declared here, one level above Processes, for the same reason `purpose` is declared above
    # SindbadTEM: `Sindbad.Setup` reaches them unqualified through `using SindbadTEM`, while the
    # configuration types themselves stay inside `Processes`. Setup never names a configuration
    # type; it gets one back from `poolConfiguration` and hands it straight to the other two.
    export poolAliases
    export poolConfiguration
    export poolStructure

    """
        poolConfiguration(T)

    Return the pool configuration a model approach is written against, or `nothing` if it
    declares none.

    An approach declares one beside its `purpose`, e.g.
    `poolConfiguration(::Type{cCycleBase_GSI}) = CarbonPoolsGSI`. The returned configuration is
    a type, passed back to `poolStructure` and `poolAliases` to obtain the pool structure and
    the alias map.
    """
    function poolConfiguration end
    poolConfiguration(::Type{<:LandEcosystem}) = nothing
    poolConfiguration(T::LandEcosystem) = poolConfiguration(typeof(T))

    """
        poolStructure(configuration)

    Return the pool structure a configuration declares, shaped exactly like the `pools` block of
    a model structure JSON (`combine` plus nested `components`), or `nothing` if none.

    Nesting carries the grouping: every level becomes a pool with its own `zix` entry, so
    declaring `cVeg.Root.{Fine,Coarse}` yields `cVegRoot` alongside `cVegRootFine` and `cVegRootCoarse`.
    """
    function poolStructure end
    poolStructure(configuration) = nothing

    """
        poolAliases(configuration)

    Return extra `zix` names a configuration wants that its nesting cannot produce, as
    `alias => (pool names it spans)`.

    Only for groupings that genuinely cut across the hierarchy. CASA needs two, because its
    litter is nested by organ while the fast/slow axis is quality; GSI and MGMT need none.
    """
    function poolAliases end
    poolAliases(configuration) = (;)

    # ------------------------- vegetation-type catalog traits ------------------------------------------------
    # Declared here for the same reason `poolConfiguration` is: `Sindbad.Setup` reaches them
    # unqualified through `using SindbadTEM`, while the catalog types themselves stay inside
    # Processes. Only `vegClassMap` approaches declare these two traits -- `vegDynamics`
    # approaches obtain a raw code (from forcing or a constant) without ever naming a
    # catalog. A `vegClassMap` approach never names a catalog directly in its `precompute`;
    # it gets both back from these two traits and hands them to `resolveVegType`.
    export vegTypeCatalog
    export vegTypeClassification

    """
        vegTypeCatalog(T)

    Return the source catalog a `vegClassMap` approach interprets `land.states.veg_type`
    (set upstream by `vegDynamics`) against, or `nothing` if it declares none.

    An approach declares one beside its `purpose`, e.g.
    `vegTypeCatalog(::Type{vegClassMap_MODIS_IGBP}) = VegTypeCatalog_MODIS_IGBP`. The
    returned catalog is a type, passed to `resolveVegType` to resolve a raw code to a
    canonical name.
    """
    function vegTypeCatalog end
    vegTypeCatalog(::Type{<:LandEcosystem}) = nothing
    vegTypeCatalog(T::LandEcosystem) = vegTypeCatalog(typeof(T))

    """
        vegTypeClassification(T)

    Return the target classification a `vegClassMap` approach crosswalks its resolved
    canonical name into, or `nothing` if it declares none, in which case
    `resolvedVegTypeClassification` (in `vegClassMap.jl`) resolves that to the canonical
    vocabulary itself, `VegTypeCatalog_SINDBAD` -- i.e. no grouping.

    An approach declares one beside its `purpose`, e.g.
    `vegTypeClassification(::Type{vegClassMap_MODIS_IGBP_PlantForm}) =
    VegTypeCatalog_PlantForm`. The returned classification is a type, passed to
    `resolveVegType`/`vegTypeClassOf` to resolve a canonical name into that
    classification's own class name.
    """
    function vegTypeClassification end
    vegTypeClassification(::Type{<:LandEcosystem}) = nothing
    vegTypeClassification(T::LandEcosystem) = vegTypeClassification(typeof(T))

    # ------------------------- model error handling type ------------------------------------------------------------
    export DoCatchModelErrors
    export DoNotCatchModelErrors
    export DoDebugModel
    export DoNotDebugModel
    export DoInlineUpdate
    export DoNotInlineUpdate


    """
        DoCatchModelErrors

    Dispatch type to **enable error catching** during model execution.
    """
    struct DoCatchModelErrors <: SindbadTypes end
    purpose(::Type{DoCatchModelErrors}) = "Enable error catching during model execution"

    """
        DoNotCatchModelErrors

    Dispatch type to **disable error catching** during model execution.
    """
    struct DoNotCatchModelErrors <: SindbadTypes end
    purpose(::Type{DoNotCatchModelErrors}) = "Disable error catching during model execution"

    """
        DoDebugModel

    Dispatch type to **enable debug mode** for model execution.

    Used by higher-level orchestration code (e.g. `computeTEM`) to select
    debug-oriented execution paths (extra printing, timing, etc.).
    """
    struct DoDebugModel <: SindbadTypes end
    purpose(::Type{DoDebugModel}) = "Enable model debugging mode"

    """
        DoNotDebugModel

    Dispatch type to **disable debug mode** for model execution.
    """
    struct DoNotDebugModel <: SindbadTypes end
    purpose(::Type{DoNotDebugModel}) = "Disable model debugging mode"

    """
        DoInlineUpdate

    Dispatch type to **enable inline updates** of model state (within a single time step).
    """
    struct DoInlineUpdate <: SindbadTypes end
    purpose(::Type{DoInlineUpdate}) = "Enable inline updates of model state"

    """
        DoNotInlineUpdate

    Dispatch type to **disable inline updates** of model state.
    """
    struct DoNotInlineUpdate <: SindbadTypes end
    purpose(::Type{DoNotInlineUpdate}) = "Disable inline updates of model state"

end  # module TEMTypes
