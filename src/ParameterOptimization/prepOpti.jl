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

    cost_function = x -> cost(x, opti_helpers.default_values, info.models.forward, run_helpers.space_forcing[space_index], run_helpers.space_spinup[space_index], run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output_mt, deepcopy(run_helpers.space_land[space_index]), run_helpers.tem_info, observations, opti_helpers.parameter_table, opti_helpers.cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, cost_vector, info.optimization.run_options.cost_method)

    opti_helpers = (; opti_helpers..., cost_function=cost_function, cost_vector=cost_vector)
    return opti_helpers
end

function  prepOpti(forcing, observations, info, ::CostModelObsLandTS)
    opti_helpers = prepOpti(forcing, observations, info, CostModelObs())
    run_helpers = opti_helpers.run_helpers

    cost_function = x -> costLand(x, info.models.forward, run_helpers.loc_forcing, run_helpers.loc_spinup, run_helpers.loc_forcing_t, run_helpers.land_time_series, run_helpers.loc_land, run_helpers.tem_info, observations, opti_helpers.parameter_table, opti_helpers.cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling)

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

    cost_function = x -> cost(x, default_values, info.models.forward, run_helpers.space_forcing, run_helpers.space_spinup, run_helpers.loc_forcing_t, run_helpers.output_array, run_helpers.space_output, deepcopy(run_helpers.space_land), run_helpers.tem_info, observations, parameter_table, cost_options, info.optimization.run_options.multi_constraint_method, info.optimization.run_options.parameter_scaling, cost_method)

    opti_helpers = (; parameter_table=parameter_table, cost_function=cost_function, cost_options=cost_options, default_values=default_values, lower_bounds=lower_bounds, upper_bounds=upper_bounds, run_helpers=run_helpers)
    
    return opti_helpers
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