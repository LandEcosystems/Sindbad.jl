# Bring the target functions into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.Visualization: plotPerformanceHistograms, plotTimeSeries
using Sindbad
import Dates

# ------------------------------------------------------------------
# shared figure style
# ------------------------------------------------------------------

# The dots per inch of the saved figures. Every plot function that gets the experiment
# info sets it from `info.output.plot_resolution` with `_setFigureResolution!`, so the
# helpers below that only get a file path use the resolution of the current experiment.
const _fig_dpi = Ref(100)

"""
    _setFigureResolution!(info)

Sets the dots per inch of the saved figures to `info.output.plot_resolution`. An info
without that field, e.g., one saved before the option existed, keeps the current value.
"""
function _setFigureResolution!(info)
    if hasproperty(info, :output) && hasproperty(info.output, :plot_resolution)
        _fig_dpi[] = info.output.plot_resolution
    end
    return nothing
end

# The figures have no top and right axis lines, a thin grid, dark grey labels and
# ticks, and are saved at the resolution of `_fig_dpi`.
_figStyle() = (; framestyle=:axes, gridalpha=0.25, gridlinewidth=0.4, guidefontcolor=:grey25, tickfontcolor=:grey25, titlefontsize=12, guidefontsize=10, tickfontsize=8, legendfontsize=9, foreground_color_legend=nothing, dpi=_fig_dpi[], size=(1200, 500), left_margin=5plots_mm, bottom_margin=4plots_mm)

# the colour of a single or default model output, a medium blue that stays apart from
# the black observations
const _model_color = "#2C7FB8"

# the colour of the forward run appended after the spinup
const _forward_color = "#E69F00"

# the colours of the default and the optimized output when both are drawn, a
# vermillion and a green that differ in hue and lightness
const _def_color = "#D55E00"
const _opt_color = :seagreen3

_varLongName(vinfo) = isempty(vinfo["long_name"]) ? vinfo["standard_name"] : vinfo["long_name"]

_varTitle(domain, vinfo) = "$(domain): $(_varLongName(vinfo)) [$(vinfo["units"])]"

_varAxisLabel(vinfo) = "$(vinfo["standard_name"]) [$(vinfo["units"])]"

# ------------------------------------------------------------------
# time series with mean seasonal and diurnal cycles
# ------------------------------------------------------------------

# one line or set of points of a time series figure, with its plot keywords
_series(y; kw...) = (; y=y, kw=(; kw...))

const _month_initials = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
# the first day of every month on the 366 day calendar of TimeSamplers
const _month_first_day = [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336]

"""
    _timeStepHours(x_data)

Returns the time step of a time axis in hours, or `nothing` when the time steps are
not dates.
"""
function _timeStepHours(x_data)
    length(x_data) < 2 && return nothing
    eltype(x_data) <: Dates.TimeType || return nothing
    return Dates.value(Dates.Millisecond(x_data[2] - x_data[1])) / 3_600_000
end

"""
    _mscAggregationName(x_data)

Returns the name of the TimeSamplers aggregation to the mean seasonal cycle at the
time step of a time axis, which is the time step followed by `_msc`, e.g.
`"day_msc"`, `"8-day_msc"` or `"month_msc"`. A time step shorter than a day gives
`"day_msc"`, the seasonal cycle of daily values. It returns `nothing` when the time
steps are not dates, are a year or longer apart, or are not a whole number of hours.
"""
function _mscAggregationName(x_data)
    step_hours = _timeStepHours(x_data)
    isnothing(step_hours) && return nothing
    step_hours >= 300 * 24 && return nothing
    step_hours >= 28 * 24 && return "month_msc"
    isinteger(step_hours) || return nothing
    n_hours = Int(step_hours)
    n_hours < 24 && return "day_msc"
    n_hours % 24 == 0 || return nothing
    return (n_hours == 24 ? "day" : "$(n_hours ÷ 24)-day") * "_msc"
end

