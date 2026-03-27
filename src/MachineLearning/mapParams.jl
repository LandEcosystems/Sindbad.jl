export stackFeatures
export mapParamsPFT
export mapParamsAll

"""
    mapNNYaxPFT(out_ps, in_pft; trainedNN, lower_bound, upper_bound)

`mapCube` wrapper function that outpus `out_ps` new parameters.

- `in_pft`: input Plant Functional Type (PFT) cube entry.
- `trainedNN`: A trained neural network.
- `lower_bound`: parameters' lower bounds.
- `upper_bound`: parameters' upper bounds.
"""
function mapNNYaxPFT(out_ps, in_pft; trainedNN, lower_bound, upper_bound)
    x_in = Flux.onehot(only(in_pft), 1:17, 17)
    new_ps = scaleToBounds.(trainedNN(x_in), lower_bound, upper_bound)
    out_ps[:] = new_ps # ? doing explicitly `.=` also works!
end

"""
    mapNNYaxAll(out_ps, in_pft, in_kg, in_all_args; trainedNN, lower_bound, upper_bound)
    
`mapCube` wrapper function that outputs `out_ps` new parameters using all covariates.

Arguments:
- `out_ps`: output parameters.
- `in_pft`: input Plant Functional Type (PFT) cube entry.
- `in_kg`: input Koeppen-Geiger (KG) cube entry.
- `in_all_args`: all other input arguments.
- `trainedNN`: A trained neural network.
- `lower_bound`: parameters' lower bounds.
- `upper_bound`: parameters' upper bounds.
"""
function mapNNYaxAll(out_ps, in_pft, in_kg, in_all_args; trainedNN, lower_bound, upper_bound)
    x_in_pft = Flux.onehot(only(in_pft), 1:17, 17)
    x_in_kg = Flux.onehot(only(in_kg), 1:32, 32)
    x_in = reduce(vcat, [x_in_kg, x_in_pft, in_all_args...])
    # @show length(x_in)
    new_ps = scaleToBounds.(trainedNN(x_in), lower_bound, upper_bound)
    out_ps[:] = new_ps # ? doing explicitly `.=` also works!
end

"""
    stackFeatures(pft, kg, add_args...;  up_bound=17, veg_cat=false, clim_cat=false)

Stack all features into a vector.

- `pft`: LandCover type (Plant Functional Type). Any entry not in 1:17 would be set to the last index, this includes NaN!  Last index is water/NaN
- `kg`: Koeppen-Geiger climater type. Any entry not in 1:32 would be set to the last index, this includes NaN! Last index is water/NaN
- `add_args`: all non-categorical additional features
- `up_bound`: last index class, the range goes from `1:up_bound`, and any case not in that range uses the `up_bound` value. For `PFT` use `17`. 
- `veg_cat`: `true` or `false`.

Returns a vector.
"""
function stackFeatures(pft, kg, add_args...; up_bound=17, veg_cat=false, clim_cat=false)
    veg_onehot = oneHotPFT(pft, up_bound, veg_cat)
    if !clim_cat
        return reduce(vcat, [veg_onehot, add_args...])
    else
        kg_onehot = Flux.onehot(kg, 1:32, 32)
        return reduce(vcat, [kg_onehot, veg_onehot, add_args...])
    end
end


"""
    mapParamsAll(incubes, trainedNN, lower_bound, upper_bound, ps_names, path; metadata_global = Dict())

Compute all parameters using a neural network and all input covariates.

Arguments:
- `incubes`: input covariates cubes. Firsts ones should be `pft` and `kc`.
- `trainedNN`: A trained neural network.
- `lower_bound`: parameters' lower bounds.
- `upper_bound`: parameters' upper bounds.
- `ps_names`: parameter names
- `path`: output path for the cube.
- `metadata_global`: global metadata to be added to the output cube.
"""
function mapParamsAll(incubes, trainedNN, lower_bound, upper_bound, ps_names, path; metadata_global = Dict())

    indims = [InDims(; filter=AllNaN()), InDims(; filter=AllNaN()), InDims("Variables"; filter=AllNaN())]
    
    properties = Dict{String, Any}(
        "name"=> "parameters",
        "description" => "neural network spatial parameters' estimations"
        )
    properties = merge(properties, metadata_global)
    mapCube(mapNNYaxAll, (incubes...,); # ! additional input function arguments
        trainedNN,
        lower_bound,
        upper_bound,
        indims = indims,
        outdims = OutDims(Dim{:parameter}(String.(ps_names));
            path=path,
            outtype=Float32,
            properties,
            overwrite=true),
        )
end

"""
    mapParamsPFT(inPFTcube, trainedNN, lower_bound, upper_bound, ps_names, path; metadata_global = Dict())

Compute parameters using a neural network and the PFT covariates.

Arguments:
- `inPFTcube`: input Plant Functional Type (PFT) cube.
- `trainedNN`: A trained neural network.
- `lower_bound`: parameters' lower bounds.
- `upper_bound`: parameters' upper bounds.
- `ps_names`: parameter names.
- `path`: output path for the cube.
- `metadata_global`: global metadata to be added to the output cube.
"""
function mapParamsPFT(inPFTcube, trainedNN, lower_bound, upper_bound, ps_names, path; metadata_global = Dict())
    indims = [InDims(; filter=AllNaN())]

    properties = Dict{String, Any}(
        "name"=> "parameters",
        "description" => "neural network spatial parameters' estimations"
        )
    properties = merge(properties, metadata_global)
    mapCube(mapNNYaxPFT, (inPFTcube,); # ! additional input function arguments
        trainedNN,
        lower_bound,
        upper_bound,
        indims = indims,
        outdims = OutDims(Dim{:parameter}(String.(ps_names));
            path=path,
            outtype=Float32,
            properties,
            overwrite=true),
        )
end