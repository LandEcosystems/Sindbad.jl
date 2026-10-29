export saveOutCubes
export saveRestartCubes
export saveSpinupCubes
export saveParameterCubes
export savePerformanceMetrics


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
    getSaveKwargs(out_format, compression)
    getSaveKwargs(info)

Returns the keyword arguments for `savedataset` that set the compression of an output
file.

# Arguments
- `out_format`: format of the output file
- `compression`: compression level of the output file, with -1 or 0 for no
  compression and 1 to 9 for increasing compression. `nothing` uses the default of
  the format, which is 4 for NetCDF and 5 for Zarr.
- `info`: a SINDBAD NamedTuple with the output format and compression level in
  `info.output.data_compression.level`

# Notes
- For NetCDF, the level is the deflate level of the variables.
- For Zarr, the level is the `clevel` of the default Blosc compressor of Zarr.jl,
  which uses lz4 with byte shuffle. A level of -1 or 0 writes the arrays without a
  compressor.
- Other formats get no keywords and keep the default compressor of their backend.
"""
function getSaveKwargs(out_format, compression)
    out_format == "nc" && return (; compress=something(compression, 4))
    if out_format == "zarr"
        compression = something(compression, 5)
        compressor = compression > 0 ? DataLoaders.Zarr.BloscCompressor(clevel=compression) : DataLoaders.Zarr.NoCompressor()
        return (; compressor=compressor)
    end
    return (;)
end
getSaveKwargs(info) = getSaveKwargs(info.output.format, info.output.data_compression.level)


"""
    roundToDigits(data, digits)

Rounds the values of an output array to keep a given number of significant decimal
digits, so that the array compresses better when it is written to a file.

# Arguments
- `data`: output array to round
- `digits`: number of significant decimal digits to keep, or `nothing` to keep full
  precision

# Returns
- A rounded copy of `data`, or `data` itself when nothing needs rounding or `digits`
  is `nothing`.

# Notes
- Each value is rounded to the nearest number with the fewest mantissa bits that hold
  `digits` decimal digits, with ties to even. The rounded-off bits are zero, which
  deflate and Blosc compress well.
- The largest relative error is half the spacing of the kept bits, e.g., about 5e-7
  for 6 digits and 3e-5 for 4 digits.
- NaN and Inf values are kept as they are.
- Arrays of other element types and arrays that already have fewer mantissa bits than
  needed are returned unchanged.
"""
function roundToDigits(data::AbstractArray{T}, digits) where {T<:Base.IEEEFloat}
    keep_bits = ceil(Int, digits * log2(10))
    keep_bits >= Base.significand_bits(T) && return data
    return roundToBits.(data, keep_bits)
end

roundToDigits(data, digits) = data

roundToDigits(data::AbstractArray{<:Base.IEEEFloat}, ::Nothing) = data


"""
    roundToBits(x, keep_bits)

Rounds a float to the nearest value with `keep_bits` mantissa bits, with ties to
even.
"""
function roundToBits(x::T, keep_bits) where {T<:Base.IEEEFloat}
    isfinite(x) || return x
    U = Base.uinttype(T)
    shift = Base.significand_bits(T) - keep_bits
    ui = reinterpret(U, x)
    ui += (one(U) << (shift - 1)) - one(U) + ((ui >> shift) & one(U))
    return reinterpret(T, ui & ~((one(U) << shift) - one(U)))
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
    saveOutCubes(data_dir, global_metadata, var_pairs, data, data_dims, out_format, t_step, <: OutputStrategy)
    saveOutCubes(info, out_cubes, output_dims, output_vars)

saves the output variables from the run as one file

# Arguments:
- `data_dir`: directory of the output files, which are named after the variables
- `global_metadata`: a collection of  global metadata information to write to the output file
- `data`: data to be written to file
- `data_dims`: a vector of dimension of data for each variable to be written to a file
- `var_pairs`: a tuple of pairs of sindbad variables to write including the field and subfield of land as the first and last element
- `out_format`: format of the output file
- `t_step`: a string for time step of the model run to be used in the units attribute of variables
- `compression`: keyword for the compression level of NetCDF and Zarr files, with -1
  for no compression. The default `nothing` uses 4 for NetCDF and 5 for Zarr.
- `digits`: keyword for the number of significant decimal digits kept in the data.
  The default `nothing` writes the data at full precision.
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
julia> # saveOutCubes(data_dir, global_metadata, var_pairs, data, data_dims, "nc", t_step, DoSaveSingleFile())
```
"""
function saveOutCubes end

