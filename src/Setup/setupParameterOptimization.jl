export getConstraintNames
export getCostOptions
export setOptimization
export prepCostOptions

"""
    checkOptimizedParametersInModels(info::NamedTuple, parameter_table)

Checks if the parameters listed in `model_parameters_to_optimize` from `optimization.json` exist in the selected model structure from `model_structure.json`.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.
- `parameter_table`: A table of parameters extracted from the model structure.

# Notes:
- Issues a warning and throws an error if any parameter in `model_parameters_to_optimize` does not exist in the model structure.
"""
function checkOptimizedParametersInModels(info::NamedTuple, parameter_table)
    model_parameters = parameter_table.name_full
    optim_parameters = info.settings.optimization.model_parameters_to_optimize
    op_names = nothing
    if typeof(optim_parameters) <: Vector
        op_names = replaceCommaSeparatedParams(optim_parameters)
    else
        op_names = replaceCommaSeparatedParams(keys(optim_parameters))
    end

    for omp ∈ eachindex(op_names)
        if op_names[omp] ∉ model_parameters
            @warn "Model Inconsistency: the parameter $(op_names[omp]) does not exist in the selected model structure."
            @show model_parameters
            error(
                "Cannot continue with the model inconsistency. Either delete the invalid parameters in model_parameters_to_optimize of optimization.json, or check model structure to provide correct parameter name"
            )
        end
    end
end

"""
    getAggrFunc(func_name::String)

Returns an aggregation function corresponding to the given function name.

# Arguments:
- `func_name`: A string specifying the name of the aggregation function (e.g., "mean", "sum").

# Returns:
- The corresponding aggregation function (e.g., `mean`, `sum`).

# Notes:
- Supports common aggregation functions such as `mean`, `sum`, `nanmean`, and `nansum`.
"""
function getAggrFunc(func_name::String)
    if func_name == "nanmean"
        return nanmean
    elseif func_name == "nansum"
        return nansum
    elseif func_name == "sum"
        return sum
    else func_name == "mean"
        return mean
    end
end

