```@docs
Sindbad.ParameterOptimization
```
## Functions

### combineMetric
```@docs
combineMetric
```

:::details Code

```julia
function combineMetric end

function combineMetric(metric_vector::AbstractArray, ::MetricSum)
    return sum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, ::MetricSum)
    return sum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, ::MetricMinimum)
    return minimum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, ::MetricMaximum)
    return maximum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, percentile_value::T) where {T<:Real}
    return percentile(metric_vector, percentile_value)
end
```

:::


----

### cost
```@docs
cost
```

:::details Code

```julia
function cost end

function cost(parameter_vector, _, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, ::CostModelObs)
    @debug parameter_vector
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    runTEM!(updated_models, space_forcing, space_spinup_forcing, loc_forcing_t, space_output, space_land, tem_info)
    cost_vector = metricVector(output_array, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end

function cost(parameter_vector, _, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, ::CostModelObs)
    @debug parameter_vector
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    runTEM!(updated_models, space_forcing, space_spinup_forcing, loc_forcing_t, space_output, space_land, tem_info)
    cost_vector = metricVector(output_array, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end

function cost(parameter_matrix, _, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, cost_out::Vector, ::CostModelObsMT)
    @debug "parameter_matrix:: ", size(parameter_matrix)
    parameter_set_size = size(parameter_matrix, 2)
    done_params=1
    Threads.@threads for parameter_index in eachindex(1:parameter_set_size)
        idx = Threads.threadid()
        parameter_vector = parameter_matrix[:, parameter_index]
        @debug parameter_vector
        updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
        coreTEM!(updated_models, space_forcing, space_spinup_forcing, loc_forcing_t, space_output[idx], space_land, tem_info)
        cost_vector = metricVector(space_output[idx], observations, cost_options)
        cost_metric = combineMetric(cost_vector, multi_constraint_method)
        cost_out[parameter_index] = cost_metric
        @debug "Parameter column:: ", idx, round(100 * done_params/parameter_set_size,digits=2), parameter_set_size, cost_metric, cost_vector
        done_params += 1
    end
    return cost_out
end

function cost(parameter_vector, default_values, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, ::CostModelObsPriors)
    # prior has to be calculated before the parameters are backscaled and models are updated
    cost_prior = metric(MSE(), parameter_vector, parameter_vector, default_values)
    cost_metric = cost(parameter_vector, default_values, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, CostModelObs())
    cost_metric = cost_metric + cost_prior
    @debug cost_vector, cost_metric
    return cost_metric
end

function cost(parameter_vector, default_values, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    cost_metric = cost(parameter_vector, default_values, selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, output_array, space_output, space_land, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, CostModelObs())
    return cost_metric
end

function costLand end

function costLand(parameter_vector::AbstractArray, selected_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    land_wrapper_timeseries = runTEM(updated_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info)
    cost_vector = metricVector(land_wrapper_timeseries, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end

function costLand(parameter_vector::AbstractArray, selected_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    land_wrapper_timeseries = runTEM(updated_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info)
    cost_vector = metricVector(land_wrapper_timeseries, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end

function costLand(parameter_vector::AbstractArray, selected_models, forcing, spinup_forcing, loc_forcing_t, ::Nothing, land_init, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    land_wrapper_timeseries = runTEM(updated_models, forcing, spinup_forcing, loc_forcing_t, land_init, tem_info)
    cost_vector = metricVector(land_wrapper_timeseries, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end
```

:::


----

### costLand
```@docs
costLand
```

:::details Code

```julia
function costLand end

function costLand(parameter_vector::AbstractArray, selected_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    land_wrapper_timeseries = runTEM(updated_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info)
    cost_vector = metricVector(land_wrapper_timeseries, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end

function costLand(parameter_vector::AbstractArray, selected_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    land_wrapper_timeseries = runTEM(updated_models, forcing, spinup_forcing, loc_forcing_t, land_timeseries, land_init, tem_info)
    cost_vector = metricVector(land_wrapper_timeseries, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end

function costLand(parameter_vector::AbstractArray, selected_models, forcing, spinup_forcing, loc_forcing_t, ::Nothing, land_init, tem_info, observations, parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type)
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    land_wrapper_timeseries = runTEM(updated_models, forcing, spinup_forcing, loc_forcing_t, land_init, tem_info)
    cost_vector = metricVector(land_wrapper_timeseries, observations, cost_options)
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    @debug cost_vector, cost_metric
    return cost_metric
end
```

:::


----

### getCostVectorSize
```@docs
getCostVectorSize
```

:::details Code

