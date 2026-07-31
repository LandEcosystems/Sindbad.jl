```@docs
Sindbad.Experiment
```
## Functions

### prepExperiment
```@docs
prepExperiment
```

:::details Code

```julia
function prepExperiment(sindbad_experiment::String; replace_info=Dict())
    print_figlet_banner("SINDBAD")

    info = getExperimentInfo(sindbad_experiment; replace_info=replace_info)

    print_info_separator()

    forcing = getForcing(info)

    return info, forcing
end
```

:::


----

### runExperiment
```@docs
runExperiment
```

:::details Code

```julia
function runExperiment end

function runExperiment(info::NamedTuple, forcing::NamedTuple, ::DoCalcCost)
    print_info_separator(sep_text="Forward Simulation + Cost Calculation")
    set_log_level()
    observations = getObservation(info, forcing.helpers)
    obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow
    print_info(runExperiment, @__FILE__, @__LINE__, "do forward run...")
    forward_output = runForward(forcing, info, DoNotRunLazy())
    print_info(runExperiment, @__FILE__, @__LINE__, "calculate cost...")
    cost_options = prepCostOptions(obs_array, info.optimization.cost_options)
    loss_vector = metricVector(forward_output, obs_array, cost_options)
    for _cp in Pair.(Pair.(cost_options.variable, nameof.(typeof.(cost_options.cost_metric))),  loss_vector)
        println(_cp)
    end
    set_log_level()
    return (; forcing, info, loss=loss_vector, observation=obs_array, output=forward_output)
end

function runExperiment(info::NamedTuple, forcing::NamedTuple, ::DoCalcCost)
    print_info_separator(sep_text="Forward Simulation + Cost Calculation")
    set_log_level()
    observations = getObservation(info, forcing.helpers)
    obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow
    print_info(runExperiment, @__FILE__, @__LINE__, "do forward run...")
    forward_output = runForward(forcing, info, DoNotRunLazy())
    print_info(runExperiment, @__FILE__, @__LINE__, "calculate cost...")
    cost_options = prepCostOptions(obs_array, info.optimization.cost_options)
    loss_vector = metricVector(forward_output, obs_array, cost_options)
    for _cp in Pair.(Pair.(cost_options.variable, nameof.(typeof.(cost_options.cost_metric))),  loss_vector)
        println(_cp)
    end
    set_log_level()
    return (; forcing, info, loss=loss_vector, observation=obs_array, output=forward_output)
end

function runExperiment(info::NamedTuple, forcing::NamedTuple, ::Union{DoRunForward, DoNotRunOptimization})
    run_output = runForward(forcing, info, info.helpers.run.run_lazy)
    set_log_level()
    return (; forcing, info, output=run_output)
end

function runExperiment(info::NamedTuple, forcing::NamedTuple, ::DoRunOptimization)
    observations = getObservation(info, forcing.helpers)
    additionaldims = setdiff(keys(forcing.helpers.sizes), info.experiment.data_settings.forcing.data_dimension.time)
    run_output = nothing
    if isempty(additionaldims)
        print_info(runExperiment, @__FILE__, @__LINE__, "run optimization per pixel...")
        run_output = optimizeTEMYax(forcing, info.tem, info.optimization, observations; max_cache=info.settings.experiment.exe_rules.yax_max_cache)
    else
        print_info(runExperiment, @__FILE__, @__LINE__, "run optimization for spatial domain...")
        obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow
        optim_params = optimizeTEM(forcing, obs_array, info)
        optim_file_prefix = joinpath(info.output.dirs.optimization, info.experiment.basics.name * "_" * info.experiment.basics.domain)
        print_info(runExperiment, @__FILE__, @__LINE__, "saving optimized parameters to file: $(optim_file_prefix)_model_parameters_optimized.csv")
        CSV.write(optim_file_prefix * "_model_parameters_optimized.csv", optim_params)
        run_output = optim_params
    end
    set_log_level()
    return (; forcing, info, observation=obs_array, parameters=run_output)
end

function runExperimentCost(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    set_log_level(log_level)
    setExperimentMode!(replace_info, :cost)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    cost_output = runExperiment(info, forcing, info.helpers.run.calc_cost)
    set_log_level()
    return cost_output
end

function runExperimentForward(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation")
    set_log_level(log_level)
    setExperimentMode!(replace_info, :forward)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    run_output = runExperiment(info, forcing, info.helpers.run.run_forward)
    output_dims = getOutDims(info, forcing.helpers)
    saveOutCubes(info, values(run_output.output), output_dims, info.output.variables)
    set_log_level()
    return run_output
end

function runExperimentForwardParams(params_vector::Vector, sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation with Input/Optimized Parameters")
    set_log_level(log_level)
    print_info(runExperimentForwardParams, @__FILE__, @__LINE__, "running forward simulation with input/optimized parameters...", n_m=1)
    replace_info = deepcopy(replace_info)
    setExperimentMode!(replace_info, :cost)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)

    default_models = info.models.forward;

    default_output = runForward(default_models, forcing, info, DoNotRunLazy())

    parameter_table = info.optimization.parameter_table;
    optimized_models = updateModelParameters(parameter_table, default_models, params_vector)
    optimized_output = runForward(optimized_models, forcing, info, DoNotRunLazy())

    output_dims = getOutDims(info, forcing.helpers)
    saveOutCubes(info, values(optimized_output), output_dims, info.output.variables)

    forward_output = (; optimized=optimized_output, default=default_output)
    set_log_level()
    return (; forcing, info, output=forward_output)
end

function runExperimentFullOutput(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation + Output of All Variables")
    set_log_level(log_level)
    replace_info = deepcopy(replace_info)
    setExperimentMode!(replace_info, :forward)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    info = @set info.helpers.run.land_output_type = PreAllocArrayAll()
    run_helpers = prepTEM(info.models.forward, forcing, info)
    info = @set info.output.variables = run_helpers.output_vars
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    output_dims = run_helpers.output_dims
    run_output = run_helpers.output_array
    saveOutCubes(info, run_output, output_dims, run_helpers.output_vars)
    set_log_level()
    return (; forcing, info, output=(; Pair.(getUniqueVarNames(run_helpers.output_vars), run_output)...))
end

function runExperimentOpti(sindbad_experiment::String; replace_info=Dict(), log_level=:warn)
    print_info_separator(sep_text="ParameterOptimization Experiment")
    set_log_level(log_level)
    setExperimentMode!(replace_info, :optimization)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    run_helpers = prepTEM(info.models.forward, forcing, info)
    opti_output = runExperiment(info, forcing, info.helpers.run.run_optimization)
    set_log_level(:info)
    fp_output = runExperimentForwardParams(opti_output.parameters.optimized, sindbad_experiment; replace_info=replace_info)
    cost_options = prepCostOptions(opti_output.observation, info.optimization.cost_options)
    loss_vector = metricVector(fp_output.output.optimized, opti_output.observation, cost_options)
    loss_vector_def = metricVector(fp_output.output.default, opti_output.observation, cost_options)
    loss_table = Table((; variable=cost_options.variable, metric=cost_options.cost_metric, loss_opt=loss_vector, loss_def=loss_vector_def))
    display(loss_table)
    parameters_nt = convertParametersToNamedTuple(opti_output.parameters, :model, :name)
    return (; forcing, cost_options, run_helpers, info=fp_output.info, loss=loss_table, observation=opti_output.observation, output=fp_output.output, parameters=opti_output.parameters, parameters_nt=parameters_nt)
end

function runExperimentSensitivity(sindbad_experiment::String; replace_info=Dict(), batch=true, log_level=:warn)
    print_info_separator(sep_text="Sensitivity Analysis Experiment")
    setExperimentMode!(replace_info, :optimization)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    observations = getObservation(info, forcing.helpers)

    obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow

    opti_helpers = prepOpti(forcing, obs_array, info, info.optimization.run_options.cost_method; algorithm_info_field=:sensitivity_analysis);

    # parameter_table = opti_helpers.parameter_table
    p_bounds=Tuple.(Pair.(opti_helpers.lower_bounds,opti_helpers.upper_bounds))
    
    cost_function = opti_helpers.cost_function

    # d_opt = getproperty(Setup, :GSAMorris)()
    method_options =info.optimization.sensitivity_analysis.options
    set_log_level(log_level)

    sensitivity = globalSensitivity(cost_function, method_options, p_bounds, info.optimization.sensitivity_analysis.method, batch=batch)
    sensitivity_output = (; opti_helpers..., info=info, forcing=forcing, obs_array=obs_array, observations=observations,sensitivity=sensitivity, p_bounds=p_bounds)
    set_log_level(:info)
    sensitivity_output_file = joinpath(info.output.dirs.data, "sensitivity_analysis_$(nameof(typeof(info.optimization.sensitivity_analysis.method)))_$(length(opti_helpers.cost_vector))-cost_evals.jld2")
    print_info(runExperimentSensitivity, @__FILE__, @__LINE__, "saving sensitivity output to file: `$(sensitivity_output_file)`", n_m=1)
    @save  sensitivity_output_file sensitivity_output
    return sensitivity_output
end
```

