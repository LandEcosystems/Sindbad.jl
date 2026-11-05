export createNestedDict
export deepMerge
export getConfiguration
export getExperimentConfiguration
export readConfiguration

const path_separator = Sys.iswindows() ? "\\" : "/"

"""
    convertToAbsolutePath(; inputDict=inputDict)

Converts all relative paths in the input dictionary to absolute paths, assuming all non-absolute paths are relative to the SINDBAD root directory.

# Arguments:
- `inputDict`: A dictionary containing paths as values.

# Returns:
- A new dictionary with all paths converted to absolute paths.

# Notes:
- This function is currently incomplete and does not perform the conversion yet.
"""
function convertToAbsolutePath(; inputDict=inputDict)
    #### NOT DONE YET
    newDict = filter(x -> !occursin("path", first(x)), inputDict)
    return newDict
end


"""
    createNestedDict(dict::AbstractDict)

Creates a nested dictionary from a flat dictionary where keys are strings separated by dots (`.`).

# Arguments:
- `dict::AbstractDict`: A flat dictionary with keys as dot-separated strings.

# Returns:
- A nested dictionary where each dot-separated key is converted into nested dictionaries.

# Examples
```jldoctest
julia> using Sindbad

julia> dict = Dict("a.b.c" => 2, "a.b.d" => 3)
Dict{String, Int64} with 2 entries:
  "a.b.c" => 2
  "a.b.d" => 3

julia> nested_dict = createNestedDict(dict)
Dict{Any, Any} with 1 entry:
  "a" => OrderedDict{Any, Any}("b"=>OrderedDict{Any, Any}("c"=>2, "d"=>3))
```
"""
function createNestedDict(dict::AbstractDict)
    nested_dict = Dict()
    for kii ∈ keys(dict)
        key_list = split(kii, ".")
        key_dict = Dict()
        for key_index ∈ reverse(eachindex(key_list))
            subkey = key_list[key_index]
            if subkey == first(key_list)
                subkey_name = subkey
            else
                subkey_name = subkey * string(key_index)
            end
            if subkey == last(key_list)
                key_dict[subkey_name] = toOrderedDict(dict[kii])
            else
                if !haskey(key_dict, subkey_name)
                    # an OrderedDict, like the parsed json, so that a level that is new in
                    # the configuration is converted to a NamedTuple with the others
                    key_dict[subkey_name] = DataStructures.OrderedDict()
                    key_dict[subkey_name][key_list[key_index+1]] = key_dict[key_list[key_index+1]*string(key_index+1)]
                else
                    tmp = Dict()
                    tmp[subkey_name] = key_dict[key_list[key_index+1]*string(key_index + 1)]
                end
                delete!(key_dict, key_list[key_index+1] * string(key_index + 1))
                delete!(nested_dict, key_list[key_index+1] * string(key_index + 1))
            end
            nested_dict = deepMerge(nested_dict, key_dict)
        end
    end
    return nested_dict
end

# A dictionary given as a value in replace_info becomes an OrderedDict, like the parsed
# json. dict_to_namedtuple converts only OrderedDicts, so a plain Dict that adds a new
# field to the configuration would otherwise stay a Dict in info.
toOrderedDict(dict::AbstractDict) = DataStructures.OrderedDict{Any,Any}(k => toOrderedDict(v) for (k, v) ∈ dict)
toOrderedDict(value) = value

"""
    deepMerge(d::AbstractDict...) = merge(deepMerge, d...)
    deepMerge(d...) = d[end]

Recursively merges multiple dictionaries, giving priority to the last dictionary.

# Arguments:
- `d::AbstractDict...`: One or more dictionaries to merge.

# Returns:
- A single dictionary with merged fields, where the last dictionary's values take precedence.

# Examples
```jldoctest
julia> using Sindbad

julia> dict1 = Dict("a" => Dict("b" => 1), "c" => 2)
Dict{String, Any} with 2 entries:
  "a" => Dict("b" => 1)
  "c" => 2

julia> dict2 = Dict("a" => Dict("d" => 3), "e" => 4)
Dict{String, Any} with 2 entries:
  "a" => Dict("d" => 3)
  "e" => 4

julia> merged = deepMerge(dict1, dict2)
Dict{String, Any} with 3 entries:
  "a" => Dict{String, Any}("b" => 1, "d" => 3)
  "c" => 2
  "e" => 4
```
"""
function deepMerge end