```julia
function getCostVectorSize end

function getCostVectorSize(algo_options, parameter_vector, ::CMAEvolutionStrategyCMAES)
    cost_vector_size = Threads.nthreads()
    if hasproperty(algo_options, :multi_threading)
        if algo_options.multi_threading
            if hasproperty(algo_options, :popsize)
                cost_vector_size = algo_options.popsize
            else
                cost_vector_size = 4 + floor(Int, 3 * log(length(parameter_vector)))
            end
        end
    end
    return cost_vector_size
end

function getCostVectorSize(algo_options, parameter_vector, ::CMAEvolutionStrategyCMAES)
    cost_vector_size = Threads.nthreads()
    if hasproperty(algo_options, :multi_threading)
        if algo_options.multi_threading
            if hasproperty(algo_options, :popsize)
                cost_vector_size = algo_options.popsize
            else
                cost_vector_size = 4 + floor(Int, 3 * log(length(parameter_vector)))
            end
        end
    end
    return cost_vector_size
end

function getCostVectorSize(algo_options, __precompile__, ::GSAMorris)
    default_opt = sindbadDefaultOptions(GSAMorris())
    num_trajectory = default_opt.num_trajectory
    len_design_mat = default_opt.len_design_mat
    if hasproperty(algo_options, :num_trajectory)
        num_trajectory = algo_options.num_trajectory
    end
    if hasproperty(algo_options, :len_design_mat)
        len_design_mat = algo_options.len_design_mat
    end
    cost_vector_size = num_trajectory * len_design_mat
    return cost_vector_size
end

function getCostVectorSize(algo_options, parameter_vector, ::GSASobol)
    default_opt = sindbadDefaultOptions(GSASobol())
    samples = default_opt.samples
    nparam = length(parameter_vector)
    norder = length(algo_options.method_options.order) - 1
    if hasproperty(algo_options, :samples)
        samples = algo_options.samples
    end
    cost_vector_size = samples * (norder * nparam + 2)
    return cost_vector_size
end

function getCostVectorSize(algo_options, parameter_vector, ::GSASobolDM)
    return getCostVectorSize(algo_options, parameter_vector, GSASobol())
end
```

:::


----

### getDataWithoutNaN
```@docs
getDataWithoutNaN
```

:::details Code

```julia
function getDataWithoutNaN end

function getDataWithoutNaN(y, yσ, ŷ, idxs)
    y_view = @view y[idxs] 
    yσ_view = @view yσ[idxs] 
    ŷ_view = @view ŷ[idxs] 
    return (y_view, yσ_view, ŷ_view)
end

function getDataWithoutNaN(y, yσ, ŷ, idxs)
    y_view = @view y[idxs] 
    yσ_view = @view yσ[idxs] 
    ŷ_view = @view ŷ[idxs] 
    return (y_view, yσ_view, ŷ_view)
end

function getDataWithoutNaN(y, yσ, ŷ)
    @debug sum(is_invalid_number.(y)), sum(is_invalid_number.(yσ)), sum(is_invalid_number.(ŷ))
    idxs = (.!isnan.(y .* yσ .* ŷ)) # TODO this has to be run because LandWrapper produces a vector. So, dispatch with the inefficient versions without idxs argument
    return y[idxs], yσ[idxs], ŷ[idxs]
end
```

:::


----

### globalSensitivity
```@docs
globalSensitivity
```

:::details Code

```julia
function globalSensitivity end

function globalSensitivity(cost_function, method_options, p_bounds, ::GSAMorris; batch=true)
    results = gsa(cost_function, Morris(; method_options...), p_bounds, batch=batch)
    return results
end

function globalSensitivity(cost_function, method_options, p_bounds, ::GSAMorris; batch=true)
    results = gsa(cost_function, Morris(; method_options...), p_bounds, batch=batch)
    return results
end

function globalSensitivity(cost_function, method_options, p_bounds, ::GSASobol; batch=true)
    sampler = getproperty(Sindbad.ParameterOptimization.GlobalSensitivity, Symbol(method_options.sampler))(; method_options.sampler_options..., method_options.method_options... )
    results = gsa(cost_function, sampler, p_bounds; method_options..., batch=batch)
    return results
end

function globalSensitivity(cost_function, method_options, p_bounds, ::GSASobolDM; batch=true)
    sampler = getproperty(Sindbad.ParameterOptimization.GlobalSensitivity, Symbol(method_options.sampler))(; method_options.sampler_options...)
    samples = method_options.samples
    lb = first.(p_bounds)
    ub = last.(p_bounds)
    A, B = QuasiMonteCarlo.generate_design_matrices(samples, lb, ub, sampler)
    results = gsa(cost_function, Sobol(; method_options.method_options...), A, B; method_options..., batch=batch)
    return results
end
```

:::


----

