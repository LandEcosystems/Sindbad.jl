export getPullback

"""
    getPullback(::MachineLearningPullbackType, flat, re, features::AbstractArray)
    getPullback(::MachineLearningPullbackType, flat, re, features::Tuple)

# Arguments:
- flat :: weight parameters.
- re :: model structure (vanilla Chain Dense Layers).
- features ::  `n` predictors and `s` samples.
    - A vector of predictors
    - A matrix of predictors: `(p_n x s)`
    - A tuple vector of predictors: `(p1, p2)`
    - A tuple of matrices of predictors: `[(p1_n x s), (p2_n x s)]`

# Returns:
- new parameters and pullback function

# Example

Here we do one input features vector or matrix.

```julia
using Sindbad.MachineLearning
using Flux
# model
m = Chain(Dense(4 => 5, relu), Dense(5 => 3), Flux.sigmoid)
# features
_feat = rand(Float32, 4)
# apply
flat, re = destructureNN(m)
# Zygote
new_params, pullback_func = getPullback(ZygotePullBack(), flat, re, _feat)
# ? or
_feat_ns = rand(Float32, 4, 3) # `n` predictors and `s` samples.
new_params, pullback_func = getPullback(ZygotePullBack(), flat, re, _feat_ns)
```

# Example

Here we do one multiple input features vector or matrix.

```julia
using Sindbad.MachineLearning
using Flux
# model
m1 = Chain(Dense(4 => 5, relu), Dense(5 => 3), Flux.sigmoid)
m2 = Dense(2=>1, Flux.sigmoid)
combo_ms = JoinDenseNN((m1, m2))
# features
_feat1 = rand(Float32, 4)
_feat2 = rand(Float32, 2)
# apply
flat, re = destructureNN(combo_ms)
# Zygote
new_params, pullback_func = getPullback(ZygotePullBack(), flat, re, (_feat1, _feat2))
# ? or with multiple samples
_feat1_ns = rand(Float32, 4, 3) # `n` predictors and `s` samples.
_feat2_ns = rand(Float32, 2, 3) # `n` predictors and `s` samples.
new_params, pullback_func = getPullback(ZygotePullBack(), flat, re, (_feat1_ns, _feat2_ns))
```
"""
function getPullback(x::MachineLearningPullbackType, _, _, _)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    getPullback `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This pullback type is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    getPullback `$(nameof(typeof(x)))` not implemented.

    To implement a new pullback type:

    - First add a new type as a subtype of `MachineLearningPullbackType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/getPullback.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningGetPullback.jl` extension.
    ")
    end
end
