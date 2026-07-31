```@docs
Sindbad.MachineLearning
```
## Functions

### JoinDenseNN
```@docs
JoinDenseNN
```

:::details Code

```julia
function JoinDenseNN(args...; kwargs...)
    error("`JoinDenseNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### SplitNN
```@docs
SplitNN
```

:::details Code

```julia
function SplitNN(args...; kwargs...)
    error("`SplitNN` is not implemented for any backend yet. To implement it, add a method in `ext/<extension_name>/MachineLearningNeuralNetwork.jl` (see the commented-out draft in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl`).")
end
```

:::


----

### activationFunction
```@docs
activationFunction
```

:::details Code

```julia
function activationFunction(model_options, x::ActivationType)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    activationFunction `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This activation function is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    activationFunction `$(nameof(typeof(x)))` not implemented.

    To implement a new activation function:

    - First add a new type as a subtype of `ActivationType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/activationFunctions.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningActivationFunctions.jl` extension.

    ")
    end
    return
end

function activationFunction(model_options, ::CustomSigmoid)
    sigmoid_k(x, K) = one(x) / (one(x) + exp(-K * x))
    custom_sigmoid = x -> sigmoid_k(x, model_options.k_σ)
    return custom_sigmoid
end
```

:::


----

### denseNN
```@docs
denseNN
```

:::details Code

```julia
function denseNN(args...; kwargs...)
    error("`denseNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### destructureNN
```@docs
destructureNN
```

:::details Code

```julia
function destructureNN(args...; kwargs...)
    error("`destructureNN` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningNeuralNetwork.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### epochLossComponents
```@docs
epochLossComponents
```

:::details Code

```julia
function epochLossComponents(loss_functions::F, loss_array_sites, loss_array_components, epoch_number, scaled_params, sites_list) where {F}
    @sync begin
        for idx ∈ eachindex(sites_list)
           Threads.@spawn begin
                site_name = sites_list[idx]
                loc_params = scaled_params(site=site_name)
                loss_f = loss_functions(site=site_name)
                loss_metric, loss_components, loss_indices = loss_f(loc_params)
                loss_array_sites[idx, epoch_number] = loss_metric
                loss_array_components[idx, loss_indices, epoch_number] = loss_components
           end
       end
    end
end
```

:::


----

### getCacheFromOutput
```@docs
getCacheFromOutput
```

:::details Code

```julia
function getCacheFromOutput(loc_output, ::MachineLearningGradType)
    return loc_output
end

function getCacheFromOutput(loc_output, ::PolyesterForwardDiffGrad)
    return getCacheFromOutput(loc_output, ForwardDiffGrad())
end

function getCacheFromOutput end


function getOutputFromCache(loc_output, _, ::MachineLearningGradType)
    return loc_output
end
```

:::


----

### getIndicesSplit
```@docs
getIndicesSplit
```

:::details Code

```julia
function getIndicesSplit end

function getIndicesSplit(info, _, ::LoadFoldFromFile)
    # load the folds from file
    path_data_folds = info.hybrid.fold.fold_path
    n_fold = info.hybrid.fold.which_fold
    data_folds = load(path_data_folds)
    indices_training = data_folds["unfold_training"][n_fold]
    indices_validation = data_folds["unfold_validation"][n_fold]
    indices_testing = data_folds["unfold_tests"][n_fold]
    return indices_training, indices_validation, indices_testing
end

function getIndicesSplit(info, _, ::LoadFoldFromFile)
    # load the folds from file
    path_data_folds = info.hybrid.fold.fold_path
    n_fold = info.hybrid.fold.which_fold
    data_folds = load(path_data_folds)
    indices_training = data_folds["unfold_training"][n_fold]
    indices_validation = data_folds["unfold_validation"][n_fold]
    indices_testing = data_folds["unfold_tests"][n_fold]
    return indices_training, indices_validation, indices_testing
end

function getIndicesSplit(info, site_indices, ::CalcFoldFromSplit)
    site_indices = collect(eachindex(site_indices))  # Ensure site_indices is an array of indices
    # split the sites into training, validation and testing
    n_fold = info.hybrid.ml_training.options.n_folds
    split_ratio = info.hybrid.ml_training.options.split_ratio
    test_ratio = split_ratio[2]
    val_ratio = split_ratio[1]
    train_ratio = 1 - test_ratio - val_ratio
    @assert train_ratio + val_ratio + test_ratio ≈ 1.0 "Ratios must sum to 1.0"

    return getNFolds(site_indices, train_ratio, val_ratio, test_ratio, n_fold, info.hybrid.ml_training.options.batch_size; seed=info.hybrid.random_seed)
