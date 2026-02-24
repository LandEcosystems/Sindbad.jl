"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `Enzyme`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: gradientSite

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: FiniteDiffGrad

# Example methods (for reference):
# - src/MachineLearning/mlGradient.jl:147  gradientSite(::PolyesterForwardDiffGrad, ::Any, ::NamedTuple, ::F) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:135  gradientSite(::PolyesterForwardDiffGrad, ::Any, ::Int64, ::F, ::Vararg{Any}) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:172  gradientSite(::ZygoteGrad, ::AbstractArray, ::NamedTuple, ::F) @ Sindbad.MachineLearning

# ------------------------------------------------------------------
# Add your extension methods below. The Example is a tentative placeholder for the method signature and should be replaced with the actual method signature.


function gradientSite(grads_lib::FiniteDiffGrad, x_vals::AbstractArray, chunk_size::Int, loss_f::F, args...) where {F}
    loss_tmp(x) = loss_f(x, grads_lib, args...)
    return FiniteDiff.finite_difference_gradient(loss_tmp, x_vals)
end
