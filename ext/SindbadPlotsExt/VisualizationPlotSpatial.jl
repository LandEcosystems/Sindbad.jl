using Random: MersenneTwister, randperm
using Dates: TimeType

# ------------------------------------------------------------------
# figures of spatial runs
# ------------------------------------------------------------------
#
# A spatial run has more than one location. Its forcing, output and observation
# arrays have the spatial dimensions last, in the order of `forcing_helpers.sizes`,
# so every array is read as (leading..., space...). For each variable these figures
# are drawn:
# - `*_timeseries_*`: the mean over all locations, and up to five random locations,
#   with their cycles. The random locations are drawn with a fixed seed, so the same
#   locations are picked from the same set of valid locations.
# - `*_spacetime_*`: a heatmap with time on the x axis and the sites, or the
#   latitudes of a grid with the mean over longitude, on the y axis. The comparison
#   has three rows: obs, model, and model - obs.
# - `*_mean_*`: the time mean of every location as a lat/lon heatmap, only for a
#   grid. Forcing without time is drawn as `forcing_mean_*` for a grid, and as
#   `forcing_spacetime_*` with one column per layer for a list of sites.

const _pixel_colors = [:darkorange2, :firebrick3, :purple3, :teal, :olivedrab]
# the colour of the mean of all locations, a strong blue that is apart from all
# location colours
const _mean_color = "#2B59C3"
const _pixel_seed = 1

"""
    _spaceInfo(forcing_helpers)

Returns the names, sizes and coordinates of the spatial dimensions in the order of
the trailing dimensions of the data arrays, or `nothing` without forcing helpers.
"""
function _spaceInfo(forcing_helpers)
    isnothing(forcing_helpers) && return nothing
    space_names = collect(Symbol, Base.tail(keys(forcing_helpers.sizes)))
    space_sizes = collect(Int, Base.tail(values(forcing_helpers.sizes)))
    axes_pairs = collect(forcing_helpers.axes)
    coords = map(space_names, space_sizes) do d_name, d_size
        ax = findfirst(a -> Symbol(first(a)) == d_name, axes_pairs)
        if isnothing(ax) || length(last(axes_pairs[ax])) != d_size
            return collect(1:d_size)
        end
        return collect(last(axes_pairs[ax]))
    end
    return (; names=space_names, sizes=space_sizes, coords=coords, n_loc=prod(space_sizes))
end

_isSpatial(space) = !isnothing(space) && space.n_loc > 1

# a grid has two spatial dimensions, e.g. lat and lon, and a list of sites has one
_isGrid(space) = length(space.sizes) == 2

_forcingHelpers(out) = hasproperty(out, :forcing) ? out.forcing.helpers : nothing

"""
    _toTimeLayerLoc(data, space; has_time=true)

Reshapes an array with the spatial dimensions last to (time, layer, location). The
leading dimensions after time are merged into one layer dimension. Without time, the
time dimension has size one.
"""
function _toTimeLayerLoc(data, space; has_time=true)
    n_space = length(space.sizes)
    lead = size(data)[1:ndims(data)-n_space]
    n_time = has_time && !isempty(lead) ? first(lead) : 1
    n_layer = has_time && !isempty(lead) ? prod(lead[2:end]; init=1) : prod(lead; init=1)
    return reshape(Array(data), n_time, n_layer, space.n_loc)
end

function _nanMean(x)
    s = 0.0
    n = 0
    for v ∈ x
        isnan(v) && continue
        s += v
        n += 1
    end
    return n == 0 ? NaN : s / n
end

# the mean over time of every location of a (time, location) array
_timeMean(data_tl) = [_nanMean(view(data_tl, :, l)) for l ∈ axes(data_tl, 2)]

# the mean over all locations at every time step of a (time, location) array
_spaceMean(data_tl) = [_nanMean(view(data_tl, t, :)) for t ∈ axes(data_tl, 1)]

_validLocations(data_tl) = [l for l ∈ axes(data_tl, 2) if any(!isnan, view(data_tl, :, l))]

function _randomLocations(valid_locs; n=length(_pixel_colors))
    isempty(valid_locs) && return Int[]
    perm = randperm(MersenneTwister(_pixel_seed), length(valid_locs))
    return sort(valid_locs[perm[1:min(n, length(valid_locs))]])
