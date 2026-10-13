export getParameterInput
export parameterVariableName
export parameterVariableAttributes
export setTypedParameters
export writeParameterInputJson


"""
    getParameterInput(info)

Returns the parameter input given as a json or a zarr/nc file in
`config_files.parameters`, with every `data_path` made absolute.

# Arguments:
- `info`: the experiment info during `setupInfo`

# Returns:
- `nothing` when there is no parameters input, or when it is a csv file. A csv gives one
  global parameter vector and is applied by `setSpinupAndForwardModels`.
- Otherwise a NamedTuple with the `default_parameter_map` and the `variables` of the
  input.

# Notes:
- The json is parsed by `readConfiguration` like every other config file. A zarr/nc
  file given directly is stored as `default_parameter_map.data_path` with no
  `variables`.
- No parameter file is opened here. `getParameters` reads and checks the parameter
  variables when the forcing is loaded.
"""
function getParameterInput(info)
    hasproperty(info.settings, :parameters) || return nothing
    parameter_input = info.settings.parameters
    parameter_input isa NamedTuple || return nothing
    isempty(parameter_input) && return nothing
    path_info = (; experiment=info.temp.experiment)
    default_map = setAbsoluteDataPath(get(parameter_input, :default_parameter_map, (;)), path_info)
    variables = map(v -> setAbsoluteDataPath(v, path_info), get(parameter_input, :variables, (;)))
    return (; default_parameter_map=default_map, variables=variables)
end

"""
    setAbsoluteDataPath(settings, path_info)

Returns `settings` with its `data_path` made absolute, when it has one.
"""
function setAbsoluteDataPath(settings, path_info)
    hasproperty(settings, :data_path) || return settings
    data_path = settings.data_path
    (data_path isa AbstractString && !isempty(data_path)) || return settings
    return merge(settings, (; data_path=getAbsDataPath(path_info, data_path)))
end


"""
    parameterVariableName(model, name)

Returns the name of the variable of a parameter in a parameter file. It is the model and
the parameter name joined by a double underscore, e.g., `fAPAR__k_extinction`.

# Notes:
- A model structure has one approach per model, so the name is unique even when the same
  parameter name is used by several models.
"""
parameterVariableName(model, name) = string(model) * "__" * string(name)


"""
    parameterVariableAttributes(parameter_table, p_index)

Returns the metadata of one parameter from a parameter table, used as the attributes of
its variable in a parameter file and as its entry in the `params.json`.

# Arguments:
- `parameter_table`: a table of SINDBAD model parameters, e.g., the optimized parameters
- `p_index`: the row of the parameter in the table

# Returns:
- An ordered dictionary with one entry per column of the table, except the value columns.

# Notes:
- Each key is the name of the table column it comes from.
- Empty strings are left out, because some file formats cannot store them. A missing
  `timescale_run` is read back as no timescale, which needs no unit conversion.
- `is_ml` is stored as an integer, because netCDF has no boolean attributes.
"""
function parameterVariableAttributes(parameter_table, p_index)
    p_row = parameter_table[p_index]
    attributes = DataStructures.OrderedDict{String,Any}()
    attributes["model"] = string(p_row.model)
    attributes["name"] = string(p_row.name)
    attributes["name_full"] = string(p_row.name_full)
    attributes["model_approach"] = string(p_row.model_approach)
    for p_field ∈ (:units, :units_ori, :timescale_run, :timescale_ori, :dist)
        hasproperty(p_row, p_field) || continue
        p_value = getproperty(p_row, p_field)
        if !ismissing(p_value) && !isempty(string(p_value))
            attributes[string(p_field)] = string(p_value)
        end
    end
    for p_field ∈ (:default, :initial, :lower, :upper)
        attributes[string(p_field)] = Float64(getproperty(p_row, p_field))
    end
    if hasproperty(p_row, :is_ml)
        attributes["is_ml"] = Int(p_row.is_ml)
    end
    if hasproperty(p_row, :p_dist) && p_row.p_dist isa AbstractVector && !isempty(p_row.p_dist)
        attributes["p_dist"] = Float64.(collect(p_row.p_dist))
    end
    return attributes
end


