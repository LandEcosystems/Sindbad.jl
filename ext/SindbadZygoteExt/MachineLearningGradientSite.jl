"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `Zygote`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: gradientSite

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: ZygoteGrad

# Example methods (for reference):
# - ext/SindbadForwardDiffExt/MachineLearningGradientSite.jl:25  gradientSite(::ForwardDiffGrad, ::AbstractArray, ::NamedTuple, ::F) @ SindbadForwardDiffExt
# - src/MachineLearning/mlGradient.jl:147  gradientSite(::PolyesterForwardDiffGrad, ::Any, ::NamedTuple, ::F) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:135  gradientSite(::PolyesterForwardDiffGrad, ::Any, ::Int64, ::F, ::Vararg{Any}) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:172  gradientSite(::ZygoteGrad, ::AbstractArray, ::NamedTuple, ::F) @ Sindbad.MachineLearning

# ------------------------------------------------------------------
function gradientSite(::ZygoteGrad, x_vals::AbstractArray, gradient_options::NamedTuple,loss_f::F) where {F}
    return Zygote.gradient(loss_f, x_vals)
end

