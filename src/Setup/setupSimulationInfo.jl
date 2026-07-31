export checkIOModelStructure
export getExperimentInfo
export getGlobalAttributesForOutCubes

"""
    checkIOModelStructure(info; model_funcs=(:define, :precompute, :compute))

Validates the input/output (I/O) structure of the models selected in `info.models.forward`,
independently of any plotting/visualization backend. Runs `getInOutModels` internally so the
checks below are always performed, whether or not a plot is ever produced.

# Arguments
- `info`: A `NamedTuple` containing experiment information, including `info.models.forward`.
- `model_funcs`: The model functions to analyze, given in their execution order (default:
  `(:define, :precompute, :compute)`). `:update` is intentionally excluded because it is not
  currently invoked anywhere in the SINDBAD run loop.

# Conventions checked (warnings only, via `@warn`; never errors):
1. **Single-writer convention**: an output variable `land.<namespace>.<variable>` may be written
   by more than one *distinct* model only if `namespace` is `:pools`, `:states`, or
   `:diagnostics`. Any other namespace written by more than one model is flagged, since it
   indicates more than one model approach is competing to produce the same variable.
2. **Valid-input convention**: a variable used as input must be one of:
    - a forcing (`:forcing` namespace),
    - a `:pools`/`:states`/`:diagnostics` variable (these are exempt from the ordering check:
      `pools`/`states` persist across timesteps/iterations and are seeded from initial
      conditions, while `diagnostics` is commonly written by more than one model),
    - the output of a strictly earlier model in `info.models.forward`, or
    - the output of an earlier function of the *same* model, following `model_funcs` order.

  Any other input is flagged as having no valid earlier producer, which typically indicates
  either a model-ordering bug or a genuinely undefined/orphaned variable.

# Returns
- `nothing`.
"""
function checkIOModelStructure(info; model_funcs=(:define, :precompute, :compute))
    models = info.models.forward
    model_names = [Symbol(nameof(supertype(typeof(m)))) for m in models]
    # `getInOutModel`/`getInOutModels` (SindbadTEM.Utils) unconditionally println progress for
    # every model/function combination; that's fine for interactive/ad hoc use but far too noisy
    # to run on every experiment setup, so it's silenced here rather than in SindbadTEM itself.
    in_out = redirect_stdout(devnull) do
        getInOutModels(models, model_funcs)
    end
    func_rank = Dict(f => i for (i, f) in enumerate(model_funcs))
    exempt_namespaces = (:pools, :states, :diagnostics)

    # registry: (namespace, variable) => [(model_index, func_rank), ...]
    producers = Dict{Tuple{Symbol,Symbol}, Vector{Tuple{Int,Int}}}()
    for (m_i, m_name) in enumerate(model_names)
        for f in model_funcs
            for (ns, var) in in_out[m_name][f][:output]
                push!(get!(producers, (ns, var), Tuple{Int,Int}[]), (m_i, func_rank[f]))
            end
        end
    end

    # convention 1: single-writer unless pools/states/diagnostics
    for ((ns, var), locs) in producers
        if ns ∉ exempt_namespaces
            distinct_models = unique(first.(locs))
            if length(distinct_models) > 1
                writer_names = join(unique(model_names[m_i] for m_i in distinct_models), ", ")
                @warn "I/O convention violation: `land.$(ns).$(var)` is output by more than one model ($writer_names). Only variables in `land.pools`/`land.states`/`land.diagnostics` may be written by multiple models."
            end
        end
    end

    # convention 2: every input must have a valid earlier producer
    for (m_i, m_name) in enumerate(model_names)
        for f in model_funcs
            for (ns, var) in in_out[m_name][f][:input]
                (ns === :forcing || ns ∈ exempt_namespaces) && continue
                locs = get(producers, (ns, var), Tuple{Int,Int}[])
                has_valid_producer = any(locs) do (p_m, p_f)
                    p_m < m_i || (p_m == m_i && p_f < func_rank[f])
                end
                if !has_valid_producer
                    @warn "I/O convention violation: `land.$(ns).$(var)` is used as input in `$(f)` of `$(m_name)` (model #$(m_i) of $(length(model_names))) but has no valid earlier producer. Inputs must be a forcing, a `pools`/`states`/`diagnostics` variable, an output of an earlier model, or an output of an earlier function of the same model (order: $(join(model_funcs, ", ")))."
                end
            end
        end
    end

    return nothing
end

