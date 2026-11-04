export combineMetric
export getDataWithoutNaN
export metricVector

"""
    combineMetric(metric_vector::AbstractArray, ::MetricSum)
    combineMetric(metric_vector::AbstractArray, ::MetricMinimum)
    combineMetric(metric_vector::AbstractArray, ::MetricMaximum)
    combineMetric(metric_vector::AbstractArray, percentile_value::T)

combines the metric from all constraints based on the type of combination.

# Arguments:
- `metric_vector`: a vector of metrics for variables

## methods for combining the metric
- `::MetricSum`: return the total sum as the metric.
- `::MetricMinimum`: return the minimum of the `metric_vector` as the metric.
- `::MetricMaximum`: return the maximum of the `metric_vector` as the metric.
- `percentile_value::T`: `percentile_value^th` percentile of metric of each constraint as the overall metric

# Examples
```jldoctest
julia> using Sindbad

julia> metric_vec = [0.5, 0.7, 0.3]
3-element Vector{Float64}:
 0.5
 0.7
 0.3

julia> combineMetric(metric_vec, MetricSum())
1.5

julia> combineMetric(metric_vec, MetricMinimum())
0.3

julia> combineMetric(metric_vec, MetricMaximum())
0.7
```

"""
function combineMetric end

function combineMetric(metric_vector::AbstractArray, ::MetricSum)
    return sum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, ::MetricMinimum)
    return minimum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, ::MetricMaximum)
    return maximum(metric_vector)
end

function combineMetric(metric_vector::AbstractArray, percentile_value::T) where {T<:Real}
    return percentile(metric_vector, percentile_value)
end



"""
    getDataWithoutNaN(y, yσ, ŷ, idxs)
    getDataWithoutNaN(y, yσ, ŷ)

return model and obs data excluding for the common `NaN` or for the valid pixels `idxs`.

# Arguments:
- `y`: observation data
- `yσ`: observational uncertainty data
- `ŷ`: model simulation data/estimate
- `idxs`: indices of valid data points

# Examples
```jldoctest
julia> using Sindbad

julia> y = [1.0, NaN, 3.0, 4.0]
4-element Vector{Float64}:
   1.0
 NaN
   3.0
   4.0

julia> yσ = [0.1, 0.2, 0.1, 0.1]
4-element Vector{Float64}:
 0.1
 0.2
 0.1
 0.1

julia> ŷ = [1.1, 2.0, 2.9, 4.1]
4-element Vector{Float64}:
 1.1
 2.0
 2.9
 4.1

julia> y_clean, yσ_clean, ŷ_clean = getDataWithoutNaN(y, yσ, ŷ)
([1.0, 3.0, 4.0], [0.1, 0.1, 0.1], [1.1, 2.9, 4.1])
```
"""
function getDataWithoutNaN end

function getDataWithoutNaN(y, yσ, ŷ, idxs)
    y_view = @view y[idxs] 
    yσ_view = @view yσ[idxs] 
    ŷ_view = @view ŷ[idxs] 
    return (y_view, yσ_view, ŷ_view)
end

function getDataWithoutNaN(y, yσ, ŷ)
    @debug sum(is_invalid_number.(y)), sum(is_invalid_number.(yσ)), sum(is_invalid_number.(ŷ))
    idxs = (.!isnan.(y .* yσ .* ŷ)) # TODO this has to be run because LandWrapper produces a vector. So, dispatch with the inefficient versions without idxs argument
    return y[idxs], yσ[idxs], ŷ[idxs]
end


"""
    metricVector(model_output::LandWrapper, observations, cost_options)
    metricVector(model_output, observations, cost_options)
   
returns a vector of metrics for variables in cost_options.variable.   

# Arguments:
- `observations`: a NT or a vector of arrays of observations, their uncertainties, and mask to use for calculation of performance metric/loss
- `model_output`: a collection of SINDBAD model output time series as a time series of stacked land NT
- `cost_options`: a table listing each observation constraint and how it should be used to calculate the loss/metric of model performance

# Examples
```jldoctest
julia> using Sindbad

julia> # Calculate metrics for all cost options
julia> # metric_vec = metricVector(model_output, observations, cost_options)
```
"""
function metricVector end

# function metricVector(model_output, observations, cost_options)
#     loss_vector = map(cost_options) do cost_option
#         @debug "***cost for $(cost_option.variable)***"
#         lossMetric = cost_option.cost_metric
#         (y, yσ, ŷ) = getData(model_output, observations, cost_option)
#         (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
#         @debug "size y, yσ, ŷ", size(y), size(yσ), size(ŷ)
#         # (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
#         metr = metric(lossMetric, ŷ, y, yσ) * cost_option.cost_weight
#         if isnan(metr)
#             metr = oftype(metr, 1e19)
#         end
#         @debug "$(cost_option.variable) => $(nameof(typeof(lossMetric))): $(metr)"
#         metr
#     end
#     @debug "\n-------------------\n"
#     return loss_vector
# end

function metricVector(model_output::LandWrapper, observations, cost_options)
    loss_vector = map(cost_options) do cost_option
        @debug "$(cost_option.variable)"
        lossMetric = cost_option.cost_metric
        (y, yσ, ŷ) = getData(model_output, observations, cost_option)
        @debug "size y, yσ, ŷ", size(y), size(yσ), size(ŷ), size(idxs)
        (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ) ## cannot use the valids because LandWrapper produces vector
        metr = metric(lossMetric, ŷ, y, yσ) * cost_option.cost_weight
        if isnan(metr)
            metr = oftype(metr, 1e19)
        end
        @debug "$(cost_option.variable) => $(nameof(typeof(lossMetric))): $(metr)"
        metr
    end
    @debug "\n-------------------\n"
    return loss_vector
end

## TODO: set penality for whole zero series
function metricVector(model_output, observations, cost_options)
    loss_vector = map(cost_options) do cost_option
        @debug "***cost for $(cost_option.variable)***"
        lossMetric = cost_option.cost_metric
        (y, yσ, ŷ) = getData(model_output, observations, cost_option)
        (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
        @debug "size y, yσ, ŷ", size(y), size(yσ), size(ŷ)
        # (y, yσ, ŷ) = getDataWithoutNaN(y, yσ, ŷ, cost_option.valids)
        if hasproperty(cost_option, :time_scale) && cost_option.time_scale !== nothing
            metr = metric(lossMetric, ŷ, y, yσ, cost_option.time_scale) * cost_option.cost_weight
        else
            metr = metric(lossMetric, ŷ, y, yσ) * cost_option.cost_weight
        end
        if isnan(metr)
            metr = oftype(metr, 1e19)
        end
        ### Optional >> it affects the optimization.
        # if the absolute ŷ (carbon and water fluxes) is very small, then set the metric to be 1e5 as a penalty, because the model is not working properly
        tol = oftype(metr, 1e-3)
        if all(x -> abs(x) < tol, ŷ)
            metr = oftype(metr, 1e5)
        end
        @debug "$(cost_option.variable) => $(nameof(typeof(lossMetric))): $(metr)"
        metr
    end
    @debug "\n-------------------\n"
    return loss_vector
end