end
```

:::


----

### getInnerArgs
```@docs
getInnerArgs
```

:::details Code

```julia
function getInnerArgs(idx, grads_lib,
    scaled_params_batch, # ? input_args
    selected_models,
    space_forcing,
    space_spinup_forcing,
    loc_forcing_t,
    space_output,
    loc_land,
    tem_info,
    parameter_to_index,
    parameter_scaling_type,
    space_observations,
    cost_options,
    constraint_method,
    indices_batch,
    sites_batch)

    site_location = indices_batch[idx]
    site_name = sites_batch[idx]
    # get site information
    x_vals = scaled_params_batch(site=site_name).data.data
    loc_forcing = space_forcing[site_location]
    loc_obs = space_observations[site_location]
    loc_output = space_output[site_location]
    loc_spinup_forcing = space_spinup_forcing[site_location]
    loc_cost_option = cost_options[site_location]

    return (;
        loc_params = x_vals,
        inner_args = (
            selected_models,
            loc_forcing,
            loc_spinup_forcing,
            loc_forcing_t,
            getCacheFromOutput(loc_output, grads_lib),
            deepcopy(loc_land),
            tem_info,
            parameter_to_index,
            parameter_scaling_type,
            loc_obs,
            loc_cost_option,
            constraint_method)
        )
end
```

:::


----

### getLossForSites
```@docs
getLossForSites
```

:::details Code

```julia
function getLossForSites(gradient_lib, loss_function::F, loss_array_sites, loss_array_split, epoch_number,
    scaled_params, sites_list, indices_sites, models, space_forcing, space_spinup_forcing,
    loc_forcing_t, space_output, loc_land, tem_info, parameter_to_index, parameter_scaling_type, space_observations,
    cost_options, constraint_method) where {F}
    @sync begin
        for idx ∈ eachindex(indices_sites)
           Threads.@spawn begin
                site_location = indices_sites[idx]
                site_name = sites_list[idx]
                loc_params = scaled_params(site=site_name)
                loc_forcing = space_forcing[site_location]
                loc_obs = space_observations[site_location]
                loc_output = space_output[site_location]
                loc_spinup_forcing = space_spinup_forcing[site_location]
                loc_cost_option = cost_options[site_location]

                gg, gg_split, loss_indices = loss_function(loc_params, gradient_lib, models, loc_forcing, loc_spinup_forcing,
                    loc_forcing_t, loc_output, deepcopy(loc_land), tem_info, parameter_to_index, parameter_scaling_type, loc_obs, loc_cost_option, constraint_method;
                    optim_mode=false)
                loss_array_sites[idx, epoch_number] = gg
                # @show gg_split, idx, loss_indices, epoch_number
                loss_array_split[idx, loss_indices, epoch_number] = gg_split
           end
       end
    end
end
```

:::


----

### getLossFunctionHandles
```@docs
getLossFunctionHandles
```

:::details Code

```julia
function getLossFunctionHandles(info, run_helpers, sites)
    loss_functions = []
    loss_component_functions = []

    for site_location in eachindex(sites)
        parameter_to_index = getParameterIndices(info.models.forward, info.optimization.parameter_table)
        loc_forcing = run_helpers.space_forcing[site_location]
        loc_obs = run_helpers.space_observation[site_location]
        loc_output = getCacheFromOutput(run_helpers.space_output[site_location], info.hybrid.ml_gradient.method)
        loc_spinup_forcing = run_helpers.space_spinup_forcing[site_location]
        loc_cost_option = prepCostOptions(loc_obs, info.optimization.cost_options)
        loss_tmp(x) = loss(x, info.models.forward, parameter_to_index, info.optimization.run_options.parameter_scaling, loc_forcing, loc_spinup_forcing, run_helpers.loc_forcing_t, loc_output, deepcopy(run_helpers.loc_land), run_helpers.tem_info, loc_obs, loc_cost_option, info.optimization.run_options.multi_constraint_method, info.hybrid.ml_gradient.method, info.hybrid.ml_training.options.loss_function)

        loss_vector_tmp(x) = lossComponents(x, info.models.forward, parameter_to_index, info.optimization.run_options.parameter_scaling, loc_forcing, loc_spinup_forcing, run_helpers.loc_forcing_t, loc_output, deepcopy(run_helpers.loc_land), run_helpers.tem_info, loc_obs, loc_cost_option, info.optimization.run_options.multi_constraint_method, info.hybrid.ml_gradient.method, info.hybrid.ml_training.options.loss_function)

        push!(loss_functions, loss_tmp)
        push!(loss_component_functions, loss_vector_tmp)
    end
    loss_functions = MachineLearning.KeyedArray(loss_functions; site=sites)
    loss_component_functions = MachineLearning.KeyedArray(loss_component_functions; site=sites)
    return loss_functions, loss_component_functions