function saveOutCubes(data_dir, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoSaveSingleFile; compression=nothing, digits=nothing)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file for all variables")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    all_yax = Tuple(getYaxForVariable.(roundToDigits.(data, digits), data_dims, variable_names, catalog_names, Ref(t_step)))
    data_path = joinpath(data_dir, "all_variables.$(out_format)")
    print_info(nothing, @__FILE__, @__LINE__, "saved all variables to `$(data_path)`", n_m=4)
    ds_new = DataLoaders.YAXArrays.Dataset(; (; zip(variable_names, all_yax)...)..., properties=global_metadata)
    DataLoaders.YAXArrays.savedataset(ds_new; path=data_path, append=true, overwrite=true, getSaveKwargs(out_format, compression)...)
    return nothing
end

function saveOutCubes(data_dir, global_metadata, data, data_dims, var_pairs, out_format, t_step, ::DoNotSaveSingleFile; compression=nothing, digits=nothing)
    print_info(saveOutCubes, @__FILE__, @__LINE__, "saving one file per variable")
    catalog_names = getVarFull.(var_pairs)
    variable_names = getUniqueVarNames(var_pairs)
    for vn ∈ eachindex(var_pairs)
        catalog_name = catalog_names[vn]
        variable_name = variable_names[vn]
        data_yax = getYaxForVariable(roundToDigits(data[vn], digits), data_dims[vn], variable_name, catalog_name, t_step)
        data_path = joinpath(data_dir, "$(variable_name).$(out_format)")
        print_info(nothing, @__FILE__, @__LINE__, "saved `$(variable_name)` to `$(data_path)`", n_m=4)
        ds_new = DataLoaders.YAXArrays.Dataset(; (variable_name => data_yax,)..., properties=global_metadata)
        DataLoaders.YAXArrays.savedataset(ds_new; path=data_path, overwrite=true, getSaveKwargs(out_format, compression)...)
    end
    return nothing
end


function saveOutCubes(info, out_cubes, output_dims, output_vars)
    saveOutCubes(info.output.dirs.data, info.output.file_info.global_metadata, out_cubes, output_dims, output_vars, info.output.format, info.experiment.basics.temporal_resolution, info.helpers.run.save_single_file; compression=info.output.data_compression.level, digits=info.output.data_compression.digits)
end

# The output of a lazy run is a Dataset of cubes that already have their dimensions,
# so only the attributes of each variable are added before saving. Saving computes
# the cubes. The data are written at full precision, `digits` is not applied.
function saveOutCubes(info, out_cubes::DataLoaders.YAXArrays.Dataset, output_dims, output_vars)
    t_step = info.experiment.basics.temporal_resolution
    out_format = info.output.format
    data_dir = info.output.dirs.data
    save_kwargs = getSaveKwargs(out_format, info.output.data_compression.level)
    variable_names = getUniqueVarNames(output_vars)
    foreach(variable_names, getVarFull.(output_vars)) do variable_name, catalog_name
        merge!(out_cubes.cubes[variable_name].properties, getVariableInfo(catalog_name, t_step))
    end
    global_metadata = info.output.file_info.global_metadata
    if info.helpers.run.save_single_file isa DoSaveSingleFile
        data_path = joinpath(data_dir, "all_variables.$(out_format)")
        ds_new = DataLoaders.YAXArrays.Dataset(; (v => out_cubes.cubes[v] for v ∈ variable_names)..., properties=global_metadata)
        DataLoaders.YAXArrays.savedataset(ds_new; path=data_path, overwrite=true, save_kwargs...)
        print_info(nothing, @__FILE__, @__LINE__, "saved all variables to `$(data_path)`", n_m=4)
    else
        for variable_name ∈ variable_names
            data_path = joinpath(data_dir, "$(variable_name).$(out_format)")
            ds_new = DataLoaders.YAXArrays.Dataset(; (variable_name => out_cubes.cubes[variable_name],)..., properties=global_metadata)
            DataLoaders.YAXArrays.savedataset(ds_new; path=data_path, overwrite=true, save_kwargs...)
            print_info(nothing, @__FILE__, @__LINE__, "saved `$(variable_name)` to `$(data_path)`", n_m=4)
        end
    end
    return nothing
end


