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
    resampleRadius(method)

Returns how many source grids a space method needs on each side beyond the two
around a target grid, or `nothing` when it needs the whole axes, as a time method
does.

# Notes:
- With a number, a block of target grids only reads and resamples the source grids
  around it, so a lazy run that reads the forcing in blocks resamples each grid once.
  With `nothing`, every read of a block resamples the whole field at every time step.
- A new space method needs the whole field until it declares its radius here.
"""
resampleRadius(::InterpolationMethod) = nothing
resampleRadius(::Union{SpaceInterpNearest,SpaceInterpLinear,SpaceInterpZhao2004}) = 0
resampleRadius(method::SpaceInterpLanczos) = method.order
resampleRadius(::SpaceInterpLanczosOpencv) = 4
# a B-spline coefficient depends on the values at a distance of k grids by the pole
# of the spline to the power k, 0.172 for quadratic and 0.268 for cubic, so with
# these radii a block differs from the whole field by less than 1e-8 of the values
resampleRadius(::SpaceInterpQuadratic) = 12
resampleRadius(::SpaceInterpCubic) = 16

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
- A space method with a `resampleRadius` gets, for each block of target grids, the
  source grids around it, see `getResampleBlock`.
- A time method, or a space method without a radius, gets the whole axes: the target
  dimensions are core dimensions of an `xmap`, so each call of `resampleSlice!` gets
  e.g. a whole time series or a whole field, and the other dimensions are looped
  over. A read of part of the target grid still resamples the whole axes, which
  suits time, as a run reads whole time series.
- Missing values are NaN for the method.
"""
function resampleCube(incube, target_dims, method::InterpolationMethod, num_type)
    radius = resampleRadius(method)
    isnothing(radius) || return getResampleBlock(incube, target_dims, method, num_type, radius)
    core_names, out_dims, source_axes, target_axes = getResampleAxes(incube, target_dims, method)
    plan = resamplePlan(method, source_axes, target_axes)
    out = xmap(resampleSlice!, incube ⊘ core_names;
        output=XOutput(out_dims...; outtype=num_type, properties=incube.properties),
        inplace=true,
        allow_threads=true,
        function_kwargs=(; source_axes, target_axes, method, num_type, plan))
    # xmap puts the core dimensions first
    in_order = DD.name.(DD.dims(incube))
    return DD.name.(DD.dims(out)) == in_order ? out : permutedims(out, in_order)
end

"""
    getResampleAxes(incube, target_dims, method)

Returns the names of the target dimensions in the order of the cube, the target
dimensions in that order, and the axis info of the source and target of each, see
`getAxisInfo`.
"""
function getResampleAxes(incube, target_dims, method)
    target_names = DD.name.(target_dims)
    core_names = Tuple(filter(∈(target_names), collect(DD.name.(DD.dims(incube)))))
    checkInterpolationAxes(method, core_names)
    source_dims = map(name -> DD.dims(incube, name), core_names)
    out_dims = map(name -> target_dims[findfirst(==(name), target_names)], core_names)
    source_axes = map(d -> getAxisInfo(d, first(DD.lookup(d))), source_dims)
    target_axes = map((d, s) -> getAxisInfo(d, first(DD.lookup(s))), out_dims, source_dims)
    return core_names, out_dims, source_axes, target_axes
end

"""
    resampleSlice!(yout, yin; source_axes, target_axes, method, num_type, plan)

Resamples one slice of the `xmap` of `resampleCube`: the whole resampled axes, e.g. a
whole field or a whole time series, at one index of the other dimensions.
"""
function resampleSlice!(yout, yin; source_axes, target_axes, method, num_type, plan)
    values = num_type[ismissing(v) ? num_type(NaN) : num_type(v) for v ∈ yin]
    resampleValues!(yout, values, source_axes, target_axes, method, plan)
    return nothing
end