"""
    getCostOptions(optim_info::NamedTuple, vars_info, tem_variables, number_helpers, dates_helpers)

Sets up cost optimization options based on the provided parameters.

# Arguments:
- `optim_info`: A NamedTuple containing optimization parameters and settings.
- `vars_info`: Information about variables used in optimization.
- `tem_variables`: Template variables for optimization setup.
- `number_helpers`: Helper functions or values for numerical operations.
- `dates_helpers`: Helper functions or values for date-related operations.

# Returns:
- A NamedTuple containing cost optimization configuration options.

# Notes:
- Configures temporal and spatial aggregation, cost metrics, and other optimization-related settings.

# Examples
```jldoctest
julia> using Sindbad

julia> # Setup cost options for optimization
julia> # cost_options = getCostOptions(optim_info, vars_info, tem_variables, number_helpers, dates_helpers)
```
"""
function getCostOptions(optim_info::NamedTuple, vars_info, tem_variables, number_helpers, dates_helpers)
    varlist = Symbol.(optim_info.observational_constraints)
    agg_type = []
    time_aggrs = []
    aggr_funcs = []
    all_costs = map(varlist) do v
        merge_namedtuple_prefer_nonempty(optim_info.observations.default_cost, getfield(getfield(optim_info.observations.variables, v), :cost_options))
    end
    all_options = []
    push!(all_options, varlist)
    prop_names = keys(all_costs[1])
    props_to_keep = (:cost_metric, :spatial_weight, :cost_weight, :temporal_data_aggr, :aggr_obs, :aggr_order, :min_data_points, :spatial_data_aggr, :spatial_cost_aggr, :aggr_func,)
    for (pn, prop) ∈ enumerate(props_to_keep)
        prop_array = []
        for vn ∈ eachindex(varlist)
            sel_opt=all_costs[vn]
            sel_value = sel_opt[prop]
            if (sel_value isa Number) && !(sel_value isa Bool)
                sel_value = number_helpers.num_type(sel_value)
            elseif sel_value isa Bool
                sel_value=getTypeInstanceForFlags(prop, sel_value, "Do")
            elseif sel_value isa String && (prop == :cost_metric)
                sel_value = getTypeInstanceForCostMetric(ErrorMetrics, sel_value)
            elseif sel_value isa String && (prop ∈ (:aggr_order, :spatial_data_aggr))
                sel_value = getTypeInstanceForCostMetric(Types, sel_value)
            end
            push!(prop_array, sel_value)
            if prop == :temporal_data_aggr
                t_a = sel_value
                to_push_type = TimeNoDiff()
                if endswith(lowercase(t_a), "_anomaly") || endswith(lowercase(t_a), "_iav")
                    to_push_type = TimeDiff()
                end
                push!(agg_type, to_push_type)
                push!(time_aggrs, sel_value)
            end
            if prop == :aggr_func
                push!(aggr_funcs, sel_value)
            end
        end
        if prop in props_to_keep
            push!(all_options, prop_array)
        end
    end
    mod_vars = vars_info.model
    mod_field = [Symbol(split(_a, ".")[1]) for _a in mod_vars]
    mod_subfield = [Symbol(split(_a, ".")[2]) for _a in mod_vars]
    mod_ind = collect(1:length(varlist))
    obs_sn = [i for i in mod_ind]
    obs_ind = [i + 3 * (i - 1) for i in mod_ind]

    mod_ind = [findfirst(s -> first(s) === mf && last(s) === msf, tem_variables) for (mf, msf) in zip(mod_field, mod_subfield)]
    # map(cost_option_table) do cost_option
    #     # @show cost_option
    #     new_mod_ind = findfirst(s -> first(s) === cost_option.mod_field && last(s) === cost_option.mod_subfield, tem_variables)
    #     cost_option = Accessors.@set cost_option.mod_ind = new_mod_ind
    # end

    agg_indices = []
    for (i, _aggr) in enumerate(time_aggrs)
        aggr_func = getAggrFunc(aggr_funcs[i])
        _aggr_name = string(_aggr)
        skip_sampling = false
        if startswith(_aggr_name, dates_helpers.temporal_resolution)
            skip_sampling = true
        end
        aggInd = create_TimeSampler(dates_helpers.range, to_uppercase_first(_aggr, "Time"), aggr_func, skip_sampling)
        push!(agg_indices, aggInd)
    end
    push!(all_options, obs_ind)
    push!(all_options, obs_sn)
    push!(all_options, mod_ind)
    push!(all_options, mod_field)
    push!(all_options, mod_subfield)
    push!(all_options, agg_indices)
    push!(all_options, agg_type)
    all_props = [:variable, props_to_keep..., :obs_ind, :obs_sn, :mod_ind, :mod_field, :mod_subfield, :temporal_aggr, :temporal_aggr_type]
    return (; Pair.(all_props, all_options)...)
end


"""
    getConstraintNames(optim::NamedTuple)

Extracts observation and model variable names for optimization constraints.

# Arguments:
- `optim`: A NamedTuple containing optimization settings and observation constraints.

# Returns:
- A tuple containing:
  - `obs_vars`: A list of observation variables used to calculate cost.
  - `optim_vars`: A lookup mapping observation variables to model variables.
  - `store_vars`: A lookup of model variables for which time series will be stored.
  - `model_vars`: A list of model variable names.
"""
function getConstraintNames(optim::NamedTuple)
    obs_vars = Symbol.(optim.observational_constraints)
    model_vars = String[]
    optim_vars = (;)
    for v ∈ obs_vars
        vinfo = getproperty(optim.observations.variables, v)
        push!(model_vars, vinfo.model_full_var)
        vf, vvar = Symbol.(split(vinfo.model_full_var, "."))
        optim_vars = set_namedtuple_field(optim_vars, (v, tuple(vf, vvar)))
    end
    store_vars = getVariableGroups(model_vars)
    return obs_vars, optim_vars, store_vars, model_vars
end

"""
    getParamModelIDVal(parameter_table)

Generates a `Val` object containing tuples of parameter names and their corresponding model IDs.

# Arguments:
- `parameter_table`: A table of parameters with their names and model IDs.

# Returns:
- A `Val` object containing tuples of parameter names and model IDs.

# Notes:
- Parameter names are transformed to a unique format by replacing dots with underscores.
"""
function getParamModelIDVal(parameter_table)
    parameter_names = Symbol.(replace.(parameter_table.name_full, "." => "____"))
    model_id = parameter_table.model_id;
    parameter_id_tuple=Tuple(map(parameter_names, model_id) do p,m
        (p, m)
    end)
    return Val(parameter_id_tuple)
end


