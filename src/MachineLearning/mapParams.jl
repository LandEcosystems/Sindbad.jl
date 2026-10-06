export stackFeatures
export mapParamsPFT
export mapParamsAll

"""
    mapParamsPFT(inPFTcube, trainedNN, lower_bound, upper_bound, ps_names, path; metadata_global = Dict())

Compute parameters using a neural network and the PFT covariates.

!!! warning
    Do `using Flux` before using this function, otherwise it will error. This is because is fully defined in the `ext/SindbadFluxExt` folder.
"""
function mapParamsPFT(args...; kwargs...)
    error("`mapParamsPFT` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end

"""
    mapParamsAll(incubes, trainedNN, lower_bound, upper_bound, ps_names, path; metadata_global = Dict())

Compute all parameters using a neural network and all input covariates.

!!! warning
    Do `using Flux` before using this function, otherwise it will error. This is because is fully defined in the `ext/SindbadFluxExt` folder.
"""
function mapParamsAll(args...; kwargs...)
    error("`mapParamsAll` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end

"""
    stackFeatures(pft, kg, add_args...; up_bound=17, veg_cat=false, clim_cat=false)

Stack all features into a vector.

!!! warning
    Do `using Flux` before using this function, otherwise it will error. This is because is fully defined in the `ext/SindbadFluxExt` folder.
"""
function stackFeatures(args...; kwargs...)
    error("`stackFeatures` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end