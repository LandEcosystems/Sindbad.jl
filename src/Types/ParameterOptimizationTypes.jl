
export ParameterOptimizationTypes
abstract type ParameterOptimizationTypes <: SindbadTypes end
purpose(::Type{ParameterOptimizationTypes}) = "Abstract type for optimization related functions and methods in SINDBAD"

# ------------------------- optimization TEM and algorithm -------------------------
export ParameterOptimizationMethod
export BayesOptKMaternARD5
export CMAEvolutionStrategyCMAES
export EvolutionaryCMAES
export OptimLBFGS
export OptimBFGS
export OptimizationBBOadaptive
export OptimizationBBOxnes
export OptimizationBFGS
export OptimizationFminboxGradientDescent
export OptimizationFminboxGradientDescentFD
export OptimizationGCMAESDef
export OptimizationGCMAESFD
export OptimizationMultistartOptimization
export OptimizationNelderMead
export OptimizationQuadDirect

abstract type ParameterOptimizationMethod <: ParameterOptimizationTypes end
purpose(::Type{ParameterOptimizationMethod}) = "Abstract type for optimization methods in SINDBAD"

struct BayesOptKMaternARD5 <: ParameterOptimizationMethod end
purpose(::Type{BayesOptKMaternARD5}) = "Bayesian Optimization using Matern 5/2 kernel with Automatic Relevance Determination from BayesOpt.jl"

struct CMAEvolutionStrategyCMAES <: ParameterOptimizationMethod end
purpose(::Type{CMAEvolutionStrategyCMAES}) = "Covariance Matrix Adaptation Evolution Strategy (CMA-ES) from CMAEvolutionStrategy.jl"
requires_package(::Type{CMAEvolutionStrategyCMAES}) = "CMAEvolutionStrategy"

struct EvolutionaryCMAES <: ParameterOptimizationMethod end
purpose(::Type{EvolutionaryCMAES}) = "Evolutionary version of CMA-ES optimization from Evolutionary.jl"

struct OptimLBFGS <: ParameterOptimizationMethod end
purpose(::Type{OptimLBFGS}) = "Limited-memory Broyden-Fletcher-Goldfarb-Shanno (L-BFGS) from Optim.jl"

struct OptimBFGS <: ParameterOptimizationMethod end
purpose(::Type{OptimBFGS}) = "Broyden-Fletcher-Goldfarb-Shanno (BFGS) from Optim.jl"

struct OptimizationBBOadaptive <: ParameterOptimizationMethod end
purpose(::Type{OptimizationBBOadaptive}) = "Black Box Optimization with adaptive parameters from Optimization.jl"
requires_package(::Type{OptimizationBBOadaptive}) = "Optimization"

struct OptimizationBBOxnes <: ParameterOptimizationMethod end
purpose(::Type{OptimizationBBOxnes}) = "Black Box Optimization using Natural Evolution Strategy (xNES) from Optimization.jl"
requires_package(::Type{OptimizationBBOxnes}) = "Optimization"

struct OptimizationBFGS <: ParameterOptimizationMethod end
purpose(::Type{OptimizationBFGS}) = "BFGS optimization with box constraints from Optimization.jl"
requires_package(::Type{OptimizationBFGS}) = "Optimization"

struct OptimizationFminboxGradientDescent <: ParameterOptimizationMethod end
purpose(::Type{OptimizationFminboxGradientDescent}) = "Gradient descent optimization with box constraints from Optimization.jl"
requires_package(::Type{OptimizationFminboxGradientDescent}) = "Optimization"

struct OptimizationFminboxGradientDescentFD <: ParameterOptimizationMethod end
purpose(::Type{OptimizationFminboxGradientDescentFD}) = "Gradient descent optimization with box constraints using forward differentiation from Optimization.jl"
requires_package(::Type{OptimizationFminboxGradientDescentFD}) = "Optimization"

struct OptimizationGCMAESDef <: ParameterOptimizationMethod end
purpose(::Type{OptimizationGCMAESDef}) = "Global CMA-ES optimization with default settings from Optimization.jl"
requires_package(::Type{OptimizationGCMAESDef}) = "Optimization"

struct OptimizationGCMAESFD <: ParameterOptimizationMethod end
purpose(::Type{OptimizationGCMAESFD}) = "Global CMA-ES optimization using forward differentiation from Optimization.jl"
requires_package(::Type{OptimizationGCMAESFD}) = "Optimization"

struct OptimizationMultistartOptimization <: ParameterOptimizationMethod end
purpose(::Type{OptimizationMultistartOptimization}) = "Multi-start optimization to find global optimum from Optimization.jl"
requires_package(::Type{OptimizationMultistartOptimization}) = "Optimization"

struct OptimizationNelderMead <: ParameterOptimizationMethod end
purpose(::Type{OptimizationNelderMead}) = "Nelder-Mead simplex optimization method from Optimization.jl"
requires_package(::Type{OptimizationNelderMead}) = "Optimization"