"""
    getResampleBlock(incube, target_dims, method, num_type, radius)

Returns the lazy resampled cube of a method with a `resampleRadius`, from a
DiskArrayEngine operation in which each target grid has a window of the source grids
around it, as `YAXArrays.xresample` does.

# Notes:
- A read of a block of target grids only reads the union of their windows and calls
  the method on it, once per index of the other dimensions, see `resampleBlock!`.
- The window of a target grid is the two source grids around it, those within its
  cell, and `radius` more on each side.
- A block of DiskArrayEngine reads from the first index of its first window to the
  last of its last, so the windows have to increase with the target index. A target
  axis that runs against its source axis is resampled in the order of the source and
  then reversed in a lazy view.
"""
function getResampleBlock(incube, target_dims, method, num_type, radius)
    core_names, out_dims, source_axes, target_axes = getResampleAxes(incube, target_dims, method)
    cube_dims = DD.dims(incube)
    core_positions = map(name -> DD.dimnum(incube, name), core_names)
    flipped = map((s, t) -> isDescending(s.points) != isDescending(t.points), source_axes, target_axes)
    run_axes = map((t, f) -> f ? reverseAxisInfo(t) : t, target_axes, flipped)
    in_windows = Any[Base.OneTo(n) for n ∈ size(incube)]
    out_windows = Any[Base.OneTo(n) for n ∈ size(incube)]
    out_size = collect(size(incube))
    for (k, d) ∈ enumerate(core_positions)
        in_windows[d] = getResampleGrids(source_axes[k], run_axes[k], radius)
        out_windows[d] = [j:j for j ∈ eachindex(run_axes[k].points)]
        out_size[d] = length(run_axes[k].points)
    end
    input = DAE.InputArray(incube.data; windows=Tuple(in_windows))
    output = DAE.create_outwindows(Tuple(out_size); windows=Tuple(out_windows))
    block_function = DAE.create_userfunction(resampleBlock!, num_type; is_blockfunction=true, is_mutating=true, dims=core_positions,
        kwargs=(; source_axes, target_axes=run_axes, method, num_type))
    result, = DAE.results_as_diskarrays(DAE.GMDWop((input,), (output,), block_function))
    if any(flipped)
        result = view(result, ntuple(ndims(result)) do d
            k = findfirst(==(d), core_positions)
            isnothing(k) || !flipped[k] ? Colon() : (out_size[d]:-1:1)
        end...)
    end
    return YAXArray(DD.setdims(cube_dims, out_dims), result, incube.properties)
end

isDescending(points) = length(points) > 1 && points[end] < points[1]

reverseAxisInfo(axis) = (; name=axis.name, points=reverse(axis.points), lower=reverse(axis.lower), upper=reverse(axis.upper))

"""
    getResampleGrids(source_axis, target_axis, radius)

Returns for each target point the range of source indices that its method needs: the
two source points around it, those within its cell, and `radius` more on each side.
"""
function getResampleGrids(source_axis, target_axis, radius)
    n = length(source_axis.points)
    brackets = getBracketIndices(source_axis.points, target_axis.points)
    return map(eachindex(target_axis.points)) do j
        i_first, i_last = extrema(brackets[j])
        cell_min, cell_max = extrema((target_axis.lower[j], target_axis.upper[j]))
        for (i, p) ∈ enumerate(source_axis.points)
            if cell_min <= p <= cell_max
                i_first, i_last = min(i_first, i), max(i_last, i)
            end
        end
        max(1, i_first - radius):min(n, i_last + radius)
    end
end

"""
    resampleBlock!(xout, data; dims, threaded=false, source_axes, target_axes,
        method, num_type)

Resamples one block of `getResampleBlock`. `data` and `xout` have the indices of the
whole cube, and `dims` are the positions of the resampled dimensions. The method is
called once per index of the other dimensions, with the axis info cut to the block
and one `resamplePlan` of the block for all calls.
"""
function resampleBlock!(xout, data; dims, threaded=false, source_axes, target_axes, method, num_type)
    source_ranges = map(d -> UnitRange(axes(data, d)), dims)
    target_ranges = map(d -> UnitRange(axes(xout, d)), dims)
    source_block = map(subsetAxisInfo, source_axes, source_ranges)
    target_block = map(subsetAxisInfo, target_axes, target_ranges)
    plan = resamplePlan(method, source_block, target_block)
    other_dims = Tuple(filter(∉(dims), 1:ndims(xout)))
    other_indices = CartesianIndices(map(d -> UnitRange(axes(xout, d)), other_dims))
    blockIndex(I, ranges) = ntuple(d -> d ∈ dims ? ranges[findfirst(==(d), dims)] : I[findfirst(==(d), other_dims)], ndims(xout))
    function resampleOne(I)
        yin = num_type[ismissing(v) ? num_type(NaN) : num_type(v) for v ∈ view(data, blockIndex(I, source_ranges)...)]
        resampleValues!(view(xout, blockIndex(I, target_ranges)...), yin, source_block, target_block, method, plan)
        return nothing
    end
    if threaded
        Threads.@threads for I ∈ other_indices
            resampleOne(I)
        end
    else
        foreach(resampleOne, other_indices)
    end
    return nothing
end

subsetAxisInfo(axis, range) = (; name=axis.name, points=axis.points[range], lower=axis.lower[range], upper=axis.upper[range])

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
    resamplePlan(method, source_axes, target_axes)

Returns what `method` computes from the axes alone, e.g. weights or the positions of
the target points on the source axes, or `nothing`.

# Notes:
- The plan is made once per block of `getResampleBlock`, or once for all calls of
  `resampleSlice!` in `resampleCube`, and is passed to every call of
  `resampleValues!` on the same axes, e.g. at every time step.
