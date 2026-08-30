
export setHybridInfo

"""
    replaceOptionsWithType(merged_options, field_name)
Replaces the options in a NamedTuple with their corresponding type instances based on the field name.
# Arguments:
- `merged_options`: A NamedTuple containing merged options.
- `field_name`: The name of the field to be replaced.
# Returns:
- The updated NamedTuple with the specified field replaced by its corresponding type instance.
"""
function replaceOptionsWithType(merged_options, field_name)
    if hasproperty(merged_options, field_name)
        field_value = getfield(merged_options, field_name)
        if isa(field_value, String) && !isempty(field_value)
            merged_options = set_namedtuple_field(merged_options, (field_name, getTypeInstanceForNamedOptions(field_value)))
        end
    end
    return merged_options
end

"""
    replaceNumbersWithTypedValues(merged_options, num_type)

Replaces non-integer numeric values in a NamedTuple with their corresponding typed values.

# Arguments:
- `merged_options`: A NamedTuple containing merged options.
- `num_type`: The numeric type to use for conversion.

# Returns:
- The updated NamedTuple with numeric values converted to the specified numeric type.
"""
function replaceNumbersWithTypedValues(merged_options, num_type)
    foreach(propertynames(merged_options)) do field_name
        pp = getproperty(merged_options, field_name)
        if (isa(pp, Number) || isa(pp, AbstractArray)) && !isa(pp, Int)
            if isa(pp, AbstractArray)
                pp = Tuple(num_type.(pp))
            else    
                pp = num_type(pp)
            end
        end
        merged_options = set_namedtuple_field(merged_options, (field_name, pp))
    end
    return merged_options
end
"""

    setHybridOptions(info::NamedTuple, which_option)
Processes and sets the machine learning options for hybrid experiments.
# Arguments:
- `info`: A NamedTuple containing the experiment configuration.
- `which_option`: The name of the option to process ("ml_model", "ml_training", etc.).
# Returns:
- The updated `info` NamedTuple with the specified machine learning option added.
"""
function setHybridOptions(info, which_option)
    ml_field = getproperty(info.settings.hybrid, which_option)
    tmp_field = (;)
    field_options = (;)
    field_method = nothing
    if !isnothing(ml_field)
        if isa(ml_field, String)
            if endswith(ml_field, ".json")
                options_path = ml_field
                if !isabspath(options_path)
                    options_path = joinpath(info.temp.experiment.dirs.settings, options_path)
                end
                options = parsefile(options_path; dicttype=DataStructures.OrderedDict)
                options = dict_to_namedtuple(options)
                field_method = options.package * "_" * options.method
                field_method = getTypeInstanceForNamedOptions(field_method)
                field_options = options.options
            else
                field_method = getTypeInstanceForNamedOptions(ml_field)
            end
        else
            options = ml_field
            field_method = getTypeInstanceForNamedOptions(getfield(options, :package) * "_" * getfield(options, :method))
            if hasproperty(options, :options)
                field_options = getfield(options, :options)
            else
                field_options = (;)
            end
        end
    end
    default_opt = sindbadDefaultOptions(getproperty(Setup, nameof(typeof(field_method)))())
    merged_options = merge_namedtuple(default_opt, field_options)
    merged_options = replaceOptionsWithType(merged_options, :activation_out)
    merged_options = replaceOptionsWithType(merged_options, :activation_hidden)
    merged_options = replaceOptionsWithType(merged_options, :loss_function)
    merged_options = replaceNumbersWithTypedValues(merged_options, info.temp.helpers.numbers.num_type)
    
    if which_option == :ml_training 
        pullback_method = hasproperty(merged_options, :pullback_method) ? merged_options.pullback_method : "ZygotePullback"
        tmp_field = set_namedtuple_field(tmp_field, (:pullback_method, getTypeInstanceForNamedOptions(pullback_method)))
    end

    if which_option == :ml_optimizer
        update_method = hasproperty(merged_options, :update_method) ? merged_options.update_method : "OptimisersUpdate"
        tmp_field = set_namedtuple_field(tmp_field, (:update_method, getTypeInstanceForNamedOptions(update_method)))
    end

    tmp_field = set_namedtuple_field(tmp_field, (:method, field_method))
    tmp_field = set_namedtuple_field(tmp_field, (:options, merged_options))
    info = set_namedtuple_subfield(info, :hybrid, (which_option, tmp_field))
    return info
end

