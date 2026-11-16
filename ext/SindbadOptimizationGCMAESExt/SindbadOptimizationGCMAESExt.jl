"""
    SindbadOptimizationGCMAESExt

Julia extension module that enables the GCMAES backend (`GCMAESOpt`) of Optimization.jl for
`Sindbad.ParameterOptimization`.

- Since Optimization.jl v4 the solver wrappers live in separate sub-packages; `GCMAESOpt` is
  provided by `OptimizationGCMAES`, not by `Optimization` itself.
- Loaded automatically once both `Optimization` and `OptimizationGCMAES` are loaded
  (see root `Project.toml` `[weakdeps]` + `[extensions]`), i.e. `using Optimization, OptimizationGCMAES`.
"""
module SindbadOptimizationGCMAESExt
    using Optimization
    using OptimizationGCMAES
    using FiniteDiff
    include("ParameterOptimizationOptimizer.jl")
end