end
```

:::


----

### getOutputFromCache
```@docs
getOutputFromCache
```

:::details Code

```julia
function getOutputFromCache(loc_output, _, ::MachineLearningGradType)
    return loc_output
end

function getOutputFromCache(loc_output, new_params, ::PolyesterForwardDiffGrad)
    return getOutputFromCache(loc_output, new_params, ForwardDiffGrad())
end
```

:::


----

### getParamsAct
```@docs
getParamsAct
```

:::details Code

```julia
function getParamsAct(x, parameter_table)
    lo_b = oftype(parameter_table.initial, parameter_table.lower)
    up_b = oftype(parameter_table.initial, parameter_table.upper)
    return scaleToBounds.(x, lo_b, up_b)
end
```

:::


----

### getPullback
```@docs
getPullback
```

:::details Code

```julia
function getPullback(x::MachineLearningPullbackType, _, _, _)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    getPullback `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This pullback type is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    getPullback `$(nameof(typeof(x)))` not implemented.

    To implement a new pullback type:

    - First add a new type as a subtype of `MachineLearningPullbackType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/getPullback.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningGetPullback.jl` extension.
    ")
    end
end
```

:::


----

### gradientBatch!
```@docs
gradientBatch!
```

:::details Code

```julia
function gradientBatch! end
function gradientBatch!(grads_lib::MachineLearningGradType, grads_batch, gradient_options::NamedTuple, loss_functions, scaled_params_batch, sites_batch; showprog=false)
    # Threads.@spawn allows dynamic scheduling instead of static scheduling
    # of Threads.@threads macro.
    # See <https://github.com/JuliaLang/julia/issues/21017>

    p = Progress(length(axes(grads_batch,2)); desc="Computing batch grads...", color=:cyan, enabled=showprog)
    @sync begin
        for idx ∈ axes(grads_batch, 2)
            Threads.@spawn begin
                site_name = sites_batch[idx]
                loss_f = loss_functions(site=site_name)
                x_vals = scaled_params_batch(site=site_name).data.data
                gg = gradientSite(grads_lib, x_vals, gradient_options, loss_f)    
                grads_batch[:, idx] = gg
                next!(p)
            end
        end
    end
end

function gradientBatch!(grads_lib::MachineLearningGradType, grads_batch, gradient_options::NamedTuple, loss_functions, scaled_params_batch, sites_batch; showprog=false)
    # Threads.@spawn allows dynamic scheduling instead of static scheduling
    # of Threads.@threads macro.
    # See <https://github.com/JuliaLang/julia/issues/21017>

    p = Progress(length(axes(grads_batch,2)); desc="Computing batch grads...", color=:cyan, enabled=showprog)
    @sync begin
        for idx ∈ axes(grads_batch, 2)
            Threads.@spawn begin
                site_name = sites_batch[idx]
                loss_f = loss_functions(site=site_name)
                x_vals = scaled_params_batch(site=site_name).data.data
                gg = gradientSite(grads_lib, x_vals, gradient_options, loss_f)    
                grads_batch[:, idx] = gg
                next!(p)
            end
        end
    end
end
```

:::


----

### gradientSite
```@docs
gradientSite
```

:::details Code

