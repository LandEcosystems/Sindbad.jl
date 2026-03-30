
export getOutDims
export getOutDimsArrays
export prepTEMOut
export setupOptiOutput


"""
    getNumericArrays(info, forcing_sizes)

Defines and instantiates numeric arrays for SINDBAD output variables.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_sizes`: A NamedTuple with forcing dimensions and their sizes.

# Returns:
- A vector of numeric arrays initialized with `NaN` values, where each array corresponds to an output variable.

# Notes:
- The arrays are created with dimensions based on the forcing sizes and the depth information of the output variables.
- The numeric type of the arrays is determined by the model settings (`info.helpers.numbers.num_type`).
- If forward differentiation is enabled (`info.helpers.run.use_forward_diff`), the array type is adjusted accordingly.

# Examples
```jldoctest
julia> using Sindbad

julia> # Create numeric arrays for output variables
julia> # forcing_sizes = (time=10, lat=5, lon=5)
julia> # numeric_arrays = getNumericArrays(info, forcing_sizes)
```
"""
function getNumericArrays(info, forcing_sizes)
    tem_output = info.output
    tem_helpers = info.helpers
    v_ind = 1
    outarray = map(tem_output.variables) do vname_full
        depth_size = 1
        depth_info = tem_output.depth_info[v_ind]
        depth_size = first(depth_info)
        ar = nothing
        ax_vals = values(forcing_sizes)
        ar = Array{getOutArrayType(tem_helpers.numbers.num_type, info.helpers.run.use_forward_diff), length(values(forcing_sizes)) + 1}(undef, ax_vals[1], depth_size, ax_vals[2:end]...)
        v_ind += 1
        ar .= info.helpers.numbers.num_type(NaN)
    end
    outarray = [outarray...]
    return outarray
end

"""
    getOutArrayType(num_type, ::DoUseForwardDiff | ::DoNotUseForwardDiff)

Determines the type of elements to be used in the output array based on whether forward differentiation is enabled.

# Arguments:
- `num_type`: The numeric type specified in the model settings (e.g., `Float64`).
- `::DoUseForwardDiff`: A type dispatch indicating that forward differentiation is enabled. Returns a generic type (`Real`) to support differentiation.
- `::DoNotUseForwardDiff`: A type dispatch indicating that forward differentiation is not enabled. Returns the specified numeric type (`num_type`).

# Returns:
- The type of elements to be used in the output array:
  - `Real` if forward differentiation is enabled.
  - `num_type` if forward differentiation is not enabled.

# Examples
```jldoctest
julia> using Sindbad

julia> # Get array type with forward differentiation enabled
julia> getOutArrayType(Float64, DoUseForwardDiff())
Real

julia> # Get array type without forward differentiation
julia> getOutArrayType(Float64, DoNotUseForwardDiff())
Float64
```
"""
function getOutArrayType end

function getOutArrayType(_, ::DoUseForwardDiff)
    return Real
end

function getOutArrayType(num_type, ::DoNotUseForwardDiff)
    return num_type
end

"""
    getOutDims(info, forcing_helpers[, ::OutputArray | ::OutputMArray | ::OutputSizedArray | ::OutputYAXArray])

Retrieves the dimensions for SINDBAD output based on the specified array backend.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_helpers`: A NamedTuple with information on forcing sizes and dimensions.
- `::OutputArray`: (Optional) A type dispatch for using a base Array as the array backend.
- `::OutputMArray`: (Optional) A type dispatch for using MArray as the array backend.
- `::OutputSizedArray`: (Optional) A type dispatch for using SizedArray as the array backend.
- `::OutputYAXArray`: (Optional) A type dispatch for using YAXArray as the array backend.

# Returns:
- A vector of output dimensions, where each dimension is represented as a tuple of `Dim` objects.

# Notes:
- For `OutputArray`, `OutputMArray`, and `OutputSizedArray`, all dimensions are included.
- For `OutputYAXArray`, spatial dimensions are excluded, and metadata is added for each variable.

# Examples
```jldoctest
julia> using Sindbad

julia> # Get output dimensions with default array type
julia> # outdims = getOutDims(info, forcing_helpers)

julia> # Get output dimensions with YAXArray
julia> # outdims = getOutDims(info, forcing_helpers, OutputYAXArray())
```
"""
function getOutDims end

