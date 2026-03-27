export getNumberOfTimeSteps
export mapCleanData
export cleanData
export applyUnitConversion
export applyQCBound
export subsetAndProcessYax
export yaxCubeToKeyedArray
export toDimStackArray
export AllNaN
"""
    AllNaN <: YAXArrays.DAT.ProcFilter

Specialized filter for YAXArrays to skip pixels with all `NaN` or `missing` values.

# Description
This struct is used as a specialized filter in data processing pipelines to identify or handle cases where all values in a data segment are NaN (Not a Number).
"""
struct AllNaN <: YAXArrays.DAT.ProcFilter end
YAXArrays.DAT.checkskip(::AllNaN, x) = all(ismissing, x) || all(isnan, x)

"""
    applyQCBound(_data, data_qc, bounds_qc, _data_fill)

Apply quality control bounds to data values.

# Arguments
- `_data`: Input data array to be quality controlled
- `data_qc`: Quality control flags associated with the data
- `bounds_qc`: Bounds/thresholds for quality control checks
- `_data_fill`: Fill value to use for data points that fail QC

# Returns
The quality controlled data array with values outside bounds replaced by fill value
"""
function applyQCBound(_data, data_qc, bounds_qc, _data_fill)
    _data_out = _data
    if data_qc < first(bounds_qc) || data_qc > last(bounds_qc)
        _data_out = _data_fill
    end
    return _data_out
end


"""
    applyUnitConversion(_data, conversion, isadditive=false)

Applies a simple factor to the input, either additively or multiplicatively depending on isadditive flag

# Arguments
- `_data`: Input data to be converted
- `conversion`: Conversion factor or function to be applied
- `isadditive`: Boolean flag indicating whether the conversion is additive (default: false) or multiplicative

# Returns
Converted data with the applied unit transformation
"""
function applyUnitConversion(_data, conversion, isadditive=false)
    if isadditive
        _data_out = _data + conversion
    else
        _data_out = _data * conversion
    end
    return _data_out
end



"""
    cleanData(_data, _data_fill, _data_info, ::Val{T}) where {T}

Applies a series of cleaning steps to the data, including replacing invalid data, applying unit conversion, and clamping to bounds.

# Arguments
- `_data`: The raw data to be cleaned
- `_data_fill`: Fill values or parameters for handling missing/invalid data
- `_data_info`: Information about the data structure and cleaning requirements
- `::Val{T}`: Value type parameter for dispatch

# Returns
Cleaned data according to the specified type parameter T
"""
function cleanData(_data, _data_fill, _data_info, ::Val{T}) where {T}
    _data = replace_invalid_number(_data, _data_fill)
    _data = applyUnitConversion(_data, _data_info.source_to_sindbad_unit,
        _data_info.additive_unit_conversion)
    bounds = _data_info.bounds
    if !isnothing(bounds)
        _data = clamp(_data, first(bounds), last(bounds))
    end
    return T(_data)
end


"""
    getDataDims(c, mappinginfo)

Retrieves the dimensions of data based on provided mapping information.

# Arguments
- `c`: The container or data structure to get dimensions from
- `mappinginfo`: Information about how the data is mapped

# Returns
The dimensions of the data specified by the mapping information.
"""
function getDataDims(c, mappinginfo)
    inax = []
    axnames = DimensionalData.name(dims(c))
    inollt = findall(∉(mappinginfo), axnames)
    !isempty(inollt) && append!(inax, axnames[inollt])
    return InDims(inax...; filter=AllNaN())
end

"""
    getDimPermutation(datDims, permDims)
Returns the permutation indices required to rearrange dimensions from `datDims` to match `permDims`.

# Arguments
- `datDims`: Array of current dimension names or indices
- `permDims`: Array of target dimension names or indices in desired order

# Returns
- Array of indices representing the required permutation
"""
function getDimPermutation(datDims, permDims)
    new_dim = Int[]
    for pd ∈ permDims
        datIndex = length(permDims)
        if pd in datDims
            datIndex = findfirst(isequal(pd), datDims)
        end
        push!(new_dim, datIndex)
    end
    return new_dim
