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

# Notes:
- Processes the input cubes to determine their types and dimensions.
- Helper information is generated using `collectForcingHelpers`.
"""
function createForcingNamedTuple(incubes, f_sizes, f_dimensions, info)
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
        data=typed_cubes,
        dims=indims,
        variables=forcing_vars,
        f_types = f_types,
        helpers=f_helpers)
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
    if hasdim(incube, DD.Dim{time_dim_name})
        return ForcingWithTime()
    else
        return ForcingWithoutTime()
    end
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

# Notes:
- Reads forcing data from the specified data path and processes it using the SINDBAD framework.
- Handles spatiotemporal and spatial-only forcing data.
- Applies masks and subsets to the forcing data if specified in the configuration.
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
    vinfo = nothing
    f_sizes = nothing
    f_dimension = nothing
    num_type = Val{info.helpers.numbers.num_type}()
    incubes = map(forcing_vars) do k
        nc = nc_default
        vinfo = merge_namedtuple_prefer_nonempty(default_info, forcing_data_settings.variables[k])
        data_path_v = getAbsDataPath(info, getfield(vinfo, :data_path))
        nc, yax = getYaxFromSource(nc, data_path, data_path_v, vinfo.source_variable)
        incube = subsetAndProcessYax(yax, forcing_mask, tar_dims, vinfo, info, num_type)
        v_op = vinfo.additive_unit_conversion ? " + " : " * "
        v_op = v_op * "$(vinfo.source_to_sindbad_unit)"
        v_string = "`$(k)` ($(vinfo.sindbad_unit), $(vinfo.bounds)) = <$(vinfo.space_time_type)> `$(vinfo.source_variable)` ($(vinfo.source_unit)) $(v_op)"
        print_info(nothing, @__FILE__, @__LINE__, v_string, n_m=4)
        if vinfo.space_time_type == "spatiotemporal" && isnothing(f_sizes)
            f_sizes = collectForcingSizes(info, incube)
            f_dimension = getSindbadDims(incube)
        end
        incube
    end
    return createForcingNamedTuple(incubes, f_sizes, f_dimension, info)
end
