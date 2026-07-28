export mlModel
export denseNN
export destructureNN
export JoinDenseNN
export SplitNN

"""
    mlModel(info, n_features, ::MachineLearningModelType)
Builds a Flux dense neural network model.
This function initializes a neural network model based on the provided `info` and `n_features`.

# Arguments
- `info`: The experiment information containing model options and parameters.
- `n_features`: The number of features in the input data.
- `::MachineLearningModelType`: Type dispatch for the machine learning model type.

# Supported MachineLearningModelType:
- `::FluxDenseNN`: A simple dense neural network model implemented in Flux.jl.

# Returns
The initialized machine learning model.
"""
function mlModel(info, n_features, x::MachineLearningModelType)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    mlModel `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This model is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    mlModel `$(nameof(typeof(x)))` not implemented.

    To implement a new ML model:

    - First add a new type as a subtype of `MachineLearningModelType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlModels.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningMLModels.jl` extension.

    ")
    end
    return
end

function denseNN(args...; kwargs...)
    error("`denseNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end

function destructureNN(args...; kwargs...)
    error("`destructureNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end

function JoinDenseNN(args...; kwargs...)
    error("`JoinDenseNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end

function SplitNN(args...; kwargs...)
    error("`SplitNN` is not implemented for any backend yet. To implement it, add a method in `ext/<extension_name>/MachineLearningNeuralNetwork.jl` (see the commented-out draft in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl`).")
end