
"""
   Setup

The `Setup` module provides tools for setting up and configuring SINDBAD experiments and runs. It handles the creation of experiment configurations, model structures, parameters, and output setups, ensuring a streamlined workflow for SINDBAD simulations.

# Purpose
This module is designed to produce the SINDBAD `info` object, which contains all the necessary configurations and metadata for running SINDBAD experiments. It facilitates reading configurations, building model structures, and preparing outputs.

# Dependencies
## Related (SINDBAD ecosystem)
- `ErrorMetrics`: Metric type construction for cost options.
- `TimeSamplers`: Temporal setup helpers.
- `OmniTools`: Shared utilities (e.g. `Table`).

## External (third-party)
- `CSV`, `JLD2`, `JSON`: Configuration and persistence tooling.
- `ConstructionBase`, `Dates`, `NaNStatistics`: Core utilities used during setup.
- `Infiltrator`: Optional interactive debugging (reexported for convenience).

## Internal (within `Sindbad`)
- `Sindbad.Types`
- `SindbadTEM`

# Included Files
- **`defaultOptions.jl`**: Default configuration knobs for optimization, sensitivity, and machine-learning routines referenced during setup.
- **`utilsSetup.jl`**: Shared setup helpers (validation, convenience utilities).
- **`generateCode.jl`**: Code-generation helpers used by development workflows.
- **`getConfiguration.jl`**: Read JSON/CSV configuration and normalize into internal settings representation.
- **`setupSimulationInfo.jl`**: Build the simulation `info` NamedTuple that downstream modules consume.
- **`setupTypes.jl`**: Instantiate SINDBAD types after parsing settings (time, land, metrics, optimization, etc.).
- **`setupPools.jl`**: Initialize land pools and state variables based on model structure/helpers/constants.
- **`updateParameters.jl`**: Apply metric feedback to parameter values (e.g., during optimization iterations).
- **`setupParameters.jl`**: Load parameter metadata (bounds/timescales/priors) and prepare arrays used by optimization/ML.
- **`setupModels.jl`**: Validate/order selected processes, wiring approaches to the overall run sequence.
- **`setupOutput.jl`**: Configure diagnostic/output arrays, filenames, and write schedules.
- **`setupParameterOptimization.jl`**: Collect optimizer-specific settings (algorithm, stopping criteria, restarts, etc.).
- **`setupHybridMachineLearning.jl`**: Hybrid ML configuration (fold definitions, feature sets, surrogate wiring).
- **`setupInfo.jl`**: Final assembly step integrating all previous pieces into the `info` object exported to simulations.

# Notes
- The package re-exports several key packages (`Infiltrator`, `CSV`, `JLD2`) for convenience, allowing users to access their functionality directly through `Setup`.
- Designed to be modular and extensible, enabling users to customize and expand the setup process for specific use cases.

"""
module Setup

   using SindbadTEM
   @reexport using OmniTools.ForCollections: Table
   using OmniTools.ForString: normalize_path_separator
   using TimeSamplers
   using ErrorMetrics
   using ..Types
   using ConstructionBase
   using Dates
   using NaNStatistics
   @reexport using CSV: CSV
   @reexport using Infiltrator
   using JSON: parsefile, json, print as json_print
   @reexport using JLD2: @save, load

   include("defaultOptions.jl")
   include("utilsSetup.jl")
   include("generateCode.jl")
   include("getConfiguration.jl")
   include("setupSimulationInfo.jl")
   include("setupTypes.jl")
   include("setupPools.jl")
   include("updateParameters.jl")
   include("setupParameters.jl")
   include("setupModels.jl")
   include("setupOutput.jl")
   include("setupParameterOptimization.jl")
   include("setupHybridMachineLearning.jl")
   include("setupInfo.jl")

end # module Setup
