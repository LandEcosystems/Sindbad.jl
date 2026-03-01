"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `ForwardDiff`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: gradientSite

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: ForwardDiffGrad

function gradientSite(::ForwardDiffGrad, x_vals::AbstractArray, gradient_options::NamedTuple, loss_f::F) where {F}
    ∇x = similar(x_vals) # pre-allocate
    chunk_size = gradient_options.chunk_size
    # cfg = ForwardDiff.GradientConfig(loss_tmp, x_vals, Chunk{chunk_size}());
    ForwardDiff.gradient!(∇x, loss_f, x_vals) # ?, add `cfg` at the end if further control is needed.
    return ∇x
end