export getForcing

"""
    collectForcingSizes(info, in_yax)

Collects the sizes of forcing dimensions from the input YAXArray.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `in_yax`: The input YAXArray containing forcing data.

# Returns:
- A NamedTuple `f_sizes` where each dimension name is paired with its size.

# Notes:
- The function retrieves the size of the time dimension and spatial dimensions specified in the experiment configuration.
- If the dimension is not directly accessible, it uses `DimensionalData.lookup` to retrieve the size.
"""
function collectForcingSizes(info, in_yax)
    time_dim_name = Symbol(info.experiment.data_settings.forcing.data_dimension.time)
    dnames = Symbol[]
    dsizes = []
    push!(dnames, time_dim_name)
    collectTimeSizes!(in_yax, dsizes, time_dim_name)
    for space ∈ info.experiment.data_settings.forcing.data_dimension.space
        push!(dnames, Symbol(space))
        push!(dsizes, length(getproperty(in_yax, Symbol(space))))
    end
    f_sizes = (; Pair.(dnames, dsizes)...)
    return f_sizes
end


function collectTimeSizes!(incube::YAXArrays.YAXArray, dsizes, time_dim_name)
    new_size = length(DimensionalData.lookup(incube, time_dim_name))
    push!(dsizes, new_size)
    return nothing
end

function collectTimeSizes!(incube::AxisKeys.KeyedArray, dsizes, time_dim_name)
    new_size = length(getproperty(incube, time_dim_name))
    push!(dsizes, new_size)
    return nothing
end

"""
    collectTimeSizes!(incube::YAXArrays.YAXArray, dsizes, time_dim_name)
    collectTimeSizes!(incube::AxisKeys.KeyedArray, dsizes, time_dim_name)

Collects the size of the time dimension from the input cube and appends it to `dsizes`.
"""
function collectTimeSizes! end

"""
    collectForcingHelpers(info, f_sizes, f_dimensions)

Generates a NamedTuple of helper information for forcing data.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `f_sizes`: A NamedTuple containing the sizes of forcing dimensions.
- `f_dimensions`: A NamedTuple containing the dimensions of the forcing data.

# Returns:
- A NamedTuple `f_helpers` containing helper information for forcing data.

# Notes:
- Includes dimensions, axes, subset information, and sizes for the forcing data.
"""
function collectForcingHelpers(info, f_sizes, f_dimensions)
    f_helpers = (;)
    f_helpers = set_namedtuple_field(f_helpers, (:dimensions, info.experiment.data_settings.forcing.data_dimension))
    f_helpers = set_namedtuple_field(f_helpers, (:axes, f_dimensions))
    if hasproperty(info.experiment.data_settings.forcing, :subset)
        f_helpers = set_namedtuple_field(f_helpers, (:subset, info.experiment.data_settings.forcing.subset))
    else
        f_helpers = set_namedtuple_field(f_helpers, (:subset, nothing))
    end
    f_helpers = set_namedtuple_field(f_helpers, (:sizes, f_sizes))
    return f_helpers
end

"""
    createForcingNamedTuple(incubes, f_sizes, f_dimensions, info)

Creates a NamedTuple containing forcing data and metadata.

# Arguments:
- `incubes`: A collection of input cubes (YAXArray) containing forcing data.
- `f_sizes`: A NamedTuple containing the sizes of forcing dimensions.
- `f_dimensions`: A NamedTuple containing the dimensions of the forcing data.
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.

# Returns:
- A NamedTuple `forcing` containing:
  - `data`: The processed input cubes.
  - `dims`: The dimensions of the forcing data.
  - `variables`: The names of the forcing variables.
  - `f_types`: The types of the forcing data (e.g., `ForcingWithTime` or `ForcingWithoutTime`).
  - `helpers`: Helper information for the forcing data.
  - `parameters`: The parameters per location from `getParameters`, or `nothing`.

# Notes:
- Processes the input cubes to determine their types and dimensions.
- Helper information is generated using `collectForcingHelpers`.
"""
function createForcingNamedTuple(incubes, f_sizes, f_dimensions, info; parameters=nothing)
    print_info(getForcing, @__FILE__, @__LINE__, "processing forcing helpers...")
    @debug "     ::dimensions::"
    indims = getDataDims.(incubes, Ref(Symbol.(info.experiment.data_settings.forcing.data_dimension.space)))
    @debug "     ::variable names::"
    forcing_vars = keys(info.experiment.data_settings.forcing.variables)
    f_helpers = collectForcingHelpers(info, f_sizes, f_dimensions)
    typed_cubes = getInputArrayOfType(incubes, info.helpers.run.input_array_type)
    data_ts_type=[]
    time_dim_name = Symbol(info.experiment.data_settings.forcing.data_dimension.time)
    for incube in typed_cubes
        push!(data_ts_type, collectTypesTiDim(incube, time_dim_name))
    end
    data_ts_type = [_dt for _dt in data_ts_type]
    f_types =  Tuple(Tuple.(Pair.(forcing_vars, data_ts_type)))
    print_info_separator()
    forcing = (;
        data=(; zip(forcing_vars, typed_cubes)...),
        dims=indims,
        variables=forcing_vars,
        f_types = f_types,
        helpers=f_helpers,
        parameters=parameters)
    return forcing