end

_formatCoord(x::AbstractFloat) = string(round(x, digits=2))
_formatCoord(x) = string(x)

function _locationLabel(space, loc)
    loc_ci = CartesianIndices(Tuple(space.sizes))[loc]
    return join(["$(d_name)=$(_formatCoord(space.coords[k][loc_ci[k]]))" for (k, d_name) ∈ enumerate(space.names)], ", ")
end

_finiteLims(values...) = (finite = filter(isfinite, vcat(values...)); isempty(finite) ? :auto : (minimum(finite), maximum(finite)))

function _symmetricLims(values)
    finite = filter(isfinite, values)
    d_max = isempty(finite) ? 1.0 : max(maximum(abs, finite), eps())
    return (-d_max, d_max)
end

# the indices of the x (longitude) and y (latitude) dimensions of a grid
function _mapDims(space)
    names = lowercase.(string.(space.names))
    x_dim = findfirst(n -> occursin("lon", n) || n == "x", names)
    x_dim = isnothing(x_dim) ? 2 : x_dim
    return x_dim, 3 - x_dim
end

"""
    _spatialPanel(space, loc_values; title, lims, cmap, units)

Draws the values of every location: a heatmap for a grid with two spatial dimensions,
and points along the location index otherwise. `lims` is the range of the colour
scale of a heatmap, or of the y axis of the points.
"""
function _spatialPanel(space, loc_values; title="", lims=:auto, cmap=:viridis, units="", color=_model_color)
    if length(space.sizes) == 2
        x_dim, y_dim = _mapDims(space)
        grid = reshape(loc_values, Tuple(space.sizes))
        z = x_dim == 1 ? permutedims(grid) : grid
        x = space.coords[x_dim]
        y = space.coords[y_dim]
        # a heatmap needs increasing coordinates
        x_order = eltype(x) <: Real ? sortperm(x) : collect(eachindex(x))
        y_order = eltype(y) <: Real ? sortperm(y) : collect(eachindex(y))
        return plots_heatmap(x[x_order], y[y_order], z[y_order, x_order]; _figStyle()..., title=title, clims=lims, color=cmap, colorbar_title=units, xlabel=string(space.names[x_dim]), ylabel=string(space.names[y_dim]), grid=false, framestyle=:box)
    end
    n_loc = space.n_loc
    x_ticks = n_loc <= 40 ? (1:n_loc, string.(first(space.coords))) : :auto
    p = plots_scatter(1:n_loc, loc_values; _figStyle()..., title=title, ylims=lims, color=color, markersize=4, msw=0, legend=false, xlabel=string(first(space.names)), ylabel=units, xticks=x_ticks, xrotation=n_loc <= 40 ? 90 : 0, grid=:y)
    lims isa Tuple && first(lims) < 0 < last(lims) && plots_hline!(p, [0]; color=:grey40, lw=0.6, label="")
    return p
end

"""
    _plotMeanMap(space, data_tl, title, units, fig_path)

Saves the time mean of every location of a (time, location) array as one
`_spatialPanel`.
"""
function _plotMeanMap(space, data_tl, title, units, fig_path; color=_model_color)
    loc_mean = _timeMean(data_tl)
    p = _spatialPanel(space, loc_mean; title=title, lims=_finiteLims(loc_mean), units=units, color=color)
    plots_savefig(p, fig_path)
    return nothing
end

"""
    _plotSpaceTimeSeries(x_data, data_tl, space, title, ylabel, fig_path)

Saves the mean over all locations and up to five random locations of a (time,
location) array as lines, with their cycles, see `_plotTimeSeriesWithCycles`.
"""
function _plotSpaceTimeSeries(x_data, data_tl, space, title, ylabel, fig_path)
    pixels = _randomLocations(_validLocations(data_tl))
    series = Any[_series(_spaceMean(data_tl); label="mean of all locations", color=_mean_color, lw=2.6)]
    for (k, loc) ∈ enumerate(pixels)
        push!(series, _series(data_tl[:, loc]; label=_locationLabel(space, loc), color=_pixel_colors[k], lw=0.8, alpha=0.85))
    end
    _plotTimeSeriesWithCycles(x_data, series, fig_path; title=title, ylabel=ylabel, legend_columns=3)
    return nothing
end

