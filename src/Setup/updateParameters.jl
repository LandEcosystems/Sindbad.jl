
export backScaleParameters
export checkParameterBounds
export scaleParameters
export updateModelParameters
export updateModels

"""
    backScaleParameters(parameter_vector_scaled, parameter_table, <: ParameterScaling)

Reverts scaling of parameters using a specified scaling strategy.

# Arguments
- `parameter_vector_scaled`: Vector of scaled parameters to be converted back to original scale
- `parameter_table`: Table containing parameter information and scaling factors
- `ParameterScaling`: Type indicating the scaling strategy to be used
    - `::ScaleDefault`: Type indicating scaling by initial parameter values
    - `::ScaleBounds`: Type indicating scaling by parameter bounds
    - `::ScaleNone`: Type indicating no scaling should be applied (parameters remain unchanged)

# Returns
Returns the unscaled/actual parameter vector in original units.
"""
function backScaleParameters end

function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleNone)
    return parameter_vector_scaled
end
    
function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleDefault)
    parameter_vector_scaled = abs.(parameter_table.initial) .* parameter_vector_scaled
    return parameter_vector_scaled
end

function backScaleParameters(parameter_vector_scaled, parameter_table, ::ScaleBounds)
    ub = parameter_table.upper  # upper bounds
    lb = parameter_table.lower   # lower bounds
    parameter_vector_scaled .= lb .+ (ub .- lb) .* parameter_vector_scaled
    return parameter_vector_scaled
end

"""
    checkInRange(name, value, lower_bound, upper_bound, show_info)

Checks whether a given value or array is within specified bounds.

# Arguments:
- `name`: A string or symbol representing the name or identifier of the parameter being checked.
- `value`: The value or array to be checked against the bounds.
    - Can be a scalar (`Real`) or an array (`AbstractArray`).
- `lower_bound`: The lower bound for the value or array.
- `upper_bound`: The upper bound for the value or array.
- `show_info`: A boolean flag indicating whether to display detailed information about the check.

# Returns:
- `true`: If the value or all elements of the array are within the specified bounds.
- `false`: If the value or any element of the array violates the bounds.

# Notes:
- If `value` is an array and `show_info` is `true`, the function logs a message indicating that the check is skipped for arrays, as bounds are typically defined for scalar parameters.
- For scalar values, the function performs a direct comparison to ensure the value lies within `[lower_bound, upper_bound]`.
- If the bounds are violated, the function logs detailed information (if `show_info` is `true`) and returns `false`.

# Examples:
1. **Checking a scalar value**:
```julia
is_in_range = checkInRange("parameter1", 5.0, 0.0, 10.0, true)
# Output: true
```

2. **Checking an array (skipping bounds check)**:
```julia
is_in_range = checkInRange("parameter2", [1.0, 2.0, 3.0], 0.0, 10.0, true)
# Output: true (logs a message indicating the check is skipped)
```

3. **Checking a scalar value outside bounds**:
```julia
is_in_range = checkInRange("parameter3", -1.0, 0.0, 10.0, true)
# Output: false (logs a message indicating the violation)
```
"""
function checkInRange end

function checkInRange(n, d::Real, l::Real, u::Real, show_info)
    return l <= d <= u
end

function checkInRange(n, d::AbstractArray, l, u, show_info)
    if show_info
        @info "           $(n) is a matrix parameter. Skipping check as bounds can be numbers and these parameters cannot be optimized by optimizers."
    end
    return true
end


