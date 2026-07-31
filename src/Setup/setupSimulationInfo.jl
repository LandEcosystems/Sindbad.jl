export getExperimentInfo
export getGlobalAttributesForOutCubes

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
