"""
    Visualization

Visualization utilities for SINDBAD experiments. This module focuses on
plotting model outputs, diagnostics, and experiment metadata via `Plots.jl`.

# Purpose
- Provide ready-to-use plotting helpers that understand SINDBAD's
  `info`, outputs, and metric structures.
- Speed up exploratory analysis by wrapping common visual layouts
  (time series, site comparisons, diagnostic summaries).

# Dependencies
## Internal (within `Sindbad`)
- `namedTupleToFlareJSON` and `getAllVariables` (`utilsVisualization.jl`) have no external plotting dependency and are always available.

## Optional (via `SindbadPlotsExt`)
- `plotPerformanceHistograms`, `plotTimeSeries`, and `plotIOModelStructure` dispatch on a `VisualizationTypes` backend value read from `info.helpers.run.visualization_backend` (set from `exe_rules.visualization_backend` in the experiment config, defaulting to `"Types"`). The default `VisualizationTypes` backend logs an info message and returns `nothing`. Setting `visualization_backend = "Plots"` in the config selects the `VisualizationPlots` backend, whose real plotting methods are only added once `Plots.jl` is loaded, at which point Julia's package extension mechanism loads `SindbadPlotsExt` (see root `Project.toml` `[weakdeps]` + `[extensions]`). `using Sindbad` alone is sufficient once `Plots` is also loaded in the session — end users typically should not `using SindbadPlotsExt` directly.
- `plotTimeSeriesWithObs` and `plotTimeSeriesDebug` are deprecated-but-supported aliases of `plotTimeSeries`, kept for backward compatibility with their original signatures.

# Notes
- Additional plot recipes are being added progressively; current focus is
  on covering the default experiment workflow.
- The API is reexported via `Sindbad.Visualization`, so users simply load
  `Sindbad` to access plotting helpers (once `Plots` is loaded for the plotting functions).

# Usage:
```julia
using Sindbad, Plots

plotPerformanceHistograms(opt_results)
plotIOModelStructure(info)
plotCarbonFlows(cCycleBase_CASA)  # writes tmp_carbon_flow_matrix_cCycleBase_CASA_default.pdf
```

`plotCarbonFlows` draws a `cCycleBase` approach's carbon flow topology as a
giver-by-taker matrix, labelled with each flow's turnover time, allocation fraction,
microbial efficiency and quality-partition fraction. Called with just the approach,
it needs no experiment or run and writes
`tmp_carbon_flow_matrix_<approach>_default.pdf` (`_actual.pdf` with a real `land`
given, `tmp_`-prefixed so it's gitignored); a second positional argument names the
file, `nothing` skips the write. Called as `plotCarbonFlows(info, approach)`, it
resolves the backend from `info.helpers.run.visualization_backend` and saves into
`info.output.dirs.figure` instead -- the form `getExperimentInfo` calls
automatically when a `cCycleBase` approach is selected.
"""
module Visualization
    using SindbadTEM.OmniTools
    using ..Types

    export plotPerformanceHistograms
    export plotTimeSeries
    export plotTimeSeriesWithObs
    export plotTimeSeriesDebug
    export plotIOModelStructure
    export plotCarbonFlows

    # Thin convenience wrappers: resolve the configured visualization backend from `info`
    # (or `out`/`out_opti`, which carry `.info`) and forward to the 4-arg method that
    # actually dispatches on the backend type. These wrappers are defined exactly once,
    # here in main src, so they never collide with a same-signature method defined by an
    # extension (Julia forbids overwriting an identical method signature across module
    # precompilation). Only the trailing-backend-typed methods are extended per backend:
    # this file's `::VisualizationTypes` fallback, and e.g. `SindbadPlotsExt`'s `::VisualizationPlots`.
    #
    # `_resolvedBackend` falls back to `VisualizationTypes()` when the configured backend
    # (e.g. `VisualizationPlots()` from `visualization_backend = "Plots"` in the config) has
    # no matching method for this function — i.e. its extension (e.g. `SindbadPlotsExt`)
    # isn't actually loaded — so a mismatch between config and loaded packages degrades
    # gracefully to the info message instead of a `MethodError`.
    function _resolvedBackend(f, backend, args...)
        hasmethod(f, Tuple{map(typeof, args)..., typeof(backend)}) ? backend : VisualizationTypes()
    end

    function plotPerformanceHistograms(out_opti)
        backend = out_opti.info.helpers.run.visualization_backend
        return plotPerformanceHistograms(out_opti, _resolvedBackend(plotPerformanceHistograms, backend, out_opti))
    end

    function plotTimeSeries(out_opti)
        backend = out_opti.info.helpers.run.visualization_backend
        return plotTimeSeries(out_opti, _resolvedBackend(plotTimeSeries, backend, out_opti))
    end

    function plotTimeSeries(out, cost_options)
        backend = out.info.helpers.run.visualization_backend
        return plotTimeSeries(out, cost_options, _resolvedBackend(plotTimeSeries, backend, out, cost_options))
    end

    function plotTimeSeries(info, opt_dat, def_dat)
        backend = info.helpers.run.visualization_backend
        return plotTimeSeries(info, opt_dat, def_dat, _resolvedBackend(plotTimeSeries, backend, info, opt_dat, def_dat))
    end

    # Backward-compatible aliases: old names/signatures forward onto the unified
    # plotTimeSeries dispatch family. plotTimeSeriesWithObs(out_opti) and
    # plotTimeSeriesDebug(info, opt_dat, def_dat) match new entry points exactly, so they
    # inherit backend resolution/fallback for free. The legacy 3-arg
    # plotTimeSeriesWithObs(out, obs_array, cost_options) doesn't match any new entry
    # point's shape (the 2-arg plotTimeSeries derives obs_array from
    # out.observation instead), so it resolves its own backend and forwards to the
    # explicit-argument method directly, preserving the exact old behavior/signature.
    plotTimeSeriesWithObs(out_opti) = plotTimeSeries(out_opti)
    plotTimeSeriesDebug(info, opt_dat, def_dat) = plotTimeSeries(info, opt_dat, def_dat)

    function plotTimeSeriesWithObs(out, obs_array, cost_options)
        backend = out.info.helpers.run.visualization_backend
        return plotTimeSeries(out.info, obs_array, cost_options, out.output, _resolvedBackend(plotTimeSeries, backend, out.info, obs_array, cost_options, out.output))
    end

    # falls back to land.models.c_model when approach is omitted, so a real `land` is
    # enough on its own; errors if neither is given.
    function _approachName(approach, kwargs)
        !isnothing(approach) && return nameof(approach isa Type ? approach : typeof(approach))
        land = get(kwargs, :land, nothing)
        isnothing(land) && error("plotCarbonFlows needs `approach`, or `land` to derive " *
            "it from `land.models.c_model`.")
        return nameof(typeof(land.models.c_model))
    end

    # No `info` to read a backend from, so VisualizationPlots() is asked for directly.
    # `tmp_`-prefixed (unlike the info-taking form below): it lands in the working
    # directory, not an experiment's output dir, and `tmp_*` is gitignored.
    function plotCarbonFlows(approach=nothing; kwargs...)
        suffix = isnothing(get(kwargs, :land, nothing)) ? "default" : "actual"
        file_path = "tmp_carbon_flow_matrix_$(_approachName(approach, kwargs))_$(suffix).pdf"
        return plotCarbonFlows(approach, file_path; kwargs...)
    end

    function plotCarbonFlows(approach, file_path; kwargs...)
        backend = VisualizationPlots()
        return plotCarbonFlows(approach, file_path, _resolvedBackend(plotCarbonFlows, backend, approach, file_path); kwargs...)
    end

    # The experiment's actually resolved carbon pool structure (set by setPoolsInfo from
    # model_structure.pools.carbon), or nothing if info carries none. This is the same
    # structure a real run's land.cCycleBase.pool_names is built from, so passing it as
    # plotCarbonFlows' pool_configuration keeps the synthetic ("default") diagram from
    # disagreeing with a real run's diagram when settings override the pool structure
    # independently of the selected cCycleBase approach (e.g. cCycleBase.approach =
    # "MGMT" with pools.carbon = "GSI").
    function _experimentPoolConfiguration(info)
        hasproperty(info, :pool_structure) || return nothing
        hasproperty(info.pool_structure, :carbon) || return nothing
        return info.pool_structure.carbon
    end

    # Called automatically by getExperimentInfo when a cCycleBase approach is selected;
    # unlike the methods above, reads the configured backend from info and saves into
    # info.output.dirs.figure, named like plotIOModelStructure's own files.
    function plotCarbonFlows(info::NamedTuple, approach=nothing; kwargs...)
        backend = info.helpers.run.visualization_backend
        suffix = isnothing(get(kwargs, :land, nothing)) ? "default" : "actual"
        approach_name = _approachName(approach, kwargs)
        file_path = joinpath(info.output.dirs.figure,
            "carbon_flow_matrix_$(info.experiment.basics.id)_$(approach_name)_$(suffix).pdf")
        # an explicit pool_configuration in kwargs (rare) wins over info's, since it
        # comes later in this merge
        kwargs = (; pool_configuration=_experimentPoolConfiguration(info), kwargs...)
        return plotCarbonFlows(approach, file_path, _resolvedBackend(plotCarbonFlows, backend, approach, file_path); kwargs...)
    end

    plotIOModelStructure(info) = plotIOModelStructure(info, :compute)
    plotIOModelStructure(info, which_function) = plotIOModelStructure(info, which_function, [:input, :output])
    function plotIOModelStructure(info, which_function, which_field)
        backend = info.helpers.run.visualization_backend
        return plotIOModelStructure(info, which_function, which_field, _resolvedBackend(plotIOModelStructure, backend, info, which_function, which_field))
    end

    # Default (no-op) backend: logs an info message instead of plotting. Used whenever
    # `visualization_backend` isn't configured, or a configured backend's extension isn't loaded.
    #
    # `configured_backend` is re-read from `info`/`out`/`out_opti` (not the dispatch arg, which
    # `_resolvedBackend` may have already substituted down to `VisualizationTypes()`), so the
    # message can distinguish "nothing was ever configured" from "a specific backend was
    # configured but its extension isn't loaded".
    function _visualizationFallbackMessage(fn, configured_backend)
        if configured_backend isa VisualizationTypes
            return "No visualization backend configured; skipping `$(nameof(fn))`. Set `visualization_backend` in the experiment config (e.g. `\"Plots\"`) and `using Plots` in your session to enable this plot."
        else
            backend_name = String(nameof(typeof(configured_backend)))
            pkg_name = startswith(backend_name, "Visualization") ? backend_name[(length("Visualization") + 1):end] : backend_name
            return "visualization_backend is set to `$(backend_name)`, but `$(pkg_name)` is not loaded; skipping `$(nameof(fn))`. Run `using $(pkg_name)` in your session to enable this plot."
        end
    end

    function plotPerformanceHistograms(out_opti, ::VisualizationTypes)
        print_info(plotPerformanceHistograms, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotPerformanceHistograms, out_opti.info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotTimeSeries(out_opti, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, out_opti.info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotTimeSeries(out, cost_options, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, out.info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotTimeSeries(info, opt_dat, def_dat, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    # Needed so the legacy 3-arg plotTimeSeriesWithObs(out, obs_array, cost_options)
    # alias (which forwards straight to this arity, bypassing the arity-2 wrapper above)
    # still degrades gracefully when no Plots backend is loaded.
    function plotTimeSeries(info, obs_array, cost_options, def_dat, ::VisualizationTypes)
        print_info(plotTimeSeries, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotTimeSeries, info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    function plotCarbonFlows(approach, file_path, ::VisualizationTypes; kwargs...)
        print_info(plotCarbonFlows, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotCarbonFlows, VisualizationPlots()), n_f=4)
        return nothing
    end

    function plotIOModelStructure(info, which_function, which_field, ::VisualizationTypes)
        print_info(plotIOModelStructure, @__FILE__, @__LINE__, _visualizationFallbackMessage(plotIOModelStructure, info.helpers.run.visualization_backend), n_f=4)
        return nothing
    end

    include("utilsVisualization.jl")

end # module Visualization
