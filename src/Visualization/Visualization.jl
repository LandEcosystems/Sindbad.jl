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
- `namedTupleToFlareJSON` and `getAllVariables` (`plotFromSindbadInfo.jl`) have no external plotting dependency and are always available.

## Optional (via `SindbadPlotsExt`)
- `plotPerformanceHistograms`, `plotTimeSeriesWithObs`, `plotTimeSeriesDebug`, and `plotIOModelStructure` dispatch on a `VisualizationTypes` backend value read from `info.helpers.run.visualization_backend` (set from `exe_rules.visualization_backend` in the experiment config, defaulting to `"Types"`). The default `VisualizationTypes` backend logs an info message and returns `nothing`. Setting `visualization_backend = "Plots"` in the config selects the `VisualizationPlots` backend, whose real plotting methods are only added once `Plots.jl` is loaded, at which point Julia's package extension mechanism loads `SindbadPlotsExt` (see root `Project.toml` `[weakdeps]` + `[extensions]`). `using Sindbad` alone is sufficient once `Plots` is also loaded in the session — end users typically should not `using SindbadPlotsExt` directly.

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
```
"""
module Visualization
    using SindbadTEM.OmniTools
    using ..Types

    export plotPerformanceHistograms
    export plotTimeSeriesWithObs
    export plotTimeSeriesDebug
    export plotIOModelStructure

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

    function plotTimeSeriesWithObs(out_opti)
        backend = out_opti.info.helpers.run.visualization_backend
        return plotTimeSeriesWithObs(out_opti, _resolvedBackend(plotTimeSeriesWithObs, backend, out_opti))
    end

    function plotTimeSeriesWithObs(out, obs_array, cost_options)
        backend = out.info.helpers.run.visualization_backend
        return plotTimeSeriesWithObs(out, obs_array, cost_options, _resolvedBackend(plotTimeSeriesWithObs, backend, out, obs_array, cost_options))
    end

    function plotTimeSeriesDebug(info, opt_dat, def_dat)
        backend = info.helpers.run.visualization_backend
        return plotTimeSeriesDebug(info, opt_dat, def_dat, _resolvedBackend(plotTimeSeriesDebug, backend, info, opt_dat, def_dat))
    end

    plotIOModelStructure(info) = plotIOModelStructure(info, :compute)
    plotIOModelStructure(info, which_function) = plotIOModelStructure(info, which_function, [:input, :output])
    function plotIOModelStructure(info, which_function, which_field)
        backend = info.helpers.run.visualization_backend
        return plotIOModelStructure(info, which_function, which_field, _resolvedBackend(plotIOModelStructure, backend, info, which_function, which_field))
    end

    # Default (no-op) backend: logs an info message instead of plotting. Used whenever
    # `visualization_backend` isn't configured, or a configured backend's extension isn't loaded.
    function plotPerformanceHistograms(out_opti, ::VisualizationTypes)
        print_info(plotPerformanceHistograms, @__FILE__, @__LINE__, "No visualization backend loaded; skipping `plotPerformanceHistograms`. Set `visualization_backend` in the experiment config (e.g. `\"Plots\"`) and `using Plots` in your session to enable this plot.", n_f=4)
        return nothing
    end

    function plotTimeSeriesWithObs(out_opti, ::VisualizationTypes)
        print_info(plotTimeSeriesWithObs, @__FILE__, @__LINE__, "No visualization backend loaded; skipping `plotTimeSeriesWithObs`. Set `visualization_backend` in the experiment config (e.g. `\"Plots\"`) and `using Plots` in your session to enable this plot.", n_f=4)
        return nothing
    end

    function plotTimeSeriesWithObs(out, obs_array, cost_options, ::VisualizationTypes)
        print_info(plotTimeSeriesWithObs, @__FILE__, @__LINE__, "No visualization backend loaded; skipping `plotTimeSeriesWithObs`. Set `visualization_backend` in the experiment config (e.g. `\"Plots\"`) and `using Plots` in your session to enable this plot.", n_f=4)
        return nothing
    end

    function plotTimeSeriesDebug(info, opt_dat, def_dat, ::VisualizationTypes)
        print_info(plotTimeSeriesDebug, @__FILE__, @__LINE__, "No visualization backend loaded; skipping `plotTimeSeriesDebug`. Set `visualization_backend` in the experiment config (e.g. `\"Plots\"`) and `using Plots` in your session to enable this plot.", n_f=4)
        return nothing
    end

    function plotIOModelStructure(info, which_function, which_field, ::VisualizationTypes)
        print_info(plotIOModelStructure, @__FILE__, @__LINE__, "No visualization backend loaded; skipping `plotIOModelStructure`. Set `visualization_backend` in the experiment config (e.g. `\"Plots\"`) and `using Plots` in your session to enable this plot.", n_f=4)
        return nothing
    end

    include("plotFromSindbadInfo.jl")

end # module Visualization
