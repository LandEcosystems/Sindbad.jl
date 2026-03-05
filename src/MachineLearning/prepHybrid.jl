export getIndicesSplit, getLossFunctionHandles, prepHybrid

"""
    getIndicesSplit(info, sites, fold_type)

Determine the indices for training, validation, and testing site splits for hybrid (ML) modeling in SINDBAD.

This function dispatches on the `fold_type` argument to either load precomputed folds from file or to compute the splits on-the-fly based on the provided split ratios and number of folds.

# Arguments
- `info`: The SINDBAD experiment info structure, containing hybrid modeling configuration.
- `sites`: Array of site identifiers (e.g., site names or indices).
- `fold_type`: Determines the splitting strategy. Use `LoadFoldFromFile()` to load folds from file, or `CalcFoldFromSplit()` to compute splits dynamically.

# Returns
- `indices_training`: Indices of sites assigned to the training set.
- `indices_validation`: Indices of sites assigned to the validation set.
- `indices_testing`: Indices of sites assigned to the testing set.

# Notes
- When using `LoadFoldFromFile`, the function loads fold indices from the file specified in `info.hybrid.fold.fold_path`.
- When using `CalcFoldFromSplit`, the function splits the sites according to the ratios and number of folds specified in `info.hybrid.ml_training.options`.
- Ensures reproducibility by using the random seed from `info.hybrid.random_seed` when shuffling sites.

# Example
```julia
indices_train, indices_val, indices_test = getIndicesSplit(info, sites, info.hybrid.fold.fold_type)
```
"""
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

"""
    getNFolds(sites, train_ratio, val_ratio, test_ratio, n_folds, batch_size; seed=1234)

Partition a list of sites into training, validation, and testing sets for k-fold cross-validation in hybrid (ML) modeling.

This function shuffles the input `sites` array using the provided random `seed` for reproducibility, then splits the sites into `n_folds` folds. It computes the number of sites for each partition based on the provided ratios, ensuring the training set size is a multiple of `batch_size`. The function returns the indices for training, validation, and testing sets, as well as the full list of folds.

# Arguments
- `sites`: Array of site identifiers (e.g., site names or indices).
- `train_ratio`: Fraction of sites to assign to the training set.
- `val_ratio`: Fraction of sites to assign to the validation set.
- `test_ratio`: Fraction of sites to assign to the testing set.
- `n_folds`: Number of folds for cross-validation.
- `batch_size`: Batch size for training; training set size will be rounded down to a multiple of this value.
- `seed`: (Optional) Random seed for reproducibility (default: 1234).

# Returns
- `train_indices`: Array of sites assigned to the training set.
- `val_indices`: Array of sites assigned to the validation set.
- `test_indices`: Array of sites assigned to the testing set.
- `folds`: Vector of arrays, each containing the sites for one fold.

# Notes
- The sum of `train_ratio`, `val_ratio`, and `test_ratio` must be approximately 1.0.
- The returned `folds` can be used for further cross-validation or analysis.

# Example
```julia
train_indices, val_indices, test_indices, folds = getNFolds(sites, 0.7, 0.15, 0.15, 5, 32; seed=42)
```
"""
function getNFolds(sites, train_ratio, val_ratio, test_ratio, n_folds, batch_size; seed=1234)
    @assert train_ratio + val_ratio + test_ratio ≈ 1.0 "Ratios must sum to 1.0"

    num_indices = length(sites)
    fold_size = div(num_indices, n_folds)

    # Set random seed for reproducibility
    Random.seed!(seed)

    # Shuffle sites for random partitioning
    shuffled_indices = shuffle(sites)

    folds = []
    for i in 1:n_folds
        push!(folds, shuffled_indices[(i-1)*fold_size+1:min(i * fold_size, num_indices)])
    end

    # Compute sizes for each partition
    train_size = round(Int, num_indices * train_ratio)
    train_size -= train_size % batch_size  # Ensure train_size is a multiple of batch_size
    val_size = round(Int, num_indices * val_ratio)
    test_size = num_indices - train_size - val_size

    # Split sites into partitions
    train_indices = shuffled_indices[1:train_size]
    val_indices = shuffled_indices[train_size+1:train_size+val_size]
    test_indices = shuffled_indices[train_size+val_size+1:end]

    return train_indices, val_indices, test_indices, folds
