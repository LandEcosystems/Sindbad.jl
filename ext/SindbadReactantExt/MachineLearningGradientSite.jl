"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `Reactant` and `Enzyme`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: gradientSite

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: ReactantGrad

# ------------------------------------------------------------------
function gradientSite(::ReactantGrad, x_vals::AbstractArray, gradient_options::NamedTuple, loss_f::F) where {F}
    x_ra = Reactant.to_rarray(Float32.(collect(x_vals)))
    # loss_f closes over mutable model state that gets written during the forward run, so
    # Enzyme's default `Const(loss_f)` wrapping fails its readonly check; a shadow via
    # `Duplicated` grants write permission (the shadow's contents are unused). Runtime
    # activity is needed because the loss/cost machinery dispatches dynamically in places.
    dup_loss_f = Enzyme.Duplicated(loss_f, Enzyme.make_zero(loss_f))
    # The scoped `@allowscalar` macro does not consistently apply across `@jit`'s deferred
    # compile+execute; the global toggle does.
    Reactant.allowscalar(true)
    g = Reactant.@jit Enzyme.gradient(Enzyme.set_runtime_activity(Reverse), dup_loss_f, x_ra)
    return Array(g[1])
end
