export saveOutCubes
export saveRestartCubes


"""
Converts an N-dimensional array of any size into a output-compatible data array without the unnecessary dimension.

# Arguments
- `_dat::AbstractArray{<:Any,N}`: Input N-dimensional array of arbitrary type

# Returns
Output-compatible data array
"""
function getModelDataArray(_dat::AbstractArray{<:Any,N}) where N
    dim = 1
    inds = map(size(_dat)) do _
        ind = dim == 2 ? 1 : Colon()
        dim += 1
        ind
    end
    _dat[inds...]
end


"""
    getYaxForVariable(data_out, data_dim, variable_name, catalog_name, t_step)

Processes YAXArray for a specific variable from simulation output.

# Arguments
- `data_out`: Output data from the simulation
- `data_dim`: Dimensions of the data output variable
- `variable_name`: Name of the variable to save as
- `catalog_name`: Name in the SINDBAD catalog of variables
- `t_step`: Time resolution for which to extract the data

# Returns
YAXArray specified variable at the given time resolution.
"""
function getYaxForVariable(data_out, data_dim, variable_name, catalog_name, t_step)
    data_prop = getVariableInfo(catalog_name, t_step)
    if size(data_out, 2) == 1
        data_out = getModelDataArray(data_out)
    end
    data_yax = DataLoaders.YAXArray(data_dim, data_out, data_prop)
    return data_yax
end


"""
    saveOutCubes(data_path_base, global_metadata, var_pairs, data, data_dims, out_format, t_step, <: OutputStrategy)
    saveOutCubes(info, out_cubes, output_dims, output_vars)

saves the output variables from the run as one file

# Arguments:
- `data_path_base`: base path of the output file including the directory and file prefix
- `global_metadata`: a collection of  global metadata information to write to the output file
- `data`: data to be written to file
- `data_dims`: a vector of dimension of data for each variable to be written to a file
- `var_pairs`: a tuple of pairs of sindbad variables to write including the field and subfield of land as the first and last element
- `out_format`: format of the output file
- `t_step`: a string for time step of the model run to be used in the units attribute of variables
- `<: OutputStrategy`: Dispatch type indicating file output mode with the following options:
    - `::DoSaveSingleFile`: single file with all the variables
    - `::DoNotSaveSingleFile`: single file per variable

# note: this function is overloaded to handle different dispatch types and the version with fewer arguments is used as a shorthand for the single file output mode

# Examples
```jldoctest
julia> using Sindbad

julia> # Save output cubes (shorthand version)
julia> # saveOutCubes(info, out_cubes, output_dims, output_vars)

julia> # Save to single file
julia> # saveOutCubes(data_path_base, global_metadata, var_pairs, data, data_dims, "nc", t_step, DoSaveSingleFile())
```
"""
function saveOutCubes end

function saveOutCubes(data_path_base, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoSaveSingleFile)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file for all variables")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    all_yax = Tuple(getYaxForVariable.(data, data_dims, variable_names, catalog_names, Ref(t_step)))
    data_path = data_path_base * "_all_variables.$(out_format)"
    print_info(nothing, @__FILE__, @__LINE__, "saved all variables to `$(data_path)`", n_m=4)
    ds_new = DataLoaders.YAXArrays.Dataset(; (; zip(variable_names, all_yax)...)..., properties=global_metadata)
    DataLoaders.YAXArrays.savedataset(ds_new, path=data_path, append=true, overwrite=true)
    return nothing
end

function saveOutCubes(data_path_base, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoNotSaveSingleFile)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file per variable")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    for vn ∈ eachindex(var_pairs)
        catalog_name = catalog_names[vn]
        variable_name = variable_names[vn]
        data_yax = getYaxForVariable(data[vn], data_dims[vn], variable_name, catalog_name, t_step)
        data_path = data_path_base * "_$(variable_name).$(out_format)"
        print_info(nothing, @__FILE__, @__LINE__, "saved `$(variable_name)` to `$(data_path)`", n_m=4)
        ds_new = DataLoaders.YAXArrays.Dataset(; (variable_name => data_yax,)..., properties=global_metadata)
        DataLoaders.YAXArrays.savedataset(ds_new, path=data_path, overwrite=true)
    end
    return nothing