"""
    setProcessMLModels(info::NamedTuple)

Parses `info.settings.hybrid.process_ml_models`, a NamedTuple keyed by process name
(e.g. `gpp`), into `info.hybrid.process_ml_models`. Each entry carries a `mode` field
("pretrained" today; "trainable" is reserved for a future joint-training dispatch that
reuses this same config shape) plus `package`/`method`/`options`, mirroring the general
shape used by `setHybridOptions` for `ml_model`/`ml_training`/etc.

Unlike `setHybridOptions`, this does not run `options` through
`replaceNumbersWithTypedValues` — that helper assumes every option is a numeric scalar
or a numeric array, which breaks for fields like a `features` list of forcing-variable
names or a `trained_state_path` file path. Only the activation-function options
(`activation_hidden`, `activation_out`) are converted from strings to type instances
via `replaceOptionsWithType`, since `activationFunction` dispatches on a type instance;
everything else is passed through unchanged. `trained_state_path`, if present, is
resolved to an absolute path here (relative to the experiment's settings directory,
the same convention used for `ml_training.fold_path` below) since `define()` only has
access to the narrow per-timestep `helpers`, not the full `info` needed to resolve a
relative path itself.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with `info.hybrid.process_ml_models` added (only if
  `info.settings.hybrid.process_ml_models` is configured).
"""
function setProcessMLModels(info)
    if hasproperty(info.settings.hybrid, :process_ml_models)
        process_ml_models = (;)
        for process_name in propertynames(info.settings.hybrid.process_ml_models)
            ml_field = getproperty(info.settings.hybrid.process_ml_models, process_name)
            mode = hasproperty(ml_field, :mode) ? ml_field.mode : "pretrained"
            merged_options = hasproperty(ml_field, :options) ? ml_field.options : (;)
            merged_options = replaceOptionsWithType(merged_options, :activation_out)
            merged_options = replaceOptionsWithType(merged_options, :activation_hidden)
            if hasproperty(merged_options, :trained_state_path)
                state_path = merged_options.trained_state_path
                if !isabspath(state_path)
                    state_path = joinpath(info.temp.experiment.dirs.settings, state_path)
                end
                merged_options = set_namedtuple_field(merged_options, (:trained_state_path, state_path))
            end
            tmp_field = (;)
            tmp_field = set_namedtuple_field(tmp_field, (:mode, mode))
            tmp_field = set_namedtuple_field(tmp_field, (:package, hasproperty(ml_field, :package) ? ml_field.package : nothing))
            tmp_field = set_namedtuple_field(tmp_field, (:method, hasproperty(ml_field, :method) ? ml_field.method : nothing))
            tmp_field = set_namedtuple_field(tmp_field, (:options, merged_options))
            process_ml_models = set_namedtuple_field(process_ml_models, (process_name, tmp_field))
        end
        info = set_namedtuple_subfield(info, :hybrid, (:process_ml_models, process_ml_models))
    end
    return info
end

"""
    setHybridInfo(info::NamedTuple)
Processes and sets up the hybrid experiment information in the experiment configuration.
# Arguments:
- `info`: A NamedTuple containing the experiment configuration.
# Returns:
- The updated `info` NamedTuple with hybrid experiment information added.
"""
function setHybridInfo(info::NamedTuple)
    print_info(setHybridInfo, @__FILE__, @__LINE__, "setting info for hybrid machine-learning + TEM experiment...", n_m=1)
    # hybrid_options = info.settings.hybrid
    # set
    info = setProcessMLModels(info)
    if hasproperty(info.settings.hybrid, :ml_model)
        info = setHybridOptions(info, :ml_model)
        info = setHybridOptions(info, :ml_training)
        info = setHybridOptions(info, :ml_gradient)
        info = setHybridOptions(info, :ml_optimizer)
        checkpoint_path = ""
        hybrid_root = joinpath(dirname(info.output.dirs.data),"hybrid")
        mkpath(hybrid_root)
        if info.settings.hybrid.save_checkpoint
            checkpoint_path = joinpath(hybrid_root,"training_checkpoints")
            mkpath(checkpoint_path)
        end



        output_dirs = info.temp.output.dirs
        output_dirs = (; output_dirs..., hybrid=(; root=hybrid_root, checkpoint=checkpoint_path))
        info = (; info..., temp = (info.temp..., output = (; info.temp.output..., dirs = output_dirs)))

        fold_type = CalcFoldFromSplit()
        fold_path = ""
        which_fold = 1
        ml_training = info.settings.hybrid.ml_training
        if hasproperty(ml_training, :fold_path)
            fold_path_file = ml_training.fold_path
            fold_path = isnothing(fold_path_file) ? fold_path : fold_path_file
            if !isempty(fold_path)
                fold_type = LoadFoldFromFile()
                if !isabspath(fold_path)
                    fold_path = joinpath(info.temp.experiment.dirs.settings, fold_path)
                end
            end
        end
        if hasproperty(ml_training, :which_fold)
            which_fold = ml_training.which_fold
        end

        fold_s = (; fold_path, which_fold, fold_type)
        info = set_namedtuple_subfield(info, :hybrid, (:fold, fold_s))

        replace_value_for_gradient = hasproperty(info.settings.hybrid, :replace_value_for_gradient) ? info.settings.hybrid.replace_value_for_gradient : 0.0

        info = set_namedtuple_subfield(info, :hybrid, (:replace_value_for_gradient, info.temp.helpers.numbers.num_type(replace_value_for_gradient)))

        info = set_namedtuple_subfield(info, :hybrid, (:ml_experiment_type, getTypeInstanceForNamedOptions(info.settings.hybrid.ml_experiment_type)))

        covariates_path = getAbsDataPath(info.temp, info.settings.hybrid.covariates.path)
        covariates = (; path=covariates_path, options=info.settings.hybrid.covariates.options)
        info = set_namedtuple_subfield(info, :hybrid, (:covariates, covariates))
        info = set_namedtuple_subfield(info, :hybrid, (:random_seed, info.settings.hybrid.random_seed))
    end

    return info
end