"""
    _diurnalAggregationName(x_data)

Returns the name of the TimeSamplers aggregation to the mean diurnal cycle at a time
step shorter than a day that divides a day, e.g. `"hour_msc_day"` or
`"3-hour_msc_day"`, or `nothing` for any other time step.
"""
function _diurnalAggregationName(x_data)
    step_hours = _timeStepHours(x_data)
    isnothing(step_hours) && return nothing
    (isinteger(step_hours) && step_hours < 24 && 24 % Int(step_hours) == 0) || return nothing
    n_hours = Int(step_hours)
    return (n_hours == 1 ? "hour" : "$(n_hours)-hour") * "_msc_day"
end

"""
    _cyclePanels(x_data)

Returns the cycles drawn next to a time series, each with its TimeSamplers sampler,
the x values and ticks of its positions and its title: the mean seasonal cycle (MSC),
and for a time step shorter than a day also the mean diurnal cycle. It is empty when
`_mscAggregationName` is `nothing`.

# Notes:
- The means skip missing values.
- The x values come from the zero based cycle positions of `time_resample_dates`, in
  the order of the sampled values. TimeSamplers counts day positions on a 366 day
  calendar, so that Mar 1 has the same position in every year. The MSC is drawn at
  the day of that calendar, or at the month for monthly data, and the diurnal cycle
  at the hour of the day.
"""
function _cyclePanels(x_data)
    cycles = []
    msc_aggr = _mscAggregationName(x_data)
    isnothing(msc_aggr) && return cycles
    sampler = first(create_TimeSampler(x_data, msc_aggr, nanmean))
    positions = time_resample_dates(x_data, msc_aggr)
    step_hours = _timeStepHours(x_data)
    diurnal_aggr = _diurnalAggregationName(x_data)
    if msc_aggr == "month_msc"
        push!(cycles, (; sampler, x=positions .+ 1, xticks=(1:12, _month_initials), xlabel="month", title="MSC"))
    else
        days_per_position = isnothing(diurnal_aggr) ? step_hours / 24 : 1
        msc_title = isnothing(diurnal_aggr) ? "MSC" : "MSC of daily values"
        push!(cycles, (; sampler, x=positions .* days_per_position .+ 1, xticks=(_month_first_day, _month_initials), xlabel="day of year", title=msc_title))
    end
    if !isnothing(diurnal_aggr)
        sampler = first(create_TimeSampler(x_data, diurnal_aggr, nanmean))
        positions = time_resample_dates(x_data, diurnal_aggr)
        push!(cycles, (; sampler, x=positions .* step_hours, xticks=0:3:21, xlabel="hour of day", title="mean diurnal cycle"))
    end
    return cycles
end

_cycleValues(y, cycle) = time_sampling(collect(y), cycle.sampler)

"""
    _plotTimeSeriesWithCycles(x_data, series, fig_path; title, ylabel, legend_columns=2)

Saves a time series figure with the time series and its cycles from `_cyclePanels` on
the same y range: the mean seasonal cycle (MSC) next to a time series of a day or
longer, with 70% of the width for the time series, and the MSC of daily values and
the mean diurnal cycle next to a time series shorter than a day, with 60% of the
width for the time series. `series` is a list of `_series`, and each is drawn with
the same keywords in every panel.

# Notes:
- The cycle panels have no y axis. Without cycles, e.g. for yearly time steps, the
  figure is the time series alone with the legend below it.
- The legend is in its own strip under the panels, so that all panels have the same
  height and their y axes line up.
"""
function _plotTimeSeriesWithCycles(x_data, series, fig_path; title, ylabel, legend_columns=2)
    cycles = _cyclePanels(x_data)
    if isempty(cycles)
        p_ts = plots_plot(; _figStyle()..., title=title, xlabel="time", ylabel=ylabel, legend=:outerbottom, legendcolumns=legend_columns)
        for s ∈ series
            plots_plot!(p_ts, x_data, s.y; s.kw...)
        end
        plots_savefig(p_ts, fig_path)
        return nothing
    end
    cycle_series = [[_cycleValues(s.y, cycle) for s ∈ series] for cycle ∈ cycles]
    y_lims = _paddedLims([[s.y for s ∈ series]; reduce(vcat, cycle_series)])

    p_ts = plots_plot(; _figStyle()..., title=title, xlabel="time", ylabel=ylabel, ylims=y_lims, legend=false)
    for s ∈ series
        plots_plot!(p_ts, x_data, s.y; s.kw..., label="")
    end
    p_cycles = map(cycles, cycle_series) do cycle, values_list
        p = plots_plot(; _figStyle()..., title=cycle.title, xlabel=cycle.xlabel, xticks=cycle.xticks, ylims=y_lims, yticks=false, showaxis=:x, grid=:x, legend=false)
        for (s, values) ∈ zip(series, values_list)
            plots_plot!(p, cycle.x, values; s.kw..., label="")
        end
        p
    end
    ts_width = length(cycles) == 1 ? 0.7 : 0.6
    cycle_widths = fill((1 - ts_width) / length(cycles), length(cycles))
    panels = plots_plot(p_ts, p_cycles...; layout=plots_grid(1, 1 + length(cycles); widths=[ts_width; cycle_widths]))

    labelled = [s for s ∈ series if !isempty(string(get(s.kw, :label, "")))]
    if isempty(labelled)
        fig = plots_plot(panels; size=(1500, 480), dpi=_fig_dpi[], left_margin=8plots_mm, bottom_margin=6plots_mm)
    else
        # a legend without axes: every labelled series drawn with no data
        p_legend = plots_plot(; framestyle=:none, grid=false, xticks=false, yticks=false, legend=:top, legendcolumns=min(legend_columns, length(labelled)), legendfontsize=9, foreground_color_legend=nothing, background_color_legend=nothing)
        for s ∈ labelled
            plots_plot!(p_legend, [NaN], [NaN]; s.kw...)
        end
        fig = plots_plot(panels, p_legend; layout=plots_grid(2, 1; heights=[0.88, 0.12]), size=(1500, 540), dpi=_fig_dpi[], left_margin=8plots_mm, bottom_margin=6plots_mm)
    end
    plots_savefig(fig, fig_path)
    return nothing