"""
    saveRestartCubes(info, restart)

Saves the pools of a forward run after the spinup step whose `save_restart` is true to
the restart file. That is the last step unless the settings mark another one.

# Arguments:
- `info`: a SINDBAD NamedTuple with all information needed for setup and execution of an experiment
- `restart`: the restart data of the run, which is either:
    - a NamedTuple with the `variables`, `dims` and `data` arrays of an eager run (`run_helpers.restart`)
    - a NamedTuple with the restart `Dataset` and `variables` of a lazy run (`runTEMYax`)

# Notes:
- The file is `restart` in the data output directory, in the output format, for
  example `restart.zarr`.
- It is always one file with all variables, whatever `save_single_file` is set to.
- The variables have no time dimension. A variable with more than one layer has a
  layer dimension followed by the spatial dimensions, and all other variables have the
  spatial dimensions only. The spinup runs before the simulation period, so the
  `restart_date` global attribute is the start date of the simulation. The
  `spinup_sequence_method` global attribute is the name of the spinup sequence method,
  e.g., `sequence_list` or `sequence_with_age`, and `spinup_mode` is the spinup mode of
  the step that saved the restart, e.g., `LoopTEM`.
- Each variable is named after its subfield in `land.pools`, so the file can be added
  to the forcing for the `SpinupInput` spinup mode.
"""
function saveRestartCubes(info, restart)
    data_path = getRestartFilePath(info)
    restart_metadata = getRestartMetadata(info, restart)
    restart_ds = getRestartDataset(info, restart, restart_metadata)
    print_info(nothing, @__FILE__, @__LINE__, "saving pools after the spinup step with save_restart to `$(data_path)`", n_m=4)
    DataLoaders.YAXArrays.savedataset(restart_ds; path=data_path, overwrite=true, getSaveKwargs(info)...)
    return nothing
end

"""
    getRestartFilePath(info)

Returns the path of the restart file, `restart` in the data output directory with the
extension of the output format.
"""
function getRestartFilePath(info)
    return joinpath(info.output.dirs.data, "restart.$(info.output.format)")
end

"""
    getRestartMetadata(info, restart)

Returns the global metadata of the output files with the date of the restart state, the
spinup sequence method and the spinup mode of the step that saved the restart added.

# Notes:
- The method is written with its name in the settings, e.g., `sequence_with_age` for
  `SequenceWithAge`.
- The spinup mode is the name of its type, e.g., `LoopTEM` or `SpinupInput`.
"""
function getRestartMetadata(info, restart)
    restart_metadata = copy(info.output.file_info.global_metadata)
    restart_metadata["restart_date"] = string(info.helpers.dates.date_begin)
    method_name = string(nameof(typeof(info.spinup.method)))
    restart_metadata["spinup_sequence_method"] = lowercase(replace(method_name, r"(?<!^)([A-Z])" => s"_\1"))
    restart_metadata["spinup_mode"] = restart.spinup_mode
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


"""
    saveSpinupCubes(info, spinup)

Saves `cEco` and `TWS` at every stored step of the spinup to the spinup file.

# Arguments:
- `info`: a SINDBAD NamedTuple with all information needed for setup and execution of
  an experiment
- `spinup`: the stored spinup of an eager run from `prepSpinupOut`, or `nothing`, in
  which case no file is written

# Notes:
- The file is `spinup` in the data output directory, in the output format, for
  example `spinup.zarr`.
- The variables and their dimensions are described in `prepSpinupOut`.
- The `spinup_sequence_method` global attribute is the name of the spinup sequence
  method, and `spinup_sequence` lists the steps of the sequence of the first
  location, as `mode:forcing:n_repeat:n_timesteps` separated by `;`.
"""
function saveSpinupCubes end

saveSpinupCubes(_, ::Nothing) = nothing

function saveSpinupCubes(info, spinup)
    data_path = getSpinupFilePath(info)
    spinup_metadata = copy(info.output.file_info.global_metadata)
    method_name = string(nameof(typeof(info.spinup.method)))
    spinup_metadata["spinup_sequence_method"] = lowercase(replace(method_name, r"(?<!^)([A-Z])" => s"_\1"))
    spinup_metadata["spinup_sequence"] = join([join((nameof(typeof(seq.spinup_mode)), seq.forcing, seq.n_repeat, seq.n_timesteps), ":") for seq ∈ first(spinup.sequences)], ";")
    t_step = info.experiment.basics.temporal_resolution
    all_yax = map(spinup.variables, spinup.dims, spinup.data) do var_pair, var_dims, var_data
        var_info = isnothing(var_pair) ? Dict{String,Any}("long_name" => "index of the spinup sequence step of the row, 0 before the spinup and -1 after the end of the sequence", "units" => "-") : getVariableInfo(getVarFull(var_pair), t_step)
        DataLoaders.YAXArray(var_dims, var_data, var_info)
    end
    spinup_ds = DataLoaders.YAXArrays.Dataset(; zip(spinup.names, all_yax)..., properties=spinup_metadata)
    print_info(nothing, @__FILE__, @__LINE__, "saving pools at every stored spinup step to `$(data_path)`", n_m=4)
    DataLoaders.YAXArrays.savedataset(spinup_ds; path=data_path, overwrite=true, getSaveKwargs(info)...)
    return nothing