end

"""
    getInputArrayOfType(input_data, <: SindbadInputDataType)

Converts the provided input data into a specific input array type.

# Arguments
- `input_data`: The data to be converted into an input array
- <: SindbadInputDataType: The specific input array type to convert the data into
    - `::InputArray`: Specifies the input array type as a simple array
    - `::InputKeyedArray`: Specifies the input array type as a keyed array
    - `::InputNamedDimsArray`: Specifies the input array type as a named dims array
    - `::InputYaxArray`: Specifies the input array type as a YAX array

# Returns
Returns the input data converted to the specified input array type.
"""
function getInputArrayOfType end

function getInputArrayOfType(input_data, ::InputArray)
    array_data = map(input_data) do c
        Array(c.data)
    end
    return array_data
end

function getInputArrayOfType(input_data, ::InputKeyedArray)
    keyed_array_data = map(input_data) do c
        t_dims = getSindbadDims(c)
        KeyedArray(Array(c.data); t_dims...)
    end
    return keyed_array_data
end

function getInputArrayOfType(input_data, ::InputNamedDimsArray)
    named_array_data = map(input_data) do c
        t_dims = getSindbadDims(c)
        NamedDimsArray(Array(c.data); t_dims...)
    end
    return named_array_data
end

function getInputArrayOfType(input_data, ::InputYaxArray)
    return input_data
end


"""
    getSindbadDims(c)

prepare the dimensions of data and name them appropriately for use in internal SINDBAD functions

# Arguments
- `c`: input data cube

# Returns
Dimensions for use in SINDBAD
"""
function getSindbadDims(c)
    dimnames = DimensionalData.name(dims(c))
    act_dimnames = []
    foreach(dimnames) do dimn
        td = dimn
        if dimn in (:Ti, :Time, :TIME, :t, :T, :TI)
            td = :time
        end
        push!(act_dimnames, td)
    end
    return [act_dimnames[k] => getproperty(c, dimnames[k]) |> Array for k ∈ eachindex(dimnames)]
end



"""
    getNumberOfTimeSteps(incubes, time_name)

Returns the number of time steps in the input data cubes.

# Arguments
- `incubes`: Input data cubes containing temporal information
- `time_name`: Name of the time dimension/variable

# Returns
Integer representing the total number of time steps in the data
"""
function getNumberOfTimeSteps(incubes, time_name)
    i1 = findfirst(c -> YAXArrays.Axes.findAxis(time_name, c) !== nothing, incubes)
    return length(getAxis(time_name, incubes[i1]).values)
end


"""
    getTargetDimensionOrder(info)

Retrieves the target dimension order to organize the forcing data from the provided information.

# Arguments
- `info`: Input information containing dimension order details.

# Returns
The ordered sequence of dimensions for the target.
"""
function getTargetDimensionOrder(info)
    tar_dims = nothing
    permute_dims = info.experiment.data_settings.forcing.data_dimension.permute
    if !isnothing(permute_dims)
        tar_dims = Symbol[]
        for pd ∈ permute_dims
            tdn = Symbol(pd)
            push!(tar_dims, tdn)
        end
    end
    return tar_dims
end

"""
    getYaxFromSource(nc, data_path, data_path_v, source_variable, info, <: DataFormatBackend)

Retrieve the data from a specified source.

# Arguments
- `nc`: The NetCDF file or object to read data from.
- `data_path`: The path to the data within the NetCDF file.
- `data_path_v`: The path to the variable within the NetCDF file.
- `source_variable`: The name of the source variable to extract data for.
- `info`: Additional information or metadata required for processing.
- `<: DataFormatBackend`: Specifies the SINDBAD backend being used.
    - `::BackendNetcdf`: Specifies that the function operates on a NetCDF backend.
    - `::BackendZarr`: Specifies that the backend being used is Zarr.

# Returns
- The file object and extracted YAX data from the specified source.

# Notes
- Ensure that the `nc` object and paths provided are valid and accessible.
- The functions are specific to the NetCDF and Zarr backend and may not work with other backends.
"""
function getYaxFromSource end

