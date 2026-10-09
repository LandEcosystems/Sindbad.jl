export getCostVectorSize
export prepOpti
export prepParameters

"""
    getCostVectorSize(algo_options, parameter_vector, ::ParameterOptimizationMethod || GSAMethod)

Calculates the size of the cost vector required for a specific optimization or sensitivity analysis method.

# Arguments:
- `algo_options`: A NamedTuple or dictionary containing algorithm-specific options (e.g., population size, number of trajectories).
- `parameter_vector`: A vector of parameters used in the optimization or sensitivity analysis.
- `::ParameterOptimizationMethod`: The optimization or sensitivity analysis method. Supported methods include:
    - `CMAEvolutionStrategyCMAES`: Covariance Matrix Adaptation Evolution Strategy.
    - `GSAMorris`: Morris method for global sensitivity analysis.
    - `GSASobol`: Sobol method for global sensitivity analysis.
    - `GSASobolDM`: Sobol method with Design Matrices.

# Returns:
- An integer representing the size of the cost vector required for the specified method.

# Notes:
- For `CMAEvolutionStrategyCMAES`, the size is determined by the population size or a default formula based on the parameter vector length.
- For `GSAMorris`, the size is calculated as the product of the number of trajectories and the length of the design matrix.
- For `GSASobol`, the size is determined by the number of parameters and the number of samples.
- For `GSASobolDM`, the size is equivalent to that of `GSASobol`.
"""
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



"""
    prepOpti(forcing, observations, info, cost_method::CostModelObs)

Prepares optimization setup including cost functions, parameter bounds, and initial values.

# Arguments:
- `forcing`: Forcing data for the simulation
- `observations`: Observation data for cost calculation
- `info`: Experiment configuration NamedTuple
- `cost_method`: Cost calculation method type

# Returns:
- A NamedTuple containing optimization helpers including cost function, parameter bounds, and default values

# Examples
```jldoctest
julia> using Sindbad

julia> # Prepare optimization setup
julia> # opti_helpers = prepOpti(forcing, observations, info, CostModelObs())
```

Prepares optimization parameters, settings, and helper functions based on the provided inputs.

# Arguments:
- `forcing`: Input forcing data used for the optimization process.
- `observations`: Observed data used for comparison or calibration during optimization.
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of the experiment.
- `cost_method`: The method used to calculate the cost function. 

# Returns:
- A NamedTuple `opti_helpers` containing:
  - `parameter_table`: Processed model parameters for optimization.
  - `cost_function`: A function to compute the cost for optimization.
  - `cost_options`: Options and settings for the cost function.
  - `default_values`: Default parameter values for the models.
  - `lower_bounds`: Lower bounds for the parameters.
  - `upper_bounds`: Upper bounds for the parameters.
  - `run_helpers`: Helper information for running the optimization.


# cost_method:
$(methods_of(CostMethod))

---

# Extended help

# Notes:
- The function processes the input data and configuration to set up the optimization problem.
- It prepares model parameters, cost options, and helper functions required for the optimization process.
- Depending on the `cost_method`, the cost function is customized to handle specific data types or computation methods.
"""
function prepOpti end

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

    cost_function = x -> cost(x, opti_helpers.default_values, getCostModels(info, run_helpers, space_index), run_helpers.space_forcing[space_index], run_helpers.space_spinup[space_index], run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output_mt, deepcopy(run_helpers.space_land[space_index]), run_helpers.tem_info, observations, opti_helpers.parameter_table, opti_helpers.cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, cost_vector, info.optimization.run_options.cost_method)

    opti_helpers = (; opti_helpers..., cost_function=cost_function, cost_vector=cost_vector)
    return opti_helpers
end

function  prepOpti(forcing, observations, info, ::CostModelObsLandTS)
    opti_helpers = prepOpti(forcing, observations, info, CostModelObs())
    run_helpers = opti_helpers.run_helpers

    cost_function = x -> costLand(x, getCostModels(info, run_helpers, 1), run_helpers.loc_forcing, run_helpers.loc_spinup, run_helpers.loc_forcing_t, run_helpers.land_time_series, run_helpers.loc_land, run_helpers.tem_info, observations, opti_helpers.parameter_table, opti_helpers.cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling)

    opti_helpers = (; opti_helpers..., cost_function=cost_function)
    
    return opti_helpers
end


