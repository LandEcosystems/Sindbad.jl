"""
    SindbadPolyesterForwardDiffExt

Julia extension module that enables ForwardDiff backends for `Sindbad.MachineLearning`.

# Notes:
- This module is loaded automatically by Julia's package extension mechanism when ForwardDiff is available (see root `Project.toml` `[weakdeps]` + `[extensions]`).
- End users typically should not `using SindbadPolyesterForwardDiffExt` directly; instead `using Sindbad` is sufficient once the weak dependency is installed.
- The extension code is included in the `ext/` directory and is automatically loaded when the extension package is installed.

Modify the code in the "MachineLearningGradientSite.jl" file to extend the package.
"""
module SindbadPolyesterForwardDiffExt
    using PolyesterForwardDiff
    using ForwardDiff
    using Distributed:
        pmap,
        workers,
        CachingPool
    using ProgressMeter:
        progress_pmap,
        progress_map
    
    include("MachineLearningGradientSite.jl")

end

