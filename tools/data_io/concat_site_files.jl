using Sindbad
using Sindbad.DataLoaders.YAXArrays
using Sindbad.DataLoaders: DimensionalData

# Concatenates the files of single-site runs along the site dimension. Two kinds of
# files are supported on top of the general `concatSiteDatasets`:
#
# - parameter files, combined with `concatParameterFiles`. The combined file and
#   its params.json can be given as the `parameters` config file of a multi-site
#   experiment, whose `forcing.subset.site` then selects the sites to run. A
#   parameter missing in a file is NaN for the sites of that file, and the
#   experiment uses the default of the parameter there.
# - restart files, combined with `concatRestartFiles`. The combined file can be added
#   to the forcing of a multi-site experiment for the `SpinupInput` spinup mode.
# - parameter files of optimizations of one class each, e.g., one PFT, combined with
#   `concatLookupParameterFiles` into a class map with its json. Another experiment
#   then takes the parameters of each location from its class in the forcing.
#
# The functions need Sindbad, so include this file from an environment that has it,
# e.g.,
# `include(joinpath(pkgdir(Sindbad), "tools", "data_io", "concat_site_files.jl"))`.

"""
    concatSiteDatasets(paths; site_dim=:site, check_attributes=("units",))

Reads the files `paths` and concatenates every variable along `site_dim`.

# Arguments:
- `paths`: the paths of the zarr or netCDF files, one or more sites each
- `site_dim`: the name of the site dimension, whose coordinates are the site names
- `check_attributes`: the attributes of a variable that must be the same in every file

# Returns:
- A NamedTuple with:
  - `dataset`: the combined `Dataset`
  - `variable_attributes`: `name => attributes` pairs of the variables, in file order
  - `sites`: the site names of the combined dataset

# Notes:
- A site must be in only one file.
- The other dimensions of a variable, e.g., the layers of a pool, must be the same in
  every file. A variable missing in a file is NaN for the sites of that file, and a
  warning is shown.
- The attributes of each variable are taken from the first file that has it.
- The global attributes are those of the files. An attribute with different values in
  the files gets the unique values joined by `, `.
"""
function concatSiteDatasets(paths; site_dim=:site, check_attributes=("units",))
    datasets = [open_dataset(p) for p ∈ paths]
    site_values = map(ds -> collect(DimensionalData.lookup(first(values(ds.cubes)), site_dim)), datasets)
    all_sites = reduce(vcat, site_values)
    if length(unique(all_sites)) != length(all_sites)
        error("Some sites are in more than one file: $(unique(filter(s -> count(==(s), all_sites) > 1, all_sites)))")
    end

    site_dim_new = DimensionalData.Dim{site_dim}(all_sites)
    var_names = unique(reduce(vcat, [collect(keys(ds.cubes)) for ds ∈ datasets]))
    all_yax = Pair{Symbol,Any}[]
    variable_attributes = Pair{String,Any}[]
    for var_name ∈ var_names
        cube, var_dims, attributes = concatSiteCubes(datasets, site_values, paths, var_name, site_dim, check_attributes)
        new_dims = map(var_dims) do d
            DimensionalData.name(d) == site_dim && return site_dim_new
            return DimensionalData.Dim{DimensionalData.name(d)}(collect(DimensionalData.lookup(d)))
        end
        push!(all_yax, var_name => YAXArray(Tuple(new_dims), cube, attributes))
        push!(variable_attributes, string(var_name) => attributes)
    end

    properties = mergeGlobalProperties(datasets)
    properties["source_files"] = join(paths, ", ")
    dataset = Dataset(; all_yax..., properties=properties)
    return (; dataset, variable_attributes, sites=all_sites)
end


