export trainML

"""
    trainML(hybrid_helpers, ::MachineLearningTrainingType)

Train a machine learning (ML) or hybrid model in SINDBAD using the specified training method.

This function performs the training loop for theMachine Learningmodel, handling batching, gradient computation, optimizer updates, loss calculation, and checkpointing. It supports hybrid modeling workflows where ML-derived parameters are used in process-based models, and is designed to work with the data structures prepared by `prepHybrid`.

# Arguments
- `hybrid_helpers`: NamedTuple containing all prepared data, models, loss functions, indices, features, optimizers, and arrays needed forMachine Learningtraining and evaluation (as returned by `prepHybrid`).
- `::MachineLearningTrainingType`: Type specifying theMachine Learningtraining method to use (e.g., `MixedGradient`).

# Workflow
- Iterates over epochs and batches of training sites.
- For each batch:
    - Extracts features and computes model parameters.
    - Computes gradients using the specified gradient method.
    - Checks for NaNs in gradients and replaces them if needed.
    - Updates model parameters using the optimizer.
- After each epoch:
    - Computes and stores losses and loss components for training, validation, and testing sets.
    - Saves model checkpoints and loss arrays to disk if a checkpoint path is specified.

# Notes
- The function is extensible to support different training strategies via dispatch on `MachineLearningTrainingType`.
- Designed for use with hybrid modeling, whereMachine Learningmodels provide parameters to process-based models.
- Checkpointing enables resuming or analyzing training progress.

# Example
```julia
hybrid_helpers = prepHybrid(forcing, observations, info, MixedGradient())
trainML(hybrid_helpers, MixedGradient())
```
"""
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