"""
    checkParameterBounds(p_names, parameter_values, lower_bounds, upper_bounds, _sc::ParameterScaling; show_info=false, model_names=nothing)

Check and display the parameter bounds information for given parameters.

# Arguments
- `p_names`: Names or identifier of the parameters. Vector of strings.
- `parameter_values`: Default values of the parameters. Vector of Numbers.
- `lower_bounds`: Lower bounds for the parameters. Vector of Numbers.
- `upper_bounds`: Upper bounds for the parameters. Vector of Numbers.
- `_sc::ParameterScaling`: Scaling Type for the parameters
- `show_info`: a flag to display model parameters and their bounds. Boolean.
- `model_names`: Names or identifier of the approaches where the parameters are defined.

# Returns
Displays a formatted output of parameter bounds information or returns an error when they are violated
"""
function checkParameterBounds(p_names, parameter_values, lower_bounds, upper_bounds, _sc::ParameterScaling; p_units=nothing, show_info=false, model_names=nothing)
    if show_info
        print_info(checkParameterBounds, @__FILE__, @__LINE__, "checking Parameter Bounds")
        if nameof(typeof(_sc)) == :ScaleNone
            print_info(nothing, @__FILE__, @__LINE__, "→→→    no scaling applied. The values and bounds are original/input values, while their units, when provided, are scaled to match the model run time steps and may differ from the original units in the model when @timescale of the parameter is different from the model run time step.")
        else
            print_info(nothing, @__FILE__, @__LINE__, "→→→    $(nameof(typeof(_sc))) scaling applied. The values and bounds are scaled values, while their units, when provided, are scaled to match the model run time steps and may differ from the original units in the model when @timescale of the parameter is different from the model run time step. Check info.models.parameter_table for interpreting parameter values in original/input units.")
        end
    end
    for (i,n) in enumerate(p_names)
        in_range = checkInRange(n, parameter_values[i], lower_bounds[i], upper_bounds[i], show_info)
        if !in_range
            error("$(String(n)) => value=$(parameter_values[i]) [lower_bound=$(lower_bounds[i]), upper_bound=$(upper_bounds[i])] violates the parameter bounds requirement (lower_bound <= value <= upper_bound). Fix the bounds in the given model ($(model_names[i])) or in the parameters input to continue.")
        end
        if show_info
            ps = String(n)
            if !isnothing(model_names)
                ps = "`$(String(model_names[i]))`.jl: `$(String(n))`" 
            end
            units_str = ""
            if !isnothing(p_units)
                units_str = p_units[i] == "" ? "unitless" : "$(p_units[i])"
                units_str = "(units: $(units_str))"
            end
            print_info(nothing, @__FILE__, @__LINE__, "$(ps) => $(parameter_values[i]) [$(lower_bounds[i]), $(upper_bounds[i])] $units_str", n_f=6)

        end
    end
end



"""
    scaleParameters(parameter_table, <: ParameterScaling)

Scale parameters from the input table using default scaling factors.

# Arguments
- `parameter_table`: Table containing parameters to be scaled
- `ParameterScaling`: Type indicating the scaling strategy to be used
    - `::ScaleDefault`: Type indicating scaling by default values
    - `::ScaleBounds`: Type parameter indicating scaling by parameter bounds 
    - `::ScaleNone`: Type parameter indicating no scaling should be applied


# Returns
Scaled parameters and their bounds according to default scaling factors
"""
function scaleParameters end

function scaleParameters(parameter_table, _sc::ScaleNone)
    init = copy(parameter_table.initial)
    ub = copy(parameter_table.upper)  # upper bounds
    lb = copy(parameter_table.lower)   # lower bounds
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end
    
function scaleParameters(parameter_table, _sc::ScaleDefault)
    init = abs.(copy(parameter_table.initial))
    ub = copy(parameter_table.upper ./ init)   # upper bounds
    lb = copy(parameter_table.lower ./ init)   # lower bounds
    init = parameter_table.initial ./ init
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end

function scaleParameters(parameter_table, _sc::ScaleBounds)
    init = copy(parameter_table.initial)
    ub = copy(parameter_table.upper)  # upper bounds
    lb = copy(parameter_table.lower)   # lower bounds
    init = (init - lb)  ./ (ub - lb)
    lb = zero(lb)
    ub = one.(ub)
    checkParameterBounds(parameter_table.name, init, lb, ub, _sc, p_units=parameter_table.units, show_info=true, model_names=parameter_table.model_approach)
    return (init, lb, ub)
end


