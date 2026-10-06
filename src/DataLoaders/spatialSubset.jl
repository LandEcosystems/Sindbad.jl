export getSpatialSubset

"""
    getSpatialSubset(ss, v)

Extracts a spatial subset of data based on specified spatial subsetting type/strategy.

# Arguments
- `ss`: Spatial subset parameters or geometry defining the region of interest
- `v`: Data to be spatially subset

# Returns
Spatially subset data according to the specified parameters

# Note
The function assumes input data and spatial parameters are in compatible formats

# Examples
```jldoctest
julia> using Sindbad

julia> # Get spatial subset from configuration
julia> # subset_data = getSpatialSubset(spatial_subset_config, data_cube)
```
"""
function getSpatialSubset(ss, v)
    if isa(ss, Dict)
        ss = dict_to_namedtuple(ss)
    end
    if !isnothing(ss)
        ssname = propertynames(ss)
        for ssn ∈ ssname
            ss_r = getproperty(ss, ssn)
            if !isnothing(ss_r)
                ss_range = collect(ss_r)
                checkSubsetValues(v, ssn, ss_range)
                ss_typeName = Symbol("Space" * string(ssn))
                v = spatialSubset(v, ss_range, getfield(Types, ss_typeName)())
            end
        end
    end
    return v
end

"""
    checkSubsetValues(v, dim_name, ss_range)

Throws an error that lists the subset values missing from the spatial dimension
`dim_name` of `v`. The subset is by value, so a list of positions such as `[1, 5]` is
only valid when the dimension itself holds those numbers.
"""
function checkSubsetValues(v, dim_name, ss_range)
    hasdim(v, dim_name) || return nothing
    dim_values = collect(DD.lookup(v, dim_name))
    missing_values = filter(x -> !any(isequal(x), dim_values), ss_range)
    if !isempty(missing_values)
        error("The spatial subset of `$(dim_name)` has values that are not in the data: $(first(missing_values, 5)). The subset is by value, not by position, so give the values of the `$(dim_name)` dimension, for example `ds.$(dim_name).val[indices]`. The first values of the dimension are $(first(dim_values, 5)).")
    end
    return nothing
end

"""
    spatialSubset(v, ss_range, <: SpatialSubsetter)

Extracts a spatial subset of the input data `v` based on the specified range and spatial dimension.

# Arguments:
- `v`: The input data from which a spatial subset is to be extracted.
- `ss_range`: The values of the spatial dimension to keep, such as site names or the latitudes of the grid cells.

# Returns:
- A subset of the input data `v` corresponding to the specified spatial range and dimension.

$(methods_of(SpatialSubsetter))

---

# Extended help

# Notes:
- The subset is always by value, never by position. The same subset therefore selects the
  same locations from any file on the same spatial axis, even one that holds only some of
  the locations, such as a restart file written by a subset run.
- Every value must exist in the spatial dimension of `v`, otherwise an error is thrown.
  Floating point coordinates such as latitudes must match the stored values exactly.
- The function dynamically selects the appropriate field in `v` based on the spatial type provided.
- The spatial type determines the field name (e.g., `site`, `lat`, `longitude`, `id`, etc.) used for subsetting.

# Examples
```jldoctest
julia> using Sindbad

julia> # Subset data by latitude
julia> # subset = spatialSubset(data, [50.25, 50.75], Spacelat())

julia> # Subset data by longitude
julia> # subset = spatialSubset(data, [10.25, 10.75], Spacelongitude())

julia> # Subset data by site name
julia> # subset = spatialSubset(data, ["DE-Hai", "DE-Tha"], Spacesite())
```
"""
function spatialSubset end

function spatialSubset(v, ss_range, ::Spacesite)
    return v[site=At(ss_range)]
end

function spatialSubset(v, ss_range, ::Spacelat)
    return v[lat=At(ss_range)]
end

function spatialSubset(v, ss_range, ::Spacelatitude)
    return v[latitude=At(ss_range)]
end

function spatialSubset(v, ss_range, ::Spacelon)
    return v[lon=At(ss_range)]
end

function spatialSubset(v, ss_range, ::Spacelongitude)
    return v[longitude=At(ss_range)]
end

function spatialSubset(v, ss_range, ::Spaceid)
    return v[id=At(ss_range)]
end

function spatialSubset(v, ss_range, ::SpaceId)
    return v[Id=At(ss_range)]
end

function spatialSubset(v, ss_range, ::SpaceID)
    return v[ID=At(ss_range)]
end
