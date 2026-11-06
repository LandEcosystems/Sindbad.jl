export getCacheFromOutput
export getOutputFromCache

function getCacheFromOutput(loc_output, ::MachineLearningGradType)
    return loc_output
end

function getCacheFromOutput(loc_output, ::PolyesterForwardDiffGrad)
    return getCacheFromOutput(loc_output, ForwardDiffGrad())
end

"""
    getCacheFromOutput(loc_output, ::MachineLearningGradType)
    getCacheFromOutput(loc_output, ::ForwardDiffGrad)
    getCacheFromOutput(loc_output, ::PolyesterForwardDiffGrad)

Returns the appropriate Cache type based on the automatic differentiation or finite differences package being used.

# Arguments
- `loc_output`: The local output
- Second argument specifies the differentiation method:
    * `ForwardDiffGrad`: Uses ForwardDiff.jl for automatic differentiation
    * `MachineLearningGradType`: All other libraries, e.g., FiniteDiff.jl,FiniteDifferences.jl, etc.  for gradient calculations
    * `PolyesterForwardDiffGrad`: Uses PolyesterForwardDiff.jl for automatic differentiation
  
"""
function getCacheFromOutput end


function getOutputFromCache(loc_output, _, ::MachineLearningGradType)
    return loc_output
end

function getOutputFromCache(loc_output, new_params, ::PolyesterForwardDiffGrad)
    return getOutputFromCache(loc_output, new_params, ForwardDiffGrad())
end


"""
    getOutputFromCache(loc_output, _, ::MachineLearningGradType)
    getOutputFromCache(loc_output, new_params, ::ForwardDiffGrad)
    getOutputFromCache(loc_output, new_params, ::PolyesterForwardDiffGrad)

Retrieves output values from `Cache` based on the differentiation method being used.

# Arguments
- `loc_output`: The cached output values
- `_` or `new_params`: Additional parameters (only used with ForwardDiff)
- Third argument specifies the differentiation method:
  * `MachineLearningGradType`: Returns cached output directly when using other libraries, e.g., FiniteDiff.jl, FiniteDifferences.jl, etc.
  * `ForwardDiffGrad`: Processes cached output with new parameters when using ForwardDiff.jl, returns `get_tmp.(loc_output, (new_params,))`
  * `PolyesterForwardDiffGrad`: Calls cached output with new parameters using ForwardDiff.jl

"""
function getOutputFromCache end
export GradientLand
export getGradientLand
export gradientParameterType
export selectLand

"""
    GradientLand{T,L}

The initial land of a site in the types that the land takes when the parameters are of
type `T`, such as the duals that ForwardDiff passes to the loss.

# Fields:
- `land`: the initial land with the values of the Float32 land and the types of the
  land after a time step with parameters of type `T`

# Notes:
- `selectLand` uses it only when the parameters are of type `T`, so the land keeps one
  type from the first time step on and is never converted during a run.
"""
struct GradientLand{T,L}
    land::L
end

GradientLand{T}(land::L) where {T,L} = GradientLand{T,L}(land)

"""
    gradientParameterType(gradient_lib, n_parameters, num_type, gradient_options)

Returns the element type of the parameters that `gradientSite` passes to the loss for
`n_parameters` parameters of type `num_type`, or `nothing` when it is not known before
the gradient is computed.

# Arguments:
- `gradient_lib`: the gradient library, a subtype of `MachineLearningGradType`
- `n_parameters`: the number of parameters of the gradient
- `num_type`: the number type of the model, e.g., `Float32`
- `gradient_options`: the options of the gradient, e.g., `chunk_size`

# Notes:
- Only the ForwardDiff extension knows the type, since it fixes the tag and the chunk of
  its duals. Every other library returns `nothing`.
"""
function gradientParameterType end

gradientParameterType(::MachineLearningGradType, _, _, _) = nothing

"""
    getGradientLand(gradient_lib, loc_land, selected_models, parameter_to_index, parameter_table, loc_forcing_t, model_helpers, num_type, gradient_options)

Returns a `GradientLand` with the values of `loc_land` in the types that the land takes
with the parameters of `gradient_lib`, or `nothing` when that type is not known.

# Arguments:
- `gradient_lib`: the gradient library, a subtype of `MachineLearningGradType`
- `loc_land`: the initial land of a location, from `prepTEM`
- `selected_models`: the models of the forward run
- `parameter_to_index`: the indices of the parameters per model, from `getParameterIndices`
- `parameter_table`: the table of the learned parameters
- `loc_forcing_t`: the forcing of one location for one time step
- `model_helpers`: the model helpers of `tem_info`
- `num_type`: the number type of the model, e.g., `Float32`
- `gradient_options`: the options of the gradient, e.g., `chunk_size`

# Notes:
- The models get the initial parameters in the type of the gradient, and precompute and
  compute run until the types of the land stop changing. A field computed from a field
  that is written later in a time step only takes its new type in the next step.
- Only the types are taken from those steps. Every value comes from `loc_land`, so the
  land starts from the same values as the Float32 land.
- A process whose result type depends on a runtime branch would keep changing the land
  type. Then a warning is shown and `nothing` is returned, so the Float32 land is used.
"""
function getGradientLand(gradient_lib, loc_land, selected_models, parameter_to_index, parameter_table, loc_forcing_t, model_helpers, num_type, gradient_options)
    T = gradientParameterType(gradient_lib, length(parameter_table.initial), num_type, gradient_options)
    isnothing(T) && return nothing
    parameter_vector = T.(num_type.(parameter_table.initial))
    models = updateModelParameters(parameter_to_index, selected_models, parameter_vector)
    land = precomputeTEM(models, loc_forcing_t, loc_land, model_helpers)
    land_type = typeof(land)
    for _ ∈ 1:10
        land = computeTEM(models, loc_forcing_t, land, model_helpers)
        if typeof(land) === land_type
            return GradientLand{T}(matchLandTypes(loc_land, land))
        end
        land_type = typeof(land)
    end
    @warn "The land types did not settle within 10 time steps with parameters of type " *
          "$(T). The Float32 land is used for the gradient, so the land changes type " *
          "during a run. Check the processes for result types that depend on a branch."
    return nothing
end

"""
    matchLandTypes(values, template)

Returns `values` with every field converted to the type of the same field in `template`,
recursing into NamedTuples and Tuples. A field missing in `template` is kept as it is.
"""
function matchLandTypes end

function matchLandTypes(values::NamedTuple, template::NamedTuple)
    names = keys(values)
    return NamedTuple{names}(map(names) do name
        value = getfield(values, name)
        haskey(template, name) ? matchLandTypes(value, getfield(template, name)) : value
    end)
end

function matchLandTypes(values::Tuple, template::Tuple)
    length(values) == length(template) || return values
    return map(matchLandTypes, values, template)
end

matchLandTypes(value, template) = typeof(value) === typeof(template) ? value : convert(typeof(template), value)

"""
    selectLand(land, gradient_land, parameters)

Returns the land of `gradient_land` when `parameters` are of its type, and `land`
otherwise, e.g., for Float32 parameters or a gradient library with other duals.

# Notes:
- The choice is made by dispatch on the types, so it is resolved when compiling.
"""
function selectLand end

selectLand(land, ::Nothing, _) = land

selectLand(_, gradient_land::GradientLand{T}, ::AbstractArray{T}) where {T} = gradient_land.land

selectLand(land, ::GradientLand, _) = land