function getYaxFromSource(nc, data_path, data_path_v, source_variable, info, ::BackendNetcdf)
    if endswith(data_path_v, ".zarr")
        error("data path $(data_path_v) ends with .zarr (zarr data) but input data backend in experiment.exe_rules.input_data_backend is set as netcdf. Change input_data_backend or data_path.")
    end
    nc = loadDataFromPath(nc, data_path, data_path_v, source_variable)
    v = nc[source_variable]
    forcing_data_settings = info.experiment.data_settings.forcing
    ax = map(NCDatasets.dimnames(v)) do dn
        rax = nothing
        if dn == forcing_data_settings.data_dimension.time
            t = nc[forcing_data_settings.data_dimension.time]
            t = [_t for _t in t]
            rax = Dim{Symbol(dn)}(t)
        else
            if dn in keys(nc)
                dv = info.helpers.numbers.num_type.(nc[dn][:])
            else
                data_path_tmp = isnothing(data_path) ? data_path_v : data_path
                error("To avoid possible issues with dimensions, Sindbad does not run when the dimension variable $(dn) is not available in input data file $(data_path_tmp). Add the variable to the data, and try again.")
            end
            rax = Dim{Symbol(dn)}(dv)
        end
        rax
    end
    yax = YAXArray(Tuple(ax), v |> Array)
    return nc, yax
end

function getYaxFromSource(nc, data_path, data_path_v, source_variable, _, ::BackendZarr)
    if endswith(data_path_v, ".nc")
        error("data path $(data_path_v) ends with .nc (netCDF data) but input data backend in experiment.exe_rules.input_data_backend is set as zarr. Using zopen to open a nc data will crash the session. Change input_data_backend or data_path.")
    end

    nc = loadDataFromPath(nc, data_path, data_path_v, source_variable)
    yax = nc[source_variable]
    return nc, yax
end

"""
    loadDataFile(data_path::String) -> Any

Load data from the specified file path.

# Arguments
- `data_path::String`: The path to the data file to be loaded.

# Returns
- The data loaded from the specified file. The return type depends on the file format and its contents.

# Notes
- Ensure that the file exists and is accessible at the given path.
- The function assumes the file format is supported by the implementation.
"""
function loadDataFile(data_path)
    if endswith(data_path, ".nc")
        nc = NCDataset(data_path)
    elseif endswith(data_path, ".zarr")
        nc = YAXArrays.open_dataset(zopen(data_path))
    else
        error("The file ending/data type is not supported for $(datapath). Either use .nc or .zarr file")
    end
    return nc
end

"""
    loadDataFromPath(nc, data_path, data_path_v, source_variable)

Load data from specified NetCDF paths using given parameters.

# Arguments
- `nc`: NetCDF file handle
- `data_path`: Path to the main data in NetCDF file
- `data_path_v`: Path to the variable data in NetCDF file
- `source_variable`: Name of the source variable to load

# Returns
Data loaded from the specified paths in the NetCDF file.
"""
function loadDataFromPath(nc, data_path, data_path_v, source_variable)
    if isnothing(data_path_v) || (data_path_v === data_path)
        nc = nc
    else
        @info "   data_path: $(data_path_v)"
        nc = loadDataFile(data_path_v)
    end
    return nc
end

"""
Maps and cleans data based on quality control parameters and fills missing values.

# Arguments
- `_data`: Raw input data to be cleaned
- `_data_qc`: Quality control data corresponding to input data
- `_data_fill`: Fill values for replacing invalid/missing data
- `bounds_qc`: Quality control bounds/thresholds
- `_data_info`: Additional information about the data
- `::Val{T}`: Value type parameter for dispatch

# Returns
Cleaned and mapped data with invalid values replaced according to QC criteria

# Note
This function performs quality control checks and data cleaning based on the provided
bounds and fill values. The exact behavior depends on the value type T.
"""
function mapCleanData(_data, _data_qc, _data_fill, bounds_qc, _data_info, ::Val{T}) where {T}
    if !isnothing(bounds_qc) && !isnothing(_data_qc)
        _data = map((da, dq) -> applyQCBound(da, dq, bounds_qc, _data_fill), _data, _data_qc)
    end
    vT = Val{T}()
    _data = map(data_point -> cleanData(data_point, _data_fill, _data_info, vT), _data)
    return _data
