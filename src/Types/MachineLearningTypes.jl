
export MachineLearningTypes
abstract type MachineLearningTypes <: SindbadTypes end
purpose(::Type{MachineLearningTypes}) = "Abstract type for types in machine learning related methods in SINDBAD"

# ------------------------- gradient related types ------------------------------------------------------------
export MachineLearningGradType
export EnzymeGrad
export FiniteDifferencesGrad
export FiniteDiffGrad
export ForwardDiffGrad
export PolyesterForwardDiffGrad
export ZygoteGrad

abstract type MachineLearningGradType <: MachineLearningTypes end
purpose(::Type{MachineLearningGradType}) = "Abstract type for automatic differentiation or finite differences for gradient calculations"

struct EnzymeGrad <: MachineLearningGradType  end
purpose(::Type{EnzymeGrad}) = "Use Enzyme.jl for automatic differentiation"
struct FiniteDifferencesGrad <: MachineLearningGradType end
purpose(::Type{FiniteDifferencesGrad}) = "Use FiniteDifferences.jl for finite difference calculations"

struct FiniteDiffGrad <: MachineLearningGradType end
purpose(::Type{FiniteDiffGrad}) = "Use FiniteDiff.jl for finite difference calculations"

struct ForwardDiffGrad <: MachineLearningGradType end
purpose(::Type{ForwardDiffGrad}) = "Use ForwardDiff.jl for automatic differentiation"

struct PolyesterForwardDiffGrad <: MachineLearningGradType end
purpose(::Type{PolyesterForwardDiffGrad}) = "Use PolyesterForwardDiff.jl for automatic differentiation"

struct ZygoteGrad <: MachineLearningGradType  end
purpose(::Type{ZygoteGrad}) = "Use Zygote.jl for automatic differentiation"

#Machine Learningtraining types
export MachineLearningTrainingType
export MixedGradient
export LossModelObsMachineLearning

abstract type MachineLearningTrainingType <: MachineLearningTypes end
purpose(::Type{MachineLearningTrainingType}) = "Abstract type for training a hybrid algorithm in SINDBAD"

struct MixedGradient <: MachineLearningTrainingType end
purpose(::Type{MixedGradient}) = "Use a mixed gradient approach for training using gradient from multiple methods and combining them with pullback from zygote"

struct LossModelObsMachineLearning <: MachineLearningTrainingType end
purpose(::Type{LossModelObsMachineLearning}) = "Loss function using metrics between the predicted model and observation as defined in optimization.json"

# Machine Learning update types
export MachineLearningUpdateType
export OptimisersUpdate

abstract type MachineLearningUpdateType <: MachineLearningTypes end
purpose(::Type{MachineLearningUpdateType}) = "Abstract type for updating the machine learning model during training"

struct OptimisersUpdate <: MachineLearningUpdateType end
purpose(::Type{OptimisersUpdate}) = "Use Optimisers.jl for updating the machine learning model during training"

# Machine Learning Pullback types
export MachineLearningPullbackType
export ZygotePullback

abstract type MachineLearningPullbackType <: MachineLearningTypes end
purpose(::Type{MachineLearningPullbackType}) = "Abstract type for pullback functions used in machine learning training for calculating the Jacobian-vector product"

struct ZygotePullback <: MachineLearningPullbackType end
purpose(::Type{ZygotePullback}) = "Use Zygote.jl for calculating the pullback function for the Jacobian-vector product during machine learning training"


# Folds
export CalcFoldFromSplit
export LoadFoldFromFile

struct CalcFoldFromSplit <: MachineLearningTrainingType end
purpose(::Type{CalcFoldFromSplit}) = "Use a split of the data to calculate the folds for cross-validation. The default way to calculate the folds is by splitting the data into k-folds. In this case, the split is done on the go based on the values given in ml_training.split_ratios and n_folds."

struct LoadFoldFromFile <: MachineLearningTrainingType end
purpose(::Type{LoadFoldFromFile}) = "Use precalculated data to load the folds for cross-validation. In this case, the data path has to be set under ml_training.fold_path and ml_training.which_fold. The data has to be in the format of a jld2 file with the following structure: /folds/0, /folds/1, /folds/2, ... /folds/n_folds. Each fold has to be a tuple of the form (train_indices, test_indices)."

## Machine Learning Model Types
export MachineLearningModelType
export FluxDenseNN

abstract type MachineLearningModelType <: MachineLearningTypes end
purpose(::Type{MachineLearningModelType}) = "Abstract type for machine learning models used in SINDBAD"

struct FluxDenseNN <: MachineLearningModelType end
purpose(::Type{FluxDenseNN}) = "simple dense neural network model implemented in Flux.jl"

## Optimizers
export MachineLearningOptimizerType
export OptimisersAdam
export OptimisersDescent

abstract type MachineLearningOptimizerType <: MachineLearningTypes end
purpose(::Type{MachineLearningOptimizerType}) = "Abstract type for optimizers used for trainingMachine Learningmodels in SINDBAD"

struct OptimisersAdam <: MachineLearningOptimizerType end
purpose(::Type{OptimisersAdam}) = "Use Optimisers.jl Adam optimizer for trainingMachine Learningmodels in SINDBAD"

struct OptimisersDescent <: MachineLearningOptimizerType end
purpose(::Type{OptimisersDescent}) = "Use Optimisers.jl Descent optimizer for trainingMachine Learningmodels in SINDBAD"

## Activation functions
export ActivationType
export FluxRelu
export FluxSigmoid
export FluxTanh
export CustomSigmoid

abstract type ActivationType <: MachineLearningTypes end
purpose(::Type{ActivationType}) = "Abstract type for activation functions used inMachine Learningmodels"

struct FluxRelu <: ActivationType end
purpose(::Type{FluxRelu}) = "Use Flux.jl ReLU activation function"

struct FluxSigmoid <: ActivationType end
purpose(::Type{FluxSigmoid}) = "Use Flux.jl Sigmoid activation function"

struct FluxTanh <: ActivationType end
purpose(::Type{FluxTanh}) = "Use Flux.jl Tanh activation function"

struct CustomSigmoid <: ActivationType end
purpose(::Type{CustomSigmoid}) = "Use a custom sigmoid activation function. In this case, the `k_σ` parameter in ml_model sections of the settings is used to control the steepness of the sigmoid function."