end

"""
    getLossFunctionHandles(info, run_helpers, sites)

Construct loss function handles for each site for use in hybrid (ML) modeling in SINDBAD.

This function generates callable loss functions and loss component functions for each site, encapsulating all necessary arguments and configuration from the experiment `info` and runtime helpers. These handles are used during training and evaluation to compute the loss and its components for each site efficiently.

# Arguments
- `info`: The SINDBAD experiment info structure, containing model, optimization, and hybrid configuration.
- `run_helpers`: Helper object returned by `prepTEM`, containing prepared model, forcing, observation, and output structures.
- `sites`: Array of site indices or identifiers for which to build loss functions.

# Returns
- `loss_functions`: A `KeyedArray` of callable loss functions, one per site. Each function takes model parameters as input and returns the scalar loss for that site.
- `loss_component_functions`: A `KeyedArray` of callable functions, one per site, that return the vector of loss components (e.g., for multi-objective or constraint-based loss).

# Notes
- Each loss function is closed over all required data and options for its site, including model structure, parameter indices, scaling, forcing, observations, output cache, cost options, and hybrid/optimization settings.
- The returned arrays are keyed by site for convenient lookup and iteration.

# Example
```julia
loss_functions, loss_component_functions = getLossFunctionHandles(info, run_helpers, sites)
site_loss = loss_functions[site_index](params)
site_loss_components = loss_component_functions[site_index](params)
```
"""
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

"""
    prepHybrid(forcing, observations, info, ::MachineLearningTrainingType)

Prepare all data structures, loss functions, and machine learning components required for hybrid (process-based + machine learning) modeling in SINDBAD.

This function orchestrates the setup for hybrid modeling by:
- Initializing model helpers and runtime structures.
- Building loss function handles for each site.
- Splitting sites into training, validation, and testing sets according to the hybrid configuration.
- Loading covariate features for all sites.
- Building the machine learning model as specified in the configuration.
- Preparing arrays for storing losses and loss components during training and evaluation.
- Initializing the optimizer forMachine Learningtraining.
- Collecting all relevant metadata and configuration into a single `hybrid_helpers` NamedTuple for downstream training routines.

# Arguments
- `forcing`: Forcing data structure as required by the process-based model.
- `observations`: Observational data structure.
- `info`: The SINDBAD experiment info structure, containing all configuration and runtime options.
- `::MachineLearningTrainingType`: Type specifying theMachine Learningtraining method to use (e.g., `MixedGradient`).

# Returns
- `hybrid_helpers`: A NamedTuple containing all prepared data, models, loss functions, indices, features, optimizers, and arrays needed for hybridMachine Learningtraining and evaluation.

## Fields of `hybrid_helpers`
- `run_helpers`: Output of `prepTEM`, containing prepared model, forcing, observation, and output structures.
- `sites`: NamedTuple with `training`, `validation`, and `testing` site arrays.
- `indices`: NamedTuple with indices for `training`, `validation`, and `testing` sites.
- `features`: NamedTuple with `n_features` and `data` (covariate features for all sites).
- `ml_model`: The machine learning model instance (e.g., a Flux neural network).
- `options`: The `info.hybrid` configuration NamedTuple.
- `checkpoint_path`: Path for saving checkpoints during training.
- `parameter_table`: Parameter table from `info.optimization`.
- `loss_functions`: KeyedArray of callable loss functions, one per site.
- `loss_component_functions`: KeyedArray of callable loss component functions, one per site.
- `training_optimizer`: The optimizer object forMachine Learningtraining.
- `loss_array`: NamedTuple of arrays to store scalar losses for training, validation, and testing.
- `loss_array_components`: NamedTuple of arrays to store loss components for training, validation, and testing.
- `metadata_global`: Global metadata from the output configuration.

# Notes
- This function is typically called once at the start of a hybrid modeling experiment to set up all necessary components.
- The returned `hybrid_helpers` is designed to be passed directly to training routines such as `trainML`.

# Example
```julia
hybrid_helpers = prepHybrid(forcing, observations, info, MixedGradient())
trainML(hybrid_helpers, MixedGradient())
```
"""
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