import Sindbad.Visualization: plotForcing, plotSpinup
using Dates: year

# ------------------------------------------------------------------
# forcing
# ------------------------------------------------------------------

# the settings can be a Dict or a NamedTuple, and a field can be missing
function _getSetting(settings, key)
    isnothing(settings) && return nothing
    settings isa AbstractDict && return get(settings, string(key), get(settings, Symbol(key), nothing))
    return hasproperty(settings, Symbol(key)) ? getproperty(settings, Symbol(key)) : nothing
end

"""
    plotForcing(info, forcing, ::VisualizationPlots)

Plots every forcing variable as a time series and saves one figure per variable.

# Arguments
- `info`: Information structure containing experiment details
- `forcing`: the forcing NamedTuple with the `variables` and their `data`

# Notes
- The figures are `forcing_<experiment>_<domain>_<variable>.png` in
  `info.output.dirs.figure`.
- For one location, every dimension after time, e.g. layers, gives one line. The x
  axis has the dates of the time coordinates of the forcing, see `_timeAxis`.
- For a spatial run, the figures are `forcing_mean_*` and `forcing_timeseries_*`, see
  `_plotForcingSpatial`.
- The name and units are the `standard_name` and `sindbad_unit` of the variable in
  the forcing settings.
"""
function plotForcing(info, forcing, ::VisualizationPlots)
    space = _spaceInfo(forcing.helpers)
    _isSpatial(space) && return _plotForcingSpatial(info, forcing, space)
    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "forcing_" * info.experiment.basics.name * "_" * domain)
    forcing_settings = _getSetting(info.experiment.data_settings.forcing, :variables)
    for (f_i, (v, f_data)) in enumerate(zip(forcing.variables, forcing.data))
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
    plotSpinup(info, spinup, ::VisualizationPlots; loc_index=1)

Plots `cEco` and `TWS` at every stored step of the spinup of one location, with one
panel per layer, and saves one figure per pool.

# Arguments
- `info`: Information structure containing experiment details
- `spinup`: the stored spinup from `prepSpinupOut`, e.g. `out.spinup` of
  `runExperimentForward`, or `prepSpinupOut(info, run_helpers)` after `runTEM!`
- `loc_index`: the index of the location in `spinup.sequences`
- `output`: the output of the forward run that followed the spinup, or `nothing`. When
  it has `pools.cEco` or `pools.TWS`, their time series is appended after the spinup
  in another colour, with a red dashed line at the end of the spinup.

# Notes
- The spinup is only stored with `store_spinup` set to true. Without it, `spinup` is
  `nothing` and nothing is plotted.
- The figures are `spinup_<experiment>_<domain>_<pool>.png` in `info.output.dirs.figure`,
  with `_loc<loc_index>` after the domain when there is more than one location.
- The x axis is in years of spinup. A `LoopTEM` step moves one time step of the run,
  and the other spinup modes change the pools without moving in time. Red dashed lines
  mark the end of each step of the spinup sequence, which are listed in the title.
"""
function plotSpinup(info, spinup, ::VisualizationPlots; loc_index=1, output=nothing)
    if isnothing(spinup)
        print_info(plotSpinup, @__FILE__, @__LINE__, "no stored spinup to plot. Set `store_spinup` to true in the flags of the experiment.", n_f=4)
        return nothing
    end
    domain = info.experiment.basics.domain
    is_multi_loc = length(spinup.sequences) > 1
    loc_name = is_multi_loc ? "$(domain) loc $(loc_index)" : domain
    fig_prefix = joinpath(info.output.dirs.figure, "spinup_" * info.experiment.basics.name * "_" * domain * (is_multi_loc ? "_loc$(loc_index)" : ""))
    loc_ind = spinup.space_ind[loc_index]
    sequence = spinup.sequences[loc_index]

    step_data = spinup.data[findfirst(==(:spinup_sequence_step), spinup.names)]
    loc_steps = collect(view_at_trailing_indices(step_data, loc_ind))
    n_rows = count(>=(0), loc_steps)
    loc_steps = loc_steps[1:n_rows]
    row_years, seq_bounds, seq_labels = _spinupYears(info, sequence, loc_steps)
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
        # the end of the last spinup step is only marked when the forward run follows it
        bound_years = has_forward ? seq_bounds : seq_bounds[1:end-1]
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
            p
        end
        fig = plots_plot(panels...; layout=(n_rows_fig, n_cols), size=(430 * n_cols, fig_height), plot_title="$(loc_name): $(title_pools) $(pool_name) [$(pool_units)]\n" * join(title_steps, "  |  "), plot_titlefontsize=10, plot_titlevspan=110 / fig_height, dpi=300, left_margin=12plots_mm, bottom_margin=8plots_mm, right_margin=3plots_mm)
        plots_savefig(fig, fig_prefix * "_$(pool_name).png")
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

# The years of spinup at every stored row, the year at the end of each step of the
# sequence, and a label for each step.
function _spinupYears(info, sequence, loc_steps)
    steps_per_year = _stepsPerYear(info)
    row_years = zeros(length(loc_steps))
    for r in 2:length(loc_steps)
        dy = sequence[loc_steps[r]].spinup_mode isa LoopTEM ? 1 / steps_per_year : 0.0
        row_years[r] = row_years[r-1] + dy
    end
    seq_bounds = Float64[]
    seq_labels = String[]
    for (k, seq) in enumerate(sequence)
        last_row = findlast(==(k), loc_steps)
        isnothing(last_row) && continue
        push!(seq_bounds, row_years[last_row])
        mode_name = nameof(typeof(seq.spinup_mode))
        push!(seq_labels, seq.spinup_mode isa LoopTEM ? "$(k): $(mode_name) $(seq.forcing) x$(seq.n_repeat)" : "$(k): $(mode_name)")
    end
    return row_years, seq_bounds, seq_labels
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