```julia
function gradientSite end

function gradientSite(grads_lib::MachineLearningGradType, ::Any, ::Any, ::Any)
    @warn "
    Gradient library `$(nameof(typeof(grads_lib)))` not implemented. 
    
    To implement a new gradient library:
    
    - First add a new type as a subtype of `MachineLearningGradType` in `src/Types/MachineLearningTypes.jl`. 
    
    - Then, add a corresponding method.
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlGradient.jl`.     
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningGradientSite.jl` extension.

    As a fallback, this function will return 10.0f0.
    "
    return 10.0f0
end

function gradientSite(grads_lib::MachineLearningGradType, ::Any, ::Any, ::Any)
    @warn "
    Gradient library `$(nameof(typeof(grads_lib)))` not implemented. 
    
    To implement a new gradient library:
    
    - First add a new type as a subtype of `MachineLearningGradType` in `src/Types/MachineLearningTypes.jl`. 
    
    - Then, add a corresponding method.
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlGradient.jl`.     
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningGradientSite.jl` extension.

    As a fallback, this function will return 10.0f0.
    "
    return 10.0f0
end
```

:::


----

### gradsNaNCheck!
```@docs
gradsNaNCheck!
```

:::details Code

```julia
function gradsNaNCheck!(grads_batch, _params_batch, sites_batch, parameter_table; replace_value = 0.0, show_params_for_nan=false)
    if sum(isnan.(grads_batch))>0
        if show_params_for_nan
            foreach(findall(x->isnan(x), grads_batch)) do ci
                p_index_tmp, si = Tuple(ci)
                site_name_tmp = sites_batch[si]
                p_vec_tmp = _params_batch(site=site_name_tmp)
                parameter_values =  Pair(parameter_table.name[p_index_tmp], (p_vec_tmp[p_index_tmp], parameter_table.lower[p_index_tmp], parameter_table.upper[p_index_tmp]))
                @info "site: $site_name_tmp, parameter: $parameter_values"
            end
        end
        @warn "NaNs in grads, replacing all by 0.0f0"
        replace!(grads_batch, NaN => eltype(grads_batch)(replace_value))
    end
end
```

:::


----

### lcKAoneHotbatch
```@docs
lcKAoneHotbatch
```

:::details Code

```julia
function lcKAoneHotbatch(args...; kwargs...)
    error("`lcKAoneHotbatch` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningOneHots.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### loadCovariates
```@docs
loadCovariates
```

:::details Code

```julia
function loadCovariates(::MachineLearningExperimentType, sites_forcing, covariate_path, covariate_options)
    c_read = Cube(covariate_path)
    kind = covariate_options.kind
    # select features, do only nor
    only_nor = occursin.(r"nor", c_read.features)
    nor_sel = c_read.features[only_nor].val
    nor_sel = [string.(s) for s in nor_sel] |> sort
    # select only normalized continuous variables
    ds_nor = c_read[features = At(nor_sel)]
    xfeat_nor = yaxCubeToKeyedArray(ds_nor)
    # apply PCA to xfeat_nor if needed
    # ? where is age?
    kg_data = c_read[features=At("KG")][:].data
    oneHot_KG = lcKAoneHotbatch(kg_data, 32, "KG", string.(c_read.site))
    pft_data = c_read[features=At("PFT")][:].data
    oneHot_pft = lcKAoneHotbatch(pft_data, 17, "PFT", string.(c_read.site))
    oneHot_veg = vegKAoneHotbatch(pft_data, string.(c_read.site))

    stackedFeatures = if kind=="all" 
            reduce(vcat, [oneHot_KG, oneHot_pft, xfeat_nor])
        elseif  kind=="PFT"
            reduce(vcat, [oneHot_pft])
        elseif kind=="KG"
            reduce(vcat, [oneHot_KG])
        elseif kind=="KG_PFT"
            reduce(vcat, [oneHot_KG, oneHot_pft])
        elseif kind=="PFT_ABCNOPSWB"
            reduce(vcat, [oneHot_pft, xfeat_nor])
        elseif kind=="KG_ABCNOPSWB"
            reduce(vcat, [oneHot_KG, xfeat_nor])
        elseif kind=="ABCNOPSWB"
            reduce(vcat, [xfeat_nor])
        elseif kind =="veg_all"
            reduce(vcat, [oneHot_KG, oneHot_veg, xfeat_nor])
        elseif kind=="veg"
            reduce(vcat, [oneHot_veg])
        elseif kind=="KG_veg"
            reduce(vcat, [oneHot_KG, oneHot_veg])
        elseif kind=="veg_ABCNOPSWB"
            reduce(vcat, [oneHot_veg, xfeat_nor])
        end
    # remove sites (with NaNs and duplicates)
    to_remove = [
        "CA-NS3",
        # "CA-NS4",
        "IT-CA1",
        # "IT-CA2",
        "IT-SR2",
        # "IT-SRo",
        "US-ARb",
        # "US-ARc",
        "US-GBT",
        # "US-GLE",
        "US-Tw1",
        # "US-Tw2"
        ]
    not_these = ["RU-Tks", "US-Atq", "US-UMd"] # NaNs
    not_these = vcat(not_these, to_remove)
    new_sites = setdiff(c_read.site, not_these)
    stackedFeatures = stackedFeatures(; site=new_sites)
    # get common sites between names in forcing and covariates
    sites_feature_all = [s for s in stackedFeatures.site]
    sites_common = intersect(sites_feature_all, sites_forcing)
    xfeatures = Float32.(stackedFeatures(; site=sites_common))

    return xfeatures
