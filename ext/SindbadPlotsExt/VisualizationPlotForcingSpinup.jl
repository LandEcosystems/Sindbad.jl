import Sindbad.Visualization: plotForcing, plotSpinup
using Dates: year

# ------------------------------------------------------------------
# forcing
# ------------------------------------------------------------------

# a field of the settings NamedTuple, or nothing when it is missing
_getSetting(settings, key) = get(settings, Symbol(key), nothing)

"""
    plotForcing(info, forcing, ::VisualizationPlots)

Saves figures of every forcing variable.

# Arguments
- `info`: Information structure containing experiment details
- `forcing`: the forcing NamedTuple with the `variables` and their `data`

# Notes
- For one location, the figure is `forcing_<variable>.png` in
  `info.output.dirs.figure`. Every dimension after time, e.g. layers, gives one line,
  the x axis has the dates of the time coordinates of the forcing, see `_timeAxis`,
  and the cycles of the time series are drawn next to it, see
  `_plotTimeSeriesWithCycles`.
- For a spatial run, the figures are listed in `_plotForcingSpatial`.
- The name and units are the `standard_name` and `sindbad_unit` of the variable in
  the forcing settings.
"""
function plotForcing(info, forcing, ::VisualizationPlots)
    _setFigureResolution!(info)
    space = _spaceInfo(forcing.helpers)
    _isSpatial(space) && return _plotForcingSpatial(info, forcing, space)
    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "forcing")
    forcing_settings = _getSetting(info.experiment.data_settings.forcing, :variables)
    for (f_i, (v, f_data)) in enumerate(zip(forcing.variables, forcing.data))
        println("plot forcing::", v)
        f_arr = Array(f_data)
        ndims(f_arr) == 0 && continue
        v_settings = _getSetting(forcing_settings, v)
        v_name = something(_getSetting(v_settings, :standard_name), string(v))
        v_units = something(_getSetting(v_settings, :sindbad_unit), "-")
        has_time = last(forcing.f_types[f_i]) isa ForcingWithTime
        _plotForcingLines(info, forcing.helpers, f_arr, has_time, "$(domain): $(v_name) [$(v_units)]", "$(v) [$(v_units)]", fig_prefix * "_$(v).png")
    end
    return nothing
end

# ------------------------------------------------------------------
# stored spinup
# ------------------------------------------------------------------

