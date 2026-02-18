module SindbadFluxExt
    using Flux
    using KeyedArrays

    include("mlModels.jl")
    include("activationFunctions.jl")
    include("neuralNetwork.jl")
    include("oneHots.jl")
end