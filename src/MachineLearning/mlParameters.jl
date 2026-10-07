export assembleFeatures
export predictParameters
export predictParametersPixel!

"""
    assembleFeatures(args...; kwargs...)

Stack input features into a 1D vector for neural network parameter prediction.

!!! warning
    Do `using Flux` before using this function, otherwise it will error. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.
"""
function assembleFeatures(args...; kwargs...)
    error("`assembleFeatures` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end

"""
    predictParametersPixel!(args...; kwargs...)

Pixel-level kernel for predicting parameters from input covariates.

!!! warning
    Do `using Flux` before using this function, otherwise it will error. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.
"""
function predictParametersPixel!(args...; kwargs...)
    error("`predictParametersPixel!` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end

"""
    predictParameters(incubes, trained_nn, lower_bound, upper_bound, ps_names, path = ""; f_features = assembleFeatures, metadata_global = Dict(), overwrite = false, kwargs...)

Compute spatial parameter cubes using a trained neural network and input covariates via `xmap`.
!!! warning
    Do `using Flux` before using this function, otherwise it will error. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.
"""
function predictParameters(args...; kwargs...)
    error("`predictParameters` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end