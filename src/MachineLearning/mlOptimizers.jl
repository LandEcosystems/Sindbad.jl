export mlOptimizer

"""
    mlOptimizer(optimizer_options, ::MachineLearningOptimizerType)

Create aMachine Learningoptimizer from the given options and type.
The optimizer is created using the given options and type. The options are passed to the constructor of the optimizer.

# Arguments:
- `optimizer_options`: A dictionary or NamedTuple containing options for the optimizer.
- `::MachineLearningOptimizerType`: The type used to determine which optimizer to create. Supported types include:
  - `OptimisersAdam`: For Adam optimizer.
  - `OptimisersDescent`: For Descent optimizer.
.
# Returns:
- AMachine Learningoptimizer object that can be used to optimize machine learning models.
"""
function mlOptimizer(optimizer_options, x::MachineLearningOptimizerType)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    mlOptimizer `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This optimizer is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    mlOptimizer `$(nameof(typeof(x)))` not implemented.

    To implement a new ML optimizer:

    - First add a new type as a subtype of `MachineLearningOptimizerType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlOptimizers.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningMlOptimizer.jl` extension.

    ")
    end
    return
end

