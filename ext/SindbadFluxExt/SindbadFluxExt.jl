module SindbadFluxExt
    using Flux
    using AxisKeys
    using Random
    
    include("mlModels.jl")
    include("activationFunctions.jl")
    include("neuralNetwork.jl")
    include("oneHots.jl")
end