deepMerge(d::AbstractDict...) = merge(deepMerge, d...)
deepMerge(d...) = d[end]

"""
    getRootDirs(local_root, sindbad_experiment)

Determines the root directories for the SINDBAD framework and the experiment.

# Arguments:
- `local_root`: The local root directory of the SINDBAD project.
- `sindbad_experiment`: The path to the experiment configuration file.

# Returns:
- A NamedTuple containing the root directories for the experiment, SINDBAD, and settings.
"""
function getRootDirs(local_root, sindbad_experiment)
    # sindbad_root = join(split(local_root, path_separator)[1:(end-2)] |> collect, path_separator)
    exp_base_path = dirname(sindbad_experiment)
    root_dir = (; experiment=normalize_path_separator(local_root), settings=normalize_path_separator(exp_base_path))
    # root_dir = (; experiment=local_root, sindbad=sindbad_root, settings=exp_base_path)
    return root_dir
end


"""
    getConfiguration(sindbad_experiment::String; replace_info=Dict())

Loads the experiment configuration from a JSON or JLD2 file.

# Arguments:
- `sindbad_experiment::String`: Path to the experiment configuration file.
- `replace_info::Dict`: A dictionary of fields to replace in the configuration.

# Returns:
- A NamedTuple containing the experiment configuration.

# Notes:
- Supports both JSON and JLD2 formats.
- If `replace_info` is provided, the specified fields are replaced in the configuration.

# Examples
```jldoctest
julia> using Sindbad

julia> # Load configuration from JSON file
julia> # config = getConfiguration("experiment_config.json")

julia> # Load with configuration overrides
julia> # config = getConfiguration("experiment_config.json"; replace_info=Dict("output" => Dict("save_all" => true)))
```
"""
function getConfiguration(sindbad_experiment::String; replace_info=Dict())
    local_root = dirname(Base.active_project())
    if !isabspath(sindbad_experiment)
        sindbad_experiment = joinpath(local_root, sindbad_experiment)
    end
    roots = getRootDirs(local_root, sindbad_experiment)
    roots = (; roots..., sindbad_experiment)
    info = nothing
    if endswith(sindbad_experiment, ".json")
        info_exp = getExperimentConfiguration(sindbad_experiment; replace_info=replace_info)
        info = readConfiguration(info_exp, roots.settings)
    elseif endswith(sindbad_experiment, ".jld2")
        #todo running from the jld2 file here still does not work because the loaded info is a named tuple and replacing the fields will not work due to issues with merge and creating a dictionary from nested namedtuple
        # info = Dict(pairs(load(sindbad_experiment)["info"]))
        info = load(sindbad_experiment)["info"]
    else
        error(
            "sindbad can only be run with either a json or a jld2 data file. Provide a correct experiment file"
        )
    end
    if !isempty(replace_info)
        non_exp_dict = filter(x -> !startswith(first(x), "experiment"), replace_info)
        if !isempty(non_exp_dict)
            info = replaceInfoFields(info, non_exp_dict)
        end
    end
    if !haskey(info["experiment"]["basics"]["config_files"], "optimization") && (info["experiment"]["flags"]["run_optimization"] || info["experiment"]["flags"]["calc_cost"])
        @warn "The config files in experiment_json and changes in replace_info do not include optimization_json. But, the settings for flags to run_optimization [set as $(info["experiment"]["flags"]["run_optimization"])] and/or calc_cost [set as $(info["experiment"]["flags"]["calc_cost"])] are set to true. These flags will be set to false from now on. The experiment will not run as intended further downstream. Cannot run optimization or calculate cost without the optimization settings. "
        info["experiment"]["flags"]["run_optimization"] = false
        info["experiment"]["flags"]["calc_cost"] = false
    end

    new_info = DataStructures.OrderedDict()
    new_info["settings"] = DataStructures.OrderedDict()
    for (k,v) in info
        new_info["settings"][k] = v
    end
    # @show keys(info)
    if !endswith(sindbad_experiment, ".jld2")
        infoTuple = dict_to_namedtuple(new_info)
    end
    infoTuple = (; infoTuple..., temp=(; experiment=(; dirs=roots)))

    print_info_separator()

    return infoTuple
    # return info