### metricVector
```@docs
metricVector
```

:::details Code

```julia
function metricVector end

function metricVector(model_output, observations, cost_options)
    loss_vector = map(cost_options) do cost_option
        @debug "***cost for $(cost_option.variable)***"
        lossMetric = cost_option.cost_metric
        (y, yσ, ŷ) = getData(model_output, observations, cost_option)
        (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
        @debug "size y, yσ, ŷ", size(y), size(yσ), size(ŷ)
        # (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
        metr = metric(lossMetric, ŷ, y, yσ) * cost_option.cost_weight
        if isnan(metr)
            metr = oftype(metr, 1e19)
        end
        @debug "$(cost_option.variable) => $(nameof(typeof(lossMetric))): $(metr)"
        metr
    end
    @debug "\n-------------------\n"
    return loss_vector
end

function metricVector(model_output, observations, cost_options)
    loss_vector = map(cost_options) do cost_option
        @debug "***cost for $(cost_option.variable)***"
        lossMetric = cost_option.cost_metric
        (y, yσ, ŷ) = getData(model_output, observations, cost_option)
        (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
        @debug "size y, yσ, ŷ", size(y), size(yσ), size(ŷ)
        # (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
        metr = metric(lossMetric, ŷ, y, yσ) * cost_option.cost_weight
        if isnan(metr)
            metr = oftype(metr, 1e19)
        end
        @debug "$(cost_option.variable) => $(nameof(typeof(lossMetric))): $(metr)"
        metr
    end
    @debug "\n-------------------\n"
    return loss_vector
end

function metricVector(model_output::LandWrapper, observations, cost_options)
    loss_vector = map(cost_options) do cost_option
        @debug "$(cost_option.variable)"
        lossMetric = cost_option.cost_metric
        (y, yσ, ŷ) = getData(model_output, observations, cost_option)
        @debug "size y, yσ, ŷ", size(y), size(yσ), size(ŷ), size(idxs)
        (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ) ## cannot use the valids because LandWrapper produces vector
        metr = metric(lossMetric, ŷ, y, yσ) * cost_option.cost_weight
        if isnan(metr)
            metr = oftype(metr, 1e19)
        end
        @debug "$(cost_option.variable) => $(nameof(typeof(lossMetric))): $(metr)"
        metr
    end
    @debug "\n-------------------\n"
    return loss_vector
end
```

:::


----

### optimizeTEM
```@docs
optimizeTEM
```

:::details Code

```julia
function optimizeTEM end

function optimizeTEM(forcing::NamedTuple, observations, info::NamedTuple)
    # get the subset of parameters table that consists of only optimized parameters
    opti_helpers = prepOpti(forcing, observations, info, info.optimization.run_options.cost_method)

    # run the optimizer
    optim_para = optimizer(opti_helpers.cost_function, opti_helpers.default_values, opti_helpers.lower_bounds, opti_helpers.upper_bounds, info.optimization.optimizer.options, info.optimization.optimizer.method)

    optim_para = backScaleParameters(optim_para, opti_helpers.parameter_table, info.optimization.run_options.parameter_scaling)

    # update the parameter table with the optimized values
    opti_helpers.parameter_table.optimized .= optim_para
    return opti_helpers.parameter_table
end

function optimizeTEM(forcing::NamedTuple, observations, info::NamedTuple)
    # get the subset of parameters table that consists of only optimized parameters
    opti_helpers = prepOpti(forcing, observations, info, info.optimization.run_options.cost_method)

    # run the optimizer
    optim_para = optimizer(opti_helpers.cost_function, opti_helpers.default_values, opti_helpers.lower_bounds, opti_helpers.upper_bounds, info.optimization.optimizer.options, info.optimization.optimizer.method)

    optim_para = backScaleParameters(optim_para, opti_helpers.parameter_table, info.optimization.run_options.parameter_scaling)

    # update the parameter table with the optimized values
    opti_helpers.parameter_table.optimized .= optim_para
    return opti_helpers.parameter_table
end

function optimizeTEMYax(forcing::NamedTuple, observations::NamedTuple, info; max_cache=1e9)
    incubes = (forcing.data..., observations.data...)
    indims = (forcing.dims..., observations.dims...)
    forcing_vars = collect(forcing.variables)
    outdims = info.output.parameter_dim
    out = output.land_init
    obs_vars = collect(observations.variables)

    params = mapCube(optimizeYax, (incubes...,); out=out, info=info, forcing_vars=forcing_vars, obs_vars=obs_vars, indims=indims, outdims=outdims, max_cache=max_cache)
    return params
end
```

:::


----

### optimizeTEMYax
```@docs
optimizeTEMYax
```

:::details Code