end

# Fixes bug. Collecting forcing variables `WithTime` was not working for YAXArrays
# These two functions now dispatch on KeyedArray and YAXArray
# remove hardcoded time_dim_name and use the one from info.experiment.data_settings.forcing.data_dimension.time 
"""
 collectTypesTiDim(incube::AxisKeys.KeyedArray, time_dim_name::Symbol)
"""
function collectTypesTiDim(incube::AxisKeys.KeyedArray, time_dim_name::Symbol)
    if in(time_dim_name, AxisKeys.dimnames(incube))
        return ForcingWithTime()
    else
        return ForcingWithoutTime()
    end
end

"""
 collectTypesTiDim(incube::YAXArrays.YAXArray, time_dim_name::Symbol)
"""
function collectTypesTiDim(incube::YAXArrays.YAXArray, time_dim_name::Symbol)
    if hasdim(incube, time_dim_name)
        return ForcingWithTime()
    else
        return ForcingWithoutTime()
    end
end

# DiskArrayEngine interpolates each output block from a window of 2 input points per
# axis, so only methods of degree 0 and 1 are valid here.
const FORCING_INTERPOLATION_METHODS = (
    Nearest=Interpolations.Constant(),
    Constant=Interpolations.Constant(),
    Previous=Interpolations.Constant(Interpolations.Previous),
    Next=Interpolations.Constant(Interpolations.Next),
    Linear=Interpolations.Linear(),
)

"""
    getInterpolationMethod(method_name::AbstractString)

Returns the Interpolations.jl method for the name given in the forcing settings.

# Arguments:
- `method_name`: One of `"Nearest"`, `"Constant"`, `"Previous"`, `"Next"` or `"Linear"`.
  `"None"` is handled before this call in `resampleToTarget` and has no method.

# Returns:
- The interpolation method to pass to `YAXArrays.xresample`.

# Notes:
- `"Nearest"` and `"Constant"` are the same method.
- Higher order methods such as `Quadratic` or `Cubic` are not supported, because
  DiskArrayEngine interpolates each output block from only 2 input points per axis.
"""
function getInterpolationMethod(method_name::AbstractString)
    method_key = Symbol(method_name)
    if !hasproperty(FORCING_INTERPOLATION_METHODS, method_key)
        valid_names = join(["None", string.(keys(FORCING_INTERPOLATION_METHODS))...], ", ")
        error("unknown forcing interpolation method `$(method_name)`. Valid methods are: $(valid_names). Quadratic and Cubic are not supported because each output value is interpolated from 2 input points per axis.")
    end
    return getproperty(FORCING_INTERPOLATION_METHODS, method_key)
end

"""
    toSymbolVector(dim_names)

Returns the dimension names as a vector of Symbols. A single name such as `"site"` is
wrapped into a one element vector.
"""
toSymbolVector(dim_names::Union{AbstractString,Symbol}) = [Symbol(dim_names)]
toSymbolVector(dim_names) = Symbol.(collect(dim_names))

"""
    mergeForcingGroup(group_fallback, group_name, setting_sources...)

Merges a grouped forcing setting such as `dimension` or `interpolation_method` key by
key, so that a variable can override only one key of the group.

# Arguments:
- `group_fallback`: A NamedTuple with the values used when no source sets a key.
- `group_name`: The name of the group, e.g. `:dimension`.
- `setting_sources`: The settings to merge in increasing priority, e.g. the default
  forcing settings and then the settings of one variable.

# Returns:
- A NamedTuple with the merged group.
"""
function mergeForcingGroup(group_fallback::NamedTuple, group_name::Symbol, setting_sources...)
    merged_group = group_fallback
    for setting_source in setting_sources
        if hasproperty(setting_source, group_name) && !isnothing(getproperty(setting_source, group_name))
            merged_group = merge_namedtuple_prefer_nonempty(merged_group, getproperty(setting_source, group_name))
        end
    end
    return merged_group