function  prepOpti(forcing, observations, info, cost_method::CostModelObs)
    run_helpers = prepTEM(forcing, info)

    opti_parameter_table = setInitialFromParameterInput(info.optimization.parameter_table, get(run_helpers, :parameters, nothing))
    parameter_helpers = prepParameters(opti_parameter_table, info.optimization.run_options.parameter_scaling)
    
    parameter_table = parameter_helpers.parameter_table
    default_values = parameter_helpers.default_values
    lower_bounds = parameter_helpers.lower_bounds
    upper_bounds = parameter_helpers.upper_bounds

    cost_options = prepCostOptions(observations, info.optimization.cost_options, cost_method)

    cost_function = x -> cost(x, default_values, getCostModels(info, run_helpers), run_helpers.space_forcing, run_helpers.space_spinup, run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output, deepcopy(run_helpers.space_land), run_helpers.tem_info, observations, parameter_table, cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, cost_method)

    opti_helpers = (; parameter_table=parameter_table, cost_function=cost_function, cost_options=cost_options, default_values=default_values, lower_bounds=lower_bounds, upper_bounds=upper_bounds, run_helpers=run_helpers)
    
    return opti_helpers
end


"""
    getCostModels(info, run_helpers[, space_index])

Returns the models to update in the cost function of the optimization.

# Arguments:
- `info`: the experiment info, whose `models.forward` are the models of all locations
  without parameters per location
- `run_helpers`: the run helpers from `prepTEM`, with the models of each location and
  the applied `parameters` when a json or zarr/nc parameters input is set
- `space_index`: the location of a single-location cost, if any

# Returns:
- Without parameters per location, `info.models.forward`, which is the same for all
  locations.
- Otherwise the vector of the models of each location, or the models of `space_index`.
  The optimized parameters are set on top of the parameters of each location.
"""
function getCostModels(info, run_helpers)
    isnothing(get(run_helpers, :parameters, nothing)) && return info.models.forward
    return run_helpers.space_selected_models
end

function getCostModels(info, run_helpers, space_index)
    isnothing(get(run_helpers, :parameters, nothing)) && return info.models.forward
    return run_helpers.space_selected_models[space_index]
end


"""
    setInitialFromParameterInput(opti_table, applied_parameters)

Returns the table of the parameters to optimize, with the start value of each parameter
that is also set by the parameters input taken from that input.

# Arguments:
- `opti_table`: the table of the parameters to optimize
- `applied_parameters`: the `parameters` of the run helpers from `prepTEM`, or `nothing`

# Returns:
- `opti_table` itself when no parameter is in both. Otherwise a copy with `initial` set
  for those parameters.

# Notes:
- The start value is the value of the parameters input. When it differs between
  locations, it is the mean over the locations.
- The value is in the units of the run, like the table, and is clamped to the bounds of
  the optimization. The bounds and everything else come from the optimization settings.
- The optimized value replaces the input values of the parameter at every location.
"""
function setInitialFromParameterInput(opti_table, applied_parameters)
    isnothing(applied_parameters) && return opti_table
    applied_table = applied_parameters.parameter_table
    both = inputParametersToOptimize(applied_table, opti_table)
    isempty(both) && return opti_table
    print_info(setInitialFromParameterInput, @__FILE__, @__LINE__, "the parameters $(both) are set by the parameters input and optimized. Their start value is the input value, or its mean over the locations, and the optimized value is used at every location.")
    opti_table = copy(opti_table)
    opti_names = string.(opti_table.name_full)
    applied_names = string.(applied_table.name_full)
    for name_full ∈ both
        o_i = findfirst(==(name_full), opti_names)
        a_i = findfirst(==(name_full), applied_names)
        start_value = clamp(applied_table.optimized[a_i], opti_table.lower[o_i], opti_table.upper[o_i])
        opti_table.initial[o_i] = oftype(opti_table.initial[o_i], start_value)
    end
    return opti_table
end


"""
    inputParametersToOptimize(applied_table, opti_table)

Returns the full names of the parameters that are set by the parameters input and are
also optimized.
"""
function inputParametersToOptimize(applied_table, opti_table)
    opti_names = string.(opti_table.name_full)
    return filter(in(opti_names), string.(applied_table.name_full))
end


"""
    prepParameters(parameter_table, parameter_scaling)

Prepare model parameters for optimization by processing default and bounds of the parameters to be optimized.

# Arguments
- `parameter_table`: Table of the parameters to be optimized
- `parameter_scaling`: Scaling method/type for parameter optimization

# Returns
A tuple containing processed parameters ready for optimization
"""
function prepParameters(parameter_table, parameter_scaling)
    
    default_values, lower_bounds, upper_bounds = scaleParameters(parameter_table, parameter_scaling)

    parameter_helpers = (; parameter_table=parameter_table, default_values=default_values, lower_bounds=lower_bounds, upper_bounds=upper_bounds)
    return parameter_helpers
end