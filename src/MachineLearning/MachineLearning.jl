"""
    MachineLearning

The `MachineLearning` module provides the core functionality for integrating machine learning (ML) and hybrid modeling capabilities into the SINDBAD framework.

# Purpose
This module brings together all components required for hybrid (process-based + ML) modeling in SINDBAD, including data preparation, model construction, training routines, gradient computation, and optimizer management. It supports flexible configuration, cross-validation, and seamless integration with SINDBAD's process-based modeling workflows.

# Dependencies
## Related (SINDBAD ecosystem)
- `OmniTools`: Shared helpers used indirectly via internal modules.

## External (third-party)
- `Base.Iterators`: Iterators for batching and repetition (`repeated`, `partition`).
- `Distributed`: Parallel and distributed computing utilities (`nworkers`, `pmap`, `workers`, `nprocs`, `CachingPool`).
- `JLD2`: Saving/loading model artifacts (e.g. fold indices, checkpoints).
- `ProgressMeter`: Progress utilities (imported symbols only).

## Internal (within `Sindbad`)
- `Sindbad.DataLoaders`
- `Sindbad.Setup`
- `Sindbad.Simulation`
- `Sindbad.Types`
- `SindbadTEM`

## Optional dependencies (weakdeps / experimental)
Some ML training/AD backends are listed as weak dependencies in the root `Project.toml` (e.g. `Flux`, `Zygote`, `ForwardDiff`, `Optimisers`, `PreallocationTools`, etc.) and are enabled via extensions.

# Included Files
- `utilsMachineLearning.jl`: Utility functions for machine-learning workflows.
- `diffCaches.jl`: Caching utilities for differentiation.
- `activationFunctions.jl`: Implements various activation functions, including custom and Flux-provided activations.
- `mlModels.jl`: Constructors and utilities for hybrid/ML model components.
- `mlOptimizers.jl`: Functions for creating and configuring optimizers for ML training (backend-dependent).
- `loss.jl`: Loss functions and utilities for evaluating model performance and computing gradients.
- `prepHybrid.jl`: Prepares data structures and loss definitions for hybrid modeling (including data splits and feature extraction).
- `mlGradient.jl`: Routines for computing gradients using different libraries and methods, supporting both automatic and finite difference differentiation.
- `mlTrain.jl`: Training routines for ML and hybrid models, including batching, checkpointing, and evaluation.
- `neuralNetwork.jl`: Neural network utilities and architectures.
- `siteLosses.jl`: Site-specific loss calculation utilities.
- `oneHots.jl`: One-hot encoding utilities.
- `loadCovariates.jl`: Functions for loading and handling covariate data.

# Notes
- The module is modular and extensible, allowing users to add new ML models, optimizers, activation functions, and training methods.
- It is tightly integrated with the SINDBAD ecosystem, ensuring consistent data handling and reproducibility across hybrid and process-based modeling workflows.
"""
module MachineLearning
    using Distributed:
        nworkers,
        pmap,
        workers,
        nprocs,
        CachingPool
    using Base.Iterators: repeated, partition
    using JLD2
    using Optimisers
    # using PolyesterForwardDiff
    # using PreallocationTools
    using ProgressMeter: @showprogress, Progress, next!, progress_pmap, progress_map
    using Random
    
    using SindbadTEM
    using AxisKeys
    using ..Types
    using ..DataLoaders: AllNaN
    using ..DataLoaders: yaxCubeToKeyedArray, Cube, At
    using ..Setup: updateModels, getParameterIndices
    using ..Simulation: coreTEM!, prepTEM, prepCostOptions
    using ..ParameterOptimization: metricVector, combineMetric


    include("utilsMachineLearning.jl")
    include("diffCaches.jl")
    include("activationFunctions.jl")
    include("mlModels.jl")
    include("mlOptimizers.jl")
    include("loss.jl")
    include("prepHybrid.jl")
    include("mlGradient.jl")
    include("mlTrain.jl")
    include("neuralNetwork.jl")
    include("siteLosses.jl")
    include("oneHots.jl")
    include("loadCovariates.jl")

end
