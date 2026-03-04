export updateMLModel

" update the model with new parameters, e.g., after updating the models with the gradient"
function updateMLModel(::MachineLearningUpdateType, _model_state, _model_flat, _gradient) 
    error("
    updateMLModel `$(nameof(typeof(x)))` not implemented. 
    
    To implement a new optimizer:
    
    - First add a new type as a subtype of `MachineLearningUpdateType` in `src/Types/MachineLearningTypes.jl`. 
    
    - Then, add a corresponding method:
      - if it can be implemented as an internal Sindbad method without additional dependencies, implement the method in `src/MachineLearning/mlUpdate.jl`.     
      - if it requires additional dependencies, implement the method in `ext/<extension_name>/MachineLearningUpdateMLModel.jl` extension.

    ")

end