end
```

:::


----

### loadTrainedNN
```@docs
loadTrainedNN
```

:::details Code

```julia
function loadTrainedNN(path_model)
    model_props = JLD2.load(path_model)
    return (;
        trainedNN=model_props["re"](model_props["flat"]), # ? model structure and trained weights
        lower_bound=model_props["lower_bound"],  # ? parameters' attributes    
        upper_bound=model_props["upper_bound"],
        ps_names=model_props["ps_names"],
        metadata_global=model_props["metadata_global"])
end
```

:::


----

### loss
```@docs
loss
```

:::details Code

```julia
function lossVector(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,::LossModelObsMachineLearning)
    loc_output_from_cache = getOutputFromCache(loc_output, params, gradient_lib)
    models = updateModels(params, parameter_to_index, parameter_scaling_type, models)
    coreTEM!(
        models,
        loc_forcing,
        loc_spinup_forcing,
        loc_forcing_t,
        loc_output_from_cache,
        land_init,
        tem_info)
    loss_vector = metricVector(loc_output_from_cache, loc_obs, cost_options)
    loss_indices = cost_options.obs_sn
    return loss_vector, loss_indices
end

function loss(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,loss_type::LossModelObsMachineLearning)
    loss_vector, _ = lossVector(params, models,parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, loss_type)
    t_loss = combineMetric(loss_vector, constraint_method)
    return t_loss
end

function lossComponents(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,loss_type::LossModelObsMachineLearning)
    loss_vector, loss_indices = lossVector(params, models,parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, loss_type)
    t_loss = combineMetric(loss_vector, constraint_method)
    return t_loss, loss_vector, loss_indices
end
```

:::


----

### lossComponents
```@docs
lossComponents
```

:::details Code

```julia
function lossComponents(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,loss_type::LossModelObsMachineLearning)
    loss_vector, loss_indices = lossVector(params, models,parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, loss_type)
    t_loss = combineMetric(loss_vector, constraint_method)
    return t_loss, loss_vector, loss_indices
end
```

:::


----

### lossSite
```@docs
lossSite
```

:::details Code

```julia
function lossSite(new_params, gradient_lib, models, loc_forcing, loc_spinup_forcing, 
    loc_forcing_t, loc_output, land_init, tem_info, parameter_to_index, parameter_scaling_type,
    loc_obs, cost_options, constraint_method; optim_mode=true)

    out_data = getOutputFromCache(loc_output, new_params, gradient_lib)
    new_models = updateModels(new_params, parameter_to_index, parameter_scaling_type, models)
    return getLoss(new_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, out_data, land_init, tem_info, loc_obs, cost_options, constraint_method; optim_mode)
end
```

:::


----

### lossVector
```@docs
lossVector
```

:::details Code

```julia
function lossVector(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,::LossModelObsMachineLearning)
    loc_output_from_cache = getOutputFromCache(loc_output, params, gradient_lib)
    models = updateModels(params, parameter_to_index, parameter_scaling_type, models)
    coreTEM!(
        models,
        loc_forcing,
        loc_spinup_forcing,
        loc_forcing_t,
        loc_output_from_cache,
        land_init,
        tem_info)
    loss_vector = metricVector(loc_output_from_cache, loc_obs, cost_options)
    loss_indices = cost_options.obs_sn
    return loss_vector, loss_indices
end
```

:::


----

### mlModel
```@docs
mlModel
```

:::details Code

```julia
function mlModel(info, n_features, x::MachineLearningModelType)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    mlModel `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This model is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    mlModel `$(nameof(typeof(x)))` not implemented.

    To implement a new ML model:

    - First add a new type as a subtype of `MachineLearningModelType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlModels.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningMLModels.jl` extension.

    ")
    end
    return
end
```

