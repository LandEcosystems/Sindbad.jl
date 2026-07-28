# Bring the target functions into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.Visualization: plotPerformanceHistograms, plotTimeSeriesWithObs, plotTimeSeriesDebug

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

"""
    plotTimeSeriesWithObs(out_opti, ::VisualizationPlots)
Generate time series plots comparing optimized and default model outputs with observations.
# Arguments
- `out_opti`: ParameterOptimization output data structure containing model outputs and information
- `::VisualizationPlots`: Placeholder for the visualization backend type
# Description
Generates time series plots that compare the optimized and default model outputs with observations. The function iterates over each variable specified in the cost options and creates a separate plot for each one. Each plot displays the observed data as scatter points, along with the default and optimized model outputs as line graphs. Additionally, it includes vertical lines indicating the calculated loss metric values for both the default and optimized models.

# Examples
```jldoctest
julia> using Sindbad

julia> # Plot time series with observations
julia> # plotTimeSeriesWithObs(out_opti)
```
"""
function plotTimeSeriesWithObs(out_opti, ::VisualizationPlots)
    opt_dat = out_opti.output.optimized
    def_dat = out_opti.output.default
    obs_array = out_opti.observation
    info = out_opti.info
    costOpt = out_opti.cost_options
    plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))

    domain = info.experiment.basics.domain

    fig_prefix = joinpath(info.output.dirs.figure, "comparison_time_series_" * info.experiment.basics.name * "_" * domain)
    foreach(costOpt) do var_row
        v = var_row.variable
        println("plot time series comparison:: $v")
        v = (var_row.mod_field, var_row.mod_subfield)
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        lossMetric = var_row.cost_metric
        loss_name = nameof(typeof(lossMetric))
        if loss_name in (:NNSEInv, :NSEInv)
            lossMetric = NSE()
        end
        valids = var_row.valids
        (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row)
        (_, _, opt_var) = getData(opt_dat, obs_array, var_row)
        obs_var_TMP = nanmean(obs_var, dims=2)

        # obs_var_TMP = obs_var[:, 1, 1]
        non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
        if length(non_nan_index) < 2
            tspan = 1:length(obs_var_TMP)
        else
            tspan = first(non_nan_index):last(non_nan_index)
        end
        obs_var = obs_var_TMP[tspan]
        obs_σ = obs_σ[tspan]
        # obs_var = obs_var[tspan]

        def_var_TMP = mean(def_var, dims=3)
        opt_var_TMP = mean(opt_var, dims=3)
        def_var = def_var_TMP[tspan]
        opt_var = opt_var_TMP[tspan]
        valids = valids[tspan]

        xdata = [info.helpers.dates.range[tspan]...]

        metr_def = metric(lossMetric, def_var[valids], obs_var[valids], obs_σ[valids])
        metr_opt = metric(lossMetric, opt_var[valids], obs_var[valids], obs_σ[valids])

        plots_plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1plots_cm)
        plots_plot!(xdata, def_var, lw=1.5, ls=:dash, left_margin=1plots_cm, legend=:outerbottom, legendcolumns=3, label="def ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(domain): $(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric)))", color=:steelblue2)
        plots_plot!(xdata, opt_var; color=:seagreen3, label="opt ($(round(metr_opt, digits=2)))", lw=1.5, ls=:dash)
        plots_savefig(fig_prefix * "_$(v).png")
    end

    return nothing
end