"""
    prepCostOptions(observations, cost_options, ::CostMethod)

Prepares cost options for optimization by filtering variables with insufficient data points and setting up the required configurations.

# Arguments:
- `observations`: A NamedTuple or a vector of arrays containing observation data, uncertainties, and masks used for calculating performance metrics or loss.
- `cost_options`: A table listing each observation constraint and its configuration for calculating the loss or performance metric.
- `::CostMethod`: A type indicating the cost function method. 

# Returns:
- A filtered table of `cost_options` containing only valid variables with sufficient data points.

# cost methods:
$(methods_of(CostMethod))

---
# Extended help

# Examples
```jldoctest
julia> using Sindbad

julia> # Prepare cost options for optimization
julia> # filtered_cost_options = prepCostOptions(observations, cost_options, CostModelObs())
```

# Notes:
- The function iterates through the observation variables and checks if the number of valid data points meets the minimum threshold specified in `cost_options.min_data_points`.
- Variables with insufficient data points are excluded from the returned `cost_options`.
- The function modifies the `cost_options` table by adding:
  - `valids`: Indices of valid data points for each variable.
  - `is_valid`: A boolean flag indicating whether the variable meets the minimum data point requirement.
- Unnecessary fields such as `min_data_points`, `temporal_data_aggr`, and `aggr_func` are removed from the final `cost_options`.
"""
function prepCostOptions end


function prepCostOptions(observations, cost_options)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObsPriors)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObs)
    valids=[]
    is_valid = []
    vars = cost_options.variable
    obs_inds = cost_options.obs_ind
    min_data_points = cost_options.min_data_points
    for vi in eachindex(vars)
        obs_ind_start = obs_inds[vi]
        min_point = min_data_points[vi]
        y = observations[obs_ind_start]
        yσ = observations[obs_ind_start+1]
        idxs = Array(.!is_invalid_number.(y .* yσ))
        total_point = sum(idxs)
        if total_point < min_point
            push!(is_valid, false)
        else
            push!(is_valid, true)
        end
        push!(valids, idxs)
    end
    cost_options = set_namedtuple_field(cost_options, (:valids, valids))
    cost_options = set_namedtuple_field(cost_options, (:is_valid, is_valid))
    cost_options = drop_namedtuple_fields(cost_options, (:min_data_points, :temporal_data_aggr, :aggr_func,))
    cost_option_table = Table(cost_options)
    cost_options_table_filtered = filter(row -> row.is_valid === true , cost_option_table)
    return cost_options_table_filtered
end

"""
    setAlgorithmOptions(info::NamedTuple, which_algorithm)
Set up algorithm-specific options for optimization.
# Arguments:
- `info`: A NamedTuple containing the experiment configuration.
- `which_algorithm`: A symbol indicating which algorithm to set up (e.g., `:algorithm_optimization`, `:algorithm_sensitivity_analysis`).
# Returns:
- The updated `info` NamedTuple with algorithm options set.
# Notes:
- Reads algorithm settings from the experiment configuration.
- If the algorithm is specified as a JSON file, it parses the file and merges the options with default settings.
"""
function setAlgorithmOptions(info, which_algorithm)
    optim_algorithm = getproperty(info.settings.optimization, which_algorithm)
    tmp_algorithm = (;)
    algo_options = (;)
    algo_method = nothing
    if !isnothing(optim_algorithm)
        if endswith(optim_algorithm, ".json")
            options_path = optim_algorithm
            if !isabspath(options_path)
                options_path = joinpath(info.temp.experiment.dirs.settings, options_path)
            end
            options = parsefile(options_path; dicttype=DataStructures.OrderedDict)
            options = dict_to_namedtuple(options)
            algo_method = options.package * "_" * options.method
            algo_method = getTypeInstanceForNamedOptions(algo_method)
            algo_options = options.options
        else
            algo_method = getTypeInstanceForNamedOptions(optim_algorithm)
        end
    else
        if which_algorithm == :algorithm_sensitivity_analysis
            algo_method = GSAMorris()
        end
    end
    default_opt = sindbadDefaultOptions(getproperty(Setup, nameof(typeof(algo_method)))())
    merged_options = merge_namedtuple(default_opt, algo_options)
    tmp_algorithm = set_namedtuple_field(tmp_algorithm, (:method, algo_method))
    tmp_algorithm = set_namedtuple_field(tmp_algorithm, (:options, merged_options))
    algo_field = which_algorithm == :algorithm_sensitivity_analysis ? :sensitivity_analysis : :optimizer
    info = set_namedtuple_subfield(info, :optimization, (algo_field, tmp_algorithm))
    return info
