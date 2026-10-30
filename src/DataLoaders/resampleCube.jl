export getInterpolationMethod
export resampleCube
export resampleValues!

const INTERPOLATION_AXES = (;
    space=(; prefix="SpaceInterp", method_type=SpaceInterpolationMethod),
    time=(; prefix="TimeInterp", method_type=TimeInterpolationMethod))

# the Interpolations.jl methods that interpolate on the positions of the values share
# one implementation in space and in time
const GridInterpolationMethod = Union{SpaceGridInterpolationMethod,TimeGridInterpolationMethod}

"""
    getInterpolationMethod(setting, axis)

Returns the interpolation method of a forcing or parameter variable from its setting
in `interpolation_method.space` or `interpolation_method.time`.

# Arguments:
- `setting`: the name of the method, e.g. `"linear"`, `"Linear"` or
  `"fritsch_carlson_monotonic"`, or a group with the name in `method` and options of
  the method, e.g. `{"method": "cubic", "extrapolation": "periodic"}`. A method is
  returned as it is.
- `axis`: `:space` or `:time`, the axis that the method is set for

# Returns:
- An instance of the subtype of `SpaceInterpolationMethod` or
  `TimeInterpolationMethod` named `SpaceInterp` or `TimeInterp` and the name in camel
  case, e.g. `TimeInterpFritschCarlsonMonotonic`, with its options set.

# Notes:
- The methods of space and time are separate types, so a name is only looked up
  among the methods of `axis`.
- The options of a method are the fields of its type. A name without options takes
  their defaults.
- The name and options are checked here, so a wrong one stops the run before the
  data is resampled.
"""
function getInterpolationMethod end

function getInterpolationMethod(method::InterpolationMethod, axis::Symbol)
    method isa getInterpolationAxis(axis).method_type || error("`$(nameof(typeof(method)))` is not a $(axis) interpolation method")
    return method
end

getInterpolationMethod(setting::Union{AbstractString,Symbol}, axis::Symbol) = getInterpolationMethod((; method=string(setting)), axis)
getInterpolationMethod(setting::AbstractDict, axis::Symbol) = getInterpolationMethod((; (Symbol(k) => v for (k, v) ∈ setting)...), axis)

function getInterpolationMethod(setting::NamedTuple, axis::Symbol)
    hasproperty(setting, :method) || error("an interpolation_method group needs the name of the method in `method`, got $(setting)")
    method_name = string(setting.method)
    method_type = getInterpolationType(method_name, axis)
    if isnothing(method_type)
        other_axis = axis == :space ? :time : :space
        other_note = isnothing(getInterpolationType(method_name, other_axis)) ? "" : " It is a $(other_axis) method."
        error("unknown $(axis) interpolation_method `$(method_name)`.$(other_note) Valid $(axis) methods are: $(join(getInterpolationMethodNames(axis), ", ")).")
    end
    options = Base.structdiff(setting, NamedTuple{(:method,)})
    unknown = setdiff(keys(options), fieldnames(method_type))
    if !isempty(unknown)
        valid_options = isempty(fieldnames(method_type)) ? "none" : join(fieldnames(method_type), ", ")
        error("$(axis) interpolation_method `$(method_name)` has no option $(join(unknown, ", ")). Its options are: $(valid_options).")
    end
    method = method_type(; options...)
    checkInterpolationMethod(method)
    return method
end

function getInterpolationAxis(axis::Symbol)
    hasproperty(INTERPOLATION_AXES, axis) || error("an interpolation_method is set for space or time, got $(axis)")
    return getproperty(INTERPOLATION_AXES, axis)
end

"""
    getInterpolationType(method_name, axis)

Returns the method type of `axis` for a name in the settings, or `nothing` when
`axis` has no method of that name.
"""
function getInterpolationType(method_name, axis::Symbol)
    axis_info = getInterpolationAxis(axis)
    type_name = to_uppercase_first(method_name, axis_info.prefix)
    method_type = isdefined(Types, type_name) ? getfield(Types, type_name) : nothing
    is_method = method_type isa Type && method_type <: axis_info.method_type && isconcretetype(method_type)
    return is_method ? method_type : nothing
