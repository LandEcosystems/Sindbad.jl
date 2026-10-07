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
    predictParameters(incubes, trained_nn, lower_bound, upper_bound, ps_names, path = ""; f_features = assembleFeatures, metadata_global = Dict(), overwrite = true, kwargs...)

Compute spatial parameter cubes using a trained neural network and input covariates via `xmap`.
The resulting cube has dimensions `(parameter, spatial_dims...)`.

Arguments:
- `incubes`: Input covariate cube, Tuple of cubes, or Vector of cubes. For multi-variable covariate cubes (e.g. continuous soil covariates, climate features, or AlphaEarth embeddings), the variable dimension must be named `:Variables` (e.g. `Dim{:Variables}`). `predictParameters` automatically detects `:Variables`, slices along it to extract per-pixel feature vectors, passes them to `f_features`, and ensures the dimension is stripped from the output cube.
- `trained_nn`: A trained neural network model.
- `lower_bound`: Lower bounds for the parameters.
- `upper_bound`: Upper bounds for the parameters.
- `ps_names`: Parameter names (defining the `:parameter` dimension).
- `path`: Output path for saving the cube (optional, e.g. `"parameters.zarr"`). Providing a path is recommended for large datasets to stream chunk-by-chunk computation to disk and avoid high in-memory usage.
- `f_features`: Feature assembly function mapping pixel covariates to a 1D input vector for `trained_nn` (default: `assembleFeatures`). Custom feature assemblers (e.g. for custom covariate orderings or AlphaEarth embeddings) can be passed here.
- `metadata_global`: Global metadata to merge into output properties (default: `Dict()`).
- `overwrite`: Whether to overwrite output file if it exists (default: `true`).

!!! warning
    Do `using Flux` before using this function, otherwise it will error. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.
"""
function predictParameters(args...; kwargs...)
    error("`predictParameters` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningParameters.jl` and requires `using Flux` to be loaded.")
end