"""
    _plotSpaceTime(x_data, data_tl, space, title, units, fig_path)

Saves a heatmap of a (time, location) array with time on the x axis, see
`_spaceTimePanel`.
"""
function _plotSpaceTime(x_data, data_tl, space, title, units, fig_path)
    p = _spaceTimePanel(x_data, data_tl, space; title=title, units=units)
    plots_savefig(plots_plot(p; size=(1500, 600), left_margin=8plots_mm), fig_path)
    return nothing
end

"""
    _spaceTimePanel(x_data, data_tl, space; title, units, lims=:auto, cmap=:viridis, xlabel="time")

Draws a heatmap of a (time, location) array with time on the x axis. A list of sites
has one row per site, and a grid has one row per latitude with the mean over
longitude. The title has the mean and the number of missing values of the array.
`lims` is the range of the colour scale. Missing values are light grey, which is
apart from the white middle of a diverging colour scale.
"""
function _spaceTimePanel(x_data, data_tl, space; title, units, lims=:auto, cmap=:viridis, xlabel="time")
    n_time = size(data_tl, 1)
    if _isGrid(space)
        x_dim, y_dim = _mapDims(space)
        data_grid = reshape(data_tl, n_time, space.sizes...)
        n_rows = space.sizes[y_dim]
        z = [_nanMean(selectdim(selectdim(data_grid, 1, t), y_dim, r)) for r ∈ 1:n_rows, t ∈ 1:n_time]
        y = space.coords[y_dim]
        y_order = eltype(y) <: Real ? sortperm(y) : collect(eachindex(y))
        y, z = y[y_order], z[y_order, :]
        y_label = string(space.names[y_dim])
        y_ticks = :auto
    else
        z = permutedims(data_tl)
        y = 1:space.n_loc
        y_label = string(first(space.names))
        y_ticks = space.n_loc <= 40 ? (1:space.n_loc, string.(first(space.coords))) : :auto
    end
    stats = "mean = $(round(_nanMean(data_tl), digits=2)), NaNs = $(count(isnan, data_tl))"
    return plots_heatmap(x_data, y, z; _figStyle()..., title="$(title) | $(stats)", xlabel=xlabel, ylabel=y_label, yticks=y_ticks, clims=lims, colorbar_title=units, color=cmap, grid=false, framestyle=:box, background_color_inside=:grey85)
end

"""
    _plotComparisonSpaceTime(x_data, obs_tl, mod_tl, space, title, model_label, units, fig_path)

Saves the observation, the model and model - obs as three rows of `_spaceTimePanel`
on the same time axis. The observation and model rows share one colour scale, and the
difference has a scale centred on zero. The model is drawn at every time step, and
the difference only where the observation is.
"""
function _plotComparisonSpaceTime(x_data, obs_tl, mod_tl, space, title, model_label, units, fig_path)
    diff_tl = mod_tl .- obs_tl
    lims = _finiteLims(vec(obs_tl), vec(mod_tl))
    p_obs = _spaceTimePanel(x_data, obs_tl, space; title="obs", units=units, lims=lims, xlabel="")
    p_mod = _spaceTimePanel(x_data, mod_tl, space; title=model_label, units=units, lims=lims, xlabel="")
    p_diff = _spaceTimePanel(x_data, diff_tl, space; title="$(model_label) - obs", units=units, lims=_symmetricLims(vec(diff_tl)), cmap=:RdBu)
    fig = plots_plot(p_obs, p_mod, p_diff; layout=(3, 1), size=(1500, 1500), plot_title=title, plot_titlefontsize=12, dpi=300, left_margin=8plots_mm, bottom_margin=4plots_mm)
    plots_savefig(fig, fig_path)
    return nothing
end

"""
    _plotSpaceLayers(data_ll, space, title, units, fig_path)

Saves a heatmap of a (layer, location) array of a list of sites, with one column per
layer and one row per site. The title has the mean and the number of missing values.
"""
function _plotSpaceLayers(data_ll, space, title, units, fig_path)
    n_layer = size(data_ll, 1)
    y_ticks = space.n_loc <= 40 ? (1:space.n_loc, string.(first(space.coords))) : :auto
    stats = "mean = $(round(_nanMean(data_ll), digits=2)), NaNs = $(count(isnan, data_ll))"
    p = plots_heatmap(1:n_layer, 1:space.n_loc, permutedims(data_ll); _figStyle()..., title="$(title) | $(stats)", xlabel="layer", ylabel=string(first(space.names)), xticks=1:n_layer, yticks=y_ticks, colorbar_title=units, color=:viridis, grid=false, framestyle=:box, size=(500 + 120 * n_layer, 600), left_margin=8plots_mm)
    plots_savefig(p, fig_path)
    return nothing