function getOutDims(info, forcing_helpers)
    outdims = getOutDims(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims
end


function getOutDims(info, forcing_helpers, ::Union{OutputArray, OutputMArray, OutputSizedArray})
    outdims_pairs = getOutDimsPairs(info.output, forcing_helpers)
    outdims = map(outdims_pairs) do dim_pairs
        od = []
        for _dim in dim_pairs
            push!(od, YAXArrays.Dim{first(_dim)}(last(_dim)))
        end
        Tuple(od)
    end
    return outdims
end

function getOutDims(info, forcing_helpers, ::OutputYAXArray)
    outdims_pairs = getOutDimsPairs(info.output, forcing_helpers);
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    var_dims = map(outdims_pairs) do dim_pairs
        od = []
        for _dim in dim_pairs
            if first(_dim) ∉ space_dims
                push!(od, YAXArrays.Dim{first(_dim)}(last(_dim)))
            end
        end
        Tuple(od)
    end
    v_index = 1
    outdims = map(info.output.variables) do vname_full
        vname = string(last(vname_full))
        _properties = collectMetadata(info, vname_full)
        vdims = var_dims[v_index]
        # outformat = info.settings.experiment.model_output.format
        outformat = info.output.format # ? test and see if this works, which it should!
        backend = outformat == "nc" ? :netcdf : :zarr
        out_dim = YAXArrays.XOutput(vdims...)#=;
        properties = _properties,
        path=info.output.file_info.file_prefix * "_$(vname).$(outformat)",
        backend=backend,
        overwrite=true)=#
        v_index += 1
        out_dim
    end
    return outdims
end


"""
    getOutDimsArrays(info, forcing_helpers[, ::OutputArray | ::OutputMArray | ::OutputSizedArray | ::OutputYAXArray])

Retrieves the dimensions and corresponding data for SINDBAD output based on the specified array backend.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_helpers`: A NamedTuple with information on forcing sizes and dimensions.
- `::OutputArray`: (Optional) A type dispatch for using a base Array as the array backend.
- `::OutputMArray`: (Optional) A type dispatch for using MArray as the array backend.
- `::OutputSizedArray`: (Optional) A type dispatch for using SizedArray as the array backend.
- `::OutputYAXArray`: (Optional) A type dispatch for using YAXArray as the array backend.

# Returns:
- A tuple `(outdims, outarray)`:
  - `outdims`: A vector of output dimensions, where each dimension is represented as a tuple of `Dim` objects.
  - `outarray`: The corresponding data array, initialized based on the specified array backend.

# Notes:
- For `OutputArray`, `OutputMArray`, and `OutputSizedArray`, the data array is initialized with the appropriate backend type.
- For `OutputYAXArray`, the data array is set to `nothing`, as YAXArray handles data differently.

# Examples:
1. **Using a base Array**:
```julia
outdims, outarray = getOutDimsArrays(info, forcing_helpers, OutputArray())
```

2. **Using MArray**:
```julia
outdims, outarray = getOutDimsArrays(info, forcing_helpers, OutputMArray())
```

3. **Using SizedArray**:
```julia
outdims, outarray = getOutDimsArrays(info, forcing_helpers, OutputSizedArray())
```

4. **Using YAXArray**:
```julia
outdims, outarray = getOutDimsArrays(info, forcing_helpers, OutputYAXArray())
```

5. **Default behavior**:
```julia
outdims, outarray = getOutDimsArrays(info, forcing_helpers)
```
"""
function getOutDimsArrays end

