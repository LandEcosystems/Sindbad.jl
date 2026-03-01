"""
    SindbadLuxExt

Julia extension module that enables Lux backends for `Sindbad.MachineLearning`.

# Notes:
- This module is loaded automatically by Julia's package extension mechanism when Lux is available (see root `Project.toml` `[weakdeps]` + `[extensions]`).
- End users typically should not `using SindbadLuxExt` directly; instead `using Sindbad` is sufficient once the weak dependency is installed.
- The extension code is included in the `ext/` directory and is automatically loaded when the extension package is installed.

Modify the code in the "MachineLearningMlModel.jl" file to extend the package.
"""
module SindbadLuxExt

    using Lux
    
    include("MachineLearningMlModel.jl")

end

