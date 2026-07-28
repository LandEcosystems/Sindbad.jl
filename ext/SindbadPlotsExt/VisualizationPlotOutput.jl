# Bring the target functions into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.Visualization: plotPerformanceHistograms, plotTimeSeries

# ------------------------------------------------------------------
# performance histograms
# ------------------------------------------------------------------

"""
    plotPerformanceHistograms(out_opti)

Generate performance histograms based on optimization output data.

# Arguments
- `out_opti`: ParameterOptimization output data structure containing model outputs and information

# Description
Creates histogram plots to visualize the distribution of  performance metrics from optimization results.

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
    costOpt = out_opti.cost_options
    run_helpers = out_opti.run_helpers
    plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))

    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "comparison_histograms_" * info.experiment.basics.name * "_" * domain)
    losses = map(costOpt) do var_row
        v = var_row.variable
        v_key = v
        println("plot performance comparison:: $v")
        v = (var_row.mod_field, var_row.mod_subfield)
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        lossMetric = var_row.cost_metric
        loss_name = nameof(typeof(lossMetric))
        if loss_name in (:NNSEInv, :NSEInv)
            lossMetric = NSE()
        end
        (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row);
        (_, _, opt_var) = getData(opt_dat, obs_array, var_row);

        (obs_var_no_nan, obs_σ_no_nan, def_var_no_nan) = getDataWithoutNaN(obs_var, obs_σ, def_var);
        (obs_var_no_nan, obs_σ_no_nan, opt_var_no_nan) = getDataWithoutNaN(obs_var, obs_σ, opt_var);

        loss_space = map([run_helpers.space_ind...]) do lsi
            opt_pix = view_at_trailing_indices(opt_var, lsi)
            def_pix = view_at_trailing_indices(def_var, lsi)
            obs_pix = view_at_trailing_indices(obs_var, lsi)
            obs_σ_pix = view_at_trailing_indices(obs_σ, lsi)
            (obs_pix_no_nan, obs_σ_pix_no_nan, opt_pix_no_nan) = getDataWithoutNaN(obs_pix, obs_σ_pix, opt_pix)
            (_, _, def_pix_no_nan) = getDataWithoutNaN(obs_pix, obs_σ_pix, def_pix)
            [metric(lossMetric, def_pix_no_nan, obs_pix_no_nan, obs_σ_pix_no_nan), metric(lossMetric, opt_pix_no_nan, obs_pix_no_nan, obs_σ_pix_no_nan)]
        end


        b_range = range(-1, 1, length=50)
        p_title = "$(var_row.variable) ($(nameof(typeof(lossMetric))))"
        plots_histogram(first.(loss_space); title=p_title, size=(2000, 1000),bins=b_range, alpha=0.9, label="default", color="#FDB311")
        plots_vline!([metric(lossMetric, def_var_no_nan, obs_var_no_nan, obs_σ_no_nan)], label="default_spatial", color="#FDB311", lw=3)
        plots_histogram!(last.(loss_space); size=(2000, 1000), bins=b_range, alpha=0.5, label="optimized", color="#18A15C")
        plots_vline!([metric(lossMetric, opt_var_no_nan, obs_var_no_nan, obs_σ_no_nan)], label="optimized_spatial", color="#18A15C", lw=3)
        plots_xlabel!("")
        plots_savefig(fig_prefix * "_$(v).png")
    end
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

# Core of the "output vs. observations" time series plot for one variable: trims to
# the non-NaN observation span, computes the default (and, if `opt_dat` is given, the
# optimized) series' performance metric, and draws obs (scatter) + def (+opt) lines.
# `opt_dat === nothing` selects the single-series (no comparison) rendering; this is a
# plain internal control-flow branch in one private helper, not a public dispatch
# method, so it doesn't conflict with using argument *count* for the public API.
function _plotOutputVsObsForVariable!(info, obs_array, var_row, def_dat, lossMetric, domain, vinfo, vname, fig_prefix; opt_dat=nothing)
    valids = var_row.valids
    (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row)
    # `dims=` reductions keep the reduced dimension as a singleton instead of dropping
    # it (e.g. (T,1,1) stays 3D), so `vec` flattens down to a plain 1D vector - without
    # it, `findall` below returns `CartesianIndex`es, `tspan` becomes a `CartesianIndices`
    # range instead of a `UnitRange`, and every `[tspan]` index downstream silently stays
    # 3D instead of collapsing to a vector (breaking the `plot(...)` calls).
    obs_var_TMP = vec(nanmean(obs_var, dims=2))

    non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
    if length(non_nan_index) < 2
        tspan = 1:length(obs_var_TMP)
    else
        tspan = first(non_nan_index):last(non_nan_index)
    end
    obs_var = obs_var_TMP[tspan]
    obs_σ = obs_σ[tspan]

    def_var_TMP = vec(mean(def_var, dims=3))
    def_var = def_var_TMP[tspan]
    valids = valids[tspan]

    xdata = [info.helpers.dates.range[tspan]...]

    metr_def = metric(lossMetric, def_var[valids], obs_var[valids], obs_σ[valids])
    has_opt = !isnothing(opt_dat)
    legend_columns = has_opt ? 3 : 2

    plots_plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1plots_cm)
    plots_plot!(xdata, def_var, lw=1.5, ls=:dash, left_margin=1plots_cm, legend=:outerbottom, legendcolumns=legend_columns, label="def ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(domain): $(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric)))", color=:steelblue2)

    if has_opt
        (_, _, opt_var) = getData(opt_dat, obs_array, var_row)
        opt_var_TMP = vec(mean(opt_var, dims=3))
        opt_var = opt_var_TMP[tspan]
        metr_opt = metric(lossMetric, opt_var[valids], obs_var[valids], obs_σ[valids])
        plots_plot!(xdata, opt_var; color=:seagreen3, label="opt ($(round(metr_opt, digits=2)))", lw=1.5, ls=:dash)
    end

    plots_savefig(fig_prefix * "_$(vname).png")
    return nothing
end

# Draws and saves one def-vs-opt line plot for a single debug variable/layer. Shared by
# plotTimeSeries(info, opt_dat, def_dat)'s single-layer and multi-layer branches.
function _plotDebugVariableLayer!(xdata, def_col, opt_col, title_str, ylabel_str, fig_path)
    plots_plot(xdata, def_col; label="def ($(round(mean(def_col), digits=2)))", size=(2000, 1000), title=title_str, left_margin=1plots_cm, color=:steelblue2)
    plots_plot!(xdata, opt_col, color=:seagreen3; label="opt ($(round(mean(opt_col), digits=2)))")
    plots_ylabel!(ylabel_str, font=(20, :green))
    plots_savefig(fig_path)
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
Generates time series plots that compare the optimized and default model outputs with observations. The function iterates over each variable specified in the cost options and creates a separate plot for each one. Each plot displays the observed data as scatter points, along with the default and optimized model outputs as line graphs. Additionally, it includes vertical lines indicating the calculated loss metric values for both the default and optimized models.

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
    return plotTimeSeries(info, obs_array, cost_options, def_dat, opt_dat, VisualizationPlots())
end

"""
    plotTimeSeries(out, cost_options)

