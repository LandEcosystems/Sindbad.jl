"""
    Experiment

The `Experiment` module provides tools for designing, running, and analyzing experiments in the SINDBAD framework. It integrates SINDBAD modules and utilities to streamline the experimental workflow, from data preparation to model execution and output analysis.

# Purpose
High-level interface for conducting experiments using the SINDBAD framework (workflow orchestration + output handling).

# Dependencies
## Related (SINDBAD ecosystem)
- `OmniTools`: Shared utilities.
- `ErrorMetrics`: Metric implementations used in cost/diagnostics.

## Internal (within `Sindbad`)
- `Sindbad.DataLoaders`
- `Sindbad.ParameterOptimization`
- `Sindbad.Setup`
- `Sindbad.Simulation`
- `Sindbad.Visualization`
- `SindbadTEM`

# Included Files
- **`runExperiment.jl`**: Experiment execution and orchestration.
- **`saveOutput.jl`**: Utilities for saving experiment outputs in supported formats.

# Notes
- Designed to be extensible, enabling users to customize and expand the experimental workflow that combines different SINDBAD modules as needed.

# Examples
```jldoctest
julia> using Sindbad

julia> # Run a forward experiment from a configuration file
julia> # out = runExperimentForward("path/to/experiment_config.json")

julia> # Prepare experiment configuration and forcing
julia> # info, forcing = prepExperiment("path/to/experiment_config.json")

julia> # Run experiment with different modes
julia> # result = runExperiment(info, forcing, DoRunForward())
```
"""
module Experiment
    using SindbadTEM.OmniTools
    using ErrorMetrics
    using ...SindbadTEM
    using ..Types
    using ..Setup
    using ..DataLoaders
    using ..Simulation
    using ..ParameterOptimization
    using ..Visualization

    include("runExperiment.jl")
    include("saveOutput.jl")

end # module Experiment