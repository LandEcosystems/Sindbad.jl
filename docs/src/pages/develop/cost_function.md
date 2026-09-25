# Adding a New Cost Calculation Method in SINDBAD

This documentation provides a framework for adding new cost calculation methods while maintaining consistency with SINDBAD's existing architecture.

:::tip
For a more detailed view of available cost methods and their purposes, use:
```julia
using Sindbad.Simulation
using OmniTools: show_methods_of
show_methods_of(CostMethod)
```
This will display a formatted list of all cost methods and their descriptions.

:::

## Overview
SINDBAD uses a type-based dispatch system for cost calculation methods. To add a new cost calculation method, you need to:

1. Define a new type in `src/Types/ParameterOptimizationTypes.jl`
2. Implement the cost calculation function in `cost.jl`
3. Update the cost preparation in `prepOpti.jl` if needed

## Step 1: Define the New Cost Method Type

In `src/Types/ParameterOptimizationTypes.jl`, add a new struct that subtypes `CostMethod`:

```julia
struct YourNewCostMethod <: CostMethod end
```

For example, the existing cost methods are (but can change, use `show_methods_of(CostMethod)` for current implementations):
- `CostModelObs`: Basic cost calculation between model and observations
- `CostModelObsMT`: Multi-threaded version of `CostModelObs`
- `CostModelObsPriors`: Cost calculation including prior information
- `CostModelObsLandTS`: Cost calculation for land time series

## Step 2: Implement the Cost Calculation Function

In `cost.jl`, implement your cost calculation function with the following signature:

```julia
function cost(parameter_vector, default_values, selected_models, space_forcing, space_spinup, 
            loc_forcing_t, output_array, space_output, space_land, tem_info, observations, 
            parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, 
            ::YourNewCostMethod)
    # Your implementation here
end
```

The function should:
1. Update model parameters using `updateModels`
2. Run the model simulation
3. Calculate the cost using `metricVector` and `combineMetric`

Example implementation structure:
```julia
function cost(parameter_vector, _, selected_models, space_forcing, space_spinup, 
            loc_forcing_t, output_array, space_output, space_land, tem_info, observations, 
            parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, 
            ::YourNewCostMethod)
    # Update models with new parameters
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    
    # Run the model simulation
    runTEM!(updated_models, space_forcing, space_spinup, loc_forcing_t, space_output, space_land, tem_info)
    
    # Calculate cost vector
    cost_vector = metricVector(output_array, observations, cost_options)
    
    # Combine costs using specified method
    cost_metric = combineMetric(cost_vector, multi_constraint_method)
    
    return cost_metric
end
```

## Step 3: Update Cost Preparation (if needed)

If your new cost method requires special preparation, update `prepOpti.jl`:

```julia
function prepOpti(forcing, observations, info, ::YourNewCostMethod)
    # Get base helpers
    opti_helpers = prepOpti(forcing, observations, info, CostModelObs())
    
    # Add your custom preparation here
    
    return opti_helpers
end
```

## Example: Adding a Weighted Cost Method

Here's a complete example of adding a new weighted cost method:

1. In `src/Types/ParameterOptimizationTypes.jl`:
```julia
struct CostModelObsWeighted <: CostMethod end
```

2. In `cost.jl`:
```julia
function cost(parameter_vector, _, selected_models, space_forcing, space_spinup, 
             loc_forcing_t, output_array, space_output, space_land, tem_info, observations, 
             parameter_updater, cost_options, multi_constraint_method, parameter_scaling_type, 
             ::CostModelObsWeighted)
    # Update models
    updated_models = updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    
    # Run simulation
    runTEM!(updated_models, space_forcing, space_spinup, loc_forcing_t, space_output, space_land, tem_info)
    
    # Calculate weighted cost vector
    cost_vector = metricVector(output_array, observations, cost_options)
    
    # Apply custom weights
    weights = getWeights(cost_options)  # getWeights is a hypothetical function, you would need to implement such function
    weighted_cost = cost_vector .* weights
    
    # Combine costs
    cost_metric = combineMetric(weighted_cost, multi_constraint_method)
    
    return cost_metric
end
```

## Important Considerations

1. **Parameter Scaling**: Ensure your method properly handles parameter scaling using `parameter_scaling_type`.

2. **Multi-threading**: If your method can benefit from parallelization, consider implementing a multi-threaded version like `CostModelObsMT`.

3. **Cost Options**: Your method should respect the `cost_options` configuration, which includes:
   - Cost metrics
   - Spatial and temporal aggregation
   - Minimum data points
   - Weights

4. **Performance**: For large-scale optimizations, consider implementing efficient memory management and parallelization.

5. **Documentation**: Add comprehensive docstrings explaining:
   - The purpose of your cost method
   - Required parameters
   - Return values
   - Any special considerations

## Testing

After implementing your new cost method:
1. Test with small parameter sets first
2. Verify the cost calculation matches expected values
3. Check performance with larger parameter sets
4. Ensure compatibility with different optimization algorithms

