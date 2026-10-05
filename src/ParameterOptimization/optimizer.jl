export optimizer

"""
    optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, algorithm <: ParameterOptimizationMethod)

Optimize model parameters using various optimization algorithms.

# Arguments:
  - `cost_function`: A function handle that takes a parameter vector as input and calculates a cost/loss (scalar or vector).
  - `default_values`: A vector of default parameter values to initialize the optimization.
  - `lower_bounds`: A vector of lower bounds for the parameters.
  - `upper_bounds`: A vector of upper bounds for the parameters.
  - `algo_options`: A set of options specific to the chosen optimization algorithm.
  - `algorithm`: The optimization algorithm to be used.

# Returns:
- `optim_para`: A vector of optimized parameter values.

# algorithm:
    
    $(methods_of(ParameterOptimizationMethod))

---

# Extended help

# Notes:
- The function supports a wide range of optimization algorithms, each tailored for specific use cases.
- Some methods do not require bounds for optimization, while others do.
- The `cost_function` should be defined by the user to calculate the loss based on the model output and observations. It is defined in cost.jl.
- The `algo_options` argument allows fine-tuning of the optimization process for each algorithm.
- Some algorithms (e.g., `BayesOptKMaternARD5`, `OptimizationBBOxnes`) require additional configuration steps, such as setting kernels or merging default and user-defined options.

# Examples
```jldoctest
julia> using Sindbad

julia> # Optimize using CMA-ES algorithm
julia> # optim_para = optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, CMAEvolutionStrategyCMAES())

julia> # Optimize using BFGS algorithm
julia> # optim_para = optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, OptimBFGS())

julia> # Optimize using Black Box Optimization (xNES)
julia> # optim_para = optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, OptimizationBBOxnes())
```

# Implementation Details:
- The function internally calls the appropriate optimization library and algorithm based on the `algorithm` argument.
- Each algorithm has its own implementation details, such as handling bounds, configuring options, and solving the optimization problem.
- The results are processed to extract the optimized parameter vector (`optim_para`), which is returned to the user.
"""
function optimizer(::Any, default_values::Any, ::Any, ::Any, ::Any, x::ParameterOptimizationMethod)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    Optimizer `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This algorithm is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    Optimizer `$(nameof(typeof(x)))` not implemented.

    To implement a new optimizer:

    - First add a new type as a subtype of `ParameterOptimizationMethod` in `src/Types/ParameterOptimizationTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/ParameterOptimization/optimizer.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/ParameterOptimizationOptimizer.jl` extension.

    ")
    end
    return
end
