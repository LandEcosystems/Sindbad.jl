"""
    Simulation

The `Simulation` module provides the core functionality for running the SINDBAD Terrestrial Ecosystem Model (TEM). It includes utilities for preparing model-ready objects, managing spinup processes and running models.

# Purpose
This module integrates various components and utilities required to execute the SINDBAD TEM, including precomputations, spinup, and time loop simulations. It supports parallel execution and efficient handling of large datasets.

# Dependencies
## Related (SINDBAD ecosystem)
- `TimeSamplers`: Temporal helpers used in time-loop workflows.
- `OmniTools`: Shared utilities used during simulation and output handling.

## External (third-party)
- `ComponentArrays`: Hierarchical state/parameter containers.
- `ProgressMeter`: Progress bars for long-running simulations.
- `ThreadPools`: Threaded parallelism helpers.

## Internal (within `Sindbad`)
- `Sindbad.DataLoaders`
- `Sindbad.Setup`
- `Sindbad.Types`
- `SindbadTEM`

# Included Files
- **`utilsSimulation.jl`**: Core helpers for forcing slices, output handling, progress/logging, and simulation orchestration.
- **`deriveSpinupForcing.jl`**: Derive spinup forcing data for steady-state initialization.
- **`prepTEMOut.jl`**: Prepare output containers/structures for efficient writing.
- **`prepTEM.jl`**: Prepare model-ready inputs and configuration for runs.
- **`runTEMForLocation.jl`**: Run the TEM for a single location (optional spinup + main loop).
- **`runTEMInSpace.jl`**: Run the TEM across spatial grids (parallel execution).
- **`utilsCube.jl`**: Helpers of lazy runs on `YAXArrays` cubes: the wrapper that hides cube types, the cache and block sizing, and the zarr store helpers.
- **`prepTEMOnCube.jl`**: Build the lazy run of the TEM on `YAXArrays` cubes with `xmap` (`prepTEMYax`).
- **`runTEMOnCube.jl`**: Run the lazy run block by block into a zarr store (`runTEMYax`), and the TEM of each grid in it (`TEMYax`).
- **`spinupTEM.jl`**: Spinup routines to initialize the model to steady state.
- **`spinupSequence.jl`**: Sequential spinup loops for iterative refinement.

# Notes
- The package is designed to be modular and extensible, allowing users to customize and extend its functionality for specific use cases.
- It integrates tightly with the SINDBAD framework, leveraging shared types and utilities from `Setup`.
- Some spinup solvers are enabled via an optional extension:
  - `NLsolve` → `SindbadNLsolveExt` (see `ext/SindbadNLsolveExt/`).
"""
module Simulation
   using ComponentArrays
   using Dates
   using ProgressMeter
   using SindbadTEM
   using TimeSamplers
   using ..Types
   using SindbadTEM.OmniTools
   using ..Setup
   using ..DataLoaders: YAXArrays
   using ..DataLoaders: AllNaN, cleanData, getForcingVariableInfo
   using ThreadPools
   using YAXArrays
   using DimensionalData: DimensionalData as DD
   using JSON: parsefile
   using FillArrays: Fill

   const DiskArrays = YAXArrays.Cubes.DiskArrays
   const DAE = YAXArrays.Xmap.DAE

   include("utilsSimulation.jl")
   include("deriveSpinupForcing.jl")
   include("prepTEMOut.jl")
   include("prepTEM.jl")
   include("runTEMForLocation.jl")
   include("runTEMInSpace.jl")
   include("utilsCube.jl")
   include("prepTEMOnCube.jl")
   include("runTEMOnCube.jl")
   include("spinupTEM.jl")
   include("spinupSequence.jl")

end # module Simulation
