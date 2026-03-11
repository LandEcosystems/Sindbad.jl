"""
    Visualization

Visualization utilities for SINDBAD experiments. This module focuses on
plotting model outputs, diagnostics, and experiment metadata—currently
via `Plots.jl`, with hooks prepared for future interactive Makie support.

# Purpose
- Provide ready-to-use plotting helpers that understand SINDBAD's
  `info`, outputs, and metric structures.
- Speed up exploratory analysis by wrapping common visual layouts
  (time series, site comparisons, diagnostic summaries).

# Dependencies
## Related (SINDBAD ecosystem)
- `ErrorMetrics`: Metric helpers used in plot annotations and summaries.
- `OmniTools`: Shared helper utilities.

## External (third-party)
- `Plots`: Default backend for static visualizations.
- *(Optional / planned)* `GLMakie`, `Colors`: Interactive plotting stack
  to be enabled once cluster compatibility issues are resolved.

## Internal (within `Sindbad`)
- `SindbadTEM`

# Included Files
- **`plotOutputUsingPlots.jl`**: Plotting helpers for land fluxes, pools, and diagnostics using `Plots.jl`.
- **`plotFromSindbadInfo.jl`**: Visualize experiment metadata (model ordering, approaches, inputs) from the `info` NamedTuple.

# Notes
- Additional plot recipes are being added progressively; current focus is
  on covering the default experiment workflow.
- The API is reexported via `Sindbad.Visualization`, so users simply load
  `Sindbad` to access plotting helpers.

# Usage:
```julia
using Sindbad.Visualization

plotPerformanceHistograms(opt_results)
plotIOModelStructure(info)
```
"""
module Visualization
    using SindbadTEM
    using SindbadTEM.OmniTools
    using ..Types
    using ..DataLoaders
    using Sindbad.ErrorMetrics
    using Sindbad.NaNStatistics
    # using GLMakie
    # @reexport using GLMakie.Makie
    # using Colors
    @reexport using Plots: annotate! as plots_annotate!, default as plots_default, histogram as plots_histogram, histogram! as plots_histogram!, scatter as plots_scatter, scatter! as plots_scatter!, vline as plots_vline, vline! as plots_vline!, hline as plots_hline, hline! as plots_hline!, xlims! as plots_xlims!, ylims! as plots_ylims!, xlabel! as plots_xlabel!, ylabel! as plots_ylabel!, title! as plots_title!, plot as plots_plot, plot! as plots_plot!, savefig as plots_savefig, text as plots_text, mm as plots_mm, cm as plots_cm

    # include("plotOutputData.jl")
    include("plotOutputUsingPlots.jl")
    include("plotFromSindbadInfo.jl")

end # module Visualization
