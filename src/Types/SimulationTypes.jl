
export SimulationTypes
abstract type SimulationTypes <: SindbadTypes end
purpose(::Type{SimulationTypes}) = "Abstract type for model simulation run flags and experimental setup and simulations in SINDBAD"

# ------------------------- running flags -------------------------
export RunFlag
export DoCalcCost
export DoNotCalcCost
export DoFilterNanPixels
export DoNotFilterNanPixels
export DoRunForward
export DoNotRunForward
export DoRunLazy
export DoNotRunLazy
export DoRunOptimization
export DoNotRunOptimization
export DoSaveInfo
export DoNotSaveInfo
export DoSpinupTEM
export DoNotSpinupTEM
export DoStoreSpinup
export DoNotStoreSpinup


abstract type RunFlag <: SimulationTypes end
purpose(::Type{RunFlag}) = "Abstract type for model run configuration flags in SINDBAD"

struct DoCalcCost <: RunFlag end
purpose(::Type{DoCalcCost}) = "Enable cost calculation between model output and observations"

struct DoNotCalcCost <: RunFlag end
purpose(::Type{DoNotCalcCost}) = "Disable cost calculation between model output and observations"

struct DoFilterNanPixels <: RunFlag end
purpose(::Type{DoFilterNanPixels}) = "Enable filtering of NaN values in spatial data"

struct DoNotFilterNanPixels <: RunFlag end
purpose(::Type{DoNotFilterNanPixels}) = "Disable filtering of NaN values in spatial data"

struct DoRunForward <: RunFlag end
purpose(::Type{DoRunForward}) = "Enable forward model run"

struct DoNotRunForward <: RunFlag end
purpose(::Type{DoNotRunForward}) = "Disable forward model run"

struct DoRunLazy <: RunFlag end
purpose(::Type{DoRunLazy}) = "Enable lazy run mode for running experiements based on Diskarrays and YAXArrays"

struct DoNotRunLazy <: RunFlag end
purpose(::Type{DoNotRunLazy}) = "Disable lazy run mode for running experiements based on Diskarrays and YAXArrays"

struct DoRunOptimization <: RunFlag end
purpose(::Type{DoRunOptimization}) = "Enable model parameter optimization"

struct DoNotRunOptimization <: RunFlag end
purpose(::Type{DoNotRunOptimization}) = "Disable model parameter optimization"

struct DoSaveInfo <: RunFlag end
purpose(::Type{DoSaveInfo}) = "Enable saving of model information"

struct DoNotSaveInfo <: RunFlag end
purpose(::Type{DoNotSaveInfo}) = "Disable saving of model information"

struct DoSpinupTEM <: RunFlag end
purpose(::Type{DoSpinupTEM}) = "Enable terrestrial ecosystem model spinup"

struct DoNotSpinupTEM <: RunFlag end
purpose(::Type{DoNotSpinupTEM}) = "Disable terrestrial ecosystem model spinup"

struct DoStoreSpinup <: RunFlag end
purpose(::Type{DoStoreSpinup}) = "Enable storing of spinup results"

struct DoNotStoreSpinup <: RunFlag end
purpose(::Type{DoNotStoreSpinup}) = "Disable storing of spinup results"

# ------------------------- parallelization options-------------------------
export ParallelizationPackage
export QbmapParallelization
export ThreadsParallelization


abstract type ParallelizationPackage <: SimulationTypes end

purpose(::Type{ParallelizationPackage}) = "Abstract type for using different parallelization packages in SINDBAD"

struct QbmapParallelization <: ParallelizationPackage end
purpose(::Type{QbmapParallelization}) = "Use Qbmap for parallelization"

struct ThreadsParallelization <: ParallelizationPackage end
purpose(::Type{ThreadsParallelization}) = "Use Julia threads for parallelization"

# ------------------------- model output options-------------------------
export OutputStrategy
export DoOutputAll
export DoNotOutputAll
export DoSaveSingleFile
export DoNotSaveSingleFile

abstract type OutputStrategy <: SimulationTypes end
purpose(::Type{OutputStrategy}) = "Abstract type for model output strategies in SINDBAD"

struct DoOutputAll <: OutputStrategy end
purpose(::Type{DoOutputAll}) = "Enable output of all model variables"

struct DoNotOutputAll <: OutputStrategy end
purpose(::Type{DoNotOutputAll}) = "Disable output of all model variables"

struct DoSaveSingleFile <: OutputStrategy end
purpose(::Type{DoSaveSingleFile}) = "Save all output variables in a single file"

struct DoNotSaveSingleFile <: OutputStrategy end
purpose(::Type{DoNotSaveSingleFile}) = "Save output variables in separate files"


# ------------------------- spinup types ------------------------------------------------------------
export SpinupTypes
abstract type SpinupTypes <: SindbadTypes end
purpose(::Type{SpinupTypes}) = "Abstract type for model spinup related functions and methods in SINDBAD"

# ------------------------- spinup mode ------------------------------------------------------------
export SpinupMode
export AllForwardModels
export SelSpinupModels
export EtaScaleA0H
export EtaScaleA0HCWD
export EtaScaleAHCWD
export EtaScaleAH
export NlsolveFixedpointTrustregionCEco
export NlsolveFixedpointTrustregionCEcoTWS
export NlsolveFixedpointTrustregionTWS
export ODEAutoTsit5Rodas5
export ODEDP5
export ODETsit5
export Spinup_TWS
export Spinup_cEco_TWS
export Spinup_cEco
export SSPDynamicSSTsit5
export SSPSSRootfind