:::


----

### mlOptimizer
```@docs
mlOptimizer
```

:::details Code

```julia
function mlOptimizer(optimizer_options, x::MachineLearningOptimizerType)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    mlOptimizer `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This optimizer is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    mlOptimizer `$(nameof(typeof(x)))` not implemented.

    To implement a new ML optimizer:

    - First add a new type as a subtype of `MachineLearningOptimizerType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlOptimizers.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningMlOptimizer.jl` extension.

    ")
    end
    return
end
```

:::


----

### oneHotPFT
```@docs
oneHotPFT
```

:::details Code

```julia
function oneHotPFT(args...; kwargs...)
    error("`oneHotPFT` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningOneHots.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### partitionBatches
```@docs
partitionBatches
```

:::details Code

```julia
function partitionBatches(n; batch_size=32)
    return partition(1:n, batch_size)
end
```

:::


----

### prepHybrid
```@docs
prepHybrid
```

:::details Code

```julia
function prepHybrid(forcing, observations, info, ::MachineLearningTrainingType)

    run_helpers = prepTEM(info.models.forward, forcing, observations, info)
    sites_forcing = forcing.data[1].site;
    print_info(prepHybrid, @__FILE__, @__LINE__, "preparing hybridMachine Learninghelpers for $(length(sites_forcing)) sites", n_f=2)
    print_info(nothing, @__FILE__, @__LINE__, "Building loss function handles for every site", n_m=4)
    loss_functions, loss_component_functions = getLossFunctionHandles(info, run_helpers, sites_forcing)

    ## split the sites

    print_info(prepHybrid, @__FILE__, @__LINE__, "Getting indices and sites for training, validation and testing", n_f=2)
    indices_training, indices_validation, indices_testing = getIndicesSplit(info, sites_forcing, info.hybrid.fold.fold_type)

    sites_training = sites_forcing[indices_training]
    sites_validation = sites_forcing[indices_validation]
    sites_testing = sites_forcing[indices_testing]

    sites = (; training = sites_training, validation = sites_validation, testing = sites_testing)
    indices = (; training = indices_training, validation = indices_validation, testing = indices_testing)

    print_info(nothing, @__FILE__, @__LINE__, "Total sites: $(length(sites_forcing))", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "Training sites: $(length(sites.training))", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "Validation sites: $(length(sites.validation))", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "Testing sites: $(length(sites.testing))", n_m=4)

    ## get covariates

    print_info(prepHybrid, @__FILE__, @__LINE__, "Loading covariates for hybridMachine Learningmodel", n_f=2)
    print_info(nothing, @__FILE__, @__LINE__, "options: $(info.hybrid.covariates.options)", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "path: $(info.hybrid.covariates.path)", n_m=4)
    xfeatures = loadCovariates(info.hybrid.ml_experiment_type, sites_forcing, info.hybrid.covariates.path, info.hybrid.covariates.options)
    print_info(nothing, @__FILE__, @__LINE__, "Min/Max of features: [$(minimum(xfeatures)), $(maximum(xfeatures))]", n_m=4)
    n_features = length(xfeatures.features)

    features = (; n_features=n_features, data=xfeatures)


    ## buildMachine Learningmodel and get init predictions
    print_info(prepHybrid, @__FILE__, @__LINE__, "Preparing machine learning model", n_f=2)
    ml_model = mlModel(info, n_features, info.hybrid.ml_model.method)

    print_info(prepHybrid, @__FILE__, @__LINE__, "Preparing loss arrays", n_f=2)
    n_epochs = info.hybrid.ml_training.options.n_epochs
    loss_array_training = fill(zero(Float32), length(sites.training), n_epochs)
    loss_array_validation = fill(zero(Float32), length(sites.validation), n_epochs)
    loss_array_testing = fill(zero(Float32), length(sites.testing), n_epochs)

    # ? save also the individual losses
    num_constraints = length(info.optimization.cost_options.variable)

    loss_array_components_training = fill(NaN32, length(sites.training), num_constraints, n_epochs)
    loss_array_components_validation = fill(NaN32, length(sites.validation), num_constraints, n_epochs)
    loss_array_components_testing = fill(NaN32, length(sites.testing), num_constraints, n_epochs)

    loss_array_components = (; 
        training=loss_array_components_training, 
        validation=loss_array_components_validation, 
        testing=loss_array_components_testing
    )

    loss_array = (; 
        training=loss_array_training, 
        validation=loss_array_validation, 
        testing=loss_array_testing
    )
    print_info(nothing, @__FILE__, @__LINE__, "Number of sites: $(length(sites_forcing))", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "Loss array shape (training | validation | testing): $(size(loss_array.training)) | $(size(loss_array.validation)) | $(size(loss_array.testing))", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "Loss array components shape (training | validation | testing): $(size(loss_array_components.training)) | $(size(loss_array_components.validation)) | $(size(loss_array_components.testing))", n_m=4)
    print_info(nothing, @__FILE__, @__LINE__, "Number of constraints: $num_constraints", n_m=4)

    
    print_info(prepHybrid, @__FILE__, @__LINE__, "Preparing training optimizer", n_f=2)
    print_info(nothing, @__FILE__, @__LINE__, "Method: $(nameof(typeof(info.hybrid.ml_optimizer.method)))", n_m=4)
    training_optimizer = mlOptimizer(info.hybrid.ml_optimizer.options, info.hybrid.ml_optimizer.method)
    metadata_global = info.output.file_info.global_metadata

    options = info.hybrid
    hybrid_helpers = (; 
        run_helpers=run_helpers, 
        sites=sites, 
        indices=indices, 
        features=features, 
        ml_model=ml_model, 
        options=options,
        checkpoint_path=info.output.dirs.hybrid.checkpoint,
        parameter_table=info.optimization.parameter_table,
        loss_functions=loss_functions, 
        loss_component_functions=loss_component_functions,
        training_optimizer=training_optimizer,
        loss_array=loss_array,
        loss_array_components=loss_array_components,
        metadata_global=metadata_global
    )
    return hybrid_helpers
end
```

:::


----

### shuffleBatches
```@docs
shuffleBatches
```

:::details Code

```julia
function shuffleBatches(list, bs; seed=1)
    bs_idxs = partitionBatches(length(list); batch_size = bs)
    s_list = shuffleList(list; seed=seed)
    xbatches = [s_list[p] for p in bs_idxs if length(p) == bs]
    return xbatches
end
```

:::


----

### shuffleList
```@docs
shuffleList
```

:::details Code

```julia
function shuffleList(list; seed=123)
    rand_indxs = randperm(MersenneTwister(seed), length(list))
    return list[rand_indxs]
end
```

:::


----

### siteNameToID
```@docs
siteNameToID
```

:::details Code

```julia
function siteNameToID(site_name, sites_list)
    return findfirst(s -> s == site_name, sites_list)
end
```

:::


----

### toClass
```@docs
toClass
```

:::details Code

```julia
function toClass(x::Number; vegetation_rules=vegetation_rules)
    if ismissing(x)
        return vegetation_rules[missing]
    elseif x isa AbstractFloat && isnan(x)
        return vegetation_rules[NaN]
    end
    new_key = Int(x)
    return get(vegetation_rules, new_key, "Unknown key")
end
```

:::


----

### trainML
```@docs
trainML
```

:::details Code

```julia
function trainML(hybrid_helpers, ::MixedGradient)
    ml_model = hybrid_helpers.ml_model
    all_sites = hybrid_helpers.sites
    sites_training = all_sites.training
    xfeatures = hybrid_helpers.features.data
    parameter_table = hybrid_helpers.parameter_table
    metadata_global = hybrid_helpers.metadata_global
    loss_functions = hybrid_helpers.loss_functions
    loss_array = hybrid_helpers.loss_array
    loss_array_components = hybrid_helpers.loss_array_components
    loss_component_functions = hybrid_helpers.loss_component_functions
    ml_optimizer = hybrid_helpers.training_optimizer
    flat, re, opt_state = destructureNN(ml_model; nn_opt=ml_optimizer)
    n_params = length(parameter_table.name)
    options = hybrid_helpers.options
    batch_size = options.ml_training.options.batch_size
    gradient_options = options.ml_gradient
    pullback_method = options.ml_training.pullback_method
    update_method = options.ml_optimizer.update_method
    n_epochs = options.ml_training.options.n_epochs
    checkpoint_path = hybrid_helpers.checkpoint_path

    @showprogress desc="training..." for epoch ∈ 1:n_epochs
        x_batches = shuffleBatches(sites_training, batch_size; seed=epoch)

        for sites_batch in x_batches
            
            grads_batch = zeros(Float32, n_params, length(sites_batch))
            x_feat_batch = xfeatures(; site=sites_batch)
            new_params, pullback_func = getPullback(pullback_method, flat, re, x_feat_batch)
            scaled_params_batch = getParamsAct(new_params, parameter_table)
            @debug "  Epoch $(epoch): training on batch with $(length(sites_batch)) sites, scaled_params: minimum=$(minimum(scaled_params_batch)), maximum=$(maximum(scaled_params_batch))"

            gradientBatch!(gradient_options.method, grads_batch, gradient_options.options, loss_functions, scaled_params_batch, sites_batch; showprog=false)

            gradsNaNCheck!(grads_batch, scaled_params_batch, sites_batch, parameter_table, replace_value=options.replace_value_for_gradient) #? checks for NaNs and if any replace them with replace_value_for_gradient
            # Jacobian-vector product
            ∇params = pullback_func(grads_batch)[1]
            opt_state, flat = updateMLModel(update_method, opt_state, flat, ∇params, )
            # opt_state, flat = Optimisers.update(opt_state, flat, ∇params)
        end
        # calculate losses for all sites!
        if !isempty(checkpoint_path)
            f_path = joinpath(checkpoint_path, "epoch_$(epoch).jld2")
            _params_epoch = re(flat)(xfeatures)

            scaled_params_epoch = getParamsAct(_params_epoch, parameter_table)
        
            for comps in (:training, :validation, :testing)
                sites_comp = getproperty(all_sites, comps)
                loss_array_epoch = getproperty(loss_array, comps)
                loss_array_components_epoch = getproperty(loss_array_components, comps)
                epochLossComponents(loss_component_functions, loss_array_epoch, loss_array_components_epoch, epoch, scaled_params_epoch, sites_comp)
            end

            jldsave(f_path;
                lower_bound=parameter_table.lower, upper_bound=parameter_table.upper, parameter_names=parameter_table.name,
                parameter_table=parameter_table,
                metadata_global=metadata_global,
                loss_array_training=loss_array.training[:, epoch],
                loss_array_validation=loss_array.validation[:, epoch],
                loss_array_testing=loss_array.testing[:, epoch],
                loss_array_components_training=loss_array_components.training[:,:, epoch],
                loss_array_components_validation=loss_array_components.validation[:,:, epoch],
                loss_array_components_testing=loss_array_components.testing[:,:, epoch],
                re=re,
                flat=flat)
        end

    end

end

function trainML(hybrid_helpers, ::MachineLearningExperimentType)
    trainML(hybrid_helpers, MixedGradient())
end

function trainML(hybrid_helpers, ::FluxnetParameterLearningWROASTED)
    trainML(hybrid_helpers, MixedGradient())
end
```

:::


----

### updateMLModel
```@docs
updateMLModel
```

:::details Code

```julia
function updateMLModel(x::MachineLearningUpdateType, _model_state, _model_flat, _gradient)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    updateMLModel `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This update method is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    updateMLModel `$(nameof(typeof(x)))` not implemented.

    To implement a new update method:

    - First add a new type as a subtype of `MachineLearningUpdateType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlUpdate.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningUpdateMLModel.jl` extension.

    ")
    end
end
```

:::


----

### vegKAoneHotbatch
```@docs
vegKAoneHotbatch
```

:::details Code

```julia
function vegKAoneHotbatch(args...; kwargs...)
    error("`vegKAoneHotbatch` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningOneHots.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### vegOneHot
```@docs
vegOneHot
```

:::details Code

```julia
function vegOneHot(args...; kwargs...)
    error("`vegOneHot` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningOneHots.jl` and requires `using Flux` to be loaded.")
end

function vegOneHotbatch(args...; kwargs...)
    error("`vegOneHotbatch` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningOneHots.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

### vegOneHotbatch
```@docs
vegOneHotbatch
```

:::details Code

```julia
function vegOneHotbatch(args...; kwargs...)
    error("`vegOneHotbatch` is not available. This function is implemented in `ext/SindbadFluxExt/MachineLearningOneHots.jl` and requires `using Flux` to be loaded.")
end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.MachineLearning
end
```