end

"""
    setOptimization(info::NamedTuple)

Sets up optimization-related fields in the experiment configuration.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- The updated `info` NamedTuple with optimization-related fields added.

# Notes:
- Configures cost metrics, optimization parameters, algorithms, and variables to store during optimization.
- Validates the parameters to be optimized against the model structure.
"""
function setOptimization(info::NamedTuple)
    print_info(setOptimization, @__FILE__, @__LINE__, "setting ParameterOptimization and Observation Info...")
    info = set_namedtuple_field(info, (:optimization, (;)))

    # set information related to cost metrics for each variable
    info = set_namedtuple_subfield(info, :optimization, (:model_parameter_default, info.settings.optimization.model_parameter_default))
    info = set_namedtuple_subfield(info, :optimization, (:observational_constraints, info.settings.optimization.observational_constraints))

    n_threads_cost = 1
    run_lazy = hasproperty(info.settings.experiment.flags, :run_lazy) ? get(info.settings.experiment.flags, :run_lazy, false) : false
    if info.settings.optimization.optimization_cost_threaded > 0 && info.settings.experiment.flags.run_optimization && !run_lazy
        n_threads_cost = info.settings.optimization.optimization_cost_threaded > 1 ? info.settings.optimization.optimization_cost_threaded : Threads.nthreads()
        # overwrite land array type when threaded optimization is set
        info = @set info.temp.helpers.run.land_output_type = PreAllocArrayMT()
        # info = set_namedtuple_subfield(info,
        # :optimization,
        # (:n_threads_cost, n_threads_cost))
    end

    # get types for optimization run options
    multi_constraint_method = getTypeInstanceForNamedOptions(info.settings.optimization.multi_constraint_method)
    cost_method = getTypeInstanceForNamedOptions(info.settings.optimization.optimization_cost_method)
    scaling_method = isnothing(info.settings.optimization.optimization_parameter_scaling) ? "scale_none" : info.settings.optimization.optimization_parameter_scaling
    parameter_scaling = getTypeInstanceForNamedOptions(scaling_method)
    optimization_types = (; cost_method, parameter_scaling, multi_constraint_method, n_threads_cost)
    info = set_namedtuple_subfield(info, :optimization, (:run_options, optimization_types))
        
    # check and set the list of parameters to be optimized
    
    # set algorithm related options
    info = setAlgorithmOptions(info, :algorithm_optimization)
    info = setAlgorithmOptions(info, :algorithm_sensitivity_analysis)
    parameter_table = getOptimizationParametersTable(info.temp.models.parameter_table, info.settings.optimization.model_parameter_default, info.settings.optimization.model_parameters_to_optimize)
    
    checkOptimizedParametersInModels(info, parameter_table)

    # use no scaling while checking bounds
    checkParameterBounds(parameter_table.name, parameter_table.initial, parameter_table.lower, parameter_table.upper, ScaleNone(), p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)

    # get the variables to be used during optimization
    obs_vars, optim_vars, store_vars, model_vars = getConstraintNames(info.settings.optimization)
    vars_info = (;)
    vars_info = set_namedtuple_field(vars_info, (:obs, obs_vars))
    vars_info = set_namedtuple_field(vars_info, (:optimization, optim_vars))
    vars_info = set_namedtuple_field(vars_info, (:store, store_vars))
    vars_info = set_namedtuple_field(vars_info, (:model, model_vars))
    info = set_namedtuple_subfield(info, :optimization, (:variables, (vars_info)))
    info = updateVariablesToStore(info)
    cost_options = getCostOptions(info.settings.optimization, vars_info, info.temp.output.variables, info.temp.helpers.numbers, info.temp.helpers.dates)
    info = set_namedtuple_subfield(info, :optimization, (:cost_options, cost_options))
    info = set_namedtuple_subfield(info, :optimization, (:parameter_table, parameter_table))
    optimization_info = info.optimization
    optimization_info = drop_namedtuple_fields(optimization_info, (:model_parameter_default, :model_parameters_to_optimize, :observational_constraints, :variables))
    info = (; info..., optimization = optimization_info)
    return info
end