:::


----

### runExperimentCost
```@docs
runExperimentCost
```

:::details Code

```julia
function runExperimentCost(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    set_log_level(log_level)
    setExperimentMode!(replace_info, :cost)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    cost_output = runExperiment(info, forcing, info.helpers.run.calc_cost)
    set_log_level()
    return cost_output
end
```

:::


----

### runExperimentForward
```@docs
runExperimentForward
```

:::details Code

```julia
function runExperimentForward(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation")
    set_log_level(log_level)
    setExperimentMode!(replace_info, :forward)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    run_output = runExperiment(info, forcing, info.helpers.run.run_forward)
    output_dims = getOutDims(info, forcing.helpers)
    saveOutCubes(info, values(run_output.output), output_dims, info.output.variables)
    set_log_level()
    return run_output
end

function runExperimentForwardParams(params_vector::Vector, sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation with Input/Optimized Parameters")
    set_log_level(log_level)
    print_info(runExperimentForwardParams, @__FILE__, @__LINE__, "running forward simulation with input/optimized parameters...", n_m=1)
    replace_info = deepcopy(replace_info)
    setExperimentMode!(replace_info, :cost)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)

    default_models = info.models.forward;

    default_output = runForward(default_models, forcing, info, DoNotRunLazy())

    parameter_table = info.optimization.parameter_table;
    optimized_models = updateModelParameters(parameter_table, default_models, params_vector)
    optimized_output = runForward(optimized_models, forcing, info, DoNotRunLazy())

    output_dims = getOutDims(info, forcing.helpers)
    saveOutCubes(info, values(optimized_output), output_dims, info.output.variables)

    forward_output = (; optimized=optimized_output, default=default_output)
    set_log_level()
    return (; forcing, info, output=forward_output)
end
```