end


function saveOutCubes(info, out_cubes, output_dims, output_vars)
    saveOutCubes(info.output.file_info.file_prefix, info.output.file_info.global_metadata, out_cubes, output_dims, output_vars, info.output.format, info.experiment.basics.temporal_resolution, info.helpers.run.save_single_file)
end


"""
    saveRestartCubes(info, restart)

Saves the pools after spinup of a forward run, which is the state at the start of the
simulation period, to the restart file.

# Arguments:
- `info`: a SINDBAD NamedTuple with all information needed for setup and execution of an experiment
- `restart`: the restart data of the run, which is either:
    - a NamedTuple with the `variables`, `dims` and `data` arrays of an eager run (`run_helpers.restart`)
    - a NamedTuple with the restart `Dataset` and `variables` of a lazy run (`runTEMYax`)

# Notes:
- The file is `restart_` followed by the base name of the output files, in the output
  format, for example `restart_<experiment>_<domain>.zarr`.
- It is always one file with all variables, whatever `save_single_file` is set to.
- The variables have no time dimension. A variable with more than one layer has a
  layer dimension followed by the spatial dimensions, and all other variables have the
  spatial dimensions only. The restart state is the state at the start of the
  simulation period, and its date is in the `restart_date` global attribute.
- Each variable is named after its subfield in `land.pools`, so the file can be added
  to the forcing for the `SpinupInput` spinup mode.
"""
function saveRestartCubes(info, restart)
    data_path = getRestartFilePath(info)
    restart_metadata = getRestartMetadata(info)
    restart_ds = getRestartDataset(info, restart, restart_metadata)
    print_info(nothing, @__FILE__, @__LINE__, "saving pools after spinup to `$(data_path)`", n_m=4)
    DataLoaders.YAXArrays.savedataset(restart_ds, path=data_path, overwrite=true)
    return nothing
end

"""
    getRestartFilePath(info)

Returns the path of the restart file, which is the output file prefix with `restart_`
added in front of its base name.
"""
function getRestartFilePath(info)
    file_prefix = info.output.file_info.file_prefix
    return joinpath(dirname(file_prefix), "restart_" * basename(file_prefix)) * ".$(info.output.format)"
end

"""
    getRestartMetadata(info)

Returns the global metadata of the output files with the date of the restart state added.
"""
function getRestartMetadata(info)
    restart_metadata = copy(info.output.file_info.global_metadata)
    restart_metadata["restart_date"] = string(info.helpers.dates.date_begin)
    return restart_metadata
end

"""
    getRestartDataset(info, restart, restart_metadata)

Builds the `Dataset` of the restart file from the restart data of an eager or a lazy run.
"""
function getRestartDataset(info, restart, restart_metadata)
    if hasproperty(restart, :dataset)
        restart_ds = restart.dataset
        return DataLoaders.YAXArrays.Dataset(; restart_ds.cubes..., properties=restart_metadata)
    end
    t_step = info.experiment.basics.temporal_resolution
    variable_names = last.(restart.variables)
    all_yax = map(restart.variables, restart.dims, restart.data) do var_pair, var_dims, var_data
        # drop the leading time dimension of size 1, and the layer dimension when the
        # variable has a single layer
        data_out = selectdim(var_data, 1, 1)
        if size(data_out, 1) == 1
            data_out = selectdim(data_out, 1, 1)
        end
        DataLoaders.YAXArray(var_dims, collect(data_out), getVariableInfo(getVarFull(var_pair), t_step))
    end
    return DataLoaders.YAXArrays.Dataset(; zip(variable_names, all_yax)..., properties=restart_metadata)
end