"""
resamplePlan(::InterpolationMethod, _, _) = nothing

resamplePlan(::GridInterpolationMethod, source_axes, target_axes) = map((s, t) -> getFractionalIndices(s.points, t.points), source_axes, target_axes)

function resamplePlan(method::SpaceInterpZhao2004, source_axes, target_axes)
    i_lat, i_lon = getLatLonPositions(map(a -> a.name, source_axes))
    lat_source, lon_source = source_axes[i_lat].points, source_axes[i_lon].points
    lat_target, lon_target = target_axes[i_lat].points, target_axes[i_lon].points
    lat_brackets = getBracketIndices(lat_source, lat_target)
    lon_brackets = getBracketIndices(lon_source, lon_target)
    sourceIndex(i, j) = i_lat == 1 ? CartesianIndex(i, j) : CartesianIndex(j, i)
    target_size = map(a -> length(a.points), Tuple(target_axes))
    corners = Array{NTuple{4,CartesianIndex{2}}}(undef, target_size)
    weights = Array{NTuple{4,Float64}}(undef, target_size)
    for I ∈ CartesianIndices(target_size)
        k_lat, k_lon = I[i_lat], I[i_lon]
        (i_1, i_2), (j_1, j_2) = lat_brackets[k_lat], lon_brackets[k_lon]
        cells = ((i_1, j_1), (i_1, j_2), (i_2, j_1), (i_2, j_2))
        d_max = maximum(greatCircleDistance(lat_source[a[1]], lon_source[a[2]], lat_source[b[1]], lon_source[b[2]]) for a ∈ cells, b ∈ cells)
        corners[I] = map(c -> sourceIndex(c...), cells)
        weights[I] = map(cells) do (i, j)
            d = greatCircleDistance(lat_target[k_lat], lon_target[k_lon], lat_source[i], lon_source[j])
            d_max > 0 ? cos(π / 2 * min(d / d_max, 1.0))^method.power : 1.0
        end
    end
    return (; corners, weights)
end

"""
    resampleValues!(yout, yin, source_axes, target_axes, method::InterpolationMethod,
        plan)

Fills `yout` on the target axes from the values `yin` on the source axes. This is the
function to extend for a new interpolation method.

# Arguments:
- `yout`: the output array, with one dimension per target axis
- `yin`: the source values in the number type of the run, with NaN for missing
  values, and one dimension per source axis
- `source_axes`, `target_axes`: one NamedTuple per resampled axis in the order of the
  dimensions of `yin` and `yout`, see `getAxisInfo`
- `method`: the interpolation method with its options
- `plan`: the `resamplePlan` of the method on these axes

# Notes:
- To add a method, add a subtype of `SpaceInterpolationMethod` or
  `TimeInterpolationMethod` in `src/Types/InputTypes.jl` with its options as fields
  with defaults and its `purpose`, and a method of this function here. Its name in
  the settings is the type name without `SpaceInterp` or `TimeInterp` in snake case,
  e.g. `"zhao2004"` for `SpaceInterpZhao2004`.
  A method that only works along some axes also adds a `checkInterpolationAxes`
  method, and one with options that need checking a `checkInterpolationMethod`. A
  space method that only needs the source grids near a target grid adds a
  `resampleRadius` method, without which it gets the whole field. What a method can
  compute from the axes alone goes into a `resamplePlan` method, so it is not
  computed again at every time step.
- All resampled axes of a cube come together, e.g. latitude and longitude for space,
  so a method can combine them, and the cell bounds allow methods that keep sums or
  means of cells.
"""
function resampleValues!(_, _, _, _, method::InterpolationMethod, _)
    error("interpolation method `$(nameof(typeof(method)))` has no resampleValues! method. Add one in src/DataLoaders/resampleCube.jl, see the docstring of resampleValues!.")
end

# the Interpolations.jl methods work on the positions of the values, so the plan has
# the target points as fractional indices on each source axis
function resampleValues!(yout, yin, _, _, method::GridInterpolationMethod, plan)
    itp = Interpolations.extrapolate(Interpolations.interpolate(yin, interpolationType(method)), getExtrapolation(method.extrapolation))
    for (I, idx) ∈ zip(CartesianIndices(yout), Iterators.product(plan...))
        yout[I] = itp(idx...)
    end
    return nothing
end

function resampleValues!(yout, yin, source_axes, target_axes, method::TimeMonotonicInterpolationMethod, _)
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

function resampleValues!(yout, yin, _, _, ::SpaceInterpZhao2004, plan)
    for I ∈ CartesianIndices(yout)
        weighted_sum, weight_sum = 0.0, 0.0
        for (source_index, weight) ∈ zip(plan.corners[I], plan.weights[I])
            value = yin[source_index]
            # an invalid grid is left out and the weights of the others are
            # normalized among themselves, which the paper does not cover
            isnan(value) && continue
            weighted_sum += weight * value
            weight_sum += weight
        end
        yout[I] = weight_sum > 0 ? weighted_sum / weight_sum : NaN
    end
    return nothing
end