abstract type SpinupMode <: SpinupTypes end
purpose(::Type{SpinupMode}) = "Abstract type for model spinup modes in SINDBAD"

struct AllForwardModels <: SpinupMode end
purpose(::Type{AllForwardModels}) = "Use all forward models for spinup"

struct EtaScaleA0H <: SpinupMode end
purpose(::Type{EtaScaleA0H}) = "scale carbon pools using diagnostic scalars for ηH and c_remain"

struct EtaScaleA0HCWD <: SpinupMode end
purpose(::Type{EtaScaleA0HCWD}) = "scale carbon pools of CWD (cLitSlow) using ηH and set vegetation pools to c_remain"

struct EtaScaleAHCWD <: SpinupMode end
purpose(::Type{EtaScaleAHCWD}) = "scale carbon pools of CWD (cLitSlow) using ηH and scale vegetation pools by ηA"

struct EtaScaleAH <: SpinupMode end
purpose(::Type{EtaScaleAH}) = "scale carbon pools using diagnostic scalars for ηH and ηA"

struct NlsolveFixedpointTrustregionCEco <: SpinupMode end
purpose(::Type{NlsolveFixedpointTrustregionCEco}) = "use a fixed-point nonlinear solver with trust region for carbon pools (cEco)"

struct NlsolveFixedpointTrustregionCEcoTWS <: SpinupMode end
purpose(::Type{NlsolveFixedpointTrustregionCEcoTWS}) = "use a fixed-point nonlinear solver with trust region for both cEco and TWS"

struct NlsolveFixedpointTrustregionTWS <: SpinupMode end
purpose(::Type{NlsolveFixedpointTrustregionTWS}) = "use a fixed-point nonlinearsolver with trust region for Total Water Storage (TWS)"

struct ODEAutoTsit5Rodas5 <: SpinupMode end
purpose(::Type{ODEAutoTsit5Rodas5}) = "use the AutoVern7(Rodas5) method from DifferentialEquations.jl for solving ODEs"

struct ODEDP5 <: SpinupMode end
purpose(::Type{ODEDP5}) = "use the DP5 method from DifferentialEquations.jl for solving ODEs"

struct ODETsit5 <: SpinupMode end
purpose(::Type{ODETsit5}) = "use the Tsit5 method from DifferentialEquations.jl for solving ODEs"

struct SelSpinupModels <: SpinupMode end
purpose(::Type{SelSpinupModels}) = "run only the models selected for spinup in the model structure"

struct SSPDynamicSSTsit5 <: SpinupMode end
purpose(::Type{SSPDynamicSSTsit5}) = "use the SteadyState solver with DynamicSS and Tsit5 methods"

struct SSPSSRootfind <: SpinupMode end
purpose(::Type{SSPSSRootfind}) = "use the SteadyState solver with SSRootfind method"


struct Spinup_TWS{M,F,T,I,O,N} <: SpinupMode
    models::M
    forcing::F
    tem_info::T
    land::I
    loc_forcing_t::O
    n_timesteps::N
end
purpose(::Type{Spinup_TWS}) = "Spinup spinup_mode for Total Water Storage (TWS)"

struct Spinup_cEco_TWS{M,F,T,I,O,N,TWS} <: SpinupMode
    models::M
    forcing::F
    tem_info::T
    land::I
    loc_forcing_t::O
    n_timesteps::N
    TWS::TWS
end
purpose(::Type{Spinup_cEco_TWS}) = "Spinup spinup_mode for cEco and TWS"

struct Spinup_cEco{M,F,T,I,O,N} <: SpinupMode
    models::M
    forcing::F
    tem_info::T
    land::I
    loc_forcing_t::O
    n_timesteps::N
end
purpose(::Type{Spinup_cEco}) = "Spinup spinup_mode for cEco"


# ------------------------- spinup sequence and types ------------------------------------------------------------
export SpinupSequence
export SpinupSequenceWithAggregator

struct SpinupSequenceWithAggregator{F,M<:SpinupMode} <: SpinupTypes
    forcing::Symbol
    n_repeat::Int
    n_timesteps::Int
    spinup_mode::M
    options::NamedTuple
    aggregator_indices::Vector{Int}
    aggregator::Vector{TimeSample}
    aggregator_type::TimeSamplerMethod
end

# The forcing name is carried as the type parameter `F` as well as in the field, so that
# looking the sequence's forcing up in the spinup forcing NamedTuple resolves at compile time.
function SpinupSequenceWithAggregator(forcing::Symbol, n_repeat, n_timesteps, spinup_mode::M, options, aggregator_indices, aggregator, aggregator_type) where {M<:SpinupMode}
    return SpinupSequenceWithAggregator{forcing,M}(forcing, n_repeat, n_timesteps, spinup_mode, options, aggregator_indices, aggregator, aggregator_type)
end
purpose(::Type{SpinupSequenceWithAggregator}) = "Spinup sequence with time aggregation for corresponding forcingtime series"

struct SpinupSequence <: SpinupTypes
    forcing::Symbol
    n_repeat::Int
    n_timesteps::Int
    spinup_mode::SpinupMode
    options::NamedTuple
end
purpose(::Type{SpinupSequence}) = "Basic Spinup sequence without time aggregation"