:::


----

### runExperimentForwardParams
```@docs
runExperimentForwardParams
```

:::details Code

```julia
function runExperimentForwardParams(params_vector::Vector, sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation with Input/Optimized Parameters")
    set_log_level(log_level)
    print_info(runExperimentForwardParams, @__FILE__, @__LINE__, "running forward simulation with input/optimized parameters...", n_m=1)
    replace_info = deepcopy(replace_info)
    setExperimentMode!(replace_info, :cost)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)

    default_models = info.models.forward;

    default_output = runForward(default_models, forcing, info, DoNotRunLazy())

    parameter_table = info.optimization.parameter_table;
    optimized_models = updateModelParameters(parameter_table, default_models, params_vector)
    optimized_output = runForward(optimized_models, forcing, info, DoNotRunLazy())

    output_dims = getOutDims(info, forcing.helpers)
    saveOutCubes(info, values(optimized_output), output_dims, info.output.variables)

    forward_output = (; optimized=optimized_output, default=default_output)
    set_log_level()
    return (; forcing, info, output=forward_output)
end
```

:::


----

### runExperimentFullOutput
```@docs
runExperimentFullOutput
```

:::details Code

```julia
function runExperimentFullOutput(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    print_info_separator(sep_text="Forward Simulation + Output of All Variables")
    set_log_level(log_level)
    replace_info = deepcopy(replace_info)
    setExperimentMode!(replace_info, :forward)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    info = @set info.helpers.run.land_output_type = PreAllocArrayAll()
    run_helpers = prepTEM(info.models.forward, forcing, info)
    info = @set info.output.variables = run_helpers.output_vars
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    output_dims = run_helpers.output_dims
    run_output = run_helpers.output_array
    saveOutCubes(info, run_output, output_dims, run_helpers.output_vars)
    set_log_level()
    return (; forcing, info, output=(; Pair.(getUniqueVarNames(run_helpers.output_vars), run_output)...))
end
```

:::


----

### runExperimentOpti
```@docs
runExperimentOpti
```

:::details Code

```julia
function runExperimentOpti(sindbad_experiment::String; replace_info=Dict(), log_level=:warn)
    print_info_separator(sep_text="ParameterOptimization Experiment")
    set_log_level(log_level)
    setExperimentMode!(replace_info, :optimization)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    run_helpers = prepTEM(info.models.forward, forcing, info)
    opti_output = runExperiment(info, forcing, info.helpers.run.run_optimization)
    set_log_level(:info)
    fp_output = runExperimentForwardParams(opti_output.parameters.optimized, sindbad_experiment; replace_info=replace_info)
    cost_options = prepCostOptions(opti_output.observation, info.optimization.cost_options)
    loss_vector = metricVector(fp_output.output.optimized, opti_output.observation, cost_options)
    loss_vector_def = metricVector(fp_output.output.default, opti_output.observation, cost_options)
    loss_table = Table((; variable=cost_options.variable, metric=cost_options.cost_metric, loss_opt=loss_vector, loss_def=loss_vector_def))
    display(loss_table)
    parameters_nt = convertParametersToNamedTuple(opti_output.parameters, :model, :name)
    return (; forcing, cost_options, run_helpers, info=fp_output.info, loss=loss_table, observation=opti_output.observation, output=fp_output.output, parameters=opti_output.parameters, parameters_nt=parameters_nt)
end
```

