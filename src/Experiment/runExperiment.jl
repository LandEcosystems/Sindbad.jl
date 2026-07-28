export prepExperiment
export runExperiment
export runExperimentCost
export runExperimentForward
export runExperimentForwardParams
export runExperimentFullOutput
export runExperimentOpti
export runExperimentSensitivity

"""
    prepExperiment(sindbad_experiment::String; replace_info::Dict=Dict())

Prepare experiment configuration, forcing data, and output settings.

# Arguments
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)

# Returns
- `info::NamedTuple`: A NamedTuple containing the experiment configuration
- `forcing::NamedTuple`: A NamedTuple containing the forcing data

# Description
This function initializes an experiment by:
1. Reading and processing the experiment configuration
2. Setting up forcing data based on the configuration
3. Preparing output settings

# Examples
```jldoctest
julia> using Sindbad

julia> # Prepare experiment from configuration file
julia> # info, forcing = prepExperiment("experiment_config.json")

julia> # Prepare with configuration overrides
julia> # info, forcing = prepExperiment("experiment_config.json"; replace_info=Dict("output" => Dict("save_all" => true)))
```
"""
function prepExperiment(sindbad_experiment::String; replace_info=Dict())
    print_figlet_banner("SINDBAD")

    info = getExperimentInfo(sindbad_experiment; replace_info=replace_info)

    print_info_separator()

    forcing = getForcing(info)

    return info, forcing
end


"""
    EXPERIMENT_MODE_FLAGS

Mapping of experiment run modes to the required combination of `experiment.flags`.
Each mode fully determines the `run_optimization`, `calc_cost`, and `run_forward`
flags, so a caller only needs to name the mode instead of setting the flags by hand.

- `:forward`      → forward simulation only
- `:cost`         → forward simulation + cost calculation
- `:optimization` → parameter optimization only
"""
const EXPERIMENT_MODE_FLAGS = (
    forward      = (run_optimization = false, calc_cost = false, run_forward = true),
    cost         = (run_optimization = false, calc_cost = true,  run_forward = true),
    optimization = (run_optimization = true,  calc_cost = false, run_forward = false),
)

"""
    setExperimentMode!(replace_info::AbstractDict, mode::Symbol)

Force the `experiment.flags` in `replace_info` to the combination required by `mode`,
warning whenever an existing value in `replace_info` is overridden. This is the single
switcher used by the `runExperiment*` entry points to select their run mode robustly,
regardless of whether the flag keys were already present in `replace_info`.

# Arguments
- `replace_info::AbstractDict`: Dictionary of configuration overrides with flat, dotted string keys (e.g. `"experiment.flags.run_forward"`)
- `mode::Symbol`: Target run mode; one of the keys of [`EXPERIMENT_MODE_FLAGS`](@ref)

# Returns
- The mutated `replace_info`
"""
function setExperimentMode!(replace_info::AbstractDict, mode::Symbol)
    haskey(EXPERIMENT_MODE_FLAGS, mode) || error("unknown experiment mode `:$(mode)`. Supported modes: $(keys(EXPERIMENT_MODE_FLAGS))")
    for (flag, target) in pairs(EXPERIMENT_MODE_FLAGS[mode])
        key = "experiment.flags.$(flag)"
        if haskey(replace_info, key) && replace_info[key] != target
            @warn "The experiment sets `$(key)` = $(replace_info[key]); overriding to $(target) to match the `:$(mode)` run mode."
        end
        replace_info[key] = target
    end
    return replace_info
end


"""
    runExperiment(info::NamedTuple, forcing::NamedTuple, mode::RunFlag)

Run a SINDBAD experiment in different modes.

# Arguments
- `info::NamedTuple`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment
- `forcing::NamedTuple`: A forcing NamedTuple containing the forcing time series set for ALL locations
- `mode::RunFlag`: Type dispatch parameter determining the mode of experiment:
  - `DoCalcCost`: Calculate cost between model output and observations
  - `DoRunForward`: Run forward simulation without optimization
  - `DoNotRunOptimization`: Run without optimization
  - `DoRunOptimization`: Run with optimization enabled

# Returns
- For `DoCalcCost` mode:
  - `(; forcing, info, loss=loss_vector, observation=obs_array, output=forward_output)`
- For `DoRunForward` or `DoNotRunOptimization` mode:
  - `(; forcing, info, output=run_output)`
- For `DoRunOptimization` mode:
  - `(; forcing, info, observation=obs_array, params=run_output)`

# Description
This function is the main entry point for running SINDBAD experiments. It supports different modes of simulation:
- Cost calculation: Compares model output with observations
- Forward run: Executes the model without optimization
- ParameterOptimization: Runs the model with parameter optimization

The function handles different spatial configurations and can operate on both single-pixel and spatial domains.
"""
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


