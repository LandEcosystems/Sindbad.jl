"""
    Sindbad

Top-level orchestration package for **S**trategies to **IN**tegrate
**D**ata and **B**iogeochemic**A**l mo**D**els. `Sindbad` reexports the
complete `SindbadTEM` modeling stack and combines the user-facing
modules under `src/` to offer a single public entry point for data
ingest, configuration, simulation, optimization, machine learning,
and visualization workflows.

# Purpose:
- Provide a cohesive API that ties together process-level models from
  `SindbadTEM` with higher-level experiment tooling.
- Ensure every stage of a SINDBAD pipeline—data handling, setup, model
  execution, calibration, post-processing, and plotting—is available
  through one package.

# Dependencies:
## Related (SINDBAD ecosystem)
- `ErrorMetrics`: Model–observation metrics used across cost/diagnostics.
- `TimeSamplers`: Temporal sampling/aggregation helpers.
- `OmniTools`: Shared utilities used across modules.

## External (third-party)
- `CSV`: Input/output of tabular forcing and calibration datasets.
- `ConstructionBase`: Shared constructors needed by downstream modules.
- `JSON`: Experiment metadata serialization (`parsefile`, `json`, `print`).
- `JLD2`: Persisting SINDBAD state, diagnostics, and trained artifacts.
- `YAXArrays` + `YAXArrays.Datasets`: Labeled n-dimensional arrays and dataset writers for model output.

## Internal (within `Sindbad`)
- `Sindbad.DataLoaders`
- `Sindbad.Experiment`
- `Sindbad.MachineLearning`
- `Sindbad.ParameterOptimization`
- `Sindbad.Setup`
- `Sindbad.Simulation`
- `Sindbad.Types`
- `Sindbad.Visualization`
- `SindbadTEM`

# Included Modules:
- **DataLoaders** (`src/DataLoaders/`):
  - Handles file IO, preprocessing, and conversion into SINDBAD-native
    data structures; exposes reusable loaders and utility helpers.
- **Setup** (`src/Setup/`):
  - Builds experiment `info` objects, validates model selections, and
    wires pools, spinup settings, and derived configuration metadata.
- **Simulation** (`src/Simulation/`):
  - Orchestrates terrestrial ecosystem simulations, including spinup,
    forward runs, diagnostics, and interaction with `SindbadTEM`.
- **ParameterOptimization** (`src/ParameterOptimization/`):
  - Provides parameter-calibration utilities and objective hooks.
  - Some optimizer backends are enabled via optional extensions (see Notes).
- **MachineLearning** (`src/MachineLearning/`):
  - Adds ML-assisted surrogates, emulators, and training pipelines that
    integrate with Sindbad outputs and optimization targets.
- **Visualization** (`src/Visualization/`):
  - Supplies plotting and reporting helpers for experiment evaluation
    (time series, spatial maps, diagnostic overlays, etc.).
- **Experiment** (`src/Experiment/`):
  - High-level experiment runner and output persistence helpers that tie together setup, loaders, simulation, optimization, ML, and visualization.

# Notes:
- Each submodule is included and reexported so end users can call
  `using Sindbad` and immediately access `Sindbad.DataLoaders`,
  `Sindbad.Simulation`, and the rest without extra imports.
- Shared dependencies are loaded here to guarantee consistent versions
  across all components.
- Some functionality is enabled via Julia extensions (`Project.toml` `[weakdeps]` + `[extensions]` and `ext/`):
  - `NLsolve` → `SindbadNLsolveExt`
  - `Optimization` → `SindbadOptimizationExt`
  - `CMAEvolutionStrategy` → `SindbadCMAEvolutionStrategyExt`

# Examples:
```jldoctest
julia> using Sindbad

julia> # Prepare an experiment from a configuration file
julia> # info, forcing = prepExperiment("path/to/experiment_config.json")

julia> # Run a forward simulation
julia> # out = runExperimentForward("path/to/experiment_config.json")
```
"""
module Sindbad
  using SindbadTEM
  using SindbadTEM.Reexport: @reexport
  @reexport using SindbadTEM
  @reexport using SindbadTEM.StatsBase
  @reexport using NaNStatistics
  @reexport using TimeSamplers
  @reexport using ErrorMetrics

  include("Types/Types.jl")
  @reexport using .Types
  include("Setup/Setup.jl")
  @reexport using .Setup
  include("DataLoaders/DataLoaders.jl")
  @reexport using .DataLoaders
  include("Visualization/Visualization.jl")
  @reexport using .Visualization
  include("Simulation/Simulation.jl")
  @reexport using .Simulation
  include("ParameterOptimization/ParameterOptimization.jl")
  @reexport using .ParameterOptimization
  include("MachineLearning/MachineLearning.jl")
  @reexport using .MachineLearning
  include("Experiment/Experiment.jl")
  @reexport using .Experiment
  # include("writeDocStringForTypes.jl")
  # include("Types/docStringForTypes.jl")
  include("Visualization/Processes.jl")

  export addExtensionToSindbad
  """
  addExtensionToSindbad(function_to_extend::Function, external_package::String) -> String

  Convenience wrapper for this repo: asserts the function belongs to `Sindbad` and always uses folder layout.
  """
  function addExtensionToSindbad(function_to_extend::Function, external_package::String)
    root_pkg = Base.moduleroot(parentmodule(function_to_extend))
    nameof(root_pkg) == :Sindbad || error("Expected a Sindbad function; got root package $(root_pkg).")
    return add_extension_to_function(function_to_extend, external_package; extension_location=:Folder)
  end
end # module Sindbad
