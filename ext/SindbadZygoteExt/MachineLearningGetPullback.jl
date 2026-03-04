# Define pullbacks for single and multi inputs
import Sindbad.MachineLearning: getPullback
using Sindbad: ZygotePullback

function getPullback(::ZygotePullback, flat, re, features::AbstractArray)
    new_params, pullback_func = Zygote.pullback(p -> re(p)(features), flat)
    return new_params, pullback_func
end

function getPullback(::ZygotePullback, flat, re, features::Tuple)
    new_params, pullback_func = Zygote.pullback(p -> re(p)(features), flat)
    return new_params, pullback_func
end