Generate time series plots comparing a single model output against observations (no def-vs-optimized comparison).

# Arguments
- `out`: an experiment output structure carrying `.info`, `.observation`, and `.output`
- `cost_options`: cost-option rows (one per variable) used to select and evaluate each series

# Description
Generates time series plots for each variable in `cost_options`, showing the observed data as scatter points alongside a single model-output line, with the calculated loss metric value in the legend.
"""
function plotTimeSeries(out, cost_options, ::VisualizationPlots)
    info = out.info
    obs_array = out.observation
    def_dat = out.output
    return plotTimeSeries(info, obs_array, cost_options, def_dat, VisualizationPlots())
end

"""
    plotTimeSeries(info, opt_dat, def_dat)

Plot debugging figures for model outputs.

# Arguments
- `info`: Information structure containing experiment details
- `opt_dat`: Optimized model output data
- `def_dat`: Default model output data

# Description
This function generates debugging figures by plotting the optimized and default model outputs for each variable specified in the experiment's output variables list. It calculates the mean of the model outputs across layers and then plots them against time using Plots.jl. Debugging figures are saved in a directory specified by `info.output.dirs.figure`.
"""
function plotTimeSeries(info, opt_dat, def_dat, ::VisualizationPlots)
    output_array_opt = values(opt_dat)
    output_array_def = values(def_dat)
    output_vars = info.output.variables

    plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "debug_" * info.experiment.basics.name * "_" * domain)
    for (o, v) in enumerate(output_vars)
        def_var = mean(output_array_def[o], dims=3)[:, :, 1]
        opt_var = mean(output_array_opt[o], dims=3)[:, :, 1]
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        vname = vinfo["standard_name"]
        println("plot debug::", vname)
        xdata = [info.helpers.dates.range...]
        if size(opt_var, 2) == 1
            _plotDebugVariableLayer!(xdata, def_var[:, 1], opt_var[:, 1], "$(vinfo["long_name"]) ($(vinfo["units"]))", vinfo["standard_name"], fig_prefix * "_$(vname).png")
        else
            foreach(axes(opt_var, 2)) do ll
                _plotDebugVariableLayer!(xdata, def_var[:, ll], opt_var[:, ll], "$(domain): $(vinfo["long_name"]), layer $(ll),  ($(vinfo["units"]))", vinfo["standard_name"], fig_prefix * "_$(vname)_$(ll).png")
            end
        end
    end
    return nothing
end

# Explicit-argument target of the arity-2 wrapper above: single-series-vs-observations
# plotting (no optimized comparison). Not an independent public entry point (see
# Visualization.jl for why it doesn't get its own `::VisualizationTypes` fallback there,
# except where needed to back the legacy `plotTimeSeriesWithObs(out, obs_array, cost_options)` alias).
function plotTimeSeries(info, obs_array, cost_options, def_dat, ::VisualizationPlots)
    plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "time_series_single_" * info.experiment.basics.name * "_" * domain)
    foreach(cost_options) do var_row
        println("plot time series comparison:: $(var_row.variable)")
        vname, vinfo, lossMetric = getCostRowVariableInfo(var_row, info.experiment.basics.temporal_resolution)
        _plotOutputVsObsForVariable!(info, obs_array, var_row, def_dat, lossMetric, domain, vinfo, vname, fig_prefix)
    end
    return nothing
end

# Explicit-argument target of the arity-1 wrapper above: def-vs-optimized-vs-observations
# plotting (the full comparison). Not an independent public entry point (see Visualization.jl).
function plotTimeSeries(info, obs_array, cost_options, def_dat, opt_dat, ::VisualizationPlots)
    plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
    domain = info.experiment.basics.domain
    fig_prefix = joinpath(info.output.dirs.figure, "comparison_time_series_" * info.experiment.basics.name * "_" * domain)
    foreach(cost_options) do var_row
        println("plot time series comparison:: $(var_row.variable)")
        vname, vinfo, lossMetric = getCostRowVariableInfo(var_row, info.experiment.basics.temporal_resolution)
        _plotOutputVsObsForVariable!(info, obs_array, var_row, def_dat, lossMetric, domain, vinfo, vname, fig_prefix; opt_dat=opt_dat)
    end
    return nothing
end