end


"""
    subsetAndProcessYax(yax, forcing_mask, tar_dims, _data_info, info, ::Val{num_type}; clean_data=true, fill_nan=false, yax_qc=nothing, bounds_qc=nothing) where {num_type}

Subset and process YAX data according to specified parameters and quality control criteria.

# Arguments
- `yax`: YAX data to be processed
- `forcing_mask`: Mask to apply to the data
- `tar_dims`: Target dimensions
- `_data_info`: Data information
- `info`: a SINDBAD NT that includes all information needed for setup and execution of an experiment
- `::Val{num_type}`: Value type parameter for numerical type specification
- `clean_data=true`: Boolean flag to enable/disable data cleaning
- `fill_nan=false`: Boolean flag to control NaN filling
- `yax_qc=nothing`: Optional quality control parameters for YAX data
- `bounds_qc=nothing`: Optional boundary quality control parameters

# Returns
Processed and subset YAX data according to specified parameters and quality controls.

# Type Parameters
- `num_type`: Numerical type specification for the processed data
"""
function subsetAndProcessYax(yax, forcing_mask, tar_dims, _data_info, info, ::Val{num_type}; clean_data=true, fill_nan=false, yax_qc=nothing, bounds_qc=nothing) where {num_type}
    forcing_data_settings = info.experiment.data_settings.forcing
    if !isnothing(forcing_mask)
        yax = yax #todo: mask the forcing variables here depending on the mask of 1 and 0
    end

    if !isnothing(tar_dims)
        permutes = getDimPermutation(YAXArrayBase.dimnames(yax), tar_dims)
        @debug "         -> permuting dimensions to $(tar_dims)..."
        yax = permutedims(yax, permutes)
    end
    if hasproperty(yax, Symbol(forcing_data_settings.data_dimension.time))
        init_date = DateTime(info.helpers.dates.date_begin)
        last_date = DateTime(info.helpers.dates.date_end)
        yax = yax[time=(init_date .. last_date)]
    end

    if hasproperty(forcing_data_settings, :subset)
        yax = getSpatialSubset(forcing_data_settings.subset, yax)
    end

    #todo mean of the data instead of zero or nan
    # do a proper check on input type for forcing and if is not lazy do the cleanup
    if info.experiment.exe_rules.land_output_type == "array"
        vfill = 0.0
        if fill_nan
            vfill = NaN
        end
        vNT = Val{num_type}()
        if clean_data
            yax = mapCleanData(yax, yax_qc, vfill, bounds_qc, _data_info, vNT)
        else
            yax = map(yax_point -> replace_invalid_number(yax_point, vfill), yax)
            yax = map(num_type, yax)
        end
    end
    return yax
end

"""
    yaxCubeToKeyedArray(c)

Convert a YAXArray cube to a KeyedArray.

# Arguments
- `c`: YAXArray input cube to be converted

# Returns
KeyedArray representation of the input YAXArray cube

# Description
Transforms a YAXArray data cube into a KeyedArray format, preserving the dimensional
structure and associated metadata of the original cube.
"""
function yaxCubeToKeyedArray(c)
    t_dims = getSindbadDims(c);
    return KeyedArray(Array(c.data); t_dims...)
end

"""
Convert a stacked array into a DimensionalArray with specified dimensions and metadata.

# Arguments
- `stackArr`: The input stacked array to be converted
- `time_interval`: Time interval information for temporal dimension
- `p_names`: Names of pools/variables
- `name`: Optional keyword argument to specify the name of the dimension (default: :pools)

# Returns
A DimensionalArray with proper dimensions and labels.

This function is useful for converting raw stacked arrays into properly dimensioned
arrays with metadata, particularly for time series data with multiple pools or variables.
"""
function toDimStackArray(stackArr, time_interval, p_names; name=:pools)
    return DimArray(stackArr,  (p_names=p_names, Ti=time_interval,); name=name,)
end

