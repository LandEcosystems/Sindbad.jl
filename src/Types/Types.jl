"""
    Types

The `Types` module consolidates and organizes all the types used in the SINDBAD framework into a central location. This ensures a single source for type definitions, promoting consistency and reusability across all SINDBAD packages. It also provides helper functions and utilities for working with these types.

# Purpose
This module serves as the backbone for type definitions in SINDBAD, ensuring modularity and extensibility. It provides a unified hierarchy for SINDBAD-specific types and includes utilities for introspection, type manipulation, and documentation.

# Dependencies
## External (third-party)
- `InteractiveUtils`: Interactive exploration and debugging helpers.
- `Base.Docs`: Documentation utilities for type introspection.

# Included Files
- **`LandTypes.jl`**: Types for land variables and land/array structures used during model execution.
- **`ArrayTypes.jl`**: Specialized array types for efficient data handling.
- **`InputTypes.jl`**: Types for input data/configuration (forcing/observation metadata and wiring).
- **`SimulationTypes.jl`**: Types representing simulation setup/configuration and results.
- **`ParameterOptimizationTypes.jl`**: Types for optimization workflows (algorithms, options, cost hooks).
- **`MachineLearningTypes.jl`**: Types supporting machine-learning workflows and data structures.

# Notes
- The `Types` module serves as the backbone for type definitions in SINDBAD, ensuring modularity and extensibility.
- Each type is documented with its purpose via the `purpose` function, making it easier for developers to understand and extend the framework.
- The `SindbadTypes` abstract type serves as the base for all Julia types in the SINDBAD framework.

# Examples
1. **Querying type purpose**:
```julia
using Sindbad.Types
purpose(BayesOptKMaternARD5)  # Returns the purpose string for the type
```

2. **Working with SINDBAD types**:
```julia
using Sindbad.Types
# All SINDBAD types are available through this module
```

"""
module Types
    import Sindbad: purpose
    using Sindbad: get_type_docstring, SindbadTypes
    using InteractiveUtils: subtypes
    using TimeSamplers

    export requires_package
    """
        requires_package(::Type{<:SindbadTypes})

    Name of the external package whose Sindbad extension (`ext/Sindbad<Package>Ext`) provides
    the real implementation for a given dispatch type, e.g. `requires_package(CMAEvolutionStrategyCMAES) == "CMAEvolutionStrategy"`.
    Returns `nothing` for types that need no external package (implemented directly in Sindbad,
    or not yet implemented for any backend). Used by generic dispatch-fallback methods (e.g.
    `optimizer`, `mlOptimizer`, `mlModel`, `activationFunction`, `getPullback`, `updateMLModel`)
    to tell users exactly which package to `using` when a selected backend type has no method
    loaded yet, instead of implying the method doesn't exist at all.
    """
    requires_package(::Type{<:SindbadTypes}) = nothing

    # Julia 1.10 compatibility:
    # `Base.Docs.hasdoc` is not available on all supported Julia versions, so we implement a
    # small helper that checks whether a *binding* has a docstring attached.
    _binding_hasdoc(mod::Module, sym::Symbol) = try
        haskey(Base.Docs.meta(mod), Base.Docs.Binding(mod, sym))
    catch
        false
    end

    _type_hasdoc(T::Type) = try
        Base.Docs.doc(T) !== nothing
    catch
        false
    end

    # ------------------------- SindbadTypes ------------------------------------------------------------
    include("LandTypes.jl")
    include("ArrayTypes.jl")
    include("InputTypes.jl")
    include("SimulationTypes.jl")
    include("ParameterOptimizationTypes.jl")
    include("MachineLearningTypes.jl")


    # append the docstring of the SindbadTypes type to the docstring of the Sindbad module so that all the methods of the SindbadTypes type are included after the models have been described
    @doc """
    $(get_type_docstring(SindbadTypes, purpose_function=purpose))
    """
    SindbadTypes

    # ------------------------------------------------------------------------------------
    # Docstrings for Types
    #
    # Documenter `@docs` blocks require actual Julia docstrings attached to objects.
    # Many Sindbad types only define `purpose(::Type{T}) = "..."`, which is great for
    # introspection but does not automatically create a docstring.
    #
    # Best practice: avoid generating/writing source files at first compile or at runtime.
    # Instead, attach deterministic in-memory docstrings derived from `purpose` /
    # `get_type_docstring` during module load. This keeps installs read-only friendly and
    # makes docs builds reproducible.
    # ------------------------------------------------------------------------------------
    function _attach_type_docstrings!(T::Type)
        for st in subtypes(T)
            # Only attach if missing to avoid stomping any hand-written docstrings.
            #
            # Important: Documenter `@docs Foo` looks up docs via module bindings.
            # Attaching docs to the object alone is not sufficient in many cases.
            #
            # Also: only attach for types whose binding lives in this module, to avoid
            # documenting imported/foreign types.
            if parentmodule(st) === @__MODULE__
                sym = Symbol(nameof(st))
                if isdefined(@__MODULE__, sym) && !_binding_hasdoc(@__MODULE__, sym) && !_type_hasdoc(st)
                    doc_txt = get_type_docstring(st, purpose_function=purpose)
                    # Use `@doc` so the stored doc is the usual Markdown-based form that
                    # Documenter expects, while still guarding with a Julia-1.10-safe
                    # "has docs?" check above.
                    @eval Base.Docs.@doc $doc_txt $sym
                end
            end
            _attach_type_docstrings!(st)
        end
        return nothing
    end

    _attach_type_docstrings!(SindbadTypes)
end