end


"""
    getExperimentConfiguration(experiment_json::String; replace_info=Dict())

Loads the basic configuration from an experiment JSON file.

# Arguments:
- `experiment_json::String`: Path to the experiment JSON file.
- `replace_info::Dict`: A dictionary of fields to replace in the configuration.

# Returns:
- A dictionary containing the experiment configuration.
"""
function getExperimentConfiguration(experiment_json::String; replace_info=Dict())
    parseFile = parsefile(experiment_json; dicttype=DataStructures.OrderedDict)
    info = DataStructures.OrderedDict()
    info["experiment"] = DataStructures.OrderedDict()
    for (k, v) ∈ parseFile
        info["experiment"][k] = v
    end
    if !isempty(replace_info)
        exp_dict = filter(x -> startswith(first(x), "experiment"), replace_info)
        if !isempty(exp_dict)
            info = replaceInfoFields(info, exp_dict)
        end
    end
    return info
end


"""
    readConfiguration(info_exp::AbstractDict, base_path::String)

Reads the experiment configuration files (JSON or CSV) and returns a dictionary.

The `parameters` config file can also be a zarr or netCDF parameter file. It is
then stored as a parameter input with only its `data_path`, see `getParameterInput`.

# Arguments:
- `info_exp::AbstractDict`: The experiment configuration dictionary.
- `base_path::String`: The base path for resolving relative file paths.

# Returns:
- A dictionary containing the parsed configuration files.
"""
function readConfiguration(info_exp::AbstractDict, base_path::String)
    info = DataStructures.OrderedDict()
    print_info(readConfiguration, @__FILE__, @__LINE__, "reading configuration files")
    for (k, v) ∈ info_exp["experiment"]["basics"]["config_files"]
        config_path = joinpath(base_path, v)
        print_info(nothing, @__FILE__, @__LINE__, "→→→    `$(k)` ::: `$(config_path)`")
        info_exp["experiment"]["basics"]["config_files"][k] = config_path
        if endswith(v, ".json")
            tmp = parsefile(config_path; dicttype=DataStructures.OrderedDict)
            info[k] = removeComments(tmp) # remove on first level
        elseif endswith(v, ".csv")
            prm = CSV.File(config_path)
            tmp = Table(prm)
            info[k] = tmp
        elseif k == "parameters" && isParameterFile(v)
            # a parameter file given directly uses all its variables, and their
            # settings are read from the attributes in getParameters
            default_map = DataStructures.OrderedDict{String,Any}("data_path" => config_path)
            info[k] = DataStructures.OrderedDict{String,Any}("default_parameter_map" => default_map, "variables" => DataStructures.OrderedDict{String,Any}())
        end
    end

    # rm second level
    for (k, v) ∈ info
        if typeof(v) <: Dict
            ks = keys(info[k])
            tmpDict = DataStructures.OrderedDict()
            for ki ∈ ks
                tmpDict[ki] = removeComments(info[k][ki])
            end
            info[k] = tmpDict
        end
    end
    info["experiment"] = info_exp["experiment"]
    return info
end


"""
    isParameterFile(path)

Returns true when `path` is a zarr or netCDF file, which can be given directly as the
`parameters` config file to set the parameters per location.
"""
isParameterFile(path) = any(ext -> endswith(rstrip(path, '/'), ext), (".zarr", ".nc"))


"""
    removeComments(inputDict::AbstractDict)

Removes unnecessary comment fields from a dictionary.

# Arguments:
- `inputDict`: The input dictionary.

# Returns:
- A new dictionary with comment fields removed.
"""
function removeComments(inputDict::AbstractDict)
    newDict = filter(x -> !occursin(".c", first(x)), inputDict)
    newDict = filter(x -> !occursin("comments", first(x)), newDict)
    newDict = filter(x -> !occursin("comment", first(x)), newDict)
    return newDict
