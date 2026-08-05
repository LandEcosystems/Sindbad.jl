"""
    SindbadTEM

A Julia package for the terrestrial ecosystem model (TEM) implementation within the **S**trategies to **IN**tegrate **D**ata and **B**iogeochemic**A**l mo**D**els (SINDBAD) framework.

The `SindbadTEM` package serves as the core of the SINDBAD framework, providing foundational types, utilities, and tools for building and managing SINDBAD models.

# Purpose
This module is the entry point for the SINDBAD TEM implementation. It pulls together:
- Core abstract types (notably `LandEcosystem`, defined in `TEMTypes`)
- Utilities for model inspection and tooling
- A canonical variable catalog for consistent metadata
- The process/approach hierarchy and default process ordering

# Dependencies
Key dependencies used/re-exported by the module include:
- `Reexport`: Re-export helpers (`@reexport`).
- `OmniTools`: Shared utilities and `purpose` integration.
- `CodeTracking`: Development/debug helpers.
- `DataStructures`: Collection types used across TEM utilities.
- `StaticArraysCore`: Fixed-size and sized array types for performance.
- `Accessors`: Nested update helpers (`@set`).
- `StatsBase`: Statistical helpers used across processes/utilities.
- `InteractiveUtils`, `Crayons`: Interactive/dev UX helpers.

# Included Files
- **`Types.jl`** (module `SindbadTEM.TEMTypes`): Core TEM types (including `LandEcosystem`) and shared type utilities.
- **`Utils.jl`** (module `SindbadTEM.Utils`): Utilities for model inspection/tooling (e.g. I/O parsing).
- **`Variables.jl`** (module `SindbadTEM.Variables`): Canonical catalog of SINDBAD TEM variables and metadata helpers.
- **`Processes.jl`** (module `SindbadTEM.Processes`): Process hierarchy, parameter metadata macros, model/approach docstring helpers, and dynamic inclusion of process implementations under `src/Processes/`.
- **`DevTools.jl`**: `test_model`/`analyse_tem`/`test_tem`, local dev-loop convenience functions for running approach checks/benchmarks (see their docstrings; `test_model`/`analyse_tem` additionally need `using Test`, provided by `ext/SindbadTEMTestExt.jl`).
- *(Internal)* `tmp_precompile_placeholder.jl`: Auto-managed placeholder to force precompilation when new processes/approaches are added.

# Notes
- The `LandEcosystem` supertype serves as the foundation for all SINDBAD TEM models/processes, enabling extensibility and modularity.
- The module re-exports key functionality from several dependencies (e.g., `StaticArraysCore`, `DataStructures`) to simplify downstream usage.
- Designed to be lightweight and modular, allowing seamless integration with other SINDBAD modules in the top src directory of the repository.

# Examples
```jldoctest
julia> using SindbadTEM

julia> # Define a new SINDBAD model
julia> struct MyProcess <: LandEcosystem
           # Define model-specific fields
       end

julia> # Query the variable catalog
julia> # catalog = getVariableCatalog()
```
"""
module SindbadTEM
   using Reexport: @reexport
   @reexport using OmniTools
   import OmniTools: purpose
   @reexport using Reexport
   @reexport using Pkg
   @reexport using CodeTracking
   @reexport using DataStructures: DataStructures
   @reexport using StaticArraysCore: StaticArray, SVector, MArray, SizedArray
   @reexport using Accessors: @set
   @reexport using StatsBase
   @reexport using InteractiveUtils
   @reexport using Crayons
   @reexport using Base.Docs: doc as base_doc

   # create a tmp_ file for tracking the creation of new approaches. This is needed because precompiler is not consistently loading the newly created approaches. This file is appended every time a new model/approach is created which forces precompile in the next use of SindbadTEM.
   #
   # NOTE: On registered/installed packages the package directory may be read-only.
   # We therefore only attempt to create the placeholder file if writing is permitted.
   file_path = joinpath(@__DIR__, "tmp_precompile_placeholder.jl")
   # Check if the file exists
      # Include the file if it exists
   if !isfile(file_path)
      # Create a blank file if it does not exist (only if the package dir is writable)
      try
         open(file_path, "w") do file
            # Optionally, you can write some initial content
            write(file, "# This is a blank file created by SindbadTEM module to keep track of newly added sindbad approaches/processes which automatically updates this file and then forces precompilation to include the new processes.\n")
         end
         @info "Created a blank file to track precompilation of new processes and approaches" file_path=file_path
      catch err
         # Ignore in read-only installs; the placeholder file should normally be shipped with the package.
         @debug "Could not create tmp_precompile_placeholder.jl (likely read-only install); skipping" file_path=file_path exception=(err, catch_backtrace())
      end
   end
   
   include(file_path)
   
   include("Types.jl")
   @reexport using .TEMTypes
   include("Utils.jl")
   @reexport using .Utils
   include("Variables.jl")
   @reexport using .Variables
   include("Processes.jl")
   @reexport using .Processes
   include("DevTools.jl")
   export test_model, analyse_tem, test_tem

   # append the docstring of the LandEcosystem type to the docstring of the SindbadTEM module so that all the methods of the LandEcosystem type are included after the models have been described
   @doc """
   LandEcosystem

   $(purpose(TEMTypes.LandEcosystem))

   # Methods
   All subtypes of `LandEcosystem` must implement at least one of the following methods:
   - `define`: Initialize arrays and variables
   - `precompute`: Update variables with new realizations
   - `compute`: Update model state in time
   - `update`: Update pools within a single time step


   # Examples
   ```jldoctest
   julia> using SindbadTEM

   julia> # Define a new model type
   julia> struct MyProcess <: LandEcosystem end

   julia> # Implement required methods
   julia> function define(params::MyProcess, forcing, land, helpers)
              # Initialize arrays and variables
              return land
          end

   julia> function precompute(params::MyProcess, forcing, land, helpers)
              # Update variables with new realizations
              return land
          end

   julia> function compute(params::MyProcess, forcing, land, helpers)
              # Update model state in time
              return land
          end

   julia> function update(params::MyProcess, forcing, land, helpers)
              # Update pools within a single time step
              return land
          end
   ```

   ---

   # Extended help
   $(methods_of(TEMTypes.LandEcosystem, purpose_function=purpose))
   """
   TEMTypes.LandEcosystem
   
end
