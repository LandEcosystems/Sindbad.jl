export getConstraintNames
export getCostOptions
export setOptimization

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
    getCostTimeResampler(name, dates_helpers, aggr_func)

Build the time resampler of one observational constraint, once, so that it can be
applied to the model output and the observations at every cost evaluation.

# Arguments:
- `name`: the `temporal_data_aggr` setting, such as `"day"`, `"hour_anomaly"`,
  `"day_MSC"` or a period spec such as `"8-day_msc"` or `"month_iav"`
- `dates_helpers`: a NamedTuple with the `range` and `timestep` of the experiment
- `aggr_func`: the function applied to every time group, such as `mean` or `nansum`

# Returns:
- a `TimeResampler` from TimeSamplers.jl

# Notes:
- The first sampler is skipped when its bins have the length of the model
  timestep, because the data is then already at that resolution.
"""
function getCostTimeResampler(name, dates_helpers, aggr_func)
    method = get_TimeSampler(String(name))
    skip_sampling = time_sampling_period(method) == dates_helpers.timestep
    return TimeResampler(dates_helpers.range, method; sampler_func=aggr_func, skip_sampling=skip_sampling)
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

    time_resamplers = map(enumerate(time_aggrs)) do (i, _aggr)
        getCostTimeResampler(_aggr, dates_helpers, getAggrFunc(aggr_funcs[i]))
    end
    push!(all_options, obs_ind)
    push!(all_options, obs_sn)
    push!(all_options, mod_ind)
    push!(all_options, mod_field)
    push!(all_options, mod_subfield)
    push!(all_options, time_resamplers)
    all_props = [:variable, props_to_keep..., :obs_ind, :obs_sn, :mod_ind, :mod_field, :mod_subfield, :temporal_aggr]
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
    setAlgorithmOptions(optimization::NamedTuple, info::NamedTuple, which_algorithm)
Set up algorithm-specific options for optimization.
# Arguments:
- `optimization`: The NamedTuple of optimization info being built in `setOptimization`.
- `info`: A NamedTuple containing the experiment configuration.
- `which_algorithm`: A symbol indicating which algorithm to set up (e.g., `:algorithm_optimization`, `:algorithm_sensitivity_analysis`).
# Returns:
- The updated `optimization` NamedTuple with the algorithm options set.
# Notes:
- Reads algorithm settings from the experiment configuration.
- If the algorithm is specified as a JSON file, it parses the file and merges the options with default settings.
"""
function setAlgorithmOptions(optimization::NamedTuple, info, which_algorithm)
    optim_algorithm = getproperty(info.settings.optimization, which_algorithm)
    tmp_algorithm = (;)
    algo_options = (;)
    algo_method = nothing
    if !isnothing(optim_algorithm)
        if optim_algorithm isa AbstractString
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
        elseif optim_algorithm isa Union{NamedTuple, AbstractDict}
            algorithm_config = optim_algorithm isa NamedTuple ? optim_algorithm : dict_to_namedtuple(optim_algorithm)
            method = algorithm_config.method
            algo_method = method isa AbstractString ? getTypeInstanceForNamedOptions(method) : method
            options = get(algorithm_config, :options, (;))
            if options isa NamedTuple
                algo_options = options
            elseif options isa AbstractDict
                algo_options = dict_to_namedtuple(options)
            else
                throw(ArgumentError("algorithm options must be a NamedTuple or dictionary, got $(typeof(options))"))
            end
        else
            throw(ArgumentError("algorithm configuration must be a string, NamedTuple, dictionary, or nothing; got $(typeof(optim_algorithm))"))
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
    return (; optimization..., algo_field => tmp_algorithm)
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
    # The optimization info is built on its own and set in info once at the end, because
    # every rebuild of info compiles anew for its large type.
    n_threads_cost = 1
    run_lazy =get(info.settings.experiment.flags, :run_lazy, false)
    threaded_cost = info.settings.optimization.optimization_cost_threaded > 0 && info.settings.experiment.flags.run_optimization && !run_lazy
    if threaded_cost
        n_threads_cost = info.settings.optimization.optimization_cost_threaded > 1 ? info.settings.optimization.optimization_cost_threaded : Threads.nthreads()
    end

    # get types for optimization run options
    multi_constraint_method = getTypeInstanceForNamedOptions(info.settings.optimization.multi_constraint_method)
    cost_method = getTypeInstanceForNamedOptions(info.settings.optimization.optimization_cost_method)
    scaling_method = isnothing(info.settings.optimization.optimization_parameter_scaling) ? "scale_none" : info.settings.optimization.optimization_parameter_scaling
    parameter_scaling = getTypeInstanceForNamedOptions(scaling_method)
    optimization_types = (; cost_method, parameter_scaling, multi_constraint_method, n_threads_cost)
    optimization = (; run_options=optimization_types)

    # set algorithm related options
    optimization = setAlgorithmOptions(optimization, info, :algorithm_optimization)
    optimization = setAlgorithmOptions(optimization, info, :algorithm_sensitivity_analysis)
    parameter_table = getOptimizationParametersTable(info.temp.models.parameter_table, info.settings.optimization.model_parameter_default, info.settings.optimization.model_parameters_to_optimize)
    
    checkOptimizedParametersInModels(info, parameter_table)

    # use no scaling while checking bounds
    checkParameterBounds(parameter_table.name, parameter_table.initial, parameter_table.lower, parameter_table.upper, ScaleNone(), p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)

    # get the variables to be used during optimization
    obs_vars, optim_vars, store_vars, model_vars = getConstraintNames(info.settings.optimization)
    vars_info = (; obs=obs_vars, optimization=optim_vars, store=store_vars, model=model_vars)

    # updateVariablesToStore reads the variables from info.optimization
    temp = info.temp
    if threaded_cost
        # overwrite land array type when threaded optimization is set
        temp = (; temp..., helpers=(; temp.helpers..., run=(; temp.helpers.run..., land_output_type=PreAllocArrayMT())))
    end
    info = (; info..., temp=temp, optimization=(; variables=vars_info))
    info = updateVariablesToStore(info)
    cost_options = getCostOptions(info.settings.optimization, vars_info, info.temp.output.variables, info.temp.helpers.numbers, info.temp.helpers.dates)
    optimization = (; optimization..., cost_options=cost_options, parameter_table=parameter_table)
    info = (; info..., optimization=optimization)
    return info
end