end

"""
    getForcingVariableInfo(default_info, var_settings, forcing_data_settings)

Merges the default forcing settings with the settings of one variable.

# Arguments:
- `default_info`: The `default_forcing` settings.
- `var_settings`: The settings of one forcing variable.
- `forcing_data_settings`: The forcing settings of the experiment.

# Returns:
- The merged settings of the variable, where `dimension` and `interpolation_method`
  always have the keys `space` and `time`.

# Notes:
- `dimension` falls back to `data_dimension.space` and `data_dimension.time`.
- `interpolation_method` falls back to `"None"`, so a variable is not interpolated
  along an axis unless `default_forcing` or the variable itself sets a method.
"""
function getForcingVariableInfo(default_info, var_settings, forcing_data_settings)
    vinfo = merge_namedtuple_prefer_nonempty(default_info, var_settings)
    dims_fallback = (; space=forcing_data_settings.data_dimension.space, time=forcing_data_settings.data_dimension.time)
    var_dims = mergeForcingGroup(dims_fallback, :dimension, default_info, var_settings)
    method_fallback = (; space="None", time="None")
    var_methods = mergeForcingGroup(method_fallback, :interpolation_method, default_info, var_settings)
    vinfo = set_namedtuple_field(vinfo, (:dimension, var_dims))
    vinfo = set_namedtuple_field(vinfo, (:interpolation_method, var_methods))
    return vinfo
end

"""
    renameToCanonicalDims(yax, var_dims, forcing_data_settings)

Renames the space and time dimensions of a variable to the names in
`data_dimension`, so that all forcing cubes share the same dimension names.

# Arguments:
- `yax`: The YAXArray of one forcing variable.
- `var_dims`: The merged `dimension` group of the variable, with `space` and `time`.
- `forcing_data_settings`: The forcing settings of the experiment.

# Returns:
- The YAXArray with renamed dimensions. Dimensions that the cube lacks are skipped.
"""
function renameToCanonicalDims(yax, var_dims, forcing_data_settings)
    canonical_space = toSymbolVector(forcing_data_settings.data_dimension.space)
    var_space = toSymbolVector(var_dims.space)
    if length(var_space) != length(canonical_space)
        error("forcing variable space dimensions $(var_space) do not match the number of space dimensions in data_dimension.space $(canonical_space).")
    end
    dim_renames = Pair{Symbol,Symbol}[]
    for (var_dim, canonical_dim) in zip(var_space, canonical_space)
        if var_dim != canonical_dim && hasdim(yax, var_dim)
            push!(dim_renames, var_dim => canonical_dim)
        end
    end
    var_time = Symbol(var_dims.time)
    canonical_time = Symbol(forcing_data_settings.data_dimension.time)
    if var_time != canonical_time && hasdim(yax, var_time)
        push!(dim_renames, var_time => canonical_time)
    end
    isempty(dim_renames) && return yax
    return set(yax, dim_renames...)
end

"""
    getTargetDims(cubes, target_variable, dim_names)

Returns the dimensions of `target_variable` that define the target resolution.

# Arguments:
- `cubes`: A NamedTuple of the forcing cubes.
- `target_variable`: The name of the forcing variable that sets the resolution.
- `dim_names`: The canonical names of the dimensions to take from that variable.

# Returns:
- A Tuple of the dimensions of the target variable.
"""
function getTargetDims(cubes, target_variable, dim_names)
    target_key = Symbol(target_variable)
    if !hasproperty(cubes, target_key)
        error("target_resolution variable `$(target_variable)` is not one of the forcing variables.")
    end
    target_cube = getproperty(cubes, target_key)
    target_dims = Tuple(dims(target_cube, dim_name) for dim_name in dim_names if hasdim(target_cube, dim_name))
    if isempty(target_dims)
        error("target_resolution variable `$(target_variable)` has none of the dimensions $(dim_names).")
    end
    return target_dims
end

"""
    isSameLookup(lookup_a, lookup_b)

Checks whether two dimension lookups have the same values, using `isapprox` for
numbers.
"""
function isSameLookup(lookup_a, lookup_b)
    length(lookup_a) == length(lookup_b) || return false
    if eltype(lookup_a) <: Number && eltype(lookup_b) <: Number
        return isapprox(collect(lookup_a), collect(lookup_b))
    end
    return collect(lookup_a) == collect(lookup_b)
end

