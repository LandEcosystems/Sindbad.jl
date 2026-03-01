"""
Extension methods for `Sindbad.MachineLearning.mlOptimizer`.

This file is included from the extension module and can use `Optimisers`.
"""

import Sindbad.MachineLearning: mlOptimizer

using Sindbad: OptimisersAdam, OptimisersDescent

function mlOptimizer(optimizer_options, ::OptimisersAdam)
    return Optimisers.Adam(optimizer_options...)
end

function mlOptimizer(optimizer_options, ::OptimisersDescent)
    return Optimisers.Descent(optimizer_options...)
end