end

# the range of all finite values of a list of series, with 5% space on both sides
function _paddedLims(all_values)
    finite = filter(isfinite, reduce(vcat, [vec(collect(v)) for v ∈ all_values]))
    isempty(finite) && return :auto
    y_low, y_high = extrema(finite)
    y_span = y_high > y_low ? y_high - y_low : max(abs(y_high), 1.0) * 0.1
    return (y_low - 0.05 * y_span, y_high + 0.05 * y_span)
end

# ------------------------------------------------------------------
# performance histograms
# ------------------------------------------------------------------

"""
    plotPerformanceHistograms(out_opti)

Generate performance histograms based on optimization output data.

# Arguments
- `out_opti`: ParameterOptimization output data structure containing model outputs and information

# Description
Saves one figure, `comparison_histograms.png`, with a panel per
observation constraint of the cost in two columns: the histograms of the metric per
location of the default and the optimized output, and the metric of all locations as
dashed lines, with its values in the title of the panel. The metric is the cost metric,
or NSE for a cost of NSEInv or NNSEInv.

# Examples
```jldoctest
julia> using Sindbad

julia> # Plot performance histograms from optimization results
julia> # plotPerformanceHistograms(out_opti)
```
"""
function plotPerformanceHistograms(out_opti, ::VisualizationPlots)
    opt_dat = out_opti.output.optimized
    def_dat = out_opti.output.default
    obs_array = out_opti.observation
    info = out_opti.info
    _setFigureResolution!(info)
    run_helpers = out_opti.run_helpers

    domain = info.experiment.basics.domain
    fig_path = joinpath(info.output.dirs.figure, "comparison_histograms.png")
    b_range = range(-1, 1, length=50)
    panels = map(enumerate(out_opti.cost_options)) do (i, var_row)
        println("plot performance comparison:: $(var_row.variable)")
        vname, vinfo, lossMetric = getCostRowVariableInfo(var_row, info.experiment.basics.temporal_resolution)
        (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row)
        (_, _, opt_var) = getData(opt_dat, obs_array, var_row)

        (obs_var_no_nan, obs_σ_no_nan, def_var_no_nan) = getDataWithoutNaN(obs_var, obs_σ, def_var)
        (obs_var_no_nan, obs_σ_no_nan, opt_var_no_nan) = getDataWithoutNaN(obs_var, obs_σ, opt_var)

        loss_space = map([run_helpers.space_ind...]) do lsi
            opt_pix = view_at_trailing_indices(opt_var, lsi)
            def_pix = view_at_trailing_indices(def_var, lsi)
            obs_pix = view_at_trailing_indices(obs_var, lsi)
            obs_σ_pix = view_at_trailing_indices(obs_σ, lsi)
            (obs_pix_no_nan, obs_σ_pix_no_nan, opt_pix_no_nan) = getDataWithoutNaN(obs_pix, obs_σ_pix, opt_pix)
            (_, _, def_pix_no_nan) = getDataWithoutNaN(obs_pix, obs_σ_pix, def_pix)
            [metric(lossMetric, def_pix_no_nan, obs_pix_no_nan, obs_σ_pix_no_nan), metric(lossMetric, opt_pix_no_nan, obs_pix_no_nan, obs_σ_pix_no_nan)]
        end

        metric_name = nameof(typeof(lossMetric))
        metr_def = metric(lossMetric, def_var_no_nan, obs_var_no_nan, obs_σ_no_nan)
        metr_opt = metric(lossMetric, opt_var_no_nan, obs_var_no_nan, obs_σ_no_nan)
        p_title = "$(vname) | $(metric_name) def $(_roundText(metr_def)), opt $(_roundText(metr_opt))"
        show_legend = i == 1 ? :topleft : false
        p = plots_histogram(first.(loss_space); _figStyle()..., title=p_title, titlefontsize=9, bins=b_range, alpha=0.55, label="def per location", color=_def_color, linecolor=:white, linewidth=0.3, xlabel="$(metric_name)", ylabel="number of locations", guidefontsize=8, tickfontsize=7, grid=:y, legend=show_legend, legendfontsize=7)
        plots_histogram!(p, last.(loss_space); bins=b_range, alpha=0.55, label="opt per location", color=_opt_color, linecolor=:white, linewidth=0.3)
        plots_vline!(p, [metr_def]; label="", color=_def_color, linestyle=:dash, lw=1.2)
        plots_vline!(p, [metr_opt]; label="", color=_opt_color, linestyle=:dash, lw=1.2)
        p
    end
    n_cols = min(2, length(panels))
    n_rows = cld(length(panels), n_cols)
    fig = plots_plot(panels...; layout=(n_rows, n_cols), size=(550 * n_cols, 320 * n_rows), dpi=_fig_dpi[], plot_title="$(domain): $(info.experiment.basics.name), dashed lines are the metric of all locations", plot_titlefontsize=11, left_margin=6plots_mm, bottom_margin=4plots_mm)
    plots_savefig(fig, fig_path)
    return nothing