end

"""
    _plotComparisonMean(space, obs_tl, mod_tl, title, model_label, units, fig_path)

Saves the time mean of the observation, the model and their difference at every
location in three panels. The model is masked where the observation is missing, and
the observation and model panels share one colour scale.
"""
function _plotComparisonMean(space, obs_tl, mod_tl, title, model_label, units, fig_path)
    obs_mean = _timeMean(obs_tl)
    mod_mean = _timeMean(ifelse.(isnan.(obs_tl), NaN, mod_tl))
    diff_mean = mod_mean .- obs_mean
    lims = _finiteLims(obs_mean, mod_mean)
    p_obs = _spatialPanel(space, obs_mean; title="obs", lims=lims, units=units)
    p_mod = _spatialPanel(space, mod_mean; title=model_label, lims=lims, units=units)
    p_diff = _spatialPanel(space, diff_mean; title="$(model_label) - obs", lims=_symmetricLims(diff_mean), cmap=:RdBu, units=units)
    fig = plots_plot(p_obs, p_mod, p_diff; layout=(1, 3), size=(1650, 480), plot_title=title, plot_titlefontsize=12, dpi=300, left_margin=6plots_mm, bottom_margin=8plots_mm)
    plots_savefig(fig, fig_path)
    return nothing
end

"""
    _plotComparisonTimeSeries(x_data, obs_tl, mod_tl, space, title, ylabel, fig_path)

Saves the mean over all locations and up to five random locations of the observation
(dashed) and the model (solid), with one colour per location and their cycles, see
`_plotTimeSeriesWithCycles`. The mean of the model is taken over the locations and
time steps with an observation, and the random locations are drawn from those with an
observation.
"""
function _plotComparisonTimeSeries(x_data, obs_tl, mod_tl, space, title, ylabel, fig_path)
    pixels = _randomLocations(_validLocations(obs_tl))
    mod_masked = ifelse.(isnan.(obs_tl), NaN, mod_tl)
    series = Any[_series(_spaceMean(mod_masked); label="mean of all locations", color=_mean_color, lw=2.6),
        _series(_spaceMean(obs_tl); label="", color=_mean_color, lw=2.0, linestyle=:dash)]
    for (k, loc) ∈ enumerate(pixels)
        push!(series, _series(mod_tl[:, loc]; label=_locationLabel(space, loc), color=_pixel_colors[k], lw=0.8))
        push!(series, _series(obs_tl[:, loc]; label="", color=_pixel_colors[k], lw=0.8, linestyle=:dash))
    end
    _plotTimeSeriesWithCycles(x_data, series, fig_path; title=title, ylabel=ylabel, legend_columns=3)
    return nothing
end

# ------------------------------------------------------------------
# spatial forms of the debug, forcing and comparison figures
# ------------------------------------------------------------------

"""
    _plotDebugSpatial(info, model_dat, space, model_label)

Saves `debug_timeseries_*` and `debug_spacetime_*` for every output variable and
layer of a spatial run, and `debug_mean_*` for a grid.
"""
function _plotDebugSpatial(info, model_dat, space, model_label)
    domain = info.experiment.basics.domain
    name_prefix = info.experiment.basics.name * "_" * domain
    fig_dir = info.output.dirs.figure
    x_data = [info.helpers.dates.range...]
    for (o, v) ∈ enumerate(info.output.variables)
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        vname = vinfo["standard_name"]
        println("plot debug::", vname)
        data_tll = _toTimeLayerLoc(values(model_dat)[o], space)
        n_layer = size(data_tll, 2)
        x_var = length(x_data) == size(data_tll, 1) ? x_data : collect(1:size(data_tll, 1))
        for ll ∈ 1:n_layer
            layer_tag = n_layer > 1 ? "_$(ll)" : ""
            layer_title = n_layer > 1 ? ", layer $(ll)" : ""
            data_tl = data_tll[:, ll, :]
            title = "$(_varTitle(domain, vinfo))$(layer_title) | $(model_label)"
            _isGrid(space) && _plotMeanMap(space, data_tl, "$(title), time mean", vinfo["units"], joinpath(fig_dir, "debug_mean_$(name_prefix)_$(vname)$(layer_tag).png"))
            _plotSpaceTimeSeries(x_var, data_tl, space, title, _varAxisLabel(vinfo), joinpath(fig_dir, "debug_timeseries_$(name_prefix)_$(vname)$(layer_tag).png"))
            _plotSpaceTime(x_var, data_tl, space, title, vinfo["units"], joinpath(fig_dir, "debug_spacetime_$(name_prefix)_$(vname)$(layer_tag).png"))
        end
    end
    return nothing
