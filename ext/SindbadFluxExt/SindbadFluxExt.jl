module SindbadFluxExt
    using Flux
    include("mlModels.jl")
    include("activationFunctions.jl")
    include("neuralNetwork.jl")
end