end

"""
    getInterpolationMethodNames(axis)

Returns the names of the interpolation methods of `axis` as they are written in the
settings.
"""
function getInterpolationMethodNames(axis::Symbol)
    axis_info = getInterpolationAxis(axis)
    concreteSubtypes(T) = isconcretetype(T) ? [T] : reduce(vcat, map(concreteSubtypes, subtypes(T)); init=Type[])
    type_names = map(T -> replace(string(nameof(T)), Regex("^" * axis_info.prefix) => ""), concreteSubtypes(axis_info.method_type))
    return sort(map(n -> lowercase(replace(n, r"(?<=[a-z0-9])(?=[A-Z])" => "_")), type_names))
end

const INTERPOLATION_EXTRAPOLATIONS = (; flat=Interpolations.Flat(), line=Interpolations.Line(), periodic=Interpolations.Periodic(), reflect=Interpolations.Reflect(), throw=Interpolations.Throw(), nan=NaN)
const INTERPOLATION_BOUNDARIES = (; line=Interpolations.Line, flat=Interpolations.Flat, free=Interpolations.Free, periodic=Interpolations.Periodic, reflect=Interpolations.Reflect)
const INTERPOLATION_GRIDS = (; on_grid=Interpolations.OnGrid(), on_cell=Interpolations.OnCell())

"""
    getInterpolationOption(options, name, option_kind)

Returns the entry `name` of `options`, or an error that lists the valid names.
"""
function getInterpolationOption(options, name, option_kind)
    key = Symbol(lowercase(string(name)))
    hasproperty(options, key) || error("unknown $(option_kind) `$(name)` of an interpolation_method. Valid ones are: $(join(keys(options), ", ")).")
    return getproperty(options, key)
end

getExtrapolation(name) = getInterpolationOption(INTERPOLATION_EXTRAPOLATIONS, name, "extrapolation")

function getBoundary(boundary, grid)
    boundary_type = getInterpolationOption(INTERPOLATION_BOUNDARIES, boundary, "boundary")
    return boundary_type(getInterpolationOption(INTERPOLATION_GRIDS, grid, "grid"))
end

"""
    interpolationType(method)

Returns the interpolation type of Interpolations.jl, e.g. `BSpline(Linear())`, for a
grid or monotonic interpolation method.
"""
function interpolationType end

interpolationType(::Union{SpaceInterpNearest,TimeInterpNearest}) = Interpolations.BSpline(Interpolations.Constant())
interpolationType(::Union{SpaceInterpLinear,TimeInterpLinear}) = Interpolations.BSpline(Interpolations.Linear())
interpolationType(method::Union{SpaceInterpQuadratic,TimeInterpQuadratic}) = Interpolations.BSpline(Interpolations.Quadratic(getBoundary(method.boundary, method.grid)))
interpolationType(method::Union{SpaceInterpCubic,TimeInterpCubic}) = Interpolations.BSpline(Interpolations.Cubic(getBoundary(method.boundary, method.grid)))
interpolationType(method::Union{SpaceInterpLanczos,TimeInterpLanczos}) = Interpolations.Lanczos(method.order)
interpolationType(::Union{SpaceInterpLanczosOpencv,TimeInterpLanczosOpencv}) = Interpolations.Lanczos4OpenCV()
interpolationType(::TimeInterpPrevious) = Interpolations.BSpline(Interpolations.Constant(Interpolations.Previous))
interpolationType(::TimeInterpNext) = Interpolations.BSpline(Interpolations.Constant(Interpolations.Next))
interpolationType(::TimeInterpLinearMonotonic) = Interpolations.LinearMonotonicInterpolation()
interpolationType(::TimeInterpFiniteDifferenceMonotonic) = Interpolations.FiniteDifferenceMonotonicInterpolation()
interpolationType(method::TimeInterpCardinalMonotonic) = Interpolations.CardinalMonotonicInterpolation(method.tension)
interpolationType(::TimeInterpFritschCarlsonMonotonic) = Interpolations.FritschCarlsonMonotonicInterpolation()
interpolationType(::TimeInterpFritschButlandMonotonic) = Interpolations.FritschButlandMonotonicInterpolation()
interpolationType(::TimeInterpSteffenMonotonic) = Interpolations.SteffenMonotonicInterpolation()
interpolationType(::TimeInterpAkimaMonotonic) = Interpolations.AkimaMonotonicInterpolation()