"""
    updateModelParameters(parameter_table::Table, selected_models::Tuple, parameter_vector::AbstractArray)
    updateModelParameters(parameter_table::Table, selected_models::LongTuple, parameter_vector::AbstractArray)
    updateModelParameters(parameter_to_index::NamedTuple, selected_models::Tuple, parameter_vector::AbstractArray)

Updates the parameters of SINDBAD models based on the provided parameter vector without mutating the original table of parameters.

# Arguments:
- `parameter_table::Table`: A table of SINDBAD model parameters selected for optimization. Contains parameter names, bounds, and scaling information.
- `selected_models::Tuple`: A tuple of all models selected in the given model structure.
- `selected_models::LongTuple`: A long tuple of models, which is converted into a standard tuple for processing.
- `parameter_vector::AbstractArray`: A vector of parameter values to update the models.
- `parameter_to_index::NamedTuple`: A mapping of parameter indices to model names, used for updating specific parameters in the models.

# Returns:
- A tuple of updated models with their parameters modified according to the provided `parameter_vector`.

# Notes:
- The function supports multiple input formats for `selected_models` (e.g., `LongTuple`, `NamedTuple`) and adapts accordingly.
- If `parameter_table` is provided, the function uses it to find and update the relevant parameters for each model.
- The `parameter_to_index` variant allows for a more direct mapping of parameters to models, bypassing the need for a parameter table.
- The generated function variant (`::Val{p_vals}`) is used for compile-time optimization of parameter updates.

# Examples:
1. **Using `parameter_table` and `selected_models`:**
```julia
updated_models = updateModelParameters(parameter_table, selected_models, parameter_vector)
```

2. **Using `parameter_to_index` for direct mapping:**
```julia
updated_models = updateModelParameters(parameter_to_index, selected_models, parameter_vector)
```

# Implementation Details:
- The function iterates over the models in `selected_models` and updates their parameters based on the provided `parameter_vector`.
- For each model, it checks if the parameter belongs to the model's approach (using `parameter_table.model_approach`) and updates the corresponding value.
- The `parameter_to_index` variant uses a mapping to directly replace parameter values in the models.
- The generated (with @generated) function variant (`::Val{p_vals}`) creates a compile-time optimized update process for specific parameters and models.
"""
function updateModelParameters end

function updateModelParameters(parameter_table::Table, selected_models::LongTuple, parameter_vector::AbstractArray)
    selected_models = to_tuple(selected_models)
    return updateModelParameters(parameter_table, selected_models, parameter_vector)
end

function updateModelParameters(parameter_table::Table, selected_models::Tuple, parameter_vector::AbstractArray)
    updatedModels = eltype(selected_models)[]
    namesApproaches = nameof.(typeof.(selected_models)) # a better way to do this?
    for (idx, modelName) ∈ enumerate(namesApproaches)
        approachx = selected_models[idx]
        model_obj = approachx
        newapproachx = if modelName in parameter_table.model_approach
            vars = propertynames(approachx)
            newvals = Pair[]
            for var ∈ vars
                pindex = findall(row -> row.name == var && row.model_approach == modelName,
                    parameter_table)
                pval = getproperty(approachx, var)
                if !isempty(pindex)
                    pval = parameter_vector[pindex[1]]
                end
                push!(newvals, var => pval)
            end
            typeof(approachx)(; newvals...)
        else
            approachx
        end
        push!(updatedModels, newapproachx)
    end
    return (updatedModels...,)
end

function updateModelParameters(parameter_to_index::NamedTuple, selected_models, parameter_vector::AbstractArray)
    map(selected_models) do model
          modelmap = parameter_to_index[nameof(typeof(model))]
          varsreplace = map(i->parameter_vector[i],modelmap)
          ConstructionBase.setproperties(model,varsreplace)
    end
end

"""
    updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)

Updates the parameters of selected models using the provided parameter vector.

# Arguments
- `parameter_vector`: Vector containing the new parameter values
- `parameter_updater`: Function or object that defines how parameters should be updated
- `parameter_scaling_type`: Specifies the type of scaling to be applied to parameters
- `selected_models`: Collection of models whose parameters need to be updated

# Returns
Updated models with new parameter values
"""
function updateModels(parameter_vector, parameter_updater, parameter_scaling_type, selected_models)
    parameter_vector = backScaleParameters(parameter_vector, parameter_updater, parameter_scaling_type)
    updated_models = updateModelParameters(parameter_updater, selected_models, parameter_vector)
    return updated_models
end