"""
    SindbadPlotsExt

Julia extension module that enables Plots backends for `Sindbad.Visualization`.

# Notes:
- This module is loaded automatically by Julia's package extension mechanism when Plots is available (see root `Project.toml` `[weakdeps]` + `[extensions]`).
- End users typically should not `using SindbadPlotsExt` directly; instead `using Sindbad` is sufficient once the weak dependency is installed.
- The extension code is included in the `ext/` directory and is automatically loaded when the extension package is installed.

Modify the code in the "VisualizationPlotOutputUsingPlots.jl" and "VisualizationPlotIOModelStructure.jl" files to extend the package.
"""
module SindbadPlotsExt
    using Plots: annotate! as plots_annotate!, default as plots_default, histogram as plots_histogram, histogram! as plots_histogram!, scatter as plots_scatter, scatter! as plots_scatter!, vline as plots_vline, vline! as plots_vline!, hline as plots_hline, hline! as plots_hline!, xlims! as plots_xlims!, ylims! as plots_ylims!, xlabel! as plots_xlabel!, ylabel! as plots_ylabel!, title! as plots_title!, plot as plots_plot, plot! as plots_plot!, savefig as plots_savefig, text as plots_text, mm as plots_mm, cm as plots_cm

    using SindbadTEM
    using SindbadTEM.OmniTools
    using Sindbad.Types
    using Sindbad.DataLoaders
    using Sindbad.ErrorMetrics
    using Sindbad.NaNStatistics

    include("VisualizationPlotOutputUsingPlots.jl")
    include("VisualizationPlotIOModelStructure.jl")
end
