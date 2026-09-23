"""
    SindbadCMAEvolutionStrategyExt

Julia extension module that enables CMAEvolutionStrategy backends for `Sindbad.ParameterOptimization`.

# Notes:
- This module is loaded automatically by Julia's package extension mechanism when CMAEvolutionStrategy is available (see root `Project.toml` `[weakdeps]` + `[extensions]`).
- End users typically should not `using SindbadCMAEvolutionStrategyExt` directly; instead `using Sindbad` is sufficient once the weak dependency is installed.
- The extension code is included in the `ext/` directory and is automatically loaded when the extension package is installed.

Modify the code in the "ParameterOptimizationOptimizer.jl" file to extend the package.
"""
module SindbadCMAEvolutionStrategyExt

    using CMAEvolutionStrategy
    using Dates: now
    
    include("ParameterOptimizationOptimizer.jl")

end

