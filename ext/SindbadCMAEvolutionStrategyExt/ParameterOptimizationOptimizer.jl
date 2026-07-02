"""
Extension methods for `Sindbad.ParameterOptimization.optimizer`.

This file is included from the extension module and can use `CMAEvolutionStrategy`.
"""

# Bring the target function into scope for adding methods. This should be done using `import` and not `using`.
import Sindbad.ParameterOptimization: optimizer

# get all the types needed to dispatch the function. These types should defined in a corresponding file in Sindbad so that they can be used for dispatching and setup, if that were needed.
using Sindbad: CMAEvolutionStrategyCMAES

# Example methods (for reference):
# - src/ParameterOptimization/optimizer.jl:55  optimizer(::Any, ::Any, ::Any, ::Any, ::Any, ::ParameterOptimizationMethod) @ Sindbad.ParameterOptimization

# ------------------------------------------------------------------
# Add your extension methods below. The Example is a tentative placeholder for the method signature and should be replaced with the actual method signature.
function optimizer(cost_function, default_values, lower_bounds, upper_bounds, algo_options, ::CMAEvolutionStrategyCMAES)
    results = CMAEvolutionStrategy.minimize(cost_function, default_values, 1; lower=lower_bounds, upper=upper_bounds, algo_options...)
    optim_para = CMAEvolutionStrategy.xbest(results)
    showInfo(optimizer, @__FILE__, @__LINE__, "[termination reason] $(results.stop.reason) = $(getproperty(results.stop, results.stop.reason)) ($(now()))")
    return optim_para
end