```julia
function optimizeTEMYax(forcing::NamedTuple, observations::NamedTuple, info; max_cache=1e9)
    incubes = (forcing.data..., observations.data...)
    indims = (forcing.dims..., observations.dims...)
    forcing_vars = collect(forcing.variables)
    outdims = info.output.parameter_dim
    out = output.land_init
    obs_vars = collect(observations.variables)

    params = mapCube(optimizeYax, (incubes...,); out=out, info=info, forcing_vars=forcing_vars, obs_vars=obs_vars, indims=indims, outdims=outdims, max_cache=max_cache)
    return params
end
```

:::


----

### optimizer
```@docs
optimizer
```

:::details Code

```julia
function optimizer(::Any, default_values::Any, ::Any, ::Any, ::Any, x::ParameterOptimizationMethod)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    Optimizer `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This algorithm is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    Optimizer `$(nameof(typeof(x)))` not implemented.

    To implement a new optimizer:

    - First add a new type as a subtype of `ParameterOptimizationMethod` in `src/Types/ParameterOptimizationTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/ParameterOptimization/optimizer.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/ParameterOptimizationOptimizer.jl` extension.

    ")
    end
    return
end
```

:::


----

### prepOpti
```@docs
prepOpti
```

:::details Code

```julia
function prepOpti end

function prepOpti(forcing, observations, info)
    return prepOpti(forcing, observations, info, CostModelObs())
end

function prepOpti(forcing, observations, info)
    return prepOpti(forcing, observations, info, CostModelObs())
end

function  prepOpti(forcing, observations, info, ::CostModelObsMT; algorithm_info_field=:optimizer)
    algorithm_info = getproperty(info.optimization, algorithm_info_field)
    opti_helpers = prepOpti(forcing, observations, info, CostModelObs())
    run_helpers = opti_helpers.run_helpers
    cost_vector_size = getCostVectorSize(getproperty(algorithm_info, :options), opti_helpers.default_values, getproperty(algorithm_info, :method))
    cost_vector = Vector{eltype(opti_helpers.default_values)}(undef, cost_vector_size)
    
    space_index = 1 # the parallelization of cost computation only runs in single pixel runs

    cost_function = x -> cost(x, opti_helpers.default_values, info.models.forward, run_helpers.space_forcing[space_index], run_helpers.space_spinup_forcing[space_index], run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output_mt, deepcopy(run_helpers.space_land[space_index]), run_helpers.tem_info, observations, opti_helpers.parameter_table, opti_helpers.cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, cost_vector, info.optimization.run_options.cost_method)

    opti_helpers = (; opti_helpers..., cost_function=cost_function, cost_vector=cost_vector)
    return opti_helpers
end

function  prepOpti(forcing, observations, info, ::CostModelObsLandTS)
    opti_helpers = prepOpti(forcing, observations, info, CostModelObs())
    run_helpers = opti_helpers.run_helpers

    cost_function = x -> costLand(x, info.models.forward, run_helpers.loc_forcing, run_helpers.loc_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.land_time_series, run_helpers.loc_land, run_helpers.tem_info, observations, opti_helpers.parameter_table, opti_helpers.cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling)

    opti_helpers = (; opti_helpers..., cost_function=cost_function)
    
    return opti_helpers
end

function  prepOpti(forcing, observations, info, cost_method::CostModelObs)
    run_helpers = prepTEM(forcing, info)

    parameter_helpers = prepParameters(info.optimization.parameter_table, info.optimization.run_options.parameter_scaling)
    
    parameter_table = parameter_helpers.parameter_table
    default_values = parameter_helpers.default_values
    lower_bounds = parameter_helpers.lower_bounds
    upper_bounds = parameter_helpers.upper_bounds

    cost_options = prepCostOptions(observations, info.optimization.cost_options, cost_method)

    cost_function = x -> cost(x, default_values, info.models.forward, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output, deepcopy(run_helpers.space_land), run_helpers.tem_info, observations, parameter_table, cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, cost_method)

    opti_helpers = (; parameter_table=parameter_table, cost_function=cost_function, cost_options=cost_options, default_values=default_values, lower_bounds=lower_bounds, upper_bounds=upper_bounds, run_helpers=run_helpers)
    
    return opti_helpers
end
```

:::


----

### prepParameters
```@docs
prepParameters
```

:::details Code

```julia
function prepParameters(parameter_table, parameter_scaling)
    
    default_values, lower_bounds, upper_bounds = scaleParameters(parameter_table, parameter_scaling)

    parameter_helpers = (; parameter_table=parameter_table, default_values=default_values, lower_bounds=lower_bounds, upper_bounds=upper_bounds)
    return parameter_helpers
end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.ParameterOptimization
end
```
