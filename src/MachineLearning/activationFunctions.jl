export activationFunction

using Sindbad: CustomSigmoid

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
function activationFunction(model_options, x::ActivationType)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    activationFunction `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This activation function is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    activationFunction `$(nameof(typeof(x)))` not implemented.

    To implement a new activation function:

    - First add a new type as a subtype of `ActivationType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/activationFunctions.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningActivationFunctions.jl` extension.

    ")
    end
    return
end


function activationFunction(model_options, ::CustomSigmoid)
    sigmoid_k(x, K) = one(x) / (one(x) + exp(-K * x))
    custom_sigmoid = x -> sigmoid_k(x, model_options.k_σ)
    return custom_sigmoid
end