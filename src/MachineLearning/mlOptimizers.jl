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
function mlOptimizer end

