module SindbadFluxExt
    using Flux
    using AxisKeys
    using Random
    
    include("MachineLearningMLModels.jl")
    include("MachineLearningActivationFunctions.jl")
    include("MachineLearningNeuralNetwork.jl")
    include("MachineLearningOneHots.jl")
end