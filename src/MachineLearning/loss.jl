export loss
export lossVector
export lossComponents
export epochLossComponents

"""
    lossVector(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, ::LossModelObsMachineLearning)

Calculate the loss vector for a given site in hybrid (ML) modeling in SINDBAD.

This function runs the core TEM model with the provided parameters, forcing data, initial land state, and model information, then computes the loss vector using the specified cost options and metrics. It is typically used for site-level loss evaluation during training and validation.

# Arguments
- `params`: Model parameters (in this case, output from anMachine Learningmodel).
- `models`: List of process-based models.
- `parameter_to_index`: Mapping from parameter names to indices.
- `parameter_scaling_type`: Parameter scaling configuration.
- `loc_forcing`: Forcing data for the site.
- `loc_spinup`: A NT with the spinup `sequence` of the site and the `forcing` derived from it.
- `loc_forcing_t`: Forcing data for a single time step.
- `loc_output`: Output data structure for the site.
- `land_init`: Initial land state.
- `tem_info`: Model information and configuration.
- `loc_obs`: Observation data for the site.
- `cost_options`: Cost function and metric configuration.
- `constraint_method`: Constraint method for combining metrics.
- `gradient_lib`: Gradient computation library or method.
- `::LossModelObsMachineLearning`: Type dispatch for loss model with observations and machine learning.

# Returns
- `loss_vector`: Vector of loss components for the site.
- `loss_indices`: Indices corresponding to each loss component.

# Notes
- This function is used internally by higher-level loss and training routines.
- The loss vector is typically combined into a scalar loss using `combineMetric`.

# Example
```julia
loss_vec, loss_idx = lossVector(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, LossModelObsMachineLearning())
```
"""
function lossVector(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,::LossModelObsMachineLearning)
    loc_output_from_cache = getOutputFromCache(loc_output, params, gradient_lib)
    models = updateModels(params, parameter_to_index, parameter_scaling_type, models)
    coreTEM!(
        models,
        loc_forcing,
        loc_spinup,
        loc_forcing_t,
        loc_output_from_cache,
        land_init,
        tem_info)
    loss_vector = metricVector(loc_output_from_cache, loc_obs, cost_options)
    loss_indices = cost_options.obs_sn
    return loss_vector, loss_indices
end

"""
    loss(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, ::LossModelObsMachineLearning)

Calculates the scalar loss for a given site in hybrid (ML) modeling in SINDBAD.

This function computes the loss value for a given site by first calling `lossVector` to obtain the vector of loss components, and then combining them into a scalar loss using the `combineMetric` function and the specified constraint method.

# Arguments
- `params`: Model parameters (typically output from anMachine Learningmodel).
- `models`: List of process-based models.
- `parameter_to_index`: Mapping from parameter names to indices.
- `parameter_scaling_type`: Parameter scaling configuration.
- `loc_forcing`: Forcing data for the site.
- `loc_spinup`: A NT with the spinup `sequence` of the site and the `forcing` derived from it.
- `loc_forcing_t`: Forcing data for a single time step.
- `loc_output`: Output data structure for the site.
- `land_init`: Initial land state.
- `tem_info`: Model information and configuration.
- `loc_obs`: Observation data for the site.
- `cost_options`: Cost function and metric configuration.
- `constraint_method`: Constraint method for combining metrics.
- `gradient_lib`: Gradient computation library or method.
- `::LossModelObsMachineLearning`: Type dispatch for loss model with observations and machine learning.

# Returns
- `t_loss`: Scalar loss value for the site.

# Notes
- This function is used internally by higher-level training and evaluation routines.
- The loss is computed by aggregating the loss vector using the specified constraint method.

# Example
```julia
t_loss = loss(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, LossModelObsMachineLearning())
```
"""
function loss(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,loss_type::LossModelObsMachineLearning)
    loss_vector, _ = lossVector(params, models,parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, loss_type)
    t_loss = combineMetric(loss_vector, constraint_method)
    return t_loss
end

function lossComponents(params, models, parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib,loss_type::LossModelObsMachineLearning)
    loss_vector, loss_indices = lossVector(params, models,parameter_to_index, parameter_scaling_type, loc_forcing, loc_spinup, loc_forcing_t, loc_output, land_init, tem_info, loc_obs, cost_options, constraint_method, gradient_lib, loss_type)
    t_loss = combineMetric(loss_vector, constraint_method)
    return t_loss, loss_vector, loss_indices
end

"""
    epochLossComponents(loss_functions::F, loss_array_sites, loss_array_components, epoch_number, scaled_params, sites_list) where {F}

Compute and store the loss metrics and loss components for each site in parallel for a given training epoch.

This function evaluates the provided loss functions for each site using the current scaled parameters, and stores the resulting scalar loss metrics and loss component vectors in the corresponding arrays for the specified epoch. Parallel execution is used to accelerate computation across sites.

# Arguments
- `loss_functions::F`: An array or KeyedArray of loss functions, one per site (where `F` is a subtype of `AbstractArray{<:Function}`).
- `loss_array_sites`: A matrix to store the scalar loss metric for each site and epoch (dimensions: site × epoch).
- `loss_array_components`: A 3D tensor to store the loss components for each site, component, and epoch (dimensions: site × component × epoch).
- `epoch_number`: The current epoch number (integer).
- `scaled_params`: A callable or array providing the scaled parameters for each site (e.g., `scaled_params(site=site_name)`).
- `sites_list`: List or array of site identifiers to process.

# Notes
- The function uses Julia's threading (`Threads.@spawn`) to compute losses for multiple sites in parallel.
- Each site's loss metric and components are stored at the corresponding index for the current epoch.
- Designed for use within training loops to track loss evolution over epochs.

# Example
```julia
epochLossComponents(loss_functions, loss_array_sites, loss_array_components, epoch, scaled_params, sites)
```
"""
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
