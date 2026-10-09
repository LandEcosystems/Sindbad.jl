using Sindbad
using Sindbad.DataLoaders.YAXArrays
using Sindbad.DataLoaders: DimensionalData

# Concatenates the parameter files of single-site runs along the site dimension, and
# writes the combined file with its params.json. The combined file can be given as the
# `parameters` config file of a multi-site experiment, whose `forcing.subset.site`
# then selects the sites to run.
#
# A parameter missing in a file is NaN for the sites of that file, and the experiment
# uses the default of the parameter there.
#
# The function needs Sindbad, so include this file from an environment that has it,
# e.g., `include(joinpath(pkgdir(Sindbad), "tools", "data_io", "concat_parameter_files.jl"))`.

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
- A site must be in only one file.
- The attributes of each variable are taken from the first file that has it. Its
  `model`, `name`, `timescale_run` and `units` must be the same in every file.
"""
function concatParameterFiles(param_paths, out_path; site_dim=:site)
    datasets = [open_dataset(p) for p ∈ param_paths]
    site_values = [collect(DimensionalData.lookup(first(values(ds.cubes)), site_dim)) for ds ∈ datasets]
    all_sites = reduce(vcat, site_values)
    if length(unique(all_sites)) != length(all_sites)
        error("Some sites are in more than one parameter file: $(unique(filter(s -> count(==(s), all_sites) > 1, all_sites)))")
    end

    var_names = unique(reduce(vcat, [collect(keys(ds.cubes)) for ds ∈ datasets]))
    all_yax = Pair{Symbol,Any}[]
    variable_attributes = Pair{String,Any}[]
    for var_name ∈ var_names
        attributes = nothing
        var_data = map(datasets, site_values) do ds, sites
            if !haskey(ds.cubes, var_name)
                return fill(NaN, length(sites))
            end
            cube = ds.cubes[var_name]
            cube_attributes = Dict{String,Any}(k => v for (k, v) ∈ cube.properties if !startswith(string(k), "_"))
            if isnothing(attributes)
                attributes = cube_attributes
            else
                for key ∈ ("model", "name", "timescale_run", "units")
                    if get(attributes, key, "") != get(cube_attributes, key, "")
                        error("The attribute `$(key)` of `$(var_name)` differs between the parameter files: $(get(attributes, key, "")) and $(get(cube_attributes, key, "")).")
                    end
                end
            end
            return Float64.(vec(Array(cube.data)))
        end
        push!(all_yax, var_name => YAXArray((DimensionalData.Dim{site_dim}(all_sites),), reduce(vcat, var_data), attributes))
        push!(variable_attributes, string(var_name) => attributes)
    end

    properties = Dict{String,Any}("parameter_source" => "concatenation", "source_files" => join(param_paths, ", "))
    savedataset(Dataset(; all_yax..., properties=properties), path=out_path, overwrite=true)
    json_path = first(splitext(rstrip(out_path, '/'))) * ".json"
    writeParameterInputJson(json_path, abspath(out_path), variable_attributes)
    println("wrote $(length(var_names)) parameters for $(length(all_sites)) sites to $(out_path) and $(json_path)")
    return (; out_path, json_path)
end


"""
    findParameterFiles(path_output; exclude=String[])

Returns the paths of the parameter files, i.e., the zarr directories named `params_*`,
under `path_output`, except those in `exclude`.
"""
function findParameterFiles(path_output; exclude=String[])
    all_dirs = [joinpath(root, d) for (root, dirs, _) ∈ walkdir(path_output) for d ∈ dirs]
    return filter(all_dirs) do p
        startswith(basename(p), "params_") && endswith(p, ".zarr") && p ∉ exclude
    end
end
