"""
Extension methods for `Sindbad.MachineLearning.gradientSite`.

This file is included from the extension module and can use `ForwardDiff`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.MachineLearning: getCacheFromOutput

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: ForwardDiffGrad


# ------------------------------------------------------------------

function getCacheFromOutput(loc_output, ::ForwardDiffGrad)
    # The caches are built on plain arrays of the output of the location, not on the
    # views into the output of all locations. For a view, get_tmp rebuilds the dual
    # array in the shape of the view with a copy at every call, which allocated the
    # full dual output once per loss evaluation. For an array, it only reshapes. The
    # loss reads its outputs from the cache, so they need not land in the shared array.
    return DiffCache.(Array.(loc_output))
end
