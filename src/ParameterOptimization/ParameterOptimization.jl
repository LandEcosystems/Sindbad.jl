"""
    ParameterOptimization

The `ParameterOptimization` module provides tools for optimizing SINDBAD models, including parameter estimation, model calibration, and cost function evaluation. It integrates various optimization algorithms and utilities to streamline the optimization workflow for SINDBAD experiments.

# Purpose
This module is designed to support optimization tasks in SINDBAD, such as calibrating model parameters to match observations or minimizing cost functions. It leverages multiple optimization libraries and provides a unified interface for running optimization routines.

# Dependencies
## Related (SINDBAD ecosystem)
- `ErrorMetrics`: Metric implementations for cost evaluation.
- `TimeSamplers`: Temporal helpers used by some workflows.
- `OmniTools`: Shared helpers and table utilities.

## External (third-party)
- `StableRNGs`: Reproducible random number generation for stochastic workflows.

## Internal (within `Sindbad`)
- `Sindbad.Setup`
- `Sindbad.Simulation`
- `Sindbad.Types`
- `SindbadTEM`

## Optional dependencies (extensions / weakdeps)
Some optimizer backends are enabled via Julia extensions (see root `Project.toml` and `ext/`):
- `CMAEvolutionStrategy` → `SindbadCMAEvolutionStrategyExt`
- `Optimization` → `SindbadOptimizationExt`

Other packages listed under `[weakdeps]` may be used by experimental workflows but are not required for the base module to load.

# Included Files
- **`getCost.jl`**: Cost extraction and convenience wrappers.
- **`optimizer.jl`**: Core optimization logic (algorithm selection + option normalization).
- **`cost.jl`**: Cost functions for evaluating model–observation mismatch.
- **`prepOpti.jl`**: Prepares inputs and bookkeeping for optimization runs.
- **`optimizeTEM.jl`**: Optimization routines for single sites and spatial workflows.
- **`sensitivityAnalysis.jl`**: Sensitivity analysis utilities.

!!! note
    - The package integrates multiple optimization libraries, allowing users to choose the most suitable algorithm for their problem.
    - Designed to be modular and extensible, enabling users to customize optimization workflows for specific use cases.
    - Supports both gradient-based and derivative-free optimization methods, ensuring flexibility for different types of cost functions.

# Examples
```jldoctest
julia> using Sindbad

julia> # Run parameter optimization from a configuration file
julia> # result = runExperimentOpti("path/to/experiment_config.json")

julia> # Calculate cost between model output and observations
julia> # cost_result = runExperimentCost("path/to/experiment_config.json")
```
"""
module ParameterOptimization
   using StableRNGs
   using ErrorMetrics
   using TimeSamplers
   using SindbadTEM
   using SindbadTEM.OmniTools
   using ..Types
   using ..Setup
   using ..DataLoaders
   using ..Simulation

   include("getCost.jl")
   include("optimizer.jl")
   include("cost.jl")
   include("prepOpti.jl")
   include("optimizeTEM.jl")
   include("sensitivityAnalysis.jl")

end # module ParameterOptimization
