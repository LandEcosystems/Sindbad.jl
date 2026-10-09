export getParameters


"""
    getParameters(info::NamedTuple, forcing_axes)

Loads the parameters per location from the parameter input, and makes their values
ready to use in the same way `getForcing` does for the forcing.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_axes`: the dimension name and coordinate pairs of the forcing, after its subset

# Returns:
- `nothing` when there is no json or zarr/nc parameters input.
- Otherwise a NamedTuple with:
  - `variables`: the names of the parameter variables
  - `data`: one YAXArray per variable on the spatial dimensions of the forcing, in the
    units of the run, without NaN, and within the bounds of the parameter
  - `parameter_table`: a Table with one row per variable with the resolved settings:
    `model`, `name`, `name_full`, `model_approach`, `units`, `timescale_run`,
    `unit_factor`, `lower`, `upper`, `default`, `source_variable`, `data_path`, `n_nan`
    and `n_clamped`

# Notes:
- The settings of a variable come from its entry in the json first, then from
  `default_parameter_map`, then from the attributes of the variable in the file.
- When the input has no `variables`, which is the case for a zarr/nc file given
  directly, every variable of the file with `model` and `name` attributes is used.
- Every parameter must exist in the selected model structure, checked against
  `info.models.parameter_table`. Only scalar parameters are supported.
- The values are selected at the coordinates of the forcing, in the order of the
  forcing, so the same spatial index selects the same location in the forcing and in
  the parameters. A file may have more locations than the forcing, in any order.
- Values, `lower`, `upper` and `default` are converted to the time step of the run with
  the `timescale_run` of the input, the same way `setInputParameters` converts a csv.
- NaN values are replaced by the `default`, and values outside `[lower, upper]` are
  clamped. Both are counted and reported once per parameter.
"""
function getParameters(info::NamedTuple, forcing_axes)
    parameter_input = get(info.experiment.data_settings, :parameters, nothing)
    isnothing(parameter_input) && return nothing
    print_info(getParameters, @__FILE__, @__LINE__, "getting parameters per location from the parameters input...", n_m=1)
    if isnothing(forcing_axes)
        error("A json or zarr/nc parameters input needs a forcing with a spatiotemporal variable to set the locations of the parameters.")
    end
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    num_type = info.helpers.numbers.num_type
    open_files = Dict{String,Any}()
    var_names, var_sources = listParameterVariables(parameter_input, open_files)

    table_rows = []
    data = map(var_names, var_sources) do var_name, var_source
        dataset = openParameterFile!(open_files, var_source.data_path)
        attributes = readVariableAttributes(dataset, var_source.source_variable, var_source.data_path)
        p_row = resolveParameterVariable(var_name, var_source, parameter_input, attributes, info)
        yax = selectForcingLocations(dataset[var_source.source_variable], forcing_axes, space_dims, var_name)
        p_values = cleanParameterValues(Array(yax), p_row, num_type)
        push!(table_rows, (; p_row..., n_nan=p_values.n_nan, n_clamped=p_values.n_clamped))
        print_info(nothing, @__FILE__, @__LINE__, "`$(var_name)` = `$(p_row.name_full)` ($(p_row.units)) from `$(var_source.source_variable)` in `$(var_source.data_path)` * $(p_row.unit_factor)", n_m=4)
        # kept as a cube on the spatial dimensions of the forcing, so a lazy run can
        # map over it together with the forcing
        YAXArray(DD.dims(yax), p_values.data)
    end

    parameter_table = Table([table_rows...])
    full_names = parameter_table.name_full
    duplicates = unique(filter(n -> count(==(n), full_names) > 1, full_names))
    if !isempty(duplicates)
        error("The parameters input sets $(duplicates) more than once. Keep one variable per parameter.")
    end
    return (; variables=Tuple(var_names), data=Tuple(data), parameter_table=parameter_table)
end


"""
    listParameterVariables(parameter_input, open_files)

Returns the names of the parameter variables to read, and for each the
`(; data_path, source_variable)` to read it from.

# Notes:
- With `variables` in the input, each variable uses its own `data_path`, else the one of
  `default_parameter_map`, and its `source_variable`, else its name.
- Without `variables`, every variable with `model` and `name` attributes in the file of
  `default_parameter_map.data_path` is read.
"""
function listParameterVariables(parameter_input, open_files)
    default_map = parameter_input.default_parameter_map
    input_variables = parameter_input.variables
    if isempty(input_variables)
        data_path = firstSetValue(:data_path, nothing, default_map)
        isnothing(data_path) && error("The parameters input has no variables and no `default_parameter_map.data_path`. Give the path of the parameter file.")
        var_names = listParameterVariablesInFile(openParameterFile!(open_files, data_path))
        var_sources = [(; data_path=string(data_path), source_variable=string(v)) for v ∈ var_names]
        return var_names, var_sources
    end
    var_names = collect(keys(input_variables))
    var_sources = map(var_names) do var_name
        var_settings = getfield(input_variables, var_name)
        data_path = firstSetValue(:data_path, nothing, var_settings, default_map)
        isnothing(data_path) && error("The parameter variable `$(var_name)` has no `data_path`. Set it for the variable or in `default_parameter_map`.")
        source_variable = firstSetValue(:source_variable, string(var_name), var_settings)
        (; data_path=string(data_path), source_variable=string(source_variable))
    end
    return var_names, var_sources