end

# ------------------------------------------------------------------
# shared helpers for the plotTimeSeries family
# ------------------------------------------------------------------

# Resolves the display name, variable metadata, and cost/loss metric (with the
# NNSEInv/NSEInv -> NSE() substitution) for one cost-options row. Shared by every
# plotTimeSeries method that iterates cost-option rows (i.e. all except the
# debug method, which iterates `info.output.variables` directly and has no metric).
function getCostRowVariableInfo(var_row, temporal_resolution)
    v2 = (var_row.mod_field, var_row.mod_subfield)
    vinfo = getVariableInfo(v2, temporal_resolution)
    vname = vinfo["standard_name"]
    lossMetric = var_row.cost_metric
    loss_name = nameof(typeof(lossMetric))
    if loss_name in (:NNSEInv, :NSEInv)
        lossMetric = NSE()
    end
    return vname, vinfo, lossMetric
end

_roundText(x) = isfinite(x) ? string(round(x; sigdigits=3)) : "n/a"

# the sampler of the monthly mean seasonal cycle of a time axis of dates, with the
# month of each value, or nothing when the time steps are not dates
function _monthlyCycle(x_data)
    eltype(x_data) <: Dates.TimeType || return nothing
    sampler = first(create_TimeSampler(x_data, "month_msc", nanmean))
    return (; sampler, x=time_resample_dates(x_data, "month_msc") .+ 1)
end