"""
    writeParameterInputJson(json_path, data_path, variable_attributes)

Writes the `params.json` of a parameter file, which can be given as the `parameters`
config file of another experiment.

# Arguments:
- `json_path`: the path of the json file to write
- `data_path`: the absolute path of the parameter file
- `variable_attributes`: an ordered collection of variable name and attribute pairs,
  e.g., from `parameterVariableAttributes`

# Returns:
- `json_path`
"""
function writeParameterInputJson(json_path, data_path, variable_attributes)
    variables = DataStructures.OrderedDict{String,Any}()
    for (variable_name, attributes) ∈ variable_attributes
        entry = DataStructures.OrderedDict{String,Any}()
        merge!(entry, attributes)
        entry["source_variable"] = string(variable_name)
        variables[string(variable_name)] = entry
    end
    default_map = DataStructures.OrderedDict{String,Any}("data_path" => data_path, "space_time_type" => "spatial")
    parameter_input = DataStructures.OrderedDict{String,Any}("default_parameter_map" => default_map, "variables" => variables)
    open(json_path, "w") do io
        write(io, json(parameter_input; pretty=true))
    end
    return json_path
end


"""
    setTypedParameters(selected_models, parameter_to_index::NamedTuple, parameter_values)
    setTypedParameters(selected_models, parameter_indices_per_model, parameter_values)

Returns the models with their parameters set from `parameter_values`, keeping the
type of each field.

# Arguments:
- `selected_models`: a tuple or long tuple of models
- `parameter_to_index`: a NamedTuple of model approach names, each with a NamedTuple of
  parameter names and their index in `parameter_values`, e.g., from
  `getParameterIndices`. The model of each entry is found by its name.
- `parameter_indices_per_model`: the same indices with one element per model in the
  order of `selected_models`, from `getParameterIndicesPerModel`. A tuple for a tuple
  of models, and a long tuple with the same chunks for a long tuple of models. Model
  k is paired with element k, so no model is looked up by name.
- `parameter_values`: the values of the parameters

# Notes:
- Each value is converted to the type of the field it replaces, so the models keep
  their concrete types. This keeps a vector of models for all locations type stable.
- The method with `parameter_to_index` suits a call made once at setup. Use the one
  with `parameter_indices_per_model` when the models are updated many times, as in
  the cost function of an optimization. It does not allocate for models without
  parameters to set and is inferred for a long tuple of models.
- `updateModelParameters` with a `parameter_to_index` does not convert, because the
  values can be dual numbers in gradient based runs. Use that one there.
"""
function setTypedParameters(selected_models, parameter_to_index::NamedTuple, parameter_values)
    return map(selected_models) do model
        model_index = parameter_to_index[nameof(typeof(model))]
        isempty(model_index) && return model
        p_keys = keys(model_index)
        new_values = map(p_keys) do p_key
            convertParameterValue(getproperty(model, p_key), parameter_values[getfield(model_index, p_key)])
        end
        ConstructionBase.setproperties(model, NamedTuple{p_keys}(new_values))
    end
end

function setTypedParameters(selected_models::Tuple, parameter_indices_per_model::Tuple, parameter_values)
    return map((model, model_indices) -> setTypedModelParameters(model, model_indices, parameter_values), selected_models, parameter_indices_per_model)
end

function setTypedParameters(selected_models::LongTuple{N}, parameter_indices_per_model::LongTuple{N}, parameter_values) where {N}
    return LongTuple{N}(map((models, model_indices) -> setTypedParameters(models, model_indices, parameter_values), selected_models.data, parameter_indices_per_model.data))
end

# A model without parameters to set is returned as it is.
setTypedModelParameters(model, ::Nothing, parameter_values) = model

# The old values are read as a subset of the fields with known names, so the new
# values and the rebuilt model are inferred.
function setTypedModelParameters(model, model_indices::NamedTuple{p_keys}, parameter_values) where {p_keys}
    old_values = NamedTuple{p_keys}(ConstructionBase.getproperties(model))
    new_values = map((old_value, p_index) -> convertParameterValue(old_value, parameter_values[p_index]), old_values, model_indices)
    return ConstructionBase.setproperties(model, new_values)
end

convertParameterValue(old_value::T, value) where {T<:Integer} = round(T, value)
convertParameterValue(old_value::T, value) where {T<:Real} = convert(T, value)
convertParameterValue(old_value, value) = error("Parameters from a parameter input must be scalars, but got a parameter of type $(typeof(old_value)).")