"""
    plotSpinup(info, spinup, ::VisualizationPlots; loc_index=1, output=nothing)

Plots `cEco` and `TWS` at every stored step of the spinup of one location, with one
panel per layer, and saves one figure per pool.

# Arguments
- `info`: Information structure containing experiment details
- `spinup`: the stored spinup from `prepSpinupOut`, e.g. `out.spinup` of
  `runExperimentForward`, or `prepSpinupOut(info, run_helpers)` after `runTEM!`
- `loc_index`: the index of the location in `spinup.sequences`
- `output`: the output of the forward run that followed the spinup, or `nothing`.
  When it has `pools.cEco` or `pools.TWS`, their time series is appended after the
  spinup in another colour, with a red dashed line at the end of the spinup.

# Notes
- The spinup is only stored with `store_spinup` set to true. Without it, `spinup` is
  `nothing` and nothing is plotted.
- The figures are `spinup_<pool>.png` in
  `info.output.dirs.figure`, with `_loc<loc_index>` after the pool when there is
  more than one location.
- The x axis is in years since the start of the spinup. A `LoopTEM` step moves one
  time step of the run, and the other spinup modes change the pools without moving in
  time. Red dashed lines mark the end of each step of the spinup sequence. The number
  of each step is written in red at the top of its period, and the steps are listed
  in the title.
"""
function plotSpinup(info, spinup, ::VisualizationPlots; loc_index=1, output=nothing)
    _setFigureResolution!(info)
    if isnothing(spinup)
        print_info(plotSpinup, @__FILE__, @__LINE__, "no stored spinup to plot. Set `store_spinup` to true in the flags of the experiment.", n_f=4)
        return nothing
    end
    domain = info.experiment.basics.domain
    is_multi_loc = length(spinup.sequences) > 1
    loc_name = is_multi_loc ? "$(domain) loc $(loc_index)" : domain
    fig_dir = info.output.dirs.figure
    loc_tag = is_multi_loc ? "_loc$(loc_index)" : ""
    loc_ind = spinup.space_ind[loc_index]
    sequence = spinup.sequences[loc_index]

    step_data = spinup.data[findfirst(==(:spinup_sequence_step), spinup.names)]
    loc_steps = collect(view_at_trailing_indices(step_data, loc_ind))
    n_rows = count(>=(0), loc_steps)
    loc_steps = loc_steps[1:n_rows]
    row_years, seq_bounds, seq_labels, seq_ids = _spinupYears(info, sequence, loc_steps)
    dates_run = info.helpers.dates.range
    forward_label = "forward $(year(first(dates_run)))-$(year(last(dates_run)))"

    for (pool_name, pool_data) in zip(spinup.names, spinup.data)
        pool_name == :spinup_sequence_step && continue
        loc_data = view_at_trailing_indices(pool_data, loc_ind)
        loc_data = reshape(collect(loc_data), size(loc_data, 1), :)[1:n_rows, :]
        n_layers = size(loc_data, 2)
        fwd_data = _forwardPoolData(info, output, pool_name, loc_ind, n_layers)
        has_forward = !isnothing(fwd_data)
        fwd_years = has_forward ? last(row_years) .+ (1:size(fwd_data, 1)) ./ _stepsPerYear(info) : Float64[]
        year_ticks = _spinupYearTicks(has_forward ? last(fwd_years) : last(row_years))
        # the end of the last spinup step is only marked when the forward run follows
        # it
        bound_years = has_forward ? seq_bounds : seq_bounds[1:end-1]
        # every period is labelled with its step number in the middle of its span
        period_starts = [0.0; seq_bounds[1:end-1]]
        period_mids = (period_starts .+ seq_bounds) ./ 2
        period_names = string.(seq_ids)
        if has_forward
            push!(period_mids, (last(row_years) + last(fwd_years)) / 2)
            push!(period_names, "fwd")
        end
        title_steps = has_forward ? [seq_labels; forward_label] : seq_labels
        title_pools = has_forward ? "spinup and forward run" : "spinup"
        layer_names = _spinupLayerNames(info, pool_name, n_layers)
        pool_units = getVariableInfo((:pools, pool_name), info.experiment.basics.temporal_resolution)["units"]
        n_cols = min(n_layers, 4)
        n_rows_fig = cld(n_layers, n_cols)
        fig_height = 280 * n_rows_fig + 110
        panels = map(1:n_layers) do l
            p = plots_plot(row_years, loc_data[:, l]; _figStyle()..., title=layer_names[l], legend=false, color=_model_color, lw=1.0, xticks=year_ticks, xlabel=l > n_layers - n_cols ? "year since spinup start" : "", ylabel=mod1(l, n_cols) == 1 ? "$(pool_name) [$(pool_units)]" : "", titlefontsize=10, tickfontsize=7, guidefontsize=8, grid=:x)
            has_forward && plots_plot!(p, fwd_years, fwd_data[:, l]; color=_forward_color, lw=1.0)
            plots_vline!(p, bound_years; color=:red, linestyle=:dash, lw=0.8)
            _labelSpinupPeriods!(p, period_mids, period_names, has_forward ? vcat(loc_data[:, l], fwd_data[:, l]) : loc_data[:, l])
            p
        end
        fig = plots_plot(panels...; layout=(n_rows_fig, n_cols), size=(430 * n_cols, fig_height), plot_title="$(loc_name): $(title_pools) $(pool_name) [$(pool_units)]\n" * join(title_steps, "  |  "), plot_titlefontsize=10, plot_titlevspan=110 / fig_height, dpi=_fig_dpi[], left_margin=12plots_mm, bottom_margin=8plots_mm, right_margin=3plots_mm)
        plots_savefig(fig, joinpath(fig_dir, "spinup_$(pool_name)$(loc_tag).png"))
    end
    return nothing