"""
    _plotComparisonAllVariables(info, obs_array, cost_options, def_dat, fig_path; opt_dat=nothing)

Saves one figure with a row per observation constraint of the cost: the observations,
the default output and, when `opt_dat` is given, the optimized output as time
series, and their mean seasonal cycle (MSC) next to it. The title of a row gives the
cost metric of the constraint and the bias of each output.

# Notes:
- The data are at the resolution of the cost. The time series span the valid
  observations.
- The cost metric is calculated as in the cost, on the valid points of the
  observation. The bias and the MSC use the points where the observation and every
  output are valid, so that the outputs are compared on the same points.
- The MSC is the monthly mean. A constraint with one or two points, e.g. a biomass,
  or without dates has none.
"""
function _plotComparisonAllVariables(info, obs_array, cost_options, def_dat, fig_path; opt_dat=nothing)
    has_opt = !isnothing(opt_dat)
    panels = Any[]
    for (i, var_row) ∈ enumerate(cost_options)
        println("plot time series comparison:: $(var_row.variable)")
        vname, vinfo, _ = getCostRowVariableInfo(var_row, info.experiment.basics.temporal_resolution)
        metric_name = nameof(typeof(var_row.cost_metric))
        (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row)
        obs_var = vec(nanmean(obs_var, dims=2))
        obs_σ = vec(collect(obs_σ))
        model_vars = Any[vec(mean(def_var, dims=3))]
        if has_opt
            (_, _, opt_var) = getData(opt_dat, obs_array, var_row)
            push!(model_vars, vec(mean(opt_var, dims=3)))
        end
        valids = var_row.valids
        common = valids .& reduce(.&, [isfinite.(m) for m ∈ model_vars])
        x_data = [time_resample_dates(var_row.temporal_aggr)...]

        names_runs = has_opt ? ["def", "opt"] : ["model"]
        colors_runs = has_opt ? [_def_color, _opt_color] : [_model_color]
        metric_texts = map(names_runs, model_vars) do run_name, m
            "$(run_name) $(_roundText(metric(var_row.cost_metric, m[valids], obs_var[valids], obs_σ[valids])))"
        end
        bias_texts = map(names_runs, model_vars) do run_name, m
            "$(run_name) $(_roundText(any(common) ? mean(m[common] .- obs_var[common]) : NaN))"
        end
        title = "$(vname) [$(vinfo["units"])] | $(metric_name) $(join(metric_texts, ", ")) | bias $(join(bias_texts, ", "))"

        show_legend = i == 1 ? :outertop : false
        p_ts = plots_plot(; _figStyle()..., title=title, titlefontsize=9, titlelocation=:left, ylabel=_varAxisLabel(vinfo), guidefontsize=8, tickfontsize=7, legend=show_legend, legendcolumns=1 + length(model_vars), legendfontsize=7)
        valid_index = findall(valids)
        if isempty(valid_index)
            push!(panels, p_ts, plots_plot(; framestyle=:none))
            continue
        end
        tspan = first(valid_index):last(valid_index)
        if length(valid_index) < 3
            # a few points, e.g. a yearly biomass, are labelled with their year
            x_points = eltype(x_data) <: Dates.TimeType ? Dates.year.(x_data[valid_index]) : x_data[valid_index]
            for (run_name, color, m) ∈ zip(names_runs, colors_runs, model_vars)
                plots_scatter!(p_ts, x_points, m[valid_index]; color=color, markersize=5, markerstrokewidth=0, label=run_name)
            end
            plots_scatter!(p_ts, x_points, obs_var[valid_index]; color=:black, markersize=5, markerstrokewidth=0, label="obs", xticks=x_points, xlims=(minimum(x_points) - 1, maximum(x_points) + 1))
        else
            for (run_name, color, m) ∈ zip(names_runs, colors_runs, model_vars)
                plots_plot!(p_ts, x_data[tspan], m[tspan]; color=color, lw=0.8, label=run_name)
            end
            plots_scatter!(p_ts, x_data[valid_index], obs_var[valid_index]; color=:black, markersize=1.5, markerstrokewidth=0, alpha=0.6, label="obs")
        end

        msc = length(valid_index) < 3 ? nothing : _monthlyCycle(x_data)
        if isnothing(msc)
            p_msc = plots_plot(; framestyle=:none)
        else
            masked(y) = ifelse.(common, y, convert(eltype(y), NaN))
            p_msc = plots_plot(; _figStyle()..., title="MSC", titlefontsize=9, xticks=(1:12, _month_initials), tickfontsize=7, legend=false)
            for (color, m) ∈ zip(colors_runs, model_vars)
                plots_plot!(p_msc, msc.x, _cycleValues(masked(m), msc); color=color, lw=1.5)
            end
            plots_scatter!(p_msc, msc.x, _cycleValues(masked(obs_var), msc); color=:black, markersize=2.5, markerstrokewidth=0)
        end
        push!(panels, p_ts, p_msc)
    end
    n_rows = length(cost_options)
    fig = plots_plot(panels...; layout=plots_grid(n_rows, 2; widths=[0.78, 0.22]), size=(1500, 230 * n_rows + 60), dpi=_fig_dpi[], plot_title="$(info.experiment.basics.domain): $(info.experiment.basics.name)", plot_titlefontsize=12, left_margin=8plots_mm, bottom_margin=2plots_mm)
    plots_savefig(fig, fig_path)
    return nothing