"""
    getExperimentInfo(sindbad_experiment::String; replace_info=Dict())

Loads and sets up the experiment configuration, saving the information and enabling debugging options if specified.

# Arguments:
- `sindbad_experiment::String`: Path to the experiment configuration file.
- `replace_info::Dict`: (Optional) A dictionary of fields to replace in the configuration.

# Returns:
- A NamedTuple `info` containing the fully loaded and configured experiment information.

# Notes:
- The function performs the following steps:
  1. Loads the experiment configuration using `getConfiguration`.
  2. Sets up the experiment `info` using `setupInfo`.
  3. Saves the experiment `info` if `save_info` is enabled.
  4. Sets up a debug error catcher if `catch_model_errors` is enabled.
  5. Plots the IO structure of the selected model structure via `plotIOModelStructure`.

# Examples
```jldoctest
julia> using Sindbad

julia> # Load experiment configuration
julia> # info = getExperimentInfo("experiment_config.json")

julia> # Load with configuration overrides
julia> # info = getExperimentInfo("experiment_config.json"; replace_info=Dict("output" => Dict("save_all" => true)))
```
"""
function getExperimentInfo(sindbad_experiment::String; replace_info=Dict())
    replace_info_text = isempty(replace_info) ? "none" : " $(Tuple(keys(replace_info)))"
    print_info_separator()
    
    print_info(getExperimentInfo, @__FILE__, @__LINE__, "loading experiment configurations", n_m=1)
    print_info(nothing, @__FILE__, @__LINE__, "→→→    experiment_path: `$(sindbad_experiment)`", n_m=1)

    print_info(nothing, @__FILE__, @__LINE__, "→→→    replace_info_fields: `$(replace_info_text)`", n_m=1)
    info = getConfiguration(sindbad_experiment; replace_info=deepcopy(replace_info))

    info = setupInfo(info)

    print_info(getExperimentInfo, @__FILE__, @__LINE__, "checking IO structure of the selected model structure...", n_m=1)
    checkIOModelStructure(info)

    print_info(getExperimentInfo, @__FILE__, @__LINE__, "plotting IO signatures in the selected model structure...", n_m=1)
    for model_func in (:define, :precompute, :compute,)
        Base.moduleroot(@__MODULE__).Visualization.plotIOModelStructure(info, model_func)
    end

    saveInfo(info, info.helpers.run.save_info)
    setDebugErrorCatcher(info.helpers.run.catch_model_errors)

    return info
end


"""
    getGlobalAttributesForOutCubes(info)

Generates global attributes for output cubes, including system and experiment metadata.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.

# Returns:
- A dictionary `global_attr` containing global attributes such as:
  - `simulation_by`: The user running the simulation.
  - `experiment`: The name of the experiment.
  - `domain`: The domain of the experiment.
  - `date`: The current date.
  - `machine`: The machine architecture.
  - `os`: The operating system.
  - `host`: The hostname of the machine.
  - `julia`: The Julia version.

# Notes:
- The function collects system information using Julia's `Sys` module and `versioninfo`.
"""
function getGlobalAttributesForOutCubes(info)
    os = Sys.iswindows() ? "Windows" : Sys.isapple() ? "macOS" : Sys.islinux() ? "Linux" : "unknown"
    simulation_by = Sys.iswindows() ? ENV["USERNAME"] : ENV["USER"]
    io = IOBuffer()
    versioninfo(io)
    str = String(take!(io))
    julia_info = split(str, "\n")

    # io = IOBuffer()
    # Pkg.status("Sindbad", io=io)
    # sindbad_version = String(take!(io))
    global_attr = Dict(
        "simulation_by" => simulation_by,
        "experiment" => info.temp.experiment.basics.name,
        "domain" => info.temp.experiment.basics.domain,
        "date" => string(Date(now())),
        # "SINDBAD" => sindbad_version,
        "machine" => Sys.MACHINE,
        "os" => os,
        "host" => gethostname(),
        "julia" => string(VERSION),
    )
    return global_attr
end


"""
    saveInfo(info, to_save::DoSaveInfo | ::DoNotSaveInfo)

Saves or skips saving the experiment configuration to a file.

# Arguments:
- `info`: A NamedTuple containing the experiment configuration.
- `::DoSaveInfo`: A type dispatch indicating that the information should be saved.
- `::DoNotSaveInfo`: A type dispatch indicating that the information should not be saved.

# Returns:
- `nothing`.

# Notes:
- When saving, the experiment configuration is saved as a `.jld2` file in the `settings` directory.
"""
function saveInfo end

function saveInfo(info, ::DoSaveInfo)
    info_path = joinpath(info.output.dirs.settings, "info.jld2")
    print_info(saveInfo, @__FILE__, @__LINE__, "saving info to `$(info_path)`")
    @save info_path info
    return nothing
end

function saveInfo(::DoNotSaveInfo)
    return nothing
end

"""
    setDebugErrorCatcher(::DoCatchModelErrors | ::DoNotCatchModelErrors)

Enables/Disables a debug error catcher for the SINDBAD framework. When enabled, a variable `error_catcher` is enabled and can be written to from within SINDBAD models and functions. This can then be accessed from any scope with `SindbadTEM.error_catcher`

# Arguments:
- `::DoCatchModelErrors`: A type dispatch indicating that model errors should be caught.
- `::DoNotCatchModelErrors`: A type dispatch indicating that model errors should not be caught.

# Returns:
- `nothing`.

# Notes:
- When enabled, sets up an empty error catcher using `SindbadTEM.eval`.
"""
function setDebugErrorCatcher end

function setDebugErrorCatcher(::DoCatchModelErrors)
    print_info(setDebugErrorCatcher, @__FILE__, @__LINE__, "setting up debug error catcher", n_m=1)
    SindbadTEM.eval(:(error_catcher = []))
    return nothing
end

function setDebugErrorCatcher(::DoNotCatchModelErrors)
    return nothing
end