"""
    runExperimentCost(sindbad_experiment::String; replace_info::Dict=Dict(), log_level::Symbol=:info)

Calculate cost for a given experiment through the `runExperiment` function in `DoCalcCost` mode.

# Arguments
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)
- `log_level::Symbol`: Logging level (default: :info)

# Returns
- A NamedTuple containing the experiment results including cost calculations
"""
function runExperimentCost(sindbad_experiment::String; replace_info=Dict(), log_level=:info)
    set_log_level(log_level)
    setExperimentMode!(replace_info, :cost)
    info, forcing = prepExperiment(sindbad_experiment; replace_info=replace_info)
    cost_output = runExperiment(info, forcing, info.helpers.run.calc_cost)
    set_log_level()
    return cost_output
end


"""
    runExperimentForward(sindbad_experiment::String; replace_info::Dict=Dict(), log_level::Symbol=:info)

Run forward simulation for a given experiment through the `runExperiment` function in `DoRunForward` mode.

# Arguments
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)
- `log_level::Symbol`: Logging level (default: :info)

# Returns
- A NamedTuple containing the experiment results including model outputs
"""
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



"""
    runExperimentForwardParams(params_vector::Vector, sindbad_experiment::String; replace_info::Dict=Dict(), log_level::Symbol=:info)

Run forward simulation of the model with default as well as modified settings with input/optimized parameters through call of the `runTEM!` function.

# Arguments
- `params_vector::Vector`: Vector of parameters to use for the simulation
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)
- `log_level::Symbol`: Logging level (default: :info)

# Returns
- A NamedTuple containing both default and optimized model outputs
"""
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


"""
    runExperimentFullOutput(sindbad_experiment::String; replace_info::Dict=Dict(), log_level::Symbol=:info)

Run forward simulation of the model through `runExperiment` function in `DoRunForward` mode but with all output variables saved.

# Arguments
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)
- `log_level::Symbol`: Logging level (default: :info)

# Returns
- A NamedTuple containing the complete model outputs
"""
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


"""
    runExperimentOpti(sindbad_experiment::String; replace_info::Dict=Dict(), log_level::Symbol=:warn)

Run optimization experiment through `runExperiment` function in `DoRunOptimization` mode, followed by forward run with optimized parameters.

# Arguments
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)
- `log_level::Symbol`: Logging level (default: :warn)

# Returns
- A NamedTuple containing optimization results, model outputs, and cost metrics
"""
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
    parameters_nt = convertParametersToNamedTuple(opti_output.parameters, :name_full)
    return (; forcing, cost_options, run_helpers, info=fp_output.info, loss=loss_table, observation=opti_output.observation, output=fp_output.output, parameters=opti_output.parameters, parameters_nt=parameters_nt)
end



"""
    runExperimentSensitivity(sindbad_experiment::String; replace_info::Dict=Dict(), batch::Bool=true, log_level::Symbol=:warn)

Run sensitivity analysis for a given experiment.

# Arguments
- `sindbad_experiment::String`: Path to the experiment configuration file
- `replace_info::Dict`: Dictionary of configuration overrides (default: empty Dict)
- `batch::Bool`: Whether to run sensitivity analysis in batch mode (default: true)
- `log_level::Symbol`: Logging level (default: :warn)

# Returns
- A NamedTuple containing sensitivity analysis results and related data
"""
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

"""
    runForward(forcing::NamedTuple, info::NamedTuple, mode::RunFlag)

Run a SINDBAD forward simulation, choosing between eager and lazy execution.

# Arguments
- `forcing::NamedTuple`: A forcing NamedTuple containing the forcing time series set for ALL locations
- `info::NamedTuple`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment
- `mode::RunFlag`: Type dispatch parameter determining how the forward run is executed:
  - `DoNotRunLazy`: Run eagerly in memory via `runTEM!`
  - `DoRunLazy`: Run lazily over YAXArrays via `runTEMYax`

# Returns
- For `DoNotRunLazy` mode:
  - A NamedTuple pairing each unique output variable name (from `info.output.variables`) with its computed time series
- For `DoRunLazy` mode:
  - The lazy YAXArray output produced by `runTEMYax`

# Description
This function is the entry point for executing the forward model of a SINDBAD experiment. It dispatches on the run mode to select between two execution strategies:
- Eager run: Evaluates the model in memory for all locations and collects the results into a NamedTuple keyed by output variable names
- Lazy run: Builds a lazy YAXArray computation that is materialized on demand, which is useful for large spatial domains that do not fit in memory

Both modes operate on the same `forcing` and `info` and produce the model forward output; they differ only in when and how the computation is carried out.
"""
function runForward end

# Default-model forms: run the forward models defined in `info.models.forward`.
function runForward(forcing, info, mode::RunFlag)
    return runForward(info.models.forward, forcing, info, mode)
end

# Explicit-model forms: run an arbitrary set of `selected_models` (e.g. default vs.
# parameter-updated models), so callers route their forward runs through `runForward`
# instead of calling `runTEM!`/`runTEMYax` directly.
function runForward(selected_models, forcing, info, ::DoNotRunLazy)
    run_output = runTEM!(selected_models, forcing, info)
    run_output = (; Pair.(getUniqueVarNames(info.output.variables), run_output)...)
    return run_output
end

function runForward(selected_models, forcing, info, ::DoRunLazy)
    run_output = runTEMYax(
        selected_models,
        forcing,
        info)
    return run_output
end