end

# Saves the time series of one debug variable or layer with its cycles, see
# `_plotTimeSeriesWithCycles`: the default output, and the optimized output when
# opt_col is not nothing.
function _plotDebugVariableLayer!(xdata, def_col, opt_col, title_str, ylabel_str, fig_path)
    series = Any[_series(def_col; label="def ($(round(mean(def_col), digits=2)))", color=isnothing(opt_col) ? _model_color : _def_color, lw=1.0)]
    if !isnothing(opt_col)
        push!(series, _series(opt_col; color=_opt_color, lw=1.0, label="opt ($(round(mean(opt_col), digits=2)))"))
    end
    _plotTimeSeriesWithCycles(xdata, series, fig_path; title=title_str, ylabel=ylabel_str)
    return nothing
end

# ------------------------------------------------------------------
# plotTimeSeries family (replaces plotTimeSeriesWithObs / plotTimeSeriesDebug)
# ------------------------------------------------------------------

"""
    plotTimeSeries(out_opti)

Generate time series plots comparing optimized and default model outputs with observations.

# Arguments
- `out_opti`: ParameterOptimization output data structure containing model outputs and information

# Description
Saves one figure, `comparison_time_series.png`, with a row per
observation constraint of the cost: the observations as points, the default and the
optimized outputs as lines, and their monthly mean seasonal cycle next to it. The title
of a row gives the cost metric of the constraint and the bias of both outputs. See
`_plotComparisonAllVariables`.

# Examples
```jldoctest
julia> using Sindbad

julia> # Plot time series with observations
julia> # plotTimeSeries(out_opti)
```
"""
function plotTimeSeries(out_opti, ::VisualizationPlots)
    info = out_opti.info
    obs_array = out_opti.observation
    cost_options = out_opti.cost_options
    def_dat = out_opti.output.default
    opt_dat = out_opti.output.optimized
    return plotTimeSeries(info, obs_array, cost_options, def_dat, opt_dat, VisualizationPlots(); forcing_helpers=_forcingHelpers(out_opti))
end

"""
    plotTimeSeries(out, cost_options)

Generate time series plots comparing a single model output against observations (no def-vs-optimized comparison).

# Arguments
- `out`: an experiment output structure carrying `.info`, `.observation`, and `.output`
- `cost_options`: cost-option rows (one per variable) used to select and evaluate each series

# Description
Saves one figure, `time_series_single.png`, with a row per variable in
`cost_options`: the observations as points and the model output as a line, with their
monthly mean seasonal cycle next to it and the cost metric and bias in the title.
"""
function plotTimeSeries(out, cost_options, ::VisualizationPlots)
    info = out.info
    obs_array = out.observation
    def_dat = out.output
    return plotTimeSeries(info, obs_array, cost_options, def_dat, VisualizationPlots(); forcing_helpers=_forcingHelpers(out))
end