"""
    resampleToTarget(incube, target_dims, method_name, num_type, var_name)

Remaps a forcing cube to the target dimensions with the given interpolation method.

# Arguments:
- `incube`: The forcing cube.
- `target_dims`: A Tuple of target dimensions, or `nothing` to skip.
- `method_name`: The name of the interpolation method, see `getInterpolationMethod`.
- `num_type`: The number type of the remapped cube.
- `var_name`: The name of the forcing variable, used in the log.

# Returns:
- The remapped cube. It is returned unchanged when it already matches every target
  dimension that it has, or when `method_name` is `"None"`.
"""
function resampleToTarget(incube, target_dims, method_name, num_type, var_name)
    isnothing(target_dims) && return incube
    needs_resample = any(target_dims) do target_dim
        dim_name = DD.name(target_dim)
        hasdim(incube, dim_name) && !isSameLookup(DD.lookup(incube, dim_name), DD.lookup(target_dim))
    end
    needs_resample || return incube
    if method_name == "None"
        target_names = join(string.(DD.name.(target_dims)), ", ")
        print_info(nothing, @__FILE__, @__LINE__, "`$(var_name)` keeps its own $(target_names) because its interpolation_method is None", n_m=4)
        return incube
    end
    method = getInterpolationMethod(method_name)
    return YAXArrays.xresample(incube; to=target_dims, method=method, outtype=num_type)
end

"""
    remapForcing(incubes, vinfos, forcing_data_settings, ::Val{num_type})

Remaps the forcing cubes to the space and time resolution set in `target_resolution`.

# Arguments:
- `incubes`: A Tuple of `variable_name => cube` pairs.
- `vinfos`: The merged settings of each variable, in the same order as `incubes`.
- `forcing_data_settings`: The forcing settings of the experiment.
- `::Val{num_type}`: The number type of the remapped cubes.

# Returns:
- A Tuple of the remapped cubes.

# Notes:
- `target_resolution.space.variable` names the variable whose space grid is used,
  and `target_resolution.time.variable` the variable whose time axis is used.
- An axis is skipped when its group is missing, its `variable` is missing or empty,
  or its `apply` is `false`. `apply` defaults to `true`. Without any axis the cubes
  are returned unchanged.
- Space is remapped first with `interpolation_method.space` of each variable, then
  time with `interpolation_method.time`.
"""
function remapForcing(incubes, vinfos, forcing_data_settings, ::Val{num_type}) where {num_type}
    target_resolution = hasproperty(forcing_data_settings, :target_resolution) ? forcing_data_settings.target_resolution : nothing
    space_variable = getTargetVariable(target_resolution, :space)
    time_variable = getTargetVariable(target_resolution, :time)
    if isnothing(space_variable) && isnothing(time_variable)
        return last.(incubes)
    end
    cubes = (; incubes...)
    data_dimension = forcing_data_settings.data_dimension
    space_target = isnothing(space_variable) ? nothing : getTargetDims(cubes, space_variable, toSymbolVector(data_dimension.space))
    time_target = isnothing(time_variable) ? nothing : getTargetDims(cubes, time_variable, [Symbol(data_dimension.time)])
    space_note = isnothing(space_variable) ? "switched off" : "`$(space_variable)`"
    time_note = isnothing(time_variable) ? "switched off" : "`$(time_variable)`"
    print_info(remapForcing, @__FILE__, @__LINE__, "remapping forcing variables to target resolution. space: $(space_note), time: $(time_note)")
    return map(incubes, vinfos) do (var_name, incube), vinfo
        incube = resampleToTarget(incube, space_target, vinfo.interpolation_method.space, num_type, var_name)
        resampleToTarget(incube, time_target, vinfo.interpolation_method.time, num_type, var_name)
    end
end

"""
    getTargetVariable(target_resolution, axis_name)

Returns `target_resolution.<axis_name>.variable`, or `nothing` when the axis group is
missing, its `variable` is missing or empty, or its `apply` is `false`.
"""
function getTargetVariable(target_resolution, axis_name::Symbol)
    isnothing(target_resolution) && return nothing
    hasproperty(target_resolution, axis_name) || return nothing
    axis_settings = getproperty(target_resolution, axis_name)
    isnothing(axis_settings) && return nothing
    if hasproperty(axis_settings, :apply) && axis_settings.apply == false
        return nothing
    end
    hasproperty(axis_settings, :variable) || return nothing
    target_variable = axis_settings.variable
    if isnothing(target_variable) || isempty(target_variable)
        return nothing
    end
    return target_variable
end