struct OptimizationQuadDirect <: ParameterOptimizationMethod end
purpose(::Type{OptimizationQuadDirect}) = "Quadratic Direct optimization method from Optimization.jl"
requires_package(::Type{OptimizationQuadDirect}) = "Optimization"

# ------------------------- global sensitivity analysis -------------------------

export GSAMethod
export GSAMorris
export GSASobol
export GSASobolDM

abstract type GSAMethod <: ParameterOptimizationTypes end
purpose(::Type{GSAMethod}) = "Abstract type for global sensitivity analysis methods in SINDBAD"

struct GSAMorris <: GSAMethod end
purpose(::Type{GSAMorris}) = "Morris method for global sensitivity analysis"

struct GSASobol <: GSAMethod end
purpose(::Type{GSASobol}) = "Sobol method for global sensitivity analysis"

struct GSASobolDM <: GSAMethod end
purpose(::Type{GSASobolDM}) = "Sobol method with derivative-based measures for global sensitivity analysis"

# ------------------------- loss calculation -------------------------

export CostMethod
export CostModelObs
export CostModelObsLandTS
export CostModelObsMT
export CostModelObsPriors

abstract type CostMethod <: ParameterOptimizationTypes end
purpose(::Type{CostMethod}) = "Abstract type for cost calculation methods in SINDBAD"

struct CostModelObs <: CostMethod end
purpose(::Type{CostModelObs}) = "cost calculation between model output and observations"

struct CostModelObsLandTS <: CostMethod end
purpose(::Type{CostModelObsLandTS}) = "cost calculation between land model output and time series observations"

struct CostModelObsMT <: CostMethod end
purpose(::Type{CostModelObsMT}) = "multi-threaded cost calculation between model output and observations"

struct CostModelObsPriors <: CostMethod end
purpose(::Type{CostModelObsPriors}) = "cost calculation between model output, observations, and priors. NOTE THAT THIS METHOD IS JUST A PLACEHOLDER AND DOES NOT CALCULATE PRIOR COST PROPERLY YET"

# ------------------------- parameter scaling -------------------------

export ParameterScaling
export ScaleNone
export ScaleDefault
export ScaleBounds

abstract type ParameterScaling <: ParameterOptimizationTypes end
purpose(::Type{ParameterScaling}) = "Abstract type for parameter scaling methods in SINDBAD"

struct ScaleNone <: ParameterScaling end
purpose(::Type{ScaleNone}) = "No parameter scaling applied"

struct ScaleDefault <: ParameterScaling end
purpose(::Type{ScaleDefault}) = "Scale parameters relative to default values"

struct ScaleBounds <: ParameterScaling end
purpose(::Type{ScaleBounds}) = "Scale parameters relative to their bounds"


# ------------------------- data aggregation for metric calculation -------------------------

export DataAggrOrder
export SpaceTime
export TimeSpace

abstract type DataAggrOrder <: ParameterOptimizationTypes end
purpose(::Type{DataAggrOrder}) = "Abstract type for data aggregation order in SINDBAD"

struct SpaceTime <: DataAggrOrder end
purpose(::Type{SpaceTime}) = "Aggregate data first over space, then over time"

struct TimeSpace <: DataAggrOrder end
purpose(::Type{TimeSpace}) = "Aggregate data first over time, then over space"

export DoAggrObs
export DoNotAggrObs

export DoSpatialWeight
export DoNotSpatialWeight

struct DoAggrObs end
purpose(::Type{DoAggrObs}) = "Apply aggregation to observations"

struct DoNotAggrObs end
purpose(::Type{DoNotAggrObs}) = "Do not apply aggregation to observations"

struct DoSpatialWeight end
purpose(::Type{DoSpatialWeight}) = "Apply spatial weighting to metrics"

struct DoNotSpatialWeight end
purpose(::Type{DoNotSpatialWeight}) = "Do not apply spatial weighting to metrics"

export SpatialDataAggr
export ConcatData

abstract type SpatialDataAggr <: ParameterOptimizationTypes end
purpose(::Type{SpatialDataAggr}) = "Abstract type for spatial data aggregation methods in SINDBAD"

struct ConcatData end
purpose(::Type{ConcatData}) = "Concatenate data arrays for aggregation"

# ------------------------- spatial metric aggregation -------------------------

export SpatialMetricAggr
export MetricMaximum
export MetricMinimum
export MetricSum
export MetricSpatial

abstract type SpatialMetricAggr <: ParameterOptimizationTypes end
purpose(::Type{SpatialMetricAggr}) = "Abstract type for spatial metric aggregation methods in SINDBAD"

struct MetricMaximum <: SpatialMetricAggr end
purpose(::Type{MetricMaximum}) = "Take maximum value across spatial dimensions"

struct MetricMinimum <: SpatialMetricAggr end
purpose(::Type{MetricMinimum}) = "Take minimum value across spatial dimensions"

struct MetricSum <: SpatialMetricAggr end
purpose(::Type{MetricSum}) = "Sum values across spatial dimensions"

struct MetricSpatial <: SpatialMetricAggr end
purpose(::Type{MetricSpatial}) = "Apply spatial aggregation to metrics"