"""
    concatSiteCubes(datasets, site_values, paths, var_name, site_dim, check_attributes)

Returns the data of `var_name` of all `datasets` concatenated along `site_dim`, the
dimensions of the first file that has it and its attributes.
"""
function concatSiteCubes(datasets, site_values, paths, var_name, site_dim, check_attributes)
    i_first = findfirst(ds -> haskey(ds.cubes, var_name), datasets)
    template = datasets[i_first].cubes[var_name]
    var_dims = DimensionalData.dims(template)
    site_pos = findfirst(d -> DimensionalData.name(d) == site_dim, var_dims)
    isnothing(site_pos) && error("The variable `$(var_name)` of $(paths[i_first]) has no `$(site_dim)` dimension.")
    other_dims = [(DimensionalData.name(d), collect(DimensionalData.lookup(d))) for d ∈ var_dims if DimensionalData.name(d) != site_dim]
    num_type = float(nonmissingtype(eltype(template)))
    attributes = Dict{String,Any}(k => v for (k, v) ∈ template.properties if !startswith(string(k), "_"))

    missing_in = String[]
    var_data = map(datasets, site_values, paths) do ds, sites, path
        if !haskey(ds.cubes, var_name)
            push!(missing_in, path)
            data_size = collect(size(template))
            data_size[site_pos] = length(sites)
            return fill(num_type(NaN), data_size...)
        end
        cube = ds.cubes[var_name]
        cube_dims = [(DimensionalData.name(d), collect(DimensionalData.lookup(d))) for d ∈ DimensionalData.dims(cube) if DimensionalData.name(d) != site_dim]
        if DimensionalData.name.(DimensionalData.dims(cube)) != DimensionalData.name.(var_dims) || cube_dims != other_dims
            error("The dimensions of `$(var_name)` in $(path) differ from those in $(paths[i_first]).")
        end
        for key ∈ check_attributes
            if get(attributes, key, "") != get(cube.properties, key, "")
                error("The attribute `$(key)` of `$(var_name)` differs between the files: $(get(attributes, key, "")) in $(paths[i_first]) and $(get(cube.properties, key, "")) in $(path).")
            end
        end
        return num_type.(replace(Array(cube.data), missing => NaN))
    end
    if !isempty(missing_in)
        @warn "The variable `$(var_name)` is not in $(length(missing_in)) of $(length(datasets)) files, so it is NaN for their sites: $(join(missing_in, ", "))"
    end
    return cat(var_data...; dims=site_pos), var_dims, attributes
end


"""
    mergeGlobalProperties(datasets)

Returns the global attributes of `datasets`. An attribute with different values in the
datasets gets the unique values joined by `, `.
"""
function mergeGlobalProperties(datasets)
    properties = Dict{String,Any}()
    all_keys = unique(reduce(vcat, [collect(string.(keys(ds.properties))) for ds ∈ datasets]))
    for key ∈ filter(k -> !startswith(k, "_"), all_keys)
        key_values = unique([ds.properties[key] for ds ∈ datasets if haskey(ds.properties, key)])
        properties[key] = length(key_values) == 1 ? only(key_values) : join(string.(key_values), ", ")
    end
    return properties
end


"""
    concatParameterFiles(param_paths, out_path; site_dim=:site)

Concatenates the parameter files `param_paths` along `site_dim` and writes the result to
`out_path` and its json next to it.

# Arguments:
- `param_paths`: the paths of the parameter files, e.g., from `saveParameterCubes`
- `out_path`: the path of the combined parameter file
- `site_dim`: the name of the site dimension

# Returns:
- A NamedTuple with the `out_path` of the combined file and its `json_path`.

# Notes:
- Write the combined file as zarr, like the parameter files of Sindbad, since netCDF
  cannot keep the site names as coordinates reliably.
- The `model`, `name`, `timescale_run` and `units` attributes of a parameter must be the
  same in every file. See `concatSiteDatasets` for the other rules.
"""
function concatParameterFiles(param_paths, out_path; site_dim=:site)
    combined = concatSiteDatasets(param_paths; site_dim=site_dim, check_attributes=("model", "name", "timescale_run", "units"))
    params_ds = combined.dataset
    params_ds.properties["parameter_source"] = "concatenation"
    saveParameterDataset(params_ds, out_path)
    json_path = first(splitext(rstrip(out_path, '/'))) * ".json"
    writeParameterInputJson(json_path, abspath(out_path), combined.variable_attributes)
    println("wrote $(length(combined.variable_attributes)) parameters for $(length(combined.sites)) sites to $(out_path) and $(json_path)")
    return (; out_path, json_path)
end