end


"""
    listParameterVariablesInFile(dataset)

Returns the names of the variables of a parameter file that have `model` and `name`
attributes. Other variables, such as coordinates stored as variables, are skipped.
"""
function listParameterVariablesInFile(dataset)
    var_names = Symbol[]
    for (var_name, cube) ∈ dataset.cubes
        if haskey(cube.properties, "model") && haskey(cube.properties, "name")
            push!(var_names, Symbol(var_name))
        else
            print_info(nothing, @__FILE__, @__LINE__, "→→→    skipping `$(var_name)`, which has no `model` and `name` attributes", n_m=4)
        end
    end
    isempty(var_names) && error("The parameter file has no variable with `model` and `name` attributes.")
    return var_names
end


"""
    openParameterFile!(open_files, data_path)

Opens a parameter file once and keeps it in `open_files`.
"""
function openParameterFile!(open_files, data_path)
    return get!(open_files, data_path) do
        is_remote = startswith(data_path, "http") || startswith(data_path, "s3://")
        is_remote || ispath(data_path) || error("The parameter file `$(data_path)` does not exist.")
        YAXArrays.open_dataset(data_path)
    end
end


"""
    readVariableAttributes(dataset, source_variable, data_path)

Returns the attributes of a variable of a parameter file as a dictionary.

# Notes:
- netCDF can read a scalar attribute as a vector of length one, which is unwrapped.
"""
function readVariableAttributes(dataset, source_variable, data_path)
    var_symbol = Symbol(source_variable)
    if !haskey(dataset.cubes, var_symbol)
        error("The variable `$(source_variable)` is not in the parameter file `$(data_path)`. The file has $(collect(keys(dataset.cubes))).")
    end
    unwrap = value -> value isa AbstractArray && length(value) == 1 ? only(value) : value
    return Dict{String,Any}(string(k) => unwrap(v) for (k, v) ∈ dataset.cubes[var_symbol].properties)
end


"""
    resolveParameterVariable(var_name, var_source, parameter_input, attributes, info)

Returns the resolved settings of one parameter variable, checked against the parameter
table of the selected model structure.

# Returns:
- A NamedTuple with `model`, `name`, `name_full`, `model_approach`, `units`,
  `timescale_run`, `unit_factor`, `lower`, `upper`, `default`, `source_variable` and
  `data_path`. `lower`, `upper` and `default` are in the units of the run.
"""
function resolveParameterVariable(var_name, var_source, parameter_input, attributes, info)
    var_string = string(var_name)
    var_settings = get(parameter_input.variables, Symbol(var_name), (;))
    default_map = parameter_input.default_parameter_map
    get_setting = (field, fallback) -> firstSetValue(field, fallback, var_settings, default_map, attributes)

    model = get_setting(:model, nothing)
    name = get_setting(:name, nothing)
    if isnothing(model) || isnothing(name)
        name_parts = split(var_string, "__")
        length(name_parts) == 2 || error("The parameter variable `$(var_string)` has no `model` and `name`, and its name is not `<model>__<name>`. Set `model` and `name` in the parameters input or in the attributes of the variable.")
        model = isnothing(model) ? name_parts[1] : model
        name = isnothing(name) ? name_parts[2] : name
    end

    parameter_table = info.models.parameter_table
    name_full = string(model) * "." * string(name)
    p_index = findfirst(==(name_full), parameter_table.name_full)
    if isnothing(p_index)
        error("parameter $(name) of the parameter variable `$(var_string)` not found (model: $(model), name_full: $(name_full)). Make sure that the parameter exists in the selected approach/model structure or correct the parameter information in parameters input.")
    end
    model_row = parameter_table[p_index]
    if !(model_row.default isa Number)
        error("The parameter `$(name_full)` is not a scalar. A parameters input only supports scalar parameters.")
    end

    model_approach = get_setting(:model_approach, nothing)
    if !isnothing(model_approach) && Symbol(model_approach) != model_row.model_approach
        @warn "The parameter variable of `$(name_full)` was written for the approach `$(model_approach)`, but the model structure uses `$(model_row.model_approach)`. The values are used as they are."
    end

    space_time_type = string(get_setting(:space_time_type, "spatial"))
    if space_time_type != "spatial"
        error("The parameter variable `$(var_string)` has space_time_type `$(space_time_type)`. A parameters input only supports `spatial` parameters.")
    end

    num_type = info.helpers.numbers.num_type
    timescale_run = string(get_setting(:timescale_run, ""))
    unit_factor = getUnitConversionForParameter(timescale_run, info.helpers.dates.temporal_resolution)
    lower = toRunUnits(get_setting(:lower, nothing), model_row.lower, unit_factor, num_type)
    upper = toRunUnits(get_setting(:upper, nothing), model_row.upper, unit_factor, num_type)
    default = toRunUnits(get_setting(:default, nothing), model_row.default, unit_factor, num_type)
    if lower > upper
        error("The parameter variable of `$(name_full)` has a lower bound $(lower) above its upper bound $(upper).")
    end

    return (; model=model_row.model, name=model_row.name, name_full=name_full, model_approach=model_row.model_approach, units=string(model_row.units), timescale_run=timescale_run, unit_factor=num_type(unit_factor), lower=lower, upper=upper, default=default, source_variable=var_source.source_variable, data_path=var_source.data_path)
