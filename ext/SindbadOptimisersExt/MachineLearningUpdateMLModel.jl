"""
Extension methods for `Sindbad.MachineLearning.updateMLModel`.

This file is included from the extension module and can use `Optimisers`.
"""

import Sindbad.MachineLearning: updateMLModel

using Sindbad: OptimisersUpdate

function updateMLModel(::OptimisersUpdate, opt_state, flat, ∇params)
    updated_opt_state, updated_flat = Optimisers.update(opt_state, flat, ∇params)
    return updated_opt_state, updated_flat
end