"""
    concatLookupParameterFiles(paths_by_value, out_path; lookup_variable="f_pft", default_value=nothing, site_dim=:site)

Combines the parameter files of optimizations of one class each into a class map, and
writes it to `out_path` with its json next to it.

# Arguments:
- `paths_by_value`: `value => path` pairs of a value of the lookup variable, e.g., a
  PFT, and the parameter file of the optimization of that value, e.g., from
  `saveParameterCubes`
- `out_path`: the path of the class map
- `lookup_variable`: the forcing variable that gives the class of each location in
  the experiments that use the class map. It names the dimension of the class map.
- `default_value`: the class whose values the locations of other classes use, or
  `nothing`, in which case they use the default of each parameter
- `site_dim`: the name of the site dimension of the parameter files

# Returns:
- A NamedTuple with the `out_path` of the class map and its `json_path`.

# Notes:
- An optimization of several sites gives one value for all of them, so the value of a
  class is the value of its sites. An error is raised when the sites differ.
- Each parameter variable keeps the attributes of the first file, and the `model`,
  `name`, `timescale_run` and `units` attributes must be the same in every file. A
  parameter missing in a file is NaN for its class, and the experiment uses the
  default of the parameter there.
- The class map has an `n_sites` variable with the number of sites of each class. It
  has no `model` and `name` attributes, so it is not read as a parameter.
- The json has the `lookup_parameter_map` of `default_parameter_map`, see
  `getParameters`, and no `variables`, since their settings are in the attributes.
- The `default` of `lookup_parameter_map` is always written, as `null` when
  `default_value` is `nothing`, so that the option is visible in the json. A `null`
  default makes the locations of other classes use the default of each parameter.
"""
function concatLookupParameterFiles(paths_by_value, out_path; lookup_variable="f_pft", default_value=nothing, site_dim=:site)
    paths_by_value = sort(collect(paths_by_value); by=first)
    class_values = Int.(first.(paths_by_value))
    allunique(class_values) || error("Some values of `$(lookup_variable)` have more than one file: $(class_values)")
    if !isnothing(default_value) && default_value ∉ class_values
        error("The default value $(default_value) of `$(lookup_variable)` has no parameter file. The values with one are $(class_values).")
    end
    paths = last.(paths_by_value)
    datasets = [open_dataset(p) for p ∈ paths]
    check_attributes = ("model", "name", "timescale_run", "units")

    var_names = unique(reduce(vcat, [Sindbad.DataLoaders.listParameterVariablesInFile(ds) for ds ∈ datasets]))
    lookup_dim = DimensionalData.Dim{Symbol(lookup_variable)}(class_values)
    all_yax = Pair{Symbol,Any}[]
    for var_name ∈ var_names
        i_first = findfirst(ds -> haskey(ds.cubes, var_name), datasets)
        attributes = Dict{String,Any}(string(k) => v for (k, v) ∈ datasets[i_first].cubes[var_name].properties if !startswith(string(k), "_"))
        values_by_class = map(datasets, paths) do ds, path
            haskey(ds.cubes, var_name) || return NaN
            cube = ds.cubes[var_name]
            for key ∈ check_attributes
                if get(attributes, key, "") != get(cube.properties, key, "")
                    error("The attribute `$(key)` of `$(var_name)` differs between the files: $(get(attributes, key, "")) in $(paths[i_first]) and $(get(cube.properties, key, "")) in $(path).")
                end
            end
            return classValue(Array(cube.data), var_name, path)
        end
        missing_in = paths[isnan.(values_by_class)]
        if !isempty(missing_in)
            @warn "The parameter `$(var_name)` has no value in $(length(missing_in)) of $(length(paths)) files, so it is NaN for their classes: $(join(missing_in, ", "))"
        end
        push!(all_yax, var_name => YAXArray((lookup_dim,), values_by_class, attributes))
    end
    n_sites = [length(DimensionalData.lookup(first(ds.cubes[v] for v ∈ var_names if haskey(ds.cubes, v)), site_dim)) for ds ∈ datasets]
    push!(all_yax, :n_sites => YAXArray((lookup_dim,), n_sites, Dict{String,Any}("description" => "number of sites of the optimization of the class")))

    properties = mergeGlobalProperties(datasets)
    properties["parameter_source"] = "class map by $(lookup_variable)"
    properties["source_files"] = join(paths, ", ")
    saveParameterDataset(Dataset(; all_yax..., properties=properties), out_path)

    # nothing is written as null, so the default option shows in the json
    lookup_parameter_map = Sindbad.Setup.DataStructures.OrderedDict{String,Any}("lookup_variable" => string(lookup_variable), "default" => default_value)
    default_map = Sindbad.Setup.DataStructures.OrderedDict{String,Any}("data_path" => abspath(out_path), "space_time_type" => "spatial", "lookup_parameter_map" => lookup_parameter_map)
    json_path = first(splitext(rstrip(out_path, '/'))) * ".json"
    open(json_path, "w") do io
        write(io, Sindbad.Setup.json(Dict("default_parameter_map" => default_map); pretty=true))
    end
    println("wrote $(length(var_names)) parameters for the values $(class_values) of `$(lookup_variable)` to $(out_path) and $(json_path)")
    return (; out_path, json_path)
end

