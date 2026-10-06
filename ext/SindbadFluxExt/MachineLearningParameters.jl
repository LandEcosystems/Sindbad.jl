using Sindbad.DataLoaders: DD
using DimensionalData: hasdim
using YAXArrays: Cube, YAXArray
using YAXArrays.DAT: xmap, XOutput, ⊘

import Flux
import Sindbad.MachineLearning:
    predictParameters,
    assembleFeatures,
    scaleToBounds,
    oneHotPFT

"""
    assembleFeatures(pft; up_bound_pft=17, veg_cat=false)
    assembleFeatures(pft, kg, add_args...; up_bound_pft=17, up_bound_kg=32, veg_cat=false, clim_cat=true)

Stack all input features into a 1D vector for neural network parameter prediction.

- `pft`: LandCover type (Plant Functional Type). Any entry not in 1:17 will map to the last index (NaN/water).
- `kg`: Koeppen-Geiger climate type. Any entry not in 1:32 will map to the last index (NaN/water).
- `add_args`: All additional non-categorical features.
- `up_bound_pft`: Last index for PFT classes (default: 17).
- `up_bound_kg`: Last index for KG classes (default: 32).
- `veg_cat`: `true` to use mapped vegetation classes (`toClass`), `false` for raw 1-hot (default: `false`).
- `clim_cat`: `true` to include KG one-hot encoding, `false` to skip (default: `true`).

Returns a 1D vector of features.
"""
function assembleFeatures(pft; up_bound_pft=17, veg_cat=false)
    pft_val = pft isa AbstractArray ? only(pft) : pft
    return oneHotPFT(pft_val, up_bound_pft, veg_cat)
end

function assembleFeatures(pft, kg, add_args...; up_bound_pft=17, up_bound_kg=32, veg_cat=false, clim_cat=true)
    pft_val = pft isa AbstractArray ? only(pft) : pft
    veg_onehot = oneHotPFT(pft_val, up_bound_pft, veg_cat)
    if !clim_cat
        return reduce(vcat, [veg_onehot, add_args...])
    else
        kg_val = kg isa AbstractArray ? only(kg) : kg
        kg_onehot = Flux.onehot(kg_val, 1:up_bound_kg, up_bound_kg)
        return reduce(vcat, [kg_onehot, veg_onehot, add_args...])
    end
end

"""
    predictParametersPixel!(out_ps, in_covariates...; trained_nn, lower_bound, upper_bound, kwargs...)

Pixel-level kernel for predicting parameters from input covariates.
Writes scaled parameters into `out_ps`.

- `out_ps`: Output parameter slice for the current pixel.
- `in_covariates`: Input covariate entries for the current pixel.
- `trained_nn`: A trained neural network model.
- `lower_bound`: Parameter lower bounds.
- `upper_bound`: Parameter upper bounds.
"""
function predictParametersPixel!(out_ps, in_covariates...; trained_nn, lower_bound, upper_bound, kwargs...)
    if any(c -> (c isa AbstractArray ? (all(isnan, c) || all(ismissing, c)) : (isnan(c) || ismissing(c))), in_covariates)
        out_ps .= NaN32
        return
    end

    x_in = assembleFeatures(in_covariates...; kwargs...)
    new_ps = scaleToBounds.(trained_nn(x_in), lower_bound, upper_bound)
    out_ps[:] = new_ps
end

"""
    predictParameters(incubes, trained_nn, lower_bound, upper_bound, ps_names, path = ""; metadata_global = Dict{String, Any}(), overwrite = true, kwargs...)

Compute spatial parameter cubes using a trained neural network and input covariates via `xmap`.

The returned cube has the dimension order `(parameter, spatial_dims...)`.

Arguments:
- `incubes`: Input covariate cube, Tuple of cubes, or Vector of cubes.
- `trained_nn`: A trained neural network model.
- `lower_bound`: Lower bounds for the parameters.
- `upper_bound`: Upper bounds for the parameters.
- `ps_names`: Parameter names (defining the `:parameter` dimension).
- `path`: Output path for saving the cube (optional).
- `metadata_global`: Global metadata to merge into output properties (default: `Dict()`).
- `overwrite`: Whether to overwrite output file if it exists (default: `true`).
"""
function predictParameters(
    incubes,
    trained_nn,
    lower_bound,
    upper_bound,
    ps_names,
    path = "";
    metadata_global = Dict{String, Any}(),
    overwrite = true,
    kwargs...,
)
    cubes_tuple = if incubes isa Tuple
        incubes
    elseif incubes isa AbstractVector
        Tuple(incubes)
    else
        (incubes,)
    end

    in_args = map(cubes_tuple) do c
        if hasdim(c, :Variables)
            c ⊘ (DD.Dim{:Variables},)
        elseif hasdim(c, "Variables")
            c ⊘ (DD.Dim{Symbol("Variables")},)
        else
            c ⊘ ()
        end
    end

    properties = Dict{String, Any}(
        "name" => "parameters",
        "description" => "neural network spatial parameters estimations",
    )
    properties = merge(properties, metadata_global)

    param_axis = DD.Dim{:parameter}(String.(ps_names))
    out_spec = if isempty(path)
        XOutput(param_axis; outtype=Float32, properties=properties)
    else
        XOutput(param_axis; path=path, outtype=Float32, properties=properties, overwrite=overwrite)
    end

    return xmap(
        predictParametersPixel!,
        in_args...;
        output = out_spec,
        function_kwargs = (
            trained_nn = trained_nn,
            lower_bound = lower_bound,
            upper_bound = upper_bound,
            kwargs...,
        ),
    )
end
