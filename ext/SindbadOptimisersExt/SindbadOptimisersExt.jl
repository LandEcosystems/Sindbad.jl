"""
    SindbadOptimisersExt

Julia extension module that enables Optimisers backends for `Sindbad.MachineLearning`.

# Notes:
- This module is loaded automatically by Julia's package extension mechanism when Optimisers is available (see root `Project.toml` `[weakdeps]` + `[extensions]`).
- End users typically should not `using SindbadOptimisersExt` directly; instead `using Sindbad` is sufficient once the weak dependency is installed.
- The extension code is included in the `ext/` directory and is automatically loaded when the extension package is installed.

Modify the code in the "MachineLearningMlOptimizer.jl" file to extend the package.
"""
module SindbadOptimisersExt

    using Optimisers
    
    include("MachineLearningMlOptimizer.jl")
    include("MachineLearningUpdateMLModel.jl")

end