"""
    classValue(values, var_name, path)

Returns the value of a parameter shared by all sites of a parameter file, NaN when no
site has a value, and an error when the sites differ.
"""
function classValue(values, var_name, path)
    site_values = filter(v -> !ismissing(v) && !isnan(v), vec(values))
    isempty(site_values) && return NaN
    v_first = Float64(first(site_values))
    if any(v -> !isapprox(Float64(v), v_first; rtol=1e-6), site_values)
        error("The sites of `$(var_name)` in $(path) have different values $(extrema(site_values)). A class map needs one value per file, as from an optimization of all its sites together.")
    end
    return v_first
end


"""
    concatRestartFiles(restart_paths, out_path; site_dim=:site)

Concatenates the restart files `restart_paths` along `site_dim` and writes the result to
`out_path`.

# Arguments:
- `restart_paths`: the paths of the restart files, e.g., from `saveRestartCubes`
- `out_path`: the path of the combined restart file
- `site_dim`: the name of the site dimension

# Returns:
- The `out_path` of the combined file.

# Notes:
- The site names stay the site coordinate, so that the forcing subset of a multi-site
  experiment selects its sites from the combined file.
- The pools of all files must have the same layers and units. See `concatSiteDatasets`
  for the other rules.
- Single-site runs often start at different dates, so `restart_date` can hold several
  dates. `SpinupInput` does not read it.
"""
function concatRestartFiles(restart_paths, out_path; site_dim=:site)
    combined = concatSiteDatasets(restart_paths; site_dim=site_dim, check_attributes=("units",))
    YAXArrays.savedataset(combined.dataset, path=out_path, overwrite=true)
    println("wrote $(length(combined.variable_attributes)) pools for $(length(combined.sites)) sites to $(out_path)")
    return out_path
end


"""
    findSiteFiles(path_output, prefix; exclude=String[])

Returns the paths of the zarr directories and netCDF files under `path_output` whose
names start with `prefix`, except those in `exclude`.
"""
function findSiteFiles(path_output, prefix; exclude=String[])
    all_paths = String[]
    for (root, dirs, files) ∈ walkdir(path_output)
        append!(all_paths, joinpath.(root, filter(d -> endswith(d, ".zarr"), dirs)))
        append!(all_paths, joinpath.(root, filter(f -> endswith(f, ".nc"), files)))
    end
    exclude_paths = rstrip.(exclude, '/')
    return filter(p -> startswith(basename(p), prefix) && p ∉ exclude_paths, all_paths)
end

"""
    findExperimentSiteFiles(path_output, exp_name, sub_dir, file_name)

Returns the files of the single-site runs of `exp_name` under `path_output`, one per
site, and the sites without one.

# Arguments:
- `path_output`: the directory with the output directories of the site runs
- `exp_name`: the experiment name, which names the directories
  `output_<site>_<exp_name>`
- `sub_dir`: the directory of the file in the output directory, e.g., `data`
- `file_name`: the file name without extension, e.g., `restart`. The file is
  `<file_name>.nc` or `.zarr`.

# Returns:
- A NamedTuple with the `paths` of the files and the `sites_without` a file.

# Notes:
- The directory name must end with the full experiment name, so `WR_DD` does not match
  the directories of `WR_DD_MT`.
"""
function findExperimentSiteFiles(path_output, exp_name, sub_dir, file_name)
    site_pattern = Regex("^output_(.+)_\\Q" * exp_name * "\\E\$")
    paths = String[]
    sites_without = String[]
    for dir_name ∈ sort(readdir(path_output))
        m = match(site_pattern, dir_name)
        (isnothing(m) || !isdir(joinpath(path_output, dir_name))) && continue
        site = m.captures[1]
        candidates = [joinpath(path_output, dir_name, sub_dir, "$(file_name).$(ext)") for ext ∈ ("nc", "zarr")]
        i_found = findfirst(ispath, candidates)
        isnothing(i_found) ? push!(sites_without, site) : push!(paths, candidates[i_found])
    end
    return (; paths, sites_without)
end

"""
    findParameterFiles(path_output; exclude=String[])

Returns the `params_*` files under `path_output`, which an optimization writes to its
optimization output directory.
"""
findParameterFiles(path_output; exclude=String[]) = findSiteFiles(path_output, "params_"; exclude=exclude)

"""
    findRestartFiles(path_output; exclude=String[])

Returns the `restart_*` files under `path_output`, which a forward run writes next to
its output files.
"""
findRestartFiles(path_output; exclude=String[]) = findSiteFiles(path_output, "restart_"; exclude=exclude)