"""
    checkInterpolationMethod(method)

Throws an error when an option of `method` has an invalid value.
"""
checkInterpolationMethod(::InterpolationMethod) = nothing

function checkInterpolationMethod(method::Union{GridInterpolationMethod,TimeMonotonicInterpolationMethod})
    interpolationType(method)
    getExtrapolation(method.extrapolation)
    return nothing
end

function checkInterpolationMethod(method::SpaceInterpZhao2004)
    method.power > 0 || error("the power of the space interpolation_method `zhao2004` must be positive, got $(method.power)")
    return nothing
end

"""
    checkInterpolationAxes(method, axis_names)

Throws an error when `method` cannot resample along the axes `axis_names`, before any
data is read. A method without its own check works along any axes.
"""
checkInterpolationAxes(::InterpolationMethod, _) = nothing

function checkInterpolationAxes(method::TimeMonotonicInterpolationMethod, axis_names)
    length(axis_names) == 1 || error("the monotonic interpolation methods work along one axis, but `$(nameof(typeof(method)))` is set for $(collect(axis_names))")
    return nothing
end

checkInterpolationAxes(::SpaceInterpZhao2004, axis_names) = (getLatLonPositions(axis_names); nothing)

"""
    getLatLonPositions(axis_names)

Returns the positions of the latitude and the longitude axis in `axis_names`, found
by names that start with `lat` and `lon`, for `SpaceInterpZhao2004`.
"""
function getLatLonPositions(axis_names)
    lower_names = map(n -> lowercase(string(n)), collect(axis_names))
    i_lat = findfirst(n -> startswith(n, "lat"), lower_names)
    i_lon = findfirst(n -> startswith(n, "lon"), lower_names)
    if length(lower_names) != 2 || isnothing(i_lat) || isnothing(i_lon)
        error("the space interpolation_method `zhao2004` works along a latitude and a longitude axis, but is set for $(collect(axis_names))")
    end
    return i_lat, i_lon
end

"""
    resampleCube(incube, target_dims, method, num_type)

Puts a cube on the target dimensions with an interpolation method.

# Arguments:
- `incube`: the cube
- `target_dims`: a Tuple of the target dimensions that the cube has
- `method`: a space or time interpolation method
- `num_type`: the number type of the resampled cube

# Returns:
- A lazy cube with the target dimensions in place of those of `incube`, in the same
  dimension order as `incube`, and with its properties.

# Notes:
- The target dimensions are core dimensions of an `xmap`, so each call of the method
  gets their whole axes, e.g. a whole time series or a whole field, and the other
  dimensions are looped over.
- Missing values are NaN for the method.
"""
function resampleCube(incube, target_dims, method, num_type)
    target_names = DD.name.(target_dims)
    core_names = Tuple(filter(∈(target_names), collect(DD.name.(DD.dims(incube)))))
    checkInterpolationAxes(method, core_names)
    source_dims = map(name -> DD.dims(incube, name), core_names)
    out_dims = map(name -> target_dims[findfirst(==(name), target_names)], core_names)
    source_axes = map(d -> getAxisInfo(d, first(DD.lookup(d))), source_dims)
    target_axes = map((d, s) -> getAxisInfo(d, first(DD.lookup(s))), out_dims, source_dims)
    out = xmap(resampleXmap!, incube ⊘ core_names;
        output=XOutput(out_dims...; outtype=num_type, properties=incube.properties),
        inplace=true,
        allow_threads=true,
        function_kwargs=(; source_axes, target_axes, method, num_type))
    # xmap puts the core dimensions first
    in_order = DD.name.(DD.dims(incube))
    return DD.name.(DD.dims(out)) == in_order ? out : permutedims(out, in_order)