"""
    getForcing(info::NamedTuple)

Reads forcing data from the `data_path` specified in the experiment configuration and returns a NamedTuple with the forcing data.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.

# Returns:
- A NamedTuple `forcing` containing:
  - `data`: The processed input cubes.
  - `dims`: The dimensions of the forcing data.
  - `variables`: The names of the forcing variables.
  - `f_types`: The types of the forcing data (e.g., `ForcingWithTime` or `ForcingWithoutTime`).
  - `helpers`: Helper information for the forcing data.
  - `parameters`: The parameters per location set by a json or zarr/nc `parameters`
    input, or `nothing`. They are kept apart from `data`, see `getParameters`.

# Notes:
- Reads forcing data from the specified data path and processes it using the SINDBAD framework.
- Handles spatiotemporal and spatial-only forcing data.
- Applies masks and subsets to the forcing data if specified in the configuration.
- Each variable can name its own source dimensions in `dimension.space`, as a vector
  or a single name such as `"site"`, and `dimension.time`. They are renamed to the
  names in `data_dimension` before subsetting.
- When `target_resolution.space.variable` or `target_resolution.time.variable`
  names a forcing variable and that axis has `apply` set to `true`, all cubes are
  remapped to its space grid or time axis with the methods in
  `interpolation_method.space` and `interpolation_method.time`. A method of `"None"`,
  which is the default, leaves that variable on its own grid. See `remapForcing`.
"""
function getForcing(info::NamedTuple)
    nc_default = nothing
    forcing_data_settings = info.experiment.data_settings.forcing
    # forcing_data_settings = info.experiment.data_settings.forcing
    data_path = forcing_data_settings.default_forcing.data_path
    if !isnothing(data_path)
        data_path = getAbsDataPath(info, data_path)
        print_info(getForcing, @__FILE__, @__LINE__, "default_data_path: `$(data_path)`")
        nc_default = YAXArrays.open_dataset(data_path)
    end

    forcing_mask = nothing
    if :sel_mask ∈ keys(forcing_data_settings)
        if !isnothing(forcing_data_settings.forcing_mask.data_path)
            mask_path = getAbsDataPath(info, forcing_data_settings.forcing_mask.data_path)
            _, forcing_mask = getYaxFromSource(nothing, mask_path, nothing, forcing_data_settings.forcing_mask.source_variable)
            forcing_mask = positive_mask(forcing_mask)
        end
    end

    default_info = info.experiment.data_settings.forcing.default_forcing
    forcing_vars = keys(forcing_data_settings.variables)
    tar_dims = getTargetDimensionOrder(info)
    print_info(getForcing, @__FILE__, @__LINE__, "getting forcing variables. Units given in forcing settings are not strictly enforced but shown for reference. Bounds are applied after unit conversion...", n_m=1)
    num_type = Val{info.helpers.numbers.num_type}()
    loaded_vars = map(forcing_vars) do k
        nc = nc_default
        vinfo = getForcingVariableInfo(default_info, forcing_data_settings.variables[k], forcing_data_settings)
        data_path_v = getAbsDataPath(info, getfield(vinfo, :data_path))
        nc, yax = getYaxFromSource(nc, data_path, data_path_v, vinfo.source_variable)
        yax = renameToCanonicalDims(yax, vinfo.dimension, forcing_data_settings)
        incube = subsetAndProcessYax(yax, forcing_mask, tar_dims, vinfo, info, num_type)
        v_op = vinfo.additive_unit_conversion ? " + " : " * "
        v_op = v_op * "$(vinfo.source_to_sindbad_unit)"
        v_string = "`$(k)` ($(vinfo.sindbad_unit), $(vinfo.bounds)) = <$(vinfo.space_time_type)> `$(vinfo.source_variable)` ($(vinfo.source_unit)) $(v_op)"
        print_info(nothing, @__FILE__, @__LINE__, v_string, n_m=4)
        (k => incube, vinfo)
    end
    incubes = first.(loaded_vars)
    vinfos = last.(loaded_vars)
    interpincubes = remapForcing(incubes, vinfos, forcing_data_settings, num_type)
    # The sizes are taken after remapping so that they match the target resolution.
    f_sizes = nothing
    f_dimension = nothing
    i_spatiotemporal = findfirst(vinfo -> vinfo.space_time_type == "spatiotemporal", vinfos)
    if !isnothing(i_spatiotemporal)
        f_sizes = collectForcingSizes(info, interpincubes[i_spatiotemporal])
        f_dimension = getSindbadDims(interpincubes[i_spatiotemporal])
    end
    parameters = getParameters(info, f_dimension, NamedTuple{Tuple(forcing_vars)}(Tuple(interpincubes)))
    return createForcingNamedTuple(interpincubes, f_sizes, f_dimension, info; parameters=parameters)
end
