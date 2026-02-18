import Sindbad.MachineLearning:
    activationFunction

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