end

"""
    getSpinupFilePath(info)

Returns the path of the spinup file, `spinup` in the data output directory with the
extension of the output format.
"""
function getSpinupFilePath(info)
    return joinpath(info.output.dirs.data, "spinup.$(info.output.format)")
end


"""
    saveParameterCubes(info, parameter_table, forcing_helpers)

Saves the parameters of an optimization run as a parameter file with one variable
per parameter, and writes its `params.json` next to it.

# Arguments:
- `info`: a SINDBAD NamedTuple with all information needed for setup and execution of an experiment
- `parameter_table`: the table of the optimized parameters, whose `optimized` column is saved
- `forcing_helpers`: the forcing helpers, which give the spatial dimensions and coordinates

# Returns:
- A NamedTuple with the `data_path` of the parameter file and the `json_path`.

# Notes:
- The file is in the optimization output directory, next to the csv of the optimized
  parameters. Its name is `params.zarr`, see `getParameterFilePath`. The json has the
  same name with a `.json` extension.
- Each variable is named `<model>__<parameter>`, see `parameterVariableName`, and has the
  spatial dimensions and coordinates of the forcing without time, e.g., the site
  names.
- The optimization gives one value for the whole domain, so every location has the
  same value.
- The attributes of each variable are the columns of the parameter table, see
  `parameterVariableAttributes`. The values are in the units of this run, given by the
  `units` and `timescale_run` attributes.
- The file and its json can be given as the `parameters` config file of another
  experiment to set the parameters per location. Single-site files can be concatenated
  along the site dimension first.
"""
function saveParameterCubes(info, parameter_table, forcing_helpers)
    data_path = getParameterFilePath(info)
    space_dims = Symbol.(forcing_helpers.dimensions.space)
    axes_values = Dict(Symbol(first(f_axis)) => last(f_axis) for f_axis ∈ forcing_helpers.axes)
    yax_dims = Tuple(DataLoaders.DD.Dim{s_dim}(collect(axes_values[s_dim])) for s_dim ∈ space_dims)
    space_sizes = Tuple(forcing_helpers.sizes[s_dim] for s_dim ∈ space_dims)

    variable_attributes = Pair{String,Any}[]
    all_yax = Pair{Symbol,Any}[]
    for p_index ∈ eachindex(parameter_table.name)
        p_value = parameter_table.optimized[p_index]
        if !(p_value isa Number)
            @warn "The parameter `$(parameter_table.name_full[p_index])` is not a scalar and is not saved to the parameter file."
            continue
        end
        variable_name = parameterVariableName(parameter_table.model[p_index], parameter_table.name[p_index])
        attributes = parameterVariableAttributes(parameter_table, p_index)
        p_data = fill(p_value, space_sizes...)
        push!(all_yax, Symbol(variable_name) => DataLoaders.YAXArray(yax_dims, p_data, Dict{String,Any}(attributes)))
        push!(variable_attributes, variable_name => attributes)
    end

    param_metadata = copy(info.output.file_info.global_metadata)
    param_metadata["parameter_source"] = "optimization"
    param_metadata["experiment_name"] = info.experiment.basics.name
    param_metadata["experiment_domain"] = info.experiment.basics.domain
    param_metadata["temporal_resolution"] = info.experiment.basics.temporal_resolution
    params_ds = DataLoaders.YAXArrays.Dataset(; all_yax..., properties=param_metadata)
    print_info(saveParameterCubes, @__FILE__, @__LINE__, "saving the optimized parameters to the parameter file `$(data_path)`", n_m=4)
    DataLoaders.saveParameterDataset(params_ds, data_path)

    json_path = first(splitext(rstrip(data_path, '/'))) * ".json"
    writeParameterInputJson(json_path, abspath(data_path), variable_attributes)
    print_info(nothing, @__FILE__, @__LINE__, "saved the parameters input of the parameter file to `$(json_path)`", n_m=4)
    return (; data_path, json_path)
end