end
removeComments(input) = input

# replace_info keys that may be missing from the configuration files, because the code
# reads them only when they are set. `*` matches any one key, and keys below these are
# not checked.
const OPTIONAL_CONFIG_KEYS = (
    "forcing.subset",
    "forcing.variables.*.data_path",
    "optimization.observations.variables.*.*.data_path",
    "experiment.flags.run_lazy",
    "experiment.model_output.plot_resolution",
    "experiment.basics.config_files.parameters",
    "model_structure.sindbad_models",
)

function isOptionalConfigKey(path_parts)
    return any(OPTIONAL_CONFIG_KEYS) do optional_key
        optional_parts = split(optional_key, ".")
        length(path_parts) >= length(optional_parts) || return false
        all(o == "*" || o == k for (k, o) ∈ zip(path_parts, optional_parts))
    end
end

# Walks `path_parts[depth:end]` from `config` and records in `missing_keys` every key
# that does not exist in `config` at its level.
function collectMissingConfigKeys!(missing_keys, config, path_parts, depth, value)
    key = path_parts[depth]
    if !haskey(config, key)
        # only the optional key itself may be missing, not a level above it
        isOptionalConfigKey(path_parts[1:depth]) && return missing_keys
        push!(missing_keys, (join(path_parts, "."), join(path_parts[1:depth-1], "."), String.(collect(keys(config)))))
        return missing_keys
    end
    next_config = config[key]
    # an existing value that is not a dictionary is replaced whole, so nothing below it
    # is checked
    next_config isa AbstractDict || return missing_keys
    if depth < length(path_parts)
        return collectMissingConfigKeys!(missing_keys, next_config, path_parts, depth + 1, value)
    end
    # a dictionary value is merged into the existing dictionary, so its keys are checked
    if value isa AbstractDict
        for (sub_key, sub_value) ∈ value
            collectMissingConfigKeys!(missing_keys, next_config, [path_parts; String(sub_key)], depth + 1, sub_value)
        end
    end
    return missing_keys
end

"""
    checkReplaceInfoKeys(info::AbstractDict, replace_dict::AbstractDict)

Warns when a key of `replace_dict` does not exist in `info`, so that a mistyped key
does not silently add a new field to the configuration. The key is still added, since
it can be a setting that is valid but not given in the configuration files. Every key
is checked against the keys of `info` at the level it replaces, except the optional
settings in `OPTIONAL_CONFIG_KEYS`.
"""
function checkReplaceInfoKeys(info::AbstractDict, replace_dict::AbstractDict)
    missing_keys = []
    for (full_key, value) ∈ replace_dict
        collectMissingConfigKeys!(missing_keys, info, String.(split(full_key, ".")), 1, value)
    end
    isempty(missing_keys) && return nothing
    msg = join(map(missing_keys) do (k, level, available)
        level_text = isempty(level) ? "the top level" : "`$(level)`"
        "  - `$(k)`: not found at $(level_text). Available keys there: $(join(sort(available), ", "))."
    end, "\n")
    @warn "replace_info has keys that do not exist in the configuration. They are added, so check that none is mistyped:\n$(msg)"
    return nothing
end

"""
    replaceInfoFields(info::AbstractDict, replace_dict::AbstractDict)

Replaces fields in the `info` dictionary with values from the `replace_dict`, after
warning with `checkReplaceInfoKeys` about the keys that do not exist. Those keys are
added.

# Arguments:
- `info::AbstractDict`: The original dictionary.
- `replace_dict::AbstractDict`: The dictionary containing replacement values.

# Returns:
- A new dictionary with the replaced fields.
"""
function replaceInfoFields(info::AbstractDict, replace_dict::AbstractDict)
    checkReplaceInfoKeys(info, replace_dict)
    nested_replace_dict = createNestedDict(replace_dict)
    info = deepMerge(Dict(info), nested_replace_dict)
    return info
end