end

function resampleXmap!(yout, yin; source_axes, target_axes, method, num_type)
    values = num_type[ismissing(v) ? num_type(NaN) : num_type(v) for v ∈ yin]
    resampleValues!(yout, values, source_axes, target_axes, method)
    return nothing
end

"""
    getAxisInfo(dim, reference)

Returns the `name`, the coordinates as `points` and the cell bounds as `lower` and
`upper` of a dimension, all as Float64.

# Notes:
- Dates are in milliseconds from `reference`, so a source axis and its target axis
  share one origin.
- The bounds come from the lookup when it has intervals. Otherwise they are halfway
  to the neighboring points, and the first and last cell are as wide on both sides.
"""
function getAxisInfo(dim, reference)
    lookup = DD.lookup(dim)
    points = toAxisNumbers(collect(lookup), reference)
    lower, upper = if lookup isa DD.Lookups.AbstractSampled && DD.sampling(lookup) isa DD.Intervals
        bounds = DD.intervalbounds(lookup)
        toAxisNumbers(first.(bounds), reference), toAxisNumbers(last.(bounds), reference)
    else
        getMidpointBounds(points)
    end
    return (; name=DD.name(dim), points, lower, upper)
end

toAxisNumbers(values, reference) = eltype(values) <: Number ? Float64.(values) : Float64[Dates.value(Dates.Millisecond(v - reference)) for v ∈ values]

function getMidpointBounds(points)
    length(points) == 1 && return copy(points), copy(points)
    mids = (points[1:end-1] .+ points[2:end]) ./ 2
    return [2 * points[1] - mids[1]; mids], [mids; 2 * points[end] - mids[end]]
end

"""
    getFractionalIndices(source_points, target_points)

Returns the position of each target point on the source axis as a fractional index,
linear between the source points and extended linearly beyond them.
"""
function getFractionalIndices(source_points, target_points)
    n = length(source_points)
    n == 1 && return fill(1.0, length(target_points))
    if source_points[end] < source_points[1]
        return (n + 1) .- getFractionalIndices(reverse(source_points), target_points)
    end
    return map(target_points) do x
        i = clamp(searchsortedlast(source_points, x), 1, n - 1)
        i + (x - source_points[i]) / (source_points[i+1] - source_points[i])
    end
end

"""
    getBracketIndices(source_points, target_points)

Returns for each target point the indices of the two source points around it, or of
the two at the nearer end when it is beyond the source axis.
"""
function getBracketIndices(source_points, target_points)
    n = length(source_points)
    n == 1 && return fill((1, 1), length(target_points))
    if source_points[end] < source_points[1]
        return map(((i, j),) -> (n + 1 - j, n + 1 - i), getBracketIndices(reverse(source_points), target_points))
    end
    return map(target_points) do x
        i = clamp(searchsortedlast(source_points, x), 1, n - 1)
        (i, i + 1)
    end
end

"""
    greatCircleDistance(lat_1, lon_1, lat_2, lon_2)

Returns the great-circle distance in radians between two points given in degrees.
"""
function greatCircleDistance(lat_1, lon_1, lat_2, lon_2)
    φ_1, φ_2 = deg2rad(lat_1), deg2rad(lat_2)
    h = sin((φ_2 - φ_1) / 2)^2 + cos(φ_1) * cos(φ_2) * sin(deg2rad(lon_2 - lon_1) / 2)^2
    return 2 * asin(min(1.0, sqrt(h)))
end

