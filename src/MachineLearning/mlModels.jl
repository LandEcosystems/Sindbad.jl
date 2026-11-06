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

"""
    denseNN(in_dim::Int, n_neurons::Int, out_dim::Int; extra_hlayers=0, activation_hidden=Flux.relu, activation_out=Flux.sigmoid, seed=1618)

Builds a dense feed-forward neural network with `in_dim` inputs, hidden layers of
`n_neurons` and `out_dim` outputs.

# Notes
- Implemented in `SindbadFluxExt` and available after `using Flux`. Without it, this
  method raises an error.
"""
function denseNN(args...; kwargs...)
    error("`denseNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end

"""
    destructureNN(model; nn_opt=Optimisers.Adam())

Flattens the parameters of a neural network `model` into one vector and returns them
with the function that rebuilds the model and the optimizer state for `nn_opt`.

# Notes
- Implemented in `SindbadFluxExt` and available after `using Flux`. Without it, this
  method raises an error.
"""
function destructureNN(args...; kwargs...)
    error("`destructureNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end

"""
    JoinDenseNN(models::Tuple)

Combines several neural networks into one model that runs each on its own input and
concatenates their outputs.

# Notes
- Implemented in `SindbadFluxExt` and available after `using Flux`. Without it, this
  method raises an error.
"""
function JoinDenseNN(args...; kwargs...)
    error("`JoinDenseNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end

"""
    SplitNN(args...; kwargs...)

Placeholder for a neural network that splits its input between sub-networks.

# Notes
- Not implemented for any backend yet, so it always raises an error. A draft is
  commented out in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl`.
"""
function SplitNN(args...; kwargs...)
    error("`SplitNN` is not implemented for any backend yet. To implement it, add a method in `ext/<extension_name>/MachineLearningNeuralNetwork.jl` (see the commented-out draft in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl`).")
end