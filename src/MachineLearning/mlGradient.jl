export gradientSite
export gradientBatch!
export gradsNaNCheck!
export loadTrainedNN

"""
    batchShuffler(x_forcings, ids_forcings, batch_size; bs_seed=1456)

Shuffles the batches of forcings and their corresponding indices.
"""
function batchShuffler(x_forcings, ids_forcings, batch_size; bs_seed=1456)
    x_batches = shuffleBatches(x_forcings, batch_size; seed=bs_seed)
    ids_batches = shuffleBatches(ids_forcings, batch_size; seed=bs_seed)
    return x_batches, ids_batches
end

# https://juliateachingctu.github.io/Scientific-Programming-in-Julia/dev/lecture_08/lecture/
"""
    gradientSite(grads_lib, x_vals::AbstractArray, gradient_options::NamedTuple, loss_f::Function)

Compute gradients of the loss function with respect to model parameters for a single site using the specified gradient library.

This function dispatches on the type of `grads_lib` to select the appropriate differentiation backend (e.g., `PolyesterForwardDiff`, `ForwardDiff`, `FiniteDiff`, `FiniteDifferences`, `Zygote`, or `Enzyme`). It supports both threaded and single-threaded computation, as well as chunked evaluation for memory and speed trade-offs.

# Arguments
- `grads_lib`: Gradient computation library or method. Supported types include:
    - `PolyesterForwardDiffGrad`: Uses `PolyesterForwardDiff.jl` for multi-threaded chunked gradients.
    - `ForwardDiffGrad`: Uses `ForwardDiff.jl` for automatic differentiation.
    - `FiniteDiffGrad`: Uses `FiniteDiff.jl` for finite difference gradients.
    - `FiniteDifferencesGrad`: Uses `FiniteDifferences.jl` for finite difference gradients.
    - `ZygoteGrad`: Uses `Zygote.jl` for reverse-mode automatic differentiation.
    - `EnzymeGrad`: Uses `Enzyme.jl` for AD (experimental).
- `x_vals`: Parameter values for which to compute gradients.
- `gradient_options`: (Optional) NamedTuple of gradient options (e.g., chunk size).
- `loss_f`: Loss function to be differentiated.

# Returns
- `∇x`: Array of gradients of the loss function with respect to `x_vals`.

# Notes
- On Apple M1 systems, `PolyesterForwardDiffGrad` falls back to single-threaded `ForwardDiff` due to closure issues.
- The function is used internally for both site-level and batch-level gradient computation in hybridMachine Learningtraining.

# Example
```julia
grads = gradientSite(ForwardDiffGrad(), x_vals, (; chunk_size=4), loss_f)
```
"""
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

"""
    gradientBatch!(grads_lib, grads_batch, gradient_options::NamedTuple, loss_functions, scaled_params_batch, sites_batch; showprog=false)

Compute gradients for a batch of samples in hybrid (ML) modeling in SINDBAD.

This function computes the gradients of the loss function with respect to model parameters for a batch of sites or samples, using the specified gradient library. It supports both distributed and multi-threaded execution, and can handle different gradient computation backends (e.g., `PolyesterForwardDiff`, `ForwardDiff`, `FiniteDiff`, etc.).

# Arguments
- `grads_lib`: Gradient computation library or method. Supported types include:
    - `PolyesterForwardDiffGrad`: Uses `PolyesterForwardDiff.jl` for multi-threaded chunked gradients.
    - Other `MachineLearningGradType` subtypes: Use their respective backend.
- `grads_batch`: Pre-allocated array for storing batched gradients (size: n_parameters × n_samples).
- `gradient_options`: (Optional) NamedTuple of gradient options (e.g., chunk size).
- `loss_f`: Loss function to be applied (for all samples).
- `loss_functions`: Array or KeyedArray of loss functions, one per site.
- `scaled_params_batch`: Callable or array providing scaled parameters for each site.
- `sites_batch`: List or array of site identifiers for the batch.
- `showprog`: (Optional) If `true`, display a progress bar during computation (default: `false`).

# Returns
- Updates `grads_batch` in-place with computed gradients for each sample in the batch.

# Notes
- The function automatically selects between distributed (`pmap`) and multi-threaded (`Threads.@spawn`) execution depending on the backend and arguments.
- Designed for use within training loops for efficient batch gradient computation.

# Example
```julia
gradientBatch!(grads_lib, grads_batch, (; chunk_size=4,), loss_functions, scaled_params_batch, sites_batch; showprog=true)
```
"""
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

"""
    gradsNaNCheck!(grads_batch, _params_batch, sites_batch, parameter_table; show_params_for_nan=false)

Utility function to check if some calculated gradients were NaN (if found please double check your approach).
This function will replace those NaNs with 0.0f0.

# Arguments
- `grads_batch`: gradients array.
- `_params_batch`: parameters values.
- `sites_batch`: sites names.
- `parameter_table`: parameters table.
- `show_params_for_nan=false`: if true, it will show the parameters that caused the NaNs.
"""
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

"""
    loadTrainedNN(path_model)

# Arguments
- `path_model`: path to the model.
"""
function loadTrainedNN(path_model)
    model_props = JLD2.load(path_model)
    return (;
        trainedNN=model_props["re"](model_props["flat"]), # ? model structure and trained weights
        lower_bound=model_props["lower_bound"],  # ? parameters' attributes    
        upper_bound=model_props["upper_bound"],
        ps_names=model_props["ps_names"],
        metadata_global=model_props["metadata_global"])
end