end


"""
    firstSetValue(field, fallback, sources...)

Returns the first set value of `field` in `sources`, in their order, or `fallback`
when none is set.

# Notes:
- A source is a NamedTuple of settings or a dictionary of file attributes.
- `nothing` and empty strings count as not set.
"""
function firstSetValue(field, fallback, sources...)
    for source ∈ sources
        value = getSettingValue(source, field)
        (isnothing(value) || (value isa AbstractString && isempty(value))) || return value
    end
    return fallback
end

getSettingValue(source::NamedTuple, field) = hasproperty(source, field) ? getproperty(source, field) : nothing
getSettingValue(source::AbstractDict, field) = get(source, string(field), nothing)
getSettingValue(::Nothing, field) = nothing


"""
    toRunUnits(input_value, model_value, unit_factor, num_type)

Returns a value of the parameters input in the units of the run. A value from the input
is multiplied by `unit_factor`. A missing one is taken from the model, which is already
in the units of the run.
"""
function toRunUnits(input_value, model_value, unit_factor, num_type)
    isnothing(input_value) && return num_type(model_value)
    return num_type(input_value * unit_factor)
end


"""
    selectForcingLocations(yax, forcing_axes, space_dims, var_name)

Returns the values of `yax` at the coordinates of the forcing, with the spatial
dimensions of the forcing in its order.

# Notes:
- The coordinates are selected by value, so the file may have more locations than the
  forcing, in any order.
- An error lists the coordinates of the forcing that are missing in the file.
"""
function selectForcingLocations(yax, forcing_axes, space_dims, var_name)
    axes_values = Dict(Symbol(first(f_axis)) => last(f_axis) for f_axis ∈ forcing_axes)
    for s_dim ∈ space_dims
        haskey(axes_values, s_dim) || error("The forcing has no coordinates for the spatial dimension `$(s_dim)`.")
        hasdim(yax, s_dim) || error("The parameter variable `$(var_name)` has no `$(s_dim)` dimension. Its dimensions are $(DD.name(DD.dims(yax))).")
        forcing_values = axes_values[s_dim]
        missing_values = setdiff(forcing_values, collect(DD.lookup(yax, s_dim)))
        if !isempty(missing_values)
            error("The parameter variable `$(var_name)` has no values for $(length(missing_values)) `$(s_dim)` of the forcing: $(missing_values).")
        end
        yax = yax[DD.Dim{s_dim}(At(forcing_values))]
    end
    extra_dims = setdiff(DD.name(DD.dims(yax)), space_dims)
    if !isempty(extra_dims)
        error("The parameter variable `$(var_name)` has the dimensions $(extra_dims) besides the spatial dimensions of the forcing. A parameters input only supports spatial parameters.")
    end
    return permutedims(yax, getDimPermutation(DD.name(DD.dims(yax)), space_dims))
end


"""
    cleanParameterValues(values, p_row, num_type)

Returns the values of one parameter variable ready to use, and the counts of the
replaced values.

# Notes:
- The values are converted to `num_type` and multiplied by the `unit_factor` of
  `p_row`.
- NaN and missing values are replaced by the `default` of `p_row`, and values outside
  `[lower, upper]` are clamped.
- One warning is printed for each kind of replaced values.
"""
function cleanParameterValues(values, p_row, num_type)
    n_nan = 0
    n_clamped = 0
    data = map(values) do value
        p_value = (ismissing(value) || isnan(value)) ? num_type(NaN) : num_type(value) * p_row.unit_factor
        if isnan(p_value)
            n_nan += 1
            return p_row.default
        end
        if p_value < p_row.lower || p_value > p_row.upper
            n_clamped += 1
            return clamp(p_value, p_row.lower, p_row.upper)
        end
        return p_value
    end
    if n_nan > 0
        @warn "The parameter `$(p_row.name_full)` is NaN at $(n_nan) of $(length(values)) locations. The default $(p_row.default) is used there."
    end
    if n_clamped > 0
        @warn "The parameter `$(p_row.name_full)` is outside [$(p_row.lower), $(p_row.upper)] at $(n_clamped) of $(length(values)) locations. The values are clamped to the bounds."
    end
    return (; data=Array{num_type}(data), n_nan=n_nan, n_clamped=n_clamped)
end