"""
    resampleValues!(yout, yin, source_axes, target_axes, method::InterpolationMethod)

Fills `yout` on the target axes from the values `yin` on the source axes. This is the
function to extend for a new interpolation method.

# Arguments:
- `yout`: the output array, with one dimension per target axis
- `yin`: the source values in the number type of the run, with NaN for missing
  values, and one dimension per source axis
- `source_axes`, `target_axes`: one NamedTuple per resampled axis in the order of the
  dimensions of `yin` and `yout`, see `getAxisInfo`
- `method`: the interpolation method with its options

# Notes:
- To add a method, add a subtype of `SpaceInterpolationMethod` or
  `TimeInterpolationMethod` in `src/Types/InputTypes.jl` with its options as fields
  with defaults and its `purpose`, and a method of this function here. Its name in
  the settings is the type name without `SpaceInterp` or `TimeInterp` in snake case,
  e.g. `"zhao2004"` for `SpaceInterpZhao2004`.
  A method that only works along some axes also adds a `checkInterpolationAxes`
  method, and one with options that need checking a `checkInterpolationMethod`.
- All resampled axes of a cube come together, e.g. latitude and longitude for space,
  so a method can combine them, and the cell bounds allow methods that keep sums or
  means of cells.
"""
function resampleValues!(_, _, _, _, method::InterpolationMethod)
    error("interpolation method `$(nameof(typeof(method)))` has no resampleValues! method. Add one in src/DataLoaders/resampleCube.jl, see the docstring of resampleValues!.")
end

# the Interpolations.jl methods work on the positions of the values, so the target
# points are converted to fractional indices on each source axis
function resampleValues!(yout, yin, source_axes, target_axes, method::GridInterpolationMethod)
    itp = Interpolations.extrapolate(Interpolations.interpolate(yin, interpolationType(method)), getExtrapolation(method.extrapolation))
    indices = map((s, t) -> getFractionalIndices(s.points, t.points), source_axes, target_axes)
    for (I, idx) ∈ zip(CartesianIndices(yout), Iterators.product(indices...))
        yout[I] = itp(idx...)
    end
    return nothing
end

function resampleValues!(yout, yin, source_axes, target_axes, method::TimeMonotonicInterpolationMethod)
    x = only(source_axes).points
    y = vec(yin)
    if x[end] < x[1]
        x, y = reverse(x), reverse(y)
    end
    itp = Interpolations.extrapolate(Interpolations.interpolate(x, y, interpolationType(method)), getExtrapolation(method.extrapolation))
    for (i, x_target) ∈ enumerate(only(target_axes).points)
        yout[i] = itp(x_target)
    end
    return nothing
end

function resampleValues!(yout, yin, source_axes, target_axes, method::SpaceInterpZhao2004)
    i_lat, i_lon = getLatLonPositions(map(a -> a.name, source_axes))
    lat_source, lon_source = source_axes[i_lat].points, source_axes[i_lon].points
    lat_target, lon_target = target_axes[i_lat].points, target_axes[i_lon].points
    lat_brackets = getBracketIndices(lat_source, lat_target)
    lon_brackets = getBracketIndices(lon_source, lon_target)
    sourceIndex(i, j) = i_lat == 1 ? CartesianIndex(i, j) : CartesianIndex(j, i)
    for I ∈ CartesianIndices(yout)
        k_lat, k_lon = I[i_lat], I[i_lon]
        corners = [(i, j) for i ∈ lat_brackets[k_lat], j ∈ lon_brackets[k_lon]]
        d_max = maximum(greatCircleDistance(lat_source[a[1]], lon_source[a[2]], lat_source[b[1]], lon_source[b[2]]) for a ∈ corners, b ∈ corners)
        weighted_sum, weight_sum = 0.0, 0.0
        for (i, j) ∈ corners
            value = yin[sourceIndex(i, j)]
            # an invalid grid is left out and the weights of the others are
            # normalized among themselves, which the paper does not cover
            isnan(value) && continue
            d = greatCircleDistance(lat_target[k_lat], lon_target[k_lon], lat_source[i], lon_source[j])
            weight = d_max > 0 ? cos(π / 2 * min(d / d_max, 1.0))^method.power : 1.0
            weighted_sum += weight * value
            weight_sum += weight
        end
        yout[I] = weight_sum > 0 ? weighted_sum / weight_sum : NaN
    end
    return nothing
end
