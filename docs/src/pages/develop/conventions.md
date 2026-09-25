# Coding Guidelines for SINDBAD Model Functions

Follow the guidelines so that SINDBAD model functions are consistent, maintainable,  performant, and self-explainable.


## Struct Definition:

Use `@bounds`, `@describe`, `@units`, and `@timescale` annotations for parameter metadata.
Define default values and valid ranges for parameters to ensure clarity and robustness.

```julia
@bounds @describe @units @timescale @with_kw struct ApproachName {T1, T2} <: ApproachName
    param1::T1 = default_value | (min, max) | "description" | "units" | "timescale"
end
```

## Function Structure

### `define` Function:

- Initialize variables and arrays with appropriate dimensions and default values.
- Use helper functions or constants for clarity and reusability.
- Pack updated variables back into the land object.

```julia
function define(params::ApproachName, forcing, land, helpers)
    @unpack params
    @unpack_nt land
    # Initialize variables
    variable = zero(array)
    # Pack variables
    @pack_nt variable ⇒ land.diagnostics
    return land
end
```

### `precompute` Function:

- Update variables based on parameters and forcing data.
- Use loops or helper functions for repetitive tasks.
- Ensure all updated variables are packed back into the land object.

```julia
    function precompute(params::ApproachName, forcing, land, helpers)
    @unpack params
    @unpack_nt land
    # Update variables
    variable[index] = new_value
    # Pack variables
    @pack_nt variable ⇒ land.diagnostics
    return land
end
```

### `Helper` Functions:

- Use helper functions (e.g., adjustPackPoolComponents) for modularity and to handle repetitive tasks like mapping or scaling variables.
- Think of reusing such helpers in other models

## Variable Naming and Management:

Use descriptive and meaningful names for variables and parameters to improve code readability.
Example: ```c_τ_Root = turnover_rate_root```

Use `@unpack_nt` and `@pack_nt` macros to access forcing/land and pack land variables efficiently.

Clearly separate diagnostics, constants, and states in the land object. 
- Follow [guidelines on the packing variables to an appropriate field of land](../concept/land.md).
- Use the model_name as the field when the variable is ONLY used in the model itself. Use the shared land fields for variable sharing across different models.

::: danger
- There are no checks for overwriting variables on land. Before packing a new variable to land. Ensure that it does not already exist in land. 
- Do not created a deeper level in land NamedTuple. By convention, all variable group are in the top level, and variable values are in the second level.
:::

## Ensuring Type Stability

It is absolutely necessary to follow coding guidelines to maintain the high computing performance of SINDBAD models. Without these, the simulations can get very slow even with minor changes.

### Avoid Hardcoding Numbers

Never hardcode numbers directly into the code. Instead, use parameters to define values. This ensures flexibility, readability, and maintainability. **Avoid typing numbers** inside the functions

```julia
c_τ_Root = 1.0
some_constant = 27.38
```

Because these numbers will be defined as Float64. Instead define them **within the struct** so that they are auto-magically type stabilized when SINDBAD experiments are setup. See example below.

### Define parameters in the struct

The approach struct are versatile bucket that can hold both model parameters and constants that will never be calibrated.

```julia
@bounds @describe @units @timescale @with_kw struct cCycleBase_GSI{T1, T2, T3}
    c_τ_Root::T1 = 1.0 | (0.05, 3.3) | "turnover rate of root carbon pool" | "year-1" | "year"
    c_τ_Wood::T2 = 0.03 | (0.001, 10.0) | "turnover rate of wood carbon pool" | "year-1" | "year"
    some_constant::T2 = 27.38 | (-Inf, Inf) | "constant that I will use in my mode" | "" | ""
end
```

:::warning

Note that the parameters and constants will be available in the approach [define, precompute, compute, update methods](../concept/TEM.md) when ```@unpack_ApproachName params``` is typed at the beginning of the function. Ensure that you do not use the parameters/constants defined in the struct as variables in your function.

:::

###  Avoid Hardcoding Array Dimensions

Use dynamic methods to determine array sizes or indices instead of hardcoding dimensions. This ensures flexibility and avoids errors when array sizes change.
Example:

```julia
# Avoid this:
some_order = Tuple(collect(1:8))

# Use this:
some_order = Tuple(collect(1:length(findall(>(z_zero), some_array))))
```

### Replace Values Dynamically

Differentiable programming limits the modification of array within the functions. **So, replacing the element of an array will make the model non-differentiable**. 

Use internal function such as `repElem` and its shorthand macro `@rep_elem` to dynamically replace values in arrays or variables, ensuring consistency and avoiding hardcoding.

```julia
# Avoid this:
my_array[my_index] = new_value

# Use this:
my_array = repElem(my_array, new_value, my_index)
```

For arrays in `land.pools`, the shorthand @rep_elem macro can be used as,
```julia
@rep_elem new_pool_value ⇒ (TWS, 2)
```

where, `new_pool_value` will be used to replace the second element of `TWS` array

:::tip

Use `@code_warntype` to test for type stability in functions and ensure there are no type ambiguities. Useful guidelines are also available at: https://viralinstruction.com/posts/optimise/

:::

## Metadata and Documentation:

Add a purpose function to describe the role of the model or approach.
Use @doc to provide detailed documentation, including references, versions, and authorship.

```julia
import OmniTools: purpose
purpose(::Type{ApproachName}) = "Description of the approach's purpose and summary of its main method or principle"
```

## Code Readability:
Use meaningful variable names and comments to explain complex logic.

## Versioning and References:

Include version history and references in the documentation for traceability.

```julia
@doc """
$(getModelDocString(ApproachName))

*References*
- Author, Year. Title. Journal.

*Versions*
- 1.0 on DD.MM.YYYY [author | @username]
"""
ApproachName
```

## Writing Code


:::info

When working with SINDBAD, it is highly recommended to utilize the built-in function `generateSindbadApproach` to create your model and approach files. This function automates the process of setting up the necessary structs and functions of the model, ensuring that your model adheres to the established conventions for code structure, performance tips, modularity, and documentation.

Check the documentation of the function for further details as:
```julia
using Sindbad.Simulation
?generateSindbadApproach
```
:::
