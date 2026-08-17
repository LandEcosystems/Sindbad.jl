"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `Enzyme`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: gradientSite

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: EnzymeGrad

# Example methods (for reference):
# - src/MachineLearning/mlGradient.jl:163  gradientSite(::FiniteDiffGrad, ::AbstractArray, ::NamedTuple, ::F) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:147  gradientSite(::PolyesterForwardDiffGrad, ::Any, ::NamedTuple, ::F) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:135  gradientSite(::PolyesterForwardDiffGrad, ::Any, ::Int64, ::F, ::Vararg{Any}) @ Sindbad.MachineLearning
# - src/MachineLearning/mlGradient.jl:172  gradientSite(::ZygoteGrad, ::AbstractArray, ::NamedTuple, ::F) @ Sindbad.MachineLearning

# ------------------------------------------------------------------
function gradientSite(::EnzymeGrad, x_vals::AbstractArray, gradient_options::NamedTuple,loss_f::F) where {F}
    # does not work with `Enzyme.gradient!` but is kept here as placeholder for future development
    # Ensure x_vals is a mutable array (Vector)
    x_vals = collect(copy(x_vals))  # Convert to a mutable array if necessary
    # x_vals = copy(x_vals)
    # loss_f closes over mutable model state that gets written during the forward
    # run, so Enzyme's default `Const(loss_f)` wrapping fails its readonly check.
    # Giving it a shadow via `Duplicated` grants write permission; the shadow's
    # contents are unused since we only need the gradient w.r.t. x_vals.
    dup_loss_f = Enzyme.Duplicated(loss_f, Enzyme.make_zero(loss_f))
    return Enzyme.gradient(Enzyme.set_runtime_activity(Reverse), dup_loss_f, x_vals)
end