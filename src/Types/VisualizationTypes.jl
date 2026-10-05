
export VisualizationTypes
struct VisualizationTypes <: SindbadTypes end
purpose(::Type{VisualizationTypes}) = "Default dispatch type for visualization; used when no plotting backend is selected/available, dispatching to a fallback that logs an info message instead of plotting"

# ------------------------- Visualization types using different packages -------------------------
export VisualizationPlots

struct VisualizationPlots <: SindbadTypes end
purpose(::Type{VisualizationPlots}) = "Dispatch type for visualizations using Plots.jl"
