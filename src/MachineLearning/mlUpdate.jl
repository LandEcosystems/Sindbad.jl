export updateMLModel

" update the model with new parameters, e.g., after updating the models with the gradient"
function updateMLModel(x::MachineLearningUpdateType, _model_state, _model_flat, _gradient)
    pkg = requires_package(typeof(x))
    if !isnothing(pkg)
        error("
    updateMLModel `$(nameof(typeof(x)))` requires the `$(pkg)` package to be loaded.

    This update method is implemented in the `Sindbad$(pkg)Ext` extension, which activates automatically once you run `using $(pkg)` in your session (alongside `using Sindbad`).
    ")
    else
        error("
    updateMLModel `$(nameof(typeof(x)))` not implemented.

    To implement a new update method:

    - First add a new type as a subtype of `MachineLearningUpdateType` in `src/Types/MachineLearningTypes.jl`.

    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlUpdate.jl`.
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningUpdateMLModel.jl` extension.

    ")
    end
end