"""
    plotTimeSeries(info, opt_dat, def_dat)

Plot debugging figures for model outputs.

# Arguments
- `info`: Information structure containing experiment details
- `opt_dat`: Optimized model output data
- `def_dat`: Default model output data

# Description
This function generates debugging figures by plotting the optimized and default model
outputs for each variable specified in the experiment's output variables list. With
`opt_dat` set to `nothing`, e.g. for a forward run, only the default output is
plotted.

For a spatial run, i.e. with `forcing_helpers` given and more than one location, the
figures are `debug_*_timeseries` and `debug_*_spacetime` of the optimized output, or
of the default output without an optimized one, and `debug_*_mean` for a grid. See
`_plotDebugSpatial`.

For one location, it calculates the mean of the model outputs across layers and then
plots them against time using Plots.jl. Debugging figures are saved in a directory
specified by `info.output.dirs.figure`.
"""
function plotTimeSeries(info, opt_dat, def_dat, ::VisualizationPlots; forcing_helpers=nothing)
    _setFigureResolution!(info)
    space = _spaceInfo(forcing_helpers)
    if _isSpatial(space)
        has_opt = !isnothing(opt_dat)
        return _plotDebugSpatial(info, has_opt ? opt_dat : def_dat, space, has_opt ? "opt" : "def")
    end
    has_opt = !isnothing(opt_dat)
    output_array_opt = has_opt ? values(opt_dat) : nothing
    output_array_def = values(def_dat)
    output_vars = info.output.variables

    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "debug")
    for (o, v) in enumerate(output_vars)
        def_var = mean(output_array_def[o], dims=3)[:, :, 1]
        opt_var = has_opt ? mean(output_array_opt[o], dims=3)[:, :, 1] : nothing
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        vname = vinfo["standard_name"]
        println("plot debug::", vname)
        xdata = [info.helpers.dates.range...]
        optLayer(ll) = has_opt ? opt_var[:, ll] : nothing
        if size(def_var, 2) == 1
            _plotDebugVariableLayer!(xdata, def_var[:, 1], optLayer(1), _varTitle(domain, vinfo), _varAxisLabel(vinfo), fig_prefix * "_$(vname).png")
        else
            foreach(axes(def_var, 2)) do ll
                _plotDebugVariableLayer!(xdata, def_var[:, ll], optLayer(ll), "$(_varTitle(domain, vinfo)), layer $(ll)", _varAxisLabel(vinfo), fig_prefix * "_$(vname)_$(ll).png")
            end
        end
    end
    return nothing
end

# Explicit-argument target of the arity-2 wrapper above: single-series-vs-observations
# plotting (no optimized comparison). Not an independent public entry point (see
# Visualization.jl for why it doesn't get its own `::VisualizationTypes` fallback there,
# except where needed to back the legacy `plotTimeSeriesWithObs(out, obs_array, cost_options)` alias).
function plotTimeSeries(info, obs_array, cost_options, def_dat, ::VisualizationPlots; forcing_helpers=nothing)
    _setFigureResolution!(info)
    space = _spaceInfo(forcing_helpers)
    if _isSpatial(space)
        foreach(cost_options) do var_row
            println("plot spatial comparison:: $(var_row.variable)")
            vname, vinfo, lossMetric = getCostRowVariableInfo(var_row, info.experiment.basics.temporal_resolution)
            _plotComparisonSpatial(info, obs_array, var_row, def_dat, "model", lossMetric, vinfo, vname, space)
        end
        return nothing
    end
    fig_path = joinpath(info.output.dirs.figure, "time_series_single.png")
    _plotComparisonAllVariables(info, obs_array, cost_options, def_dat, fig_path)
    return nothing
end

# Explicit-argument target of the arity-1 wrapper above:
# def-vs-optimized-vs-observations plotting (the full comparison). Not an independent
# public entry point (see Visualization.jl). A spatial run compares only the
# optimized output with the observations, see `_plotComparisonSpatial`.
function plotTimeSeries(info, obs_array, cost_options, def_dat, opt_dat, ::VisualizationPlots; forcing_helpers=nothing)
    _setFigureResolution!(info)
    space = _spaceInfo(forcing_helpers)
    if _isSpatial(space)
        foreach(cost_options) do var_row
            println("plot spatial comparison:: $(var_row.variable)")
            vname, vinfo, lossMetric = getCostRowVariableInfo(var_row, info.experiment.basics.temporal_resolution)
            _plotComparisonSpatial(info, obs_array, var_row, opt_dat, "opt", lossMetric, vinfo, vname, space)
        end
        return nothing
    end
    fig_path = joinpath(info.output.dirs.figure, "comparison_time_series.png")
    _plotComparisonAllVariables(info, obs_array, cost_options, def_dat, fig_path; opt_dat=opt_dat)
    return nothing
end