"""
    plotTimeSeriesDebug(info, opt_dat, def_dat, ::VisualizationPlots)
Plot debugging figures for model outputs.
# Arguments
- `info`: Information structure containing experiment details
- `opt_dat`: Optimized model output data
- `def_dat`: Default model output data
- `::VisualizationPlots`: Placeholder for the visualization backend type
# Description
This function generates debugging figures by plotting the optimized and default model outputs for each variable specified in the experiment's output variables list. It calculates the mean of the model outputs across layers and then plots them against time using Plots.jl. Debugging figures are saved in a directory specified by `info.output.dirs.figure`.
"""
function plotTimeSeriesDebug(info, opt_dat, def_dat, ::VisualizationPlots)

    # plot debug figures
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
        v = vinfo["standard_name"]
        println("plot debug::", v)
        xdata = [info.helpers.dates.range...]
        if size(opt_var, 2) == 1
            plots_plot(xdata, def_var[:, 1]; label="def ($(round(mean(def_var[:, 1]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"]))", left_margin=1plots_cm, color=:steelblue2)
            plots_plot!(xdata, opt_var[:, 1], color=:seagreen3; label="opt ($(round(mean(opt_var[:, 1]), digits=2)))")
            plots_ylabel!("$(vinfo["standard_name"])", font=(20, :green))
            plots_savefig(fig_prefix * "_$(v).png")
        else
            foreach(axes(opt_var, 2)) do ll
                plots_plot(xdata, def_var[:, ll]; label="def ($(round(mean(def_var[:, ll]), digits=2)))", size=(2000, 1000), title="$(domain): $(vinfo["long_name"]), layer $(ll),  ($(vinfo["units"]))", left_margin=1plots_cm, color=:steelblue2)
                plots_plot!(xdata, opt_var[:, ll]; color=:seagreen3, label="opt ($(round(mean(opt_var[:, ll]), digits=2)))")
                plots_ylabel!("$(vinfo["standard_name"])", font=(20, :green))
                plots_savefig(fig_prefix * "_$(v)_$(ll).png")
            end
        end
    end
    return nothing
end


"""
    plotTimeSeriesWithObs(out,obs_array,cost_options,info)
Generate time series plots comparing optimized and default model outputs with observations.
# Arguments
- `out_opti`: ParameterOptimization output data structure containing model outputs and information
# Description
Generates time series plots that compare the optimized and default model outputs with observations. The function iterates over each variable specified in the cost options and creates a separate plot for each one. Each plot displays the observed data as scatter points, along with the default and optimized model outputs as line graphs. Additionally, it includes vertical lines indicating the calculated loss metric values for both the default and optimized models.
"""
function plotTimeSeriesWithObs(out,obs_array,cost_options, ::VisualizationPlots)
    costOpt = cost_options
    info    = out.info
    domain  = info.experiment.basics.domain
    plots_default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))


    fig_prefix = joinpath(info.output.dirs.figure, "comparison_time_series_1_" * info.experiment.basics.name * "_" * domain)
    foreach(costOpt) do var_row
        v = var_row.variable
        println("plot time series comparison:: $v")
        v = (var_row.mod_field, var_row.mod_subfield)
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        lossMetric = var_row.cost_metric
        loss_name = nameof(typeof(lossMetric))
        if loss_name in (:NNSEInv, :NSEInv)
            lossMetric = NSE()
        end
        valids = var_row.valids
        (obs_var, obs_σ, def_var) = getData(out.output, obs_array, var_row)
        obs_var_TMP = nanmean(obs_var, dims=2)

        # obs_var_TMP = obs_var[:, 1, 1]
        non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
        if length(non_nan_index) < 2
            tspan = 1:length(obs_var_TMP)
        else
            tspan = first(non_nan_index):last(non_nan_index)
        end
        obs_var = obs_var_TMP[tspan]
        obs_σ = obs_σ[tspan]
        # obs_var = obs_var[tspan]

        def_var_TMP = mean(def_var, dims=3)
        def_var = def_var_TMP[tspan]
        valids = valids[tspan]

        xdata = [info.helpers.dates.range[tspan]...]

        metr_def = metric(lossMetric, def_var[valids], obs_var[valids], obs_σ[valids])

        plots_plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1plots_cm)
        plots_plot!(xdata, def_var, lw=1.5, ls=:dash, left_margin=1plots_cm, legend=:outerbottom, legendcolumns=2, label="def ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(domain): $(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric)))", color=:steelblue2)
        plots_savefig(fig_prefix * "_$(v).png")
    end

    return nothing
end
