export getDataWithoutNaN
export getData
export getModelOutputView
export prepCostOptions

"""
    aggregateData(dat, cost_option, ::TimeSpace)
    aggregateData(dat, cost_option, ::SpaceTime)

aggregate the data based on the order of aggregation.

# Arguments:
- `dat`: a data array/vector to aggregate
- `cost_option`: information for a observation constraint on how it should be used to calculate the loss/metric of model performance
- `::TimeSpace`: appropriate type dispatch for the order of aggregation
- `::SpaceTime`: appropriate type dispatch for the order of aggregation
"""
function aggregateData end

function aggregateData(dat, cost_option, ::TimeSpace)
    dat = time_resample(dat, cost_option.temporal_aggr)
    dat = doSpatialAggregation(dat, cost_option, cost_option.spatial_data_aggr)
    return dat
end

function aggregateData(dat, cost_option, ::SpaceTime)
    dat = doSpatialAggregation(dat, cost_option, cost_option.spatial_data_aggr)
    dat = time_resample(dat, cost_option.temporal_aggr)
    return dat
end


"""
    maskWithObservation(dat, obs_mask)

Return a copy of `dat` that is `NaN` wherever `obs_mask` is false.

# Arguments:
- `dat`: a data array/vector at the native time resolution of the observations
- `obs_mask`: the valid points of the observation and its uncertainty at the same
  resolution
"""
function maskWithObservation(dat, obs_mask)
    nan_value = convert(eltype(dat), NaN)
    return ifelse.(reshape(obs_mask, size(dat)), dat, nan_value)
end


"""
    aggregateObsData(y, yσ, obs_mask, cost_option, ::DoAggrObs)
    aggregateObsData(y, yσ, _, _, ::DoNotAggrObs)

Return the observation and its uncertainty at the resolution used in the cost. When
the observations are aggregated, the points where either of them is invalid are
excluded from the aggregation of both.

# Arguments:
- `y`: observation data
- `yσ`: observational uncertainty data
- `obs_mask`: the valid points of `y` and `yσ` at their native resolution
- `cost_option`: information for a observation constraint on how it should be used to calculate the loss/metric of model performance
- `::DoAggrObs`: appropriate type dispatch for aggregation of observation data
- `::DoNotAggrObs`: appropriate type dispatch for not aggregating observation data
"""
function aggregateObsData end

function aggregateObsData(y, yσ, obs_mask, cost_option, ::DoAggrObs)
    y = aggregateData(maskWithObservation(y, obs_mask), cost_option, cost_option.aggr_order)
    yσ = aggregateData(maskWithObservation(yσ, obs_mask), cost_option, cost_option.aggr_order)
    return y, yσ
end

function aggregateObsData(y, yσ, _, _, ::DoNotAggrObs)
    return y, yσ
end


"""
    aggregateModelData(ŷ, cost_option, ::DoAggrObs)
    aggregateModelData(ŷ, cost_option, ::DoNotAggrObs)

Return the model output at the resolution used in the cost. When the observations
are aggregated, the model is first masked by the valid observations so that both
are aggregated over the same time steps.

# Arguments:
- `ŷ`: model simulation data/estimate
- `cost_option`: information for a observation constraint on how it should be used to calculate the loss/metric of model performance
- `::DoAggrObs`: appropriate type dispatch for aggregation of observation data
- `::DoNotAggrObs`: appropriate type dispatch for not aggregating observation data
"""
function aggregateModelData end

function aggregateModelData(ŷ, cost_option, ::DoAggrObs)
    ŷ = maskWithObservation(ŷ, cost_option.obs_mask)
    return aggregateData(ŷ, cost_option, cost_option.aggr_order)
end

function aggregateModelData(ŷ, cost_option, ::DoNotAggrObs)
    return aggregateData(ŷ, cost_option, cost_option.aggr_order)
end


"""
    applySpatialWeight(y, yσ, ŷ, cost_option, ::DoSpatialWeight)
    applySpatialWeight(y, yσ, ŷ, _, ::DoNotSpatialWeight)

return model and obs data after applying the area weight.

# Arguments:
- `y`: observation data
- `yσ`: observational uncertainty data
- `ŷ`: model simulation data/estimate
- `::DoSpatialWeight`: type dispatch for doing area weight
- `::DoNotSpatialWeight`: type dispatch for not doing area weight
"""
function applySpatialWeight end

function applySpatialWeight(y, yσ, ŷ, cost_option, ::DoSpatialWeight)
    yweight = observations[cost_option.obs_ind+3]
    y .= y .* yweight
    yσ .= yσ .* yweight
    ŷ .= ŷ .* yweight
    return y, yσ, ŷ
end

function applySpatialWeight(y, yσ, ŷ, _, ::DoNotSpatialWeight)
    return y, yσ, ŷ
end

"""
    getHarmonizedData(y, yσ, ŷ, cost_option)

Return the observation, its uncertainty and the model output at the resolution used
in the cost. The observations are already at that resolution as they are prepared
once in `prepCostOptions`, so only the model output is aggregated here.
"""
function getHarmonizedData(y, yσ, ŷ, cost_option)
    ŷ = aggregateModelData(ŷ, cost_option, cost_option.aggr_obs)
    (y, yσ, ŷ) = applySpatialWeight(y, yσ, ŷ, cost_option, cost_option.spatial_weight)
    return (y, yσ, ŷ)
end