end

"""
    _plotForcingSpatial(info, forcing, space)

Saves the figures of every forcing variable of a spatial run:
- with spatial dimensions and time: `forcing_timeseries_*` and `forcing_spacetime_*`
  per layer, and `forcing_mean_*` per layer for a grid
- with spatial dimensions and without time: `forcing_mean_*` per layer for a grid,
  and one `forcing_spacetime_*` with a column per layer for a list of sites
- without spatial dimensions: `forcing_<experiment>_<domain>_<variable>`, as for one
  location
"""
function _plotForcingSpatial(info, forcing, space)
    domain = info.experiment.basics.domain
    name_prefix = info.experiment.basics.name * "_" * domain
    fig_dir = info.output.dirs.figure
    forcing_settings = _getSetting(info.experiment.data_settings.forcing, :variables)
    for (f_i, (v, f_data)) ∈ enumerate(zip(forcing.variables, forcing.data))
        println("plot forcing::", v)
        f_arr = Array(f_data)
        ndims(f_arr) == 0 && continue
        v_settings = _getSetting(forcing_settings, v)
        v_name = something(_getSetting(v_settings, :standard_name), string(v))
        v_units = something(_getSetting(v_settings, :sindbad_unit), "-")
        title = "$(domain): $(v_name) [$(v_units)]"
        ylabel = "$(v) [$(v_units)]"
        has_time = last(forcing.f_types[f_i]) isa ForcingWithTime
        if ndims(f_arr) < length(space.sizes)
            _plotForcingLines(info, forcing.helpers, f_arr, has_time, title, ylabel, joinpath(fig_dir, "forcing_$(name_prefix)_$(v).png"))
            continue
        end
        data_tll = _toTimeLayerLoc(f_arr, space; has_time=has_time)
        n_layer = size(data_tll, 2)
        # forcing without time of a list of sites is one heatmap with a column per
        # layer
        if !has_time && !_isGrid(space)
            _plotSpaceLayers(data_tll[1, :, :], space, title, v_units, joinpath(fig_dir, "forcing_spacetime_$(name_prefix)_$(v).png"))
            continue
        end
        x_var = _timeAxis(info, forcing.helpers, size(data_tll, 1))
        for ll ∈ 1:n_layer
            layer_tag = n_layer > 1 ? "_$(ll)" : ""
            layer_title = n_layer > 1 ? ", layer $(ll)" : ""
            data_tl = data_tll[:, ll, :]
            mean_title = has_time ? "$(title)$(layer_title), time mean" : "$(title)$(layer_title)"
            _isGrid(space) && _plotMeanMap(space, data_tl, mean_title, v_units, joinpath(fig_dir, "forcing_mean_$(name_prefix)_$(v)$(layer_tag).png"); color=_def_color)
            has_time || continue
            _plotSpaceTimeSeries(x_var, data_tl, space, "$(title)$(layer_title)", ylabel, joinpath(fig_dir, "forcing_timeseries_$(name_prefix)_$(v)$(layer_tag).png"))
            _plotSpaceTime(x_var, data_tl, space, "$(title)$(layer_title)", v_units, joinpath(fig_dir, "forcing_spacetime_$(name_prefix)_$(v)$(layer_tag).png"))
        end
    end
    return nothing
end

