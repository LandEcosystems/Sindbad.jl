"""
    SindbadReactantExt

Julia extension module that enables Reactant.jl (combined with Enzyme.jl) as a gradient
backend for `Sindbad.MachineLearning`.

# Notes:
- This module is loaded automatically by Julia's package extension mechanism when both
  Reactant and Enzyme are available (see root `Project.toml` `[weakdeps]` + `[extensions]`).
- End users typically should not `using SindbadReactantExt` directly; instead `using Sindbad`
  is sufficient once the weak dependencies are installed.
- Reactant traces the loss function to a StableHLO/MLIR graph before Enzyme differentiates
  it, which avoids several limitations of differentiating raw, mutating Julia/LLVM IR
  directly (see `MachineLearningGradientSite.jl`, `PrepTEMReactant.jl`, and
  `TimeLoopReactant.jl`).
"""
module SindbadReactantExt

    using Reactant
    using Enzyme

    include("PrepTEMReactant.jl")
    include("TimeLoopReactant.jl")
    include("MachineLearningGradientSite.jl")

end