function getOutDimsArrays(info, forcing_helpers)
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers, oarr::OutputArray)
    outdims = getOutDims(info, forcing_helpers, oarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers, omarr::OutputMArray)
    outdims = getOutDims(info, forcing_helpers, omarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    marray = MArray{Tuple{size(outarray)...},eltype(outarray)}(undef)
    return outdims, marray
end

function getOutDimsArrays(info, forcing_helpers, osarr::OutputSizedArray)
    outdims = getOutDims(info, forcing_helpers, osarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    sized_array = SizedArray{Tuple{size(outarray)...},eltype(outarray)}(undef)
    return outdims, sized_array
end

function getOutDimsArrays(info, forcing_helpers, oayax::OutputYAXArray)
    outdims = getOutDims(info, forcing_helpers, oayax)
    outarray = nothing
    return outdims, outarray
end

"""
    getOutDimsPairs(tem_output, forcing_helpers; dthres=1)

Creates dimension pairs for each output variable based on forcing dimensions and depth information.

# Arguments:
- `tem_output`: A NamedTuple containing information about output variables and depth dimensions of output arrays.
- `forcing_helpers`: A NamedTuple with information on forcing sizes, dimensions, and optional permutations.
- `dthres`: (Optional) A threshold for the number of depth layers to define depth as a new dimension. Defaults to `1`.

# Returns:
- A vector of tuples, where each tuple contains dimension pairs for an output variable. Each dimension pair is represented as a `Pair` of a dimension name and its corresponding range or size.

# Notes:
- If `forcing_helpers.dimensions.permute` is provided, the function reorders dimensions based on the permutation.
- Depth dimensions are included if their size exceeds the threshold `dthres`. If the depth size is `1`, the depth dimension is labeled as `"idx"`.
- The function processes each output variable independently, combining forcing dimensions and depth information.

# Examples:
1. **Basic usage**:
```julia
tem_output = (variables=[:var1, :var2], depth_info=[(3, "depth"), (1, "depth")])
forcing_helpers = (axes=[(:time, 10), (:lat, 5), (:lon, 5)], dimensions=(permute=nothing))
outdims_pairs = getOutDimsPairs(tem_output, forcing_helpers)
```

2. **With dimension permutation**:
```julia
forcing_helpers = (axes=[(:time, 10), (:lat, 5), (:lon, 5)], dimensions=(permute=["lon", "lat", "time"]))
outdims_pairs = getOutDimsPairs(tem_output, forcing_helpers)
```

3. **With depth threshold**:
```julia
outdims_pairs = getOutDimsPairs(tem_output, forcing_helpers; dthres=2)
```
"""
function getOutDimsPairs(tem_output, forcing_helpers; dthres=1)
    forcing_axes = forcing_helpers.axes
    dim_loops = first.(forcing_axes)
    axes_dims_pairs = []
    if !isnothing(forcing_helpers.dimensions.permute)
        dim_perms = Symbol.(forcing_helpers.dimensions.permute)
        if dim_loops !== dim_perms
            for ix in eachindex(dim_perms)
                dp_i = dim_perms[ix]
                dl_ind = findall(x -> x == dp_i, dim_loops)[1]
                f_a = forcing_axes[dl_ind]
                ax_dim = Pair(first(f_a), last(f_a))
                push!(axes_dims_pairs, ax_dim)
            end
        end
    else
        axes_dims_pairs = map(x -> Pair(first(x), last(x)), forcing_axes)
    end
    opInd = 1
    outdims_pairs = map(tem_output.variables) do vname_full
        depth_info = tem_output.depth_info[opInd]
        depth_size = first(depth_info)
        depth_name = last(depth_info)
        od = []
        push!(od, axes_dims_pairs[1])
        if depth_size > dthres
            if depth_size == 1
                depth_name = "idx"
            end
            push!(od, Pair(Symbol(depth_name), (1:depth_size)))
        end
        foreach(axes_dims_pairs[2:end]) do f_d
            push!(od, f_d)
        end
        opInd += 1
        Tuple(od)
    end
    return outdims_pairs
end


"""
    prepTEMOut(info::NamedTuple, forcing_helpers::NamedTuple)

Prepares the output NamedTuple required for running the Terrestrial Ecosystem Model (TEM) in SINDBAD.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_helpers`: A NamedTuple with information on forcing sizes and dimensions.

# Returns:
A NamedTuple `output_tuple` containing:
- `land_init`: The initial land state from `info.land_init`.
- `dims`: A vector of output dimensions, where each dimension is represented as a tuple of `Dim` objects.
- `data`: A vector of numeric arrays initialized for output variables.
- `variables`: A list of output variable names.
- Additional fields for optimization output if optimization is enabled.

# Notes:
- The function initializes the output dimensions and data arrays based on the specified array backend (`info.helpers.run.output_array_type`).
- If optimization is enabled (`info.helpers.run.run_optimization`), additional fields for optimized parameters are added to the output.
- The function uses helper functions like `getOutDimsArrays` and `setupOptiOutput` to prepare the output.

# Examples:
1. **Basic usage**:
```julia
output_tuple = prepTEMOut(info, forcing_helpers)
```

2. **Accessing output fields**:
```julia
dims = output_tuple.dims
data = output_tuple.data
variables = output_tuple.variables
```
"""
function prepTEMOut(info::NamedTuple, forcing_helpers::NamedTuple)
    print_info(prepTEMOut, @__FILE__, @__LINE__, "preparing output helpers for Terrestrial Ecosystem Model (TEM)", n_f=4)
    land = info.helpers.land_init
    output_tuple = (;)
    output_tuple = set_namedtuple_field(output_tuple, (:land_init, land))
    @debug "     prepTEMOut: getting out variables, dimension and arrays..."
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    output_tuple = set_namedtuple_field(output_tuple, (:dims, outdims))
    output_tuple = set_namedtuple_field(output_tuple, (:data, outarray))
    output_tuple = set_namedtuple_field(output_tuple, (:variables, info.output.variables))

    output_tuple = setupOptiOutput(info, output_tuple, info.helpers.run.run_optimization)
    @debug "\n----------------------------------------------\n"
    return output_tuple
end


"""
    setupOptiOutput(info::NamedTuple, output::NamedTuple[, ::DoRunOptimization | ::DoNotRunOptimization])

Creates the output fields needed for the optimization experiment.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `output`: A base output NamedTuple to which optimization-specific fields will be added.
- `::DoRunOptimization`: (Optional) A type dispatch indicating that optimization is enabled. Adds fields for optimized parameters.
- `::DoNotRunOptimization`: (Optional) A type dispatch indicating that optimization is not enabled. Returns the base output unchanged.

# Returns:
- A NamedTuple containing the base output fields, with additional fields for optimization if enabled.

# Notes:
- When optimization is enabled, the function:
  - Adds a `parameter_dim` field to the output, which includes the parameter dimension and metadata.
  - Creates an `OutDims` object for storing optimized parameters, with the appropriate backend and file path.
- When optimization is not enabled, the function simply returns the input `output` NamedTuple unchanged.

# Examples:
1. **With optimization enabled**:
```julia
output = setupOptiOutput(info, output, DoRunOptimization())
```

2. **Without optimization**:
```julia
output = setupOptiOutput(info, output, DoNotRunOptimization())
```
"""
function setupOptiOutput end

function setupOptiOutput(info::NamedTuple, output::NamedTuple, ::DoRunOptimization)
    @debug "     setupOptiOutput: getting parameter output for optimization..."
    params = info.optimization.parameter_table.name_full    
    paramaxis = YAXArrays.Dim{:parameter}(params)
    outformat = info.output.format
    backend = outformat == "nc" ? :netcdf : :zarr
    od = YAXArrays.XOutput(paramaxis)
        #path=joinpath(info.output.dirs.optimization,
        #    "optimized_parameters.$(outformat)"),
        #backend=backend,
        #overwrite=true)
    # list of parameter
    output = set_namedtuple_field(output, (:parameter_dim, od))
    return output
end

function setupOptiOutput(info::NamedTuple, output::NamedTuple, ::DoNotRunOptimization)
    return output
end


"""
    collectMetadata(info, vname)

Collects metadata for a specific output variable in the SINDBAD experiment.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `vname`: A tuple of symbols representing the variable name, e.g., `(:diagnostics, :water_balance)`.

# Returns:
- A dictionary `Dict{String, Any}` containing metadata for the specified variable, including:
  - Metadata from the variable catalog (if available).
  - Global metadata about the platform from `info.output.file_info.global_metadata`.

# Notes:
- If the variable is not found in the catalog, a warning is issued, and the metadata dictionary will not include catalog-specific information.
- The metadata includes platform information for every output variable. For datasets, this should ideally be added once, not for every variable.

# Examples:
1. **Collecting metadata for a variable**:
```julia
metadata = collectMetadata(info, (:diagnostics, :water_balance))
```

2. **Accessing specific metadata fields**:
```julia
platform_info = metadata["platform_info"]
variable_units = metadata["units"]
```

# Warnings:
- If the variable is not found in the catalog, a warning is logged.
"""
function collectMetadata(info, vname)
    metadata_platform = info.output.file_info.global_metadata
    _properties = Dict{String, Any}()
    try
        vinfo = getVariableInfo(vname, info.experiment.basics.temporal_resolution)
        for (k,v) in vinfo
            _properties[k] = v
        end
    catch
        @warn "variable `$(vname)` is not in the catalog. Please create a new entry in `sindbadVariableCatalog.jl`. "
    end
    # as of now this is for every single output cube, for datasets it should be only once, and not for every variable.
    _properties["platform_info"] = metadata_platform
    return _properties
end