"""
    _timeAxis(info, forcing_helpers, n_time)

Returns the dates of a time dimension of `n_time` steps: the time coordinates of the
forcing, or else the dates of the run, or the step index when neither has that
length.
"""
function _timeAxis(info, forcing_helpers, n_time)
    if !isnothing(forcing_helpers)
        time_name = Symbol(forcing_helpers.dimensions.time)
        axes_pairs = collect(forcing_helpers.axes)
        ax = findfirst(a -> Symbol(first(a)) == time_name, axes_pairs)
        if !isnothing(ax)
            time_values = collect(last(axes_pairs[ax]))
            length(time_values) == n_time && eltype(time_values) <: TimeType && return time_values
        end
    end
    dates_run = [info.helpers.dates.range...]
    length(dates_run) == n_time && return dates_run
    return collect(1:n_time)
end

# Saves one line per column of a forcing variable. With time, the first dimension is
# time, the x axis has its dates, and the cycles are drawn next to it. Without time,
# the x axis is the index of the values.
function _plotForcingLines(info, forcing_helpers, f_arr, has_time, title, ylabel, fig_path)
    f_mat = reshape(f_arr, size(f_arr, 1), :)
    x_data = has_time ? _timeAxis(info, forcing_helpers, size(f_mat, 1)) : axes(f_mat, 1)
    is_dates = eltype(x_data) <: TimeType
    is_multi = size(f_mat, 2) > 1
    if is_dates
        series = Any[_series(f_mat[:, l]; label=is_multi ? "layer $(l)" : "", color=is_multi ? :auto : _def_color, lw=1.0) for l in axes(f_mat, 2)]
        _plotTimeSeriesWithCycles(x_data, series, fig_path; title=title, ylabel=ylabel, legend_columns=min(size(f_mat, 2), 6))
        return nothing
    end
    plots_plot(x_data, f_mat; _figStyle()..., title=title, xlabel="index", ylabel=ylabel, label=permutedims(["layer $(l)" for l in axes(f_mat, 2)]), legend=is_multi ? :outerright : false, color=is_multi ? :auto : _def_color, lw=1.0)
    plots_savefig(fig_path)
    return nothing
end

"""
    _plotComparisonSpatial(info, obs_array, var_row, model_dat, model_label, lossMetric, vinfo, vname, space)

Saves `comparison_spacetime_*` and `comparison_timeseries_*` of one observed variable
of a spatial run, and `comparison_mean_*` for a grid.
"""
function _plotComparisonSpatial(info, obs_array, var_row, model_dat, model_label, lossMetric, vinfo, vname, space)
    domain = info.experiment.basics.domain
    name_prefix = info.experiment.basics.name * "_" * domain
    fig_dir = info.output.dirs.figure
    (obs_var, obs_σ, mod_var) = getData(model_dat, obs_array, var_row)
    (obs_no_nan, obs_σ_no_nan, mod_no_nan) = getDataWithoutNaN(obs_var, obs_σ, mod_var)
    metric_value = metric(lossMetric, mod_no_nan, obs_no_nan, obs_σ_no_nan)
    metric_name = nameof(typeof(lossMetric))

    # observations with several layers are compared as the mean of the layers
    obs_tl = dropdims(mapslices(_nanMean, _toTimeLayerLoc(obs_var, space); dims=2); dims=2)
    mod_tl = dropdims(mapslices(_nanMean, _toTimeLayerLoc(mod_var, space); dims=2); dims=2)

    x_data = [time_resample_dates(var_row.temporal_aggr)...]
    x_data = length(x_data) == size(obs_tl, 1) ? x_data : collect(1:size(obs_tl, 1))
    title = "$(_varTitle(domain, vinfo)) | $(model_label) $(metric_name): $(round(metric_value, digits=2))"
    # the map of the time mean is only drawn for a grid
    _isGrid(space) && _plotComparisonMean(space, obs_tl, mod_tl, "$(title), time mean", model_label, vinfo["units"], joinpath(fig_dir, "comparison_mean_$(name_prefix)_$(vname).png"))
    _plotComparisonSpaceTime(x_data, obs_tl, mod_tl, space, title, model_label, vinfo["units"], joinpath(fig_dir, "comparison_spacetime_$(name_prefix)_$(vname).png"))
    _plotComparisonTimeSeries(x_data, obs_tl, mod_tl, space, "$(title)\nsolid: $(model_label), dashed: obs", _varAxisLabel(vinfo), joinpath(fig_dir, "comparison_timeseries_$(name_prefix)_$(vname).png"))
    return nothing
end
