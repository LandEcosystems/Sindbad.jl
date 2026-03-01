import Sindbad.MachineLearning:
    activationFunction
using Sindbad: FluxRelu, FluxTanh, FluxSigmoid

function activationFunction(_, ::FluxRelu)
    return Flux.relu
end
function activationFunction(_, ::FluxTanh)
    return Flux.tanh
end
function activationFunction(_, ::FluxSigmoid)
    return Flux.sigmoid
end