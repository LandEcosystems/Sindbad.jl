"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `ForwardDiff`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning:
    getCacheFromOutput,
    getOutputFromCache,
    gradientSite

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: ForwardDiffGrad

# ------------------------------------------------------------------
# WARNING! Loading PreallocationTools before is required!

function getCacheFromOutput(loc_output, ::ForwardDiffGrad)
    return getCacheFromOutput(loc_output, ForwardDiffGrad())
end

function getOutputFromCache(loc_output, new_params, ::ForwardDiffGrad)
    return getOutputFromCache(loc_output, new_params, ForwardDiffGrad())
end

function gradientSite(grads_lib::ForwardDiffGrad, x_vals::AbstractArray, chunk_size::Int, loss_f::F, args...) where {F}
    loss_tmp(x) = loss_f(x, grads_lib, args...)
    ∇x = similar(x_vals) # pre-allocate
    # cfg = ForwardDiff.GradientConfig(loss_tmp, x_vals, Chunk{chunk_size}());
    ForwardDiff.gradient!(∇x, loss_tmp, x_vals) # ?, add `cfg` at the end if further control is needed.
    return ∇x
end