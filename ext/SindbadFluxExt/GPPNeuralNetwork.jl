import SindbadTEM.Processes: define, precompute, compute, @pack_nt, @unpack_nt
using SindbadTEM: gpp_neuralNetwork
using Flux
using JLD2

function define(params::gpp_neuralNetwork, forcing, land, helpers)
    opts = helpers.hybrid.process_ml_models.gpp.options
    n_features = length(opts.features)
    activation_hidden = activationFunction(opts, opts.activation_hidden)
    activation_out = activationFunction(opts, opts.activation_out)
    layer_sizes = (n_features, opts.hidden_sizes..., 1)
    n_dense = length(layer_sizes) - 1
    skeleton = Flux.Chain([
        Flux.Dense(layer_sizes[i] => layer_sizes[i+1], i < n_dense ? activation_hidden : activation_out)
        for i in 1:n_dense]...)
    ckpt = JLD2.load(opts.trained_state_path)
    Flux.loadmodel!(skeleton, ckpt["model_state"])
    gpp_nn_model = skeleton
    gpp_nn_mu = ckpt["mu"]
    gpp_nn_sigma = ckpt["sigma"]
    @pack_nt begin
        gpp_nn_model ⇒ land.diagnostics
        gpp_nn_mu ⇒ land.diagnostics
        gpp_nn_sigma ⇒ land.diagnostics
    end
    return land
end

function precompute(params::gpp_neuralNetwork, forcing, land, helpers)
    return land
end

function compute(params::gpp_neuralNetwork, forcing, land, helpers)
    @unpack_nt begin
        gpp_nn_model ⇐ land.diagnostics
        gpp_nn_mu ⇐ land.diagnostics
        gpp_nn_sigma ⇐ land.diagnostics
    end
    feature_names = helpers.hybrid.process_ml_models.gpp.options.features
    x_raw = reshape(Float32[getproperty(forcing, Symbol(f)) for f in feature_names], :, 1)
    x_norm = (x_raw .- gpp_nn_mu) ./ gpp_nn_sigma
    gpp = gpp_nn_model(x_norm)[1]
    @pack_nt gpp ⇒ land.fluxes
    return land
end