:::


----

### runExperimentSensitivity
```@docs
runExperimentSensitivity
```

:::details Code

```julia
function runExperimentSensitivity(sindbad_experiment::String; replace_info=Dict(), batch=true, log_level=:warn)
    print_info_separator(sep_text="Sensitivity Analysis Experiment")
    setExperimentMode!(replace_info, :optimization)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    observations = getObservation(info, forcing.helpers)

    obs_array = [Array(_o) for _o in observations.data]; # TODO: necessary now for performance because view of keyedarray is slow

    opti_helpers = prepOpti(forcing, obs_array, info, info.optimization.run_options.cost_method; algorithm_info_field=:sensitivity_analysis);

    # parameter_table = opti_helpers.parameter_table
    p_bounds=Tuple.(Pair.(opti_helpers.lower_bounds,opti_helpers.upper_bounds))
    
    cost_function = opti_helpers.cost_function

    # d_opt = getproperty(Setup, :GSAMorris)()
    method_options =info.optimization.sensitivity_analysis.options
    set_log_level(log_level)

    sensitivity = globalSensitivity(cost_function, method_options, p_bounds, info.optimization.sensitivity_analysis.method, batch=batch)
    sensitivity_output = (; opti_helpers..., info=info, forcing=forcing, obs_array=obs_array, observations=observations,sensitivity=sensitivity, p_bounds=p_bounds)
    set_log_level(:info)
    sensitivity_output_file = joinpath(info.output.dirs.data, "sensitivity_analysis_$(nameof(typeof(info.optimization.sensitivity_analysis.method)))_$(length(opti_helpers.cost_vector))-cost_evals.jld2")
    print_info(runExperimentSensitivity, @__FILE__, @__LINE__, "saving sensitivity output to file: `$(sensitivity_output_file)`", n_m=1)
    @save  sensitivity_output_file sensitivity_output
    return sensitivity_output
end
```

:::


----

### saveOutCubes
```@docs
saveOutCubes
```

:::details Code

```julia
function saveOutCubes end

function saveOutCubes(data_path_base, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoSaveSingleFile)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file for all variables")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    all_yax = Tuple(getYaxForVariable.(data, data_dims, variable_names, catalog_names, Ref(t_step)))
    data_path = data_path_base * "_all_variables.$(out_format)"
    print_info(nothing, @__FILE__, @__LINE__, "saved all variables to `$(data_path)`", n_m=4)
    ds_new = DataLoaders.YAXArrays.Dataset(; (; zip(variable_names, all_yax)...)..., properties=global_metadata)
    DataLoaders.YAXArrays.savedataset(ds_new, path=data_path, append=true, overwrite=true)
    return nothing
end

function saveOutCubes(data_path_base, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoSaveSingleFile)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file for all variables")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    all_yax = Tuple(getYaxForVariable.(data, data_dims, variable_names, catalog_names, Ref(t_step)))
    data_path = data_path_base * "_all_variables.$(out_format)"
    print_info(nothing, @__FILE__, @__LINE__, "saved all variables to `$(data_path)`", n_m=4)
    ds_new = DataLoaders.YAXArrays.Dataset(; (; zip(variable_names, all_yax)...)..., properties=global_metadata)
    DataLoaders.YAXArrays.savedataset(ds_new, path=data_path, append=true, overwrite=true)
    return nothing
end

function saveOutCubes(data_path_base, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoNotSaveSingleFile)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file per variable")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    for vn ∈ eachindex(var_pairs)
        catalog_name = catalog_names[vn]
        variable_name = variable_names[vn]
        data_yax = getYaxForVariable(data[vn], data_dims[vn], variable_name, catalog_name, t_step)
        data_path = data_path_base * "_$(variable_name).$(out_format)"
        print_info(nothing, @__FILE__, @__LINE__, "saved `$(variable_name)` to `$(data_path)`", n_m=4)
        ds_new = DataLoaders.YAXArrays.Dataset(; (variable_name => data_yax,)..., properties=global_metadata)
        DataLoaders.YAXArrays.savedataset(ds_new, path=data_path, overwrite=true)
    end
    return nothing
end

function saveOutCubes(info, out_cubes, output_dims, output_vars)
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, out_cubes, output_dims, output_vars, info.output.format, info.experiment.basics.temporal_resolution, info.helpers.run.save_single_file)
end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.Experiment
end
```
