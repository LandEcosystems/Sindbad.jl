export activationFunction
export mlModel

"""
    activationFunction(model_options, act::AbstractActivation)

Return the activation function corresponding to the specified activation type and model options.

This function dispatches on the activation type to provide the appropriate activation function for use in neural network layers. For custom activation types, relevant parameters can be passed via `model_options`.

# Arguments
- `model_options`: A struct or NamedTuple containing model options, including parameters for custom activation functions (e.g., `k_σ` for `CustomSigmoid`).
- `act`: An activation type specifying the desired activation function. Supported types include:
    - `FluxRelu`: Rectified Linear Unit (ReLU) activation.
    - `FluxTanh`: Hyperbolic Tangent (tanh) activation.
    - `FluxSigmoid`: Sigmoid activation.
    - `CustomSigmoid`: Custom sigmoid activation with steepness parameter `k_σ`.

# Returns
- A callable activation function suitable for use in neural network layers.

# Example
```julia
act_fn = activationFunction(model_options, FluxRelu())
y = act_fn(x)
```
"""
function activationFunction end

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
function mlModel end

function denseNN end
function destructureNN end
function JoinDenseNN end
function SplitNN end