"""
    getData(model_output::LandWrapper, observations, cost_option)
    getData(model_output::NamedTuple, observations, cost_option)
    getData(model_output::AbstractArray, observations, cost_option)

# Arguments:
- `model_output`: a collection of SINDBAD model output time series as a time series of stacked land NT or as a preallocated array.
- `observations`: a NT or a vector of arrays of observations, their uncertainties, and mask to use for calculation of performance metric/loss
- `cost_option`: information for a observation constraint on how it should be used to calculate the loss/metric of model performance

# Notes:
- The observations are taken from `cost_option.obs_y` and `cost_option.obs_yσ`,
  which `prepCostOptions` prepares from `observations` at the resolution of the cost.
"""
function getData end

function getData(model_output::LandWrapper, observations, cost_option)
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷField = getproperty(model_output, mod_field)
    ŷ = getproperty(ŷField, mod_subfield)
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
        y = y[:]
        yσ = yσ[:]
    end
    # ymask = observations[obs_ind + 2]
    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end


function getData(model_output::NamedTuple, observations, cost_option)
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷ = model_output
    sf_name = mod_subfield
    if !hasproperty(model_output, sf_name)
        sf_name = Symbol(String(mod_field) * "__" * String(mod_subfield))
    end
    ŷ = getproperty(model_output, sf_name)
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
    end
    # ymask = observations[obs_ind + 2]

    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end

function getData(model_output::AbstractArray, observations, cost_option)
    ŷ = model_output[cost_option.mod_ind]
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
    end
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end


"""
     getModelOutputView(_dat::AbstractArray{<:Any,N}) where N


"""
function getModelOutputView(_dat::AbstractArray{<:Any,N}) where N
    dim = 1
    inds = map(size(_dat)) do _
        ind = dim == 2 ? 1 : Colon()
        dim += 1
        ind
    end
    @view _dat[inds...]
end


"""
    doSpatialAggregation(dat, _, ::ConcatData)

# Arguments:
- `dat`: a data array/vector to aggregate
- `_`: unused argument
- `::ConcatData`: A type indicating that the data should not be aggregated spatially
"""
function doSpatialAggregation(dat, _, ::ConcatData)
    return dat
end


"""
    prepCostOptions(observations, cost_options, ::CostMethod)

Prepares cost options for optimization by filtering variables with insufficient data points and setting up the required configurations.

# Arguments:
- `observations`: A NamedTuple or a vector of arrays containing observation data, uncertainties, and masks used for calculating performance metrics or loss.
- `cost_options`: A table listing each observation constraint and its configuration for calculating the loss or performance metric.
- `::CostMethod`: A type indicating the cost function method. 

# Returns:
- A filtered table of `cost_options` containing only valid variables with sufficient data points.

# cost methods:
$(methods_of(CostMethod))

---
# Extended help

# Examples
```jldoctest
julia> using Sindbad

julia> # Prepare cost options for optimization
julia> # filtered_cost_options = prepCostOptions(observations, cost_options, CostModelObs())
```

# Notes:
- The function iterates through the observation variables and checks if the number of valid data points meets the minimum threshold specified in `cost_options.min_data_points`.
- Variables with insufficient data points are excluded from the returned `cost_options`.
- The function modifies the `cost_options` table by adding:
  - `obs_mask`: The valid points of the observation and its uncertainty at their
    native resolution. With `aggr_obs`, the model output is masked by it before it
    is aggregated.
  - `obs_y` and `obs_yσ`: The observation and its uncertainty at the resolution of
    the cost. They are aggregated here once, and not in every cost evaluation.
  - `valids`: Indices of valid data points for each variable at the resolution of
    the cost.
  - `is_valid`: A boolean flag indicating whether the variable meets the minimum data point requirement.
- Unnecessary fields such as `min_data_points`, `temporal_data_aggr`, and `aggr_func` are removed from the final `cost_options`.
"""
function prepCostOptions end


function prepCostOptions(observations, cost_options)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObsPriors)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObs)
    obs_masks = []
    obs_ys = []
    obs_yσs = []
    valids = []
    is_valid = []
    for cost_option in Table(cost_options)
        y = observations[cost_option.obs_ind]
        yσ = observations[cost_option.obs_ind+1]
        obs_mask = Array(.!is_invalid_number.(y .* yσ))
        y, yσ = aggregateObsData(y, yσ, obs_mask, cost_option, cost_option.aggr_obs)
        idxs = Array(.!is_invalid_number.(y .* yσ))
        push!(is_valid, sum(idxs) >= cost_option.min_data_points)
        push!(obs_masks, obs_mask)
        push!(obs_ys, y)
        push!(obs_yσs, yσ)
        push!(valids, idxs)
    end
    cost_options = set_namedtuple_field(cost_options, (:obs_mask, obs_masks))
    cost_options = set_namedtuple_field(cost_options, (:obs_y, obs_ys))
    cost_options = set_namedtuple_field(cost_options, (:obs_yσ, obs_yσs))
    cost_options = set_namedtuple_field(cost_options, (:valids, valids))
    cost_options = set_namedtuple_field(cost_options, (:is_valid, is_valid))
    cost_options = drop_namedtuple_fields(cost_options, (:min_data_points, :temporal_data_aggr, :aggr_func,))
    cost_option_table = Table(cost_options)
    cost_options_table_filtered = filter(row -> row.is_valid === true , cost_option_table)
    return cost_options_table_filtered
end