"""
    getParameterFilePath(info)

Returns the path of the parameter file. It is in the optimization output directory, next
to the csv of the optimized parameters, and its name is `params.zarr`.

# Notes:
- Without an optimization output directory, e.g., in a run that does not optimize, the
  file is in the data output directory.
- The parameter file is always a zarr store, whatever the output format. NetCDF.jl
  cannot read string coordinates such as site names reliably.
"""
function getParameterFilePath(info)
    param_dir = hasproperty(info.output.dirs, :optimization) ? info.output.dirs.optimization : info.output.dirs.data
    return joinpath(param_dir, "params.zarr")
end


"""
    savePerformanceMetrics(info, cost_options, observations, def_output, opt_output)

Saves the performance of the default and the optimized output for every observation
constraint of the cost, in every metric of ErrorMetrics, to
`performance.csv` next to the csv of the optimized parameters, see
`getPerformanceFilePath`. Returns the path.

# Arguments:
- `info`: the experiment information of the forward runs
- `cost_options`: the cost options from `prepCostOptions`
- `observations`: the observation arrays of the cost
- `def_output`, `opt_output`: the output of the forward runs with the default and the
  optimized parameters

# Notes:
- One row per constraint, with its cost metric and weight, the number of points, the
  mean of the observation and of both outputs, `loss_def` and `loss_opt`, and a
  `<metric>_def` and `<metric>_opt` column per metric.
- `loss_def` and `loss_opt` are the weighted cost of the constraint, as in the
  optimization.
- The other columns use the data of the cost, after its aggregation, on the points
  where the observation, its uncertainty and both outputs are valid, so that both
  outputs are compared on the same points.
- A metric that is not finite, e.g. a correlation of one point, is NaN.
"""
function savePerformanceMetrics(info, cost_options, observations, def_output, opt_output)
    metrics = errorMetrics()
    loss_def = metricVector(def_output, observations, cost_options)
    loss_opt = metricVector(opt_output, observations, cost_options)
    rows = map(enumerate(cost_options)) do (i, cost_option)
        y, yσ, y_def = getData(def_output, observations, cost_option)
        _, _, y_opt = getData(opt_output, observations, cost_option)
        y, yσ, y_def, y_opt = (Float64.(vec(collect(a))) for a ∈ (y, yσ, y_def, y_opt))
        valid = isfinite.(y) .& isfinite.(yσ) .& isfinite.(y_def) .& isfinite.(y_opt)
        y, yσ, y_def, y_opt = y[valid], yσ[valid], y_def[valid], y_opt[valid]
        metric_values = Pair{Symbol,Float64}[]
        for m ∈ metrics, (run_name, ŷ) ∈ (("def", y_def), ("opt", y_opt))
            push!(metric_values, Symbol("$(nameof(typeof(m)))_$(run_name)") => performanceMetricValue(m, ŷ, y, yσ))
        end
        (; variable=String(cost_option.variable),
            cost_metric=String(nameof(typeof(cost_option.cost_metric))),
            cost_weight=Float64(cost_option.cost_weight), n=length(y),
            mean_obs=meanOrNaN(y), mean_def=meanOrNaN(y_def), mean_opt=meanOrNaN(y_opt),
            loss_def=Float64(loss_def[i]), loss_opt=Float64(loss_opt[i]), metric_values...)
    end
    performance_path = getPerformanceFilePath(info)
    CSV.write(performance_path, rows)
    print_info(savePerformanceMetrics, @__FILE__, @__LINE__, "saved the performance of the default and optimized output to `$(performance_path)`", n_m=4)
    return performance_path
end

"""
    errorMetrics()

Returns an instance of every concrete metric type of ErrorMetrics, sorted by name.
"""
function errorMetrics()
    metric_types = [getproperty(ErrorMetrics, n) for n ∈ names(ErrorMetrics)]
    metric_types = filter(t -> t isa DataType && t <: ErrorMetric && isconcretetype(t), metric_types)
    return [t() for t ∈ sort(metric_types; by=nameof)]
end

# the value of a metric, or NaN when it is not finite or cannot be calculated, e.g. a
# correlation of a constant series
function performanceMetricValue(m, ŷ, y, yσ)
    isempty(y) && return NaN
    value = try
        Float64(metric(m, ŷ, y, yσ))
    catch
        NaN
    end
    return isfinite(value) ? value : NaN
end

meanOrNaN(x) = isempty(x) ? NaN : sum(x) / length(x)

"""
    getPerformanceFilePath(info)

Returns the path of the performance file of `savePerformanceMetrics`. It is next to
the csv of the optimized parameters, and its name is `performance.csv`.
"""
function getPerformanceFilePath(info)
    performance_dir = hasproperty(info.output.dirs, :optimization) ? info.output.dirs.optimization : info.output.dirs.data
    return joinpath(performance_dir, "performance.csv")
end
