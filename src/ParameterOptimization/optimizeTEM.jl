export optimizeTEM
export optimizeTEMYax

"""
    optimizeTEM(forcing::NamedTuple, observations, info::NamedTuple)

Optimizes TEM parameters by minimizing the cost function between model outputs and observations.

# Arguments:
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `observations`: a NT or a vector of arrays of observations, their uncertainties, and mask to use for calculation of performance metric/loss
- `info`: a SINDBAD NT that includes all information needed for setup and execution of an experiment

# Returns:
- `parameter_table`: A table containing optimized parameter values

# Examples
```jldoctest
julia> using Sindbad

julia> # Optimize TEM parameters
julia> # optimized_params = optimizeTEM(forcing, observations, info)
```
"""
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


"""
    optimizeTEMYax(forcing::NamedTuple, output::NamedTuple, tem::NamedTuple, optim::NamedTuple, observations::NamedTuple; max_cache=1e9)

Optimizes the Terrestrial Ecosystem Model (TEM) parameters for each pixel by mapping over the YAXcube(s).


# Arguments
- `forcing::NamedTuple`: Input forcing data for the TEM model
- `output::NamedTuple`: Output configuration settings
- `tem::NamedTuple`: TEM model parameters and settings
- `optim::NamedTuple`: Optimization parameters and settings
- `observations::NamedTuple`: Observed data for model calibration

# Keywords
- `max_cache::Float64=1e9`: Maximum cache size for optimization process

# Returns
Optimized TEM parameters cube
"""
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


"""   
    optimizeYax(map_cubes...; out::NamedTuple, tem::NamedTuple, optim::NamedTuple, forcing_vars::AbstractArray, obs_vars::AbstractArray)

A helper function to optimize parameters for each pixel by mapping over the YAXcube(s).

# Arguments
- `map_cubes...`: Variadic input of cube maps to be optimized
- `out::NamedTuple`: Output configuration parameters
- `tem::NamedTuple`: TEM (Terrestrial Ecosystem Model) configuration parameters
- `optim::NamedTuple`: Optimization configuration parameters
- `forcing_vars::AbstractArray`: Array of forcing variables used in optimization
- `obs_vars::AbstractArray`: Array of observation variables used in optimization
"""
function optimizeYax(map_cubes...; forcing_vars::AbstractArray, obs_vars::AbstractArray)
    output, forcing, observation = unpackYaxOpti(map_cubes; forcing_vars)
    forcing = (; Pair.(forcing_vars, forcing)...)
    observation = (; Pair.(obs_vars, observation)...)
    params = optimizeTEM(forcing, observation, info)
    return output[:] = params.optimized
end


"""
    unpackYaxOpti(args; forcing_vars::AbstractArray)

Unpacks the variables for the mapCube function

# Arguments
- `all_cubes`: Collection of cubes containing input, output and optimization/observation variables
- `forcing_vars::AbstractArray`: Array specifying which variables should be forced/constrained

# Returns
Unpacked data arrays
"""
function unpackYaxOpti(all_cubes; forcing_vars::AbstractArray)
    nforc = length(forcing_vars)
    outputs = first(all_cubes)
    forcings = all_cubes[2:(nforc+1)]
    observations = all_cubes[(nforc+2):end]
    return outputs, forcings, observations
end