end

# the number of time steps of the run in one year
_stepsPerYear(info) = (dates_run = info.helpers.dates.range; length(dates_run) / length(unique(year.(dates_run))))

# The time series of a pool of the forward run at one location as (time, layer), or
# nothing when the output does not have the pool with the same layers as the spinup.
function _forwardPoolData(info, output, pool_name, loc_ind, n_layers)
    isnothing(output) && return nothing
    o = findfirst(vp -> Symbol(first(vp)) == :pools && Symbol(last(vp)) == pool_name, collect(info.output.variables))
    isnothing(o) && return nothing
    loc_data = view_at_trailing_indices(values(output)[o], loc_ind)
    loc_data = reshape(collect(loc_data), size(loc_data, 1), :)
    return size(loc_data, 2) == n_layers ? loc_data : nothing
end

# The years since the start of the spinup at every stored row, and for every step of
# the sequence with stored rows, the year at its end, its label and its index.
function _spinupYears(info, sequence, loc_steps)
    steps_per_year = _stepsPerYear(info)
    row_years = zeros(length(loc_steps))
    for r in 2:length(loc_steps)
        dy = sequence[loc_steps[r]].spinup_mode isa LoopTEM ? 1 / steps_per_year : 0.0
        row_years[r] = row_years[r-1] + dy
    end
    seq_bounds = Float64[]
    seq_labels = String[]
    seq_ids = Int[]
    for (k, seq) in enumerate(sequence)
        last_row = findlast(==(k), loc_steps)
        isnothing(last_row) && continue
        push!(seq_bounds, row_years[last_row])
        push!(seq_ids, k)
        mode_name = nameof(typeof(seq.spinup_mode))
        push!(seq_labels, seq.spinup_mode isa LoopTEM ? "$(k): $(mode_name) $(seq.forcing) x$(seq.n_repeat)" : "$(k): $(mode_name)")
    end
    return row_years, seq_bounds, seq_labels, seq_ids
end

# Writes the name of every period above the lines of a panel, and makes room for it
# at the top of the y axis.
function _labelSpinupPeriods!(p, period_mids, period_names, panel_values)
    finite = filter(isfinite, panel_values)
    isempty(finite) && return nothing
    y_low, y_high = extrema(finite)
    y_span = y_high > y_low ? y_high - y_low : max(abs(y_high), 1.0) * 0.1
    plots_ylims!(p, (y_low - 0.05 * y_span, y_high + 0.2 * y_span))
    y_label = y_high + 0.11 * y_span
    plots_annotate!(p, [(x, y_label, plots_text(name, 7, :red)) for (x, name) in zip(period_mids, period_names)])
    return nothing
end

# A round tick interval that gives close to n_ticks ticks for any spinup length.
function _spinupYearTicks(total_years; n_ticks=13)
    tick_steps = [1, 2, 5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 150, 200, 250, 500, 1000]
    tick_step = tick_steps[argmin(abs.(total_years ./ tick_steps .- n_ticks))]
    return 0:tick_step:total_years
end

# A component can have several layers, e.g. soilW in TWS, so the names come from the
# layer indices of each component in its main pool.
function _spinupLayerNames(info, pool_name, n_layers)
    layer_names = ["layer $(l)" for l in 1:n_layers]
    pool_helpers = info.helpers.pools
    hasproperty(pool_helpers.components, pool_name) || return layer_names
    for comp in unique(getproperty(pool_helpers.components, pool_name))
        comp_zix = getproperty(pool_helpers.zix, comp)
        for (k, ix) in enumerate(comp_zix)
            ix <= n_layers && (layer_names[ix] = length(comp_zix) > 1 ? "$(comp) $(k)" : "$(comp)")
        end
    end
    return layer_names
end
