import Sindbad.MachineLearning:
    activationFunction
using Sindbad: FluxRelu, FluxTanh, FluxSigmoid, FluxSoftplus

function activationFunction(_, ::FluxRelu)
    return Flux.relu
end
function activationFunction(_, ::FluxTanh)
    return Flux.tanh
end
function activationFunction(_, ::FluxSigmoid)
    return Flux.sigmoid
end
function activationFunction(_, ::FluxSoftplus)
    return Flux.softplus
end