export activationFunction

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

function activationFunction(_, ::FluxRelu)
    return Flux.relu
end
function activationFunction(_, ::FluxTanh)
    return Flux.tanh
end
function activationFunction(_, ::FluxSigmoid)
    return Flux.sigmoid
end

function activationFunction(model_options, ::CustomSigmoid)
    sigmoid_k(x, K) = one(x) / (one(x) + exp(-K * x))
    custom_sigmoid = x -> sigmoid_k(x, model_options.k_σ)
    return custom_sigmoid
end
