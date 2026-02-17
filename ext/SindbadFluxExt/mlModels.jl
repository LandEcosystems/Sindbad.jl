
export mlModel

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

function mlModel(info, n_features, ::FluxDenseNN)
    n_params = sum(info.optimization.parameter_table.is_ml);
    n_layers = info.hybrid.ml_model.options.n_layers
    n_neurons = info.hybrid.ml_model.options.n_neurons
    ml_seed = info.hybrid.random_seed;
    print_info(mlModel, @__FILE__, @__LINE__, "Flux Dense NN with $n_features features, $n_params parameters, $n_layers hidden/inner layers and $n_neurons neurons.", n_f=2)

    print_info(nothing, @__FILE__, @__LINE__, "Seed: $ml_seed", n_f=4)
    print_info(nothing, @__FILE__, @__LINE__, "Hidden Layers: $(n_layers)", n_f=4)
    print_info(nothing, @__FILE__, @__LINE__, "Total number of parameters: $(sum(info.optimization.parameter_table.is_ml))", n_f=4)
    print_info(nothing, @__FILE__, @__LINE__, "Number of neurons per layer: $(n_neurons)", n_f=4)
    print_info(nothing, @__FILE__, @__LINE__, "Number of parameters per layer: $(n_params / n_layers)", n_f=4)
    activation_hidden = activationFunction(info.hybrid.ml_model.options, info.hybrid.ml_model.options.activation_hidden)
    activation_out = activationFunction(info.hybrid.ml_model.options, info.hybrid.ml_model.options.activation_out)
    print_info(nothing, @__FILE__, @__LINE__, "Activation function for hidden layers: $(info.hybrid.ml_model.options.activation_hidden)", n_f=4)
    print_info(nothing, @__FILE__, @__LINE__, "Activation function for output layer: $(info.hybrid.ml_model.options.activation_out)", n_f=4)
    Random.seed!(ml_seed)
    flux_model = Flux.Chain(
        Flux.Dense(n_features => n_neurons, activation_hidden),
        [Flux.Dense(n_neurons, n_neurons, activation_hidden) for _ in 1:n_layers]...,
        Flux.Dense(n_neurons => n_params, activation_out)
        )
    return flux_model
end
