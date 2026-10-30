export getParameters
export saveParameterDataset


"""
    getParameters(info::NamedTuple, forcing_axes, forcing_cubes=nothing)

Loads the parameters per location from the parameter input, and makes their values
ready to use in the same way `getForcing` does for the forcing.

# Arguments:
- `info`: A SINDBAD NamedTuple containing all information needed for setup and execution of an experiment.
- `forcing_axes`: the dimension name and coordinate pairs of the forcing, after its subset
- `forcing_cubes`: a NamedTuple of the forcing cubes by variable name, which gives
  the class of each location for a `lookup_parameter_map`

# Returns:
- `nothing` when there is no json or zarr/nc parameters input.
- Otherwise a NamedTuple with:
  - `variables`: the names of the parameter variables
  - `data`: one YAXArray per variable on the spatial dimensions of the forcing, in the
    units of the run, without NaN, and within the bounds of the parameter. A variable
    that varies in time has the time dimension of the forcing first. It is lazy in a
    lazy run, so a large forcing is only read where the run needs it, and in memory
    otherwise.
  - `parameter_table`: a Table with one row per variable with the resolved settings:
    `model`, `name`, `name_full`, `model_approach`, `units`, `timescale_run`,
    `unit_factor`, `lower`, `upper`, `default`, `source_variable`, `data_path`,
    `space_time_type`, `time_dimension`, `time_method`, `n_nan` and `n_clamped`
  - `f_types`: `ForcingWithTime()` or `ForcingWithoutTime()` per variable, as for the
    forcing
  - `dims`: the dimensions of each variable besides the spatial ones, `(time,)` or
    `()`, as `forcing.dims`
  - `lookup_variable`: the `lookup_variable` of a class map whose lookup variable has
    time, else `nothing`

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
- A `lookup_parameter_map` in `default_parameter_map`, e.g.,
  `{"lookup_variable": "f_pft", "default": 4}`, makes the file a class map: its
  variables have one dimension named after the forcing variable `lookup_variable`,
  with one value per class. Each location takes the value of its class in that
  forcing variable, else of the `default` class, else the `default` of the parameter.
  The result is a location map like any other, see `getParameterValuesByClass`.
- A variable with `space_time_type` `spatiotemporal` varies in time like a forcing
  variable, see `getParameterValuesByLocationAndTime`. A class map varies in time when
  its lookup variable does, e.g., a yearly map of PFT, and its variables then stay
  `spatial`. The run updates the models when the values change, see `timeLoopTEM!`.
"""
function getParameters(info::NamedTuple, forcing_axes, forcing_cubes=nothing)
    parameter_input = get(info.experiment.data_settings, :parameters, nothing)
    isnothing(parameter_input) && return nothing
    print_info(getParameters, @__FILE__, @__LINE__, "getting parameters per location from the parameters input...", n_m=1)
    if isnothing(forcing_axes)
        error("A json or zarr/nc parameters input needs a forcing with a spatiotemporal variable to set the locations of the parameters.")
    end
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    time_name = Symbol(info.experiment.data_settings.forcing.data_dimension.time)
    num_type = info.helpers.numbers.num_type
    axes_values = Dict(Symbol(first(f_axis)) => last(f_axis) for f_axis ∈ forcing_axes)
    forcing_space_dims = Tuple(DD.Dim{s_dim}(axes_values[s_dim]) for s_dim ∈ space_dims)
    forcing_time_dim = haskey(axes_values, time_name) ? DD.Dim{time_name}(axes_values[time_name]) : nothing
    open_files = Dict{String,Any}()
    var_names, var_sources = listParameterVariables(parameter_input, open_files)
    lookup = getParameterLookup(parameter_input)
    lookup_cube = isnothing(lookup) ? nothing : getLookupCube(lookup, forcing_cubes, space_dims, time_name)
    lookup_has_time = !isnothing(lookup_cube) && hasdim(lookup_cube, time_name)
    # the lazy cube of each parameter is computed once for an eager run, which reads
    # it per location
    keep_lazy = info.helpers.run.run_lazy isa DoRunLazy

    table_rows = []
    map_classes = []
    data = map(var_names, var_sources) do var_name, var_source
        dataset = openParameterFile!(open_files, var_source.data_path)
        attributes = readVariableAttributes(dataset, var_source.source_variable, var_source.data_path)
        p_row = resolveParameterVariable(var_name, var_source, parameter_input, attributes, info)
        is_spatiotemporal = p_row.space_time_type == "spatiotemporal"
        p_values = if !isnothing(lookup)
            if is_spatiotemporal
                error("The parameter variable `$(var_name)` of the class map by `$(lookup.lookup_variable)` is spatiotemporal. A class map varies in time through its lookup variable, so its variables are spatial.")
            end
            by_class = getParameterValuesByClass(dataset[var_source.source_variable], lookup, lookup_cube, p_row, num_type, var_name)
            push!(map_classes, by_class.classes)
            by_class
        elseif is_spatiotemporal
            isnothing(forcing_time_dim) && error("The parameter variable `$(var_name)` is spatiotemporal, but the forcing has no `$(time_name)` dimension.")
            getParameterValuesByLocationAndTime(dataset[var_source.source_variable], forcing_axes, space_dims, forcing_time_dim, p_row, num_type, var_name)
        else
            getParameterValuesByLocation(dataset[var_source.source_variable], forcing_axes, space_dims, p_row, num_type, var_name)
        end
        push!(table_rows, (; p_row..., n_nan=p_values.n_nan, n_clamped=p_values.n_clamped))
        print_info(nothing, @__FILE__, @__LINE__, "`$(var_name)` = <$(p_row.space_time_type)> `$(p_row.name_full)` ($(p_row.units)) from `$(var_source.source_variable)` in `$(var_source.data_path)` * $(p_row.unit_factor)", n_m=4)
        # kept as a cube on the dimensions and coordinates of the forcing, so a lazy
        # run can map over it together with the forcing
        p_dims = hasdim(p_values.data, time_name) ? (forcing_time_dim, forcing_space_dims...) : forcing_space_dims
        YAXArray(p_dims, keep_lazy ? p_values.data.data : Array(p_values.data.data))
    end
    if !isnothing(lookup)
        allequal(map_classes) || error("The variables of the class map by `$(lookup.lookup_variable)` have different classes. All need the same `$(lookup.lookup_variable)` coordinates.")
        if lookup_has_time
            # counting the classes would read the whole lookup variable, which is far
            # too much for a global forcing at every time step
            print_info(nothing, @__FILE__, @__LINE__, "the class map by `$(lookup.lookup_variable)` varies in time, so the classes that are not in the map are not counted", n_m=4)
        else
            warnClassesNotInMap(lookup, findClassesNotInMap(lookup_cube, first(map_classes)))
        end
    end

    parameter_table = Table([table_rows...])
    full_names = parameter_table.name_full
    duplicates = unique(filter(n -> count(==(n), full_names) > 1, full_names))
    if !isempty(duplicates)
        error("The parameters input sets $(duplicates) more than once. Keep one variable per parameter.")
    end
    has_time = map(p_data -> hasdim(p_data, time_name), Tuple(data))
    f_types = map(t -> t ? ForcingWithTime() : ForcingWithoutTime(), has_time)
    p_dims = map(t -> t ? (time_name,) : (), has_time)
    lookup_variable = lookup_has_time ? lookup.lookup_variable : nothing
    return (; variables=Tuple(var_names), data=Tuple(data), parameter_table=parameter_table, f_types=f_types, dims=p_dims, lookup_variable=lookup_variable)
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
  `timescale_run`, `unit_factor`, `lower`, `upper`, `default`, `source_variable`,
  `data_path`, `space_time_type`, `time_dimension` and `time_method`. `lower`, `upper`
  and `default` are in the units of the run.

# Notes:
- `space_time_type` is `spatial` or `spatiotemporal`, as for a forcing variable.
- `time_dimension` and `time_method` are the `time` of the `dimension` and
  `interpolation_method` groups, from the variable, then `default_parameter_map`. They
  default to `time` and `Previous`, so a value holds from its time stamp until the
  next one.
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
    if space_time_type ∉ ("spatial", "spatiotemporal")
        error("The parameter variable `$(var_string)` has space_time_type `$(space_time_type)`. A parameters input supports `spatial` and `spatiotemporal` parameters.")
    end
    # the time settings are groups like those of a forcing variable
    time_dimension = string(firstSetValue(:time, "time", getSettingValue(var_settings, :dimension), getSettingValue(default_map, :dimension)))
    time_method = string(firstSetValue(:time, "Previous", getSettingValue(var_settings, :interpolation_method), getSettingValue(default_map, :interpolation_method)))

    num_type = info.helpers.numbers.num_type
    timescale_run = string(get_setting(:timescale_run, ""))
    unit_factor = getUnitConversionForParameter(timescale_run, info.helpers.dates.temporal_resolution)
    lower = toRunUnits(get_setting(:lower, nothing), model_row.lower, unit_factor, num_type)
    upper = toRunUnits(get_setting(:upper, nothing), model_row.upper, unit_factor, num_type)
    default = toRunUnits(get_setting(:default, nothing), model_row.default, unit_factor, num_type)
    if lower > upper
        error("The parameter variable of `$(name_full)` has a lower bound $(lower) above its upper bound $(upper).")
    end

    return (; model=model_row.model, name=model_row.name, name_full=name_full, model_approach=model_row.model_approach, units=string(model_row.units), timescale_run=timescale_run, unit_factor=num_type(unit_factor), lower=lower, upper=upper, default=default, source_variable=var_source.source_variable, data_path=var_source.data_path, space_time_type=space_time_type, time_dimension=time_dimension, time_method=time_method)
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
    getParameterValuesByLocation(yax, forcing_axes, space_dims, p_row, num_type, var_name)

Returns the values of one variable of a location map at the locations of the forcing,
ready to use.

# Returns:
- A NamedTuple with the `data` with the spatial dimensions of the forcing in its
  order, and the `n_nan` and `n_clamped` of the values at the forcing locations.

# Notes:
- The coordinates are selected by value, so the file may have more locations than the
  forcing, in any order.
- An error lists the coordinates of the forcing that are missing in the file.
- The locations are selected as a view and the values are made ready by `map` with
  `parameterCleaner`, so the `data` is computed only where it is read. The counts are
  taken in one pass over the selected values, see `countReplacedValues`.
"""
function getParameterValuesByLocation(yax, forcing_axes, space_dims, p_row, num_type, var_name)
    yax = selectForcingLocations(yax, forcing_axes, space_dims, var_name)
    extra_dims = setdiff(DD.name(DD.dims(yax)), space_dims)
    if !isempty(extra_dims)
        error("The parameter variable `$(var_name)` has the dimensions $(extra_dims) besides the spatial dimensions of the forcing. Set its `space_time_type` to `spatiotemporal` when one of them is time.")
    end
    yax = permutedims(yax, getDimPermutation(DD.name(DD.dims(yax)), space_dims))
    counts = countReplacedValues(yax.data, p_row, num_type)
    warnReplacedValues(p_row, counts, "locations")
    return (; data=map(parameterCleaner(p_row, num_type), yax), n_nan=counts.n_nan, n_clamped=counts.n_clamped)
end

"""
    getParameterValuesByLocationAndTime(yax, forcing_axes, space_dims, forcing_time_dim, p_row, num_type, var_name)

Returns the values of one spatiotemporal variable of a location map at the locations
and time steps of the forcing, ready to use.

# Arguments:
- `forcing_time_dim`: the time dimension of the forcing, i.e., the time steps of the
  run
- the other arguments are the same as for `getParameterValuesByLocation`

# Returns:
- A NamedTuple with the `data` with the time dimension of the forcing first and its
  spatial dimensions after it, and the `n_nan` and `n_clamped` of the values in the
  file at the forcing locations.

# Notes:
- The time dimension of the file is `p_row.time_dimension`. Its coordinate is a date,
  or a year as an integer, which is taken as the start of that year.
- The values are put on the time steps of the run with `resampleToTarget` and the
  method `p_row.time_method`, as a forcing variable. With the default `Previous`, a
  value holds from its time stamp until the next one. The steps before the first time
  stamp take the first value, and those after the last time stamp the last value.
- The counts are taken on the values in the file, before they are put on the time
  steps of the run.
"""
function getParameterValuesByLocationAndTime(yax, forcing_axes, space_dims, forcing_time_dim, p_row, num_type, var_name)
    source_time = Symbol(p_row.time_dimension)
    if !hasdim(yax, source_time)
        error("The parameter variable `$(var_name)` is spatiotemporal, but has no `$(source_time)` dimension. Its dimensions are $(DD.name(DD.dims(yax))). Set the `time` of `dimension` for the variable or in `default_parameter_map`.")
    end
    yax = selectForcingLocations(yax, forcing_axes, space_dims, var_name)
    extra_dims = setdiff(DD.name(DD.dims(yax)), (space_dims..., source_time))
    if !isempty(extra_dims)
        error("The parameter variable `$(var_name)` has the dimensions $(extra_dims) besides the spatial and time dimensions of the forcing.")
    end
    time_name = DD.name(forcing_time_dim)
    yax = setParameterTimeStamps(yax, source_time, time_name)
    counts = countReplacedValues(yax.data, p_row, num_type)
    warnReplacedValues(p_row, counts, "values")
    yax = resampleToTarget(yax, (forcing_time_dim,), p_row.time_method, num_type, var_name)
    if length(DD.lookup(yax, time_name)) != length(forcing_time_dim)
        error("The parameter variable `$(var_name)` is not on the time steps of the run, because its time `interpolation_method` is `$(p_row.time_method)`. Use a method such as `Previous`.")
    end
    yax = permutedims(yax, getDimPermutation(DD.name(DD.dims(yax)), (time_name, space_dims...)))
    return (; data=map(parameterCleaner(p_row, num_type), yax), n_nan=counts.n_nan, n_clamped=counts.n_clamped)
end

"""
    selectForcingLocations(yax, forcing_axes, space_dims, var_name)

Returns a view of a parameter variable at the spatial coordinates of the forcing, in
the order of the forcing.

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
        file_values = collect(DD.lookup(yax, s_dim))
        missing_values = setdiff(forcing_values, file_values)
        if !isempty(missing_values)
            error("The parameter variable `$(var_name)` has no values for $(length(missing_values)) `$(s_dim)` of the forcing: $(missing_values).")
        end
        positions = [findfirst(==(v), file_values) for v ∈ forcing_values]
        yax = view(yax, DD.Dim{s_dim}(positions))
    end
    return yax
end

"""
    setParameterTimeStamps(yax, source_time, time_name)

Returns `yax` with its time dimension `source_time` renamed to `time_name`, the time
dimension of the forcing, and its coordinate as `DateTime`.

# Notes:
- An integer or other real coordinate is taken as a year, and its time stamp is the
  start of that year, e.g., the `time_annual` of a yearly map.
"""
function setParameterTimeStamps(yax, source_time, time_name)
    stamps = collect(DD.lookup(yax, source_time))
    date_times = eltype(stamps) <: Real ? [DateTime(round(Int, s), 1, 1) for s ∈ stamps] : DateTime.(stamps)
    new_dims = map(d -> DD.name(d) == source_time ? DD.Dim{time_name}(date_times) : d, DD.dims(yax))
    return YAXArray(new_dims, yax.data, yax.properties)
end

"""
    getParameterLookup(parameter_input)

Returns the `(; lookup_variable, default)` of the `lookup_parameter_map` of
`default_parameter_map`, or `nothing` for a location map. `default` is `nothing` when
not given.
"""
function getParameterLookup(parameter_input)
    lookup = getSettingValue(parameter_input.default_parameter_map, :lookup_parameter_map)
    isnothing(lookup) && return nothing
    lookup_variable = firstSetValue(:lookup_variable, nothing, lookup)
    isnothing(lookup_variable) && error("The `lookup_parameter_map` of the parameters input needs a `lookup_variable`, the forcing variable with the class of each location, but has $(lookup).")
    default = firstSetValue(:default, nothing, lookup)
    return (; lookup_variable=Symbol(lookup_variable), default=isnothing(default) ? nothing : round(Int, default))
end


"""
    getLookupCube(lookup, forcing_cubes, space_dims, time_name)

Returns the forcing cube of the `lookup_variable`, with the spatial dimensions of the
forcing in their order, and its time dimension `time_name` first when it has one.

# Notes:
- With time, the class of a location can change between time steps, e.g., with a
  yearly map of PFT, and so do the parameters of the class map.
"""
function getLookupCube(lookup, forcing_cubes, space_dims, time_name)
    lookup_variable = lookup.lookup_variable
    if isnothing(forcing_cubes) || !hasproperty(forcing_cubes, lookup_variable)
        error("The `lookup_variable` `$(lookup_variable)` of the parameters input is not a forcing variable. Add it to the forcing settings.")
    end
    cube = getproperty(forcing_cubes, lookup_variable)
    cube_dims = DD.name(DD.dims(cube))
    target_dims = time_name ∈ cube_dims ? (time_name, space_dims...) : Tuple(space_dims)
    if Set(cube_dims) != Set(target_dims)
        error("The `lookup_variable` `$(lookup_variable)` has the dimensions $(cube_dims), but needs the spatial dimensions $(Tuple(space_dims)) of the forcing, and its time dimension `$(time_name)` when the classes change in time.")
    end
    return permutedims(cube, getDimPermutation(cube_dims, target_dims))
end


"""
    getParameterValuesByClass(yax, lookup, lookup_cube, p_row, num_type, var_name)

Returns the values of one variable of a class map at the locations of the forcing.

# Arguments:
- `yax`: the variable, with only the dimension `lookup_variable`, one value per class
- `lookup`: the `(; lookup_variable, default)` from `getParameterLookup`
- `lookup_cube`: the forcing cube with the class of each location, from
  `getLookupCube`
- `p_row`: the resolved settings of the parameter, see `resolveParameterVariable`
- `num_type`: the number type of the run
- `var_name`: the name of the variable, for the errors

# Returns:
- A NamedTuple with the `data` on the dimensions of `lookup_cube`, i.e., the spatial
  dimensions of the forcing and its time dimension when the lookup variable has one,
  the `classes` of the variable, and the `n_nan` and `n_clamped` of its values by
  class.

# Notes:
- The values by class are made ready with `cleanParameterValues`, so `n_nan` and
  `n_clamped` count classes, not locations.
- A location takes the value of its class, else the value of the `default` class,
  else the `default` of the parameter. A class is compared as an integer.
- The `data` is `map` over `lookup_cube`, which is computed only where it is read
  when the forcing cube is on disk.
"""
function getParameterValuesByClass(yax, lookup, lookup_cube, p_row, num_type, var_name)
    lookup_variable = lookup.lookup_variable
    var_dims = DD.name(DD.dims(yax))
    if var_dims != (lookup_variable,)
        error("The parameter variable `$(var_name)` has the dimensions $(var_dims), but a class map by `$(lookup_variable)` needs only the dimension `$(lookup_variable)`.")
    end
    classes = round.(Int, collect(DD.lookup(yax, lookup_variable)))
    allunique(classes) || error("The `$(lookup_variable)` dimension of `$(var_name)` has repeated classes: $(classes).")
    class_values = cleanParameterValues(Array(yax), p_row, num_type; what="classes")
    value_of_class = Dict(zip(classes, class_values.data))
    if !isnothing(lookup.default) && !haskey(value_of_class, lookup.default)
        error("The `default` class $(lookup.default) of the class map by `$(lookup_variable)` is not one of its classes $(classes).")
    end
    # assigned once, so the closure below is type stable and the cube has its eltype
    fallback = isnothing(lookup.default) ? num_type(p_row.default) : value_of_class[lookup.default]
    location_value = class -> (ismissing(class) || isnan(class)) ? fallback : get(value_of_class, round(Int, class), fallback)
    return (; data=map(location_value, lookup_cube), classes, n_nan=class_values.n_nan, n_clamped=class_values.n_clamped)
end


"""
    findClassesNotInMap(lookup_cube, classes)

Returns the number of locations of each class of `lookup_cube` that is not in
`classes`, with `missing` for the locations without a class.

# Notes:
- The cube is read chunk by chunk, so a large forcing is not loaded at once.
"""
function findClassesNotInMap(lookup_cube, classes)
    class_set = Set(classes)
    counts = Dict{Union{Missing,Int},Int}()
    lookup_data = lookup_cube.data
    for chunk ∈ YAXArrays.Cubes.eachchunk(lookup_data)
        for class ∈ lookup_data[chunk...]
            key = (ismissing(class) || isnan(class)) ? missing : round(Int, class)
            (ismissing(key) || key ∉ class_set) && (counts[key] = get(counts, key, 0) + 1)
        end
    end
    return counts
end

# One warning for the locations whose class is not in the class map, with what they
# use instead.
function warnClassesNotInMap(lookup, counts)
    isempty(counts) && return nothing
    fallback = isnothing(lookup.default) ? "the default of each parameter" : "the values of the default class $(lookup.default)"
    n_without = get(counts, missing, 0)
    missing_classes = join(["$(c) ($(n))" for (c, n) ∈ sort(collect(filter(p -> !ismissing(first(p)), counts)); by=first)], ", ")
    @warn "The class map by `$(lookup.lookup_variable)` has no values for $(sum(values(counts))) locations, which use $(fallback). Classes not in the map, with their number of locations: $(isempty(missing_classes) ? "none" : missing_classes). Locations without a class: $(n_without)."
    return nothing
end


"""
    cleanParameterValues(values, p_row, num_type; what="locations")

Returns the values of one parameter variable ready to use, see `parameterCleaner`,
and the counts of the replaced values. One warning is printed for each kind of
replaced values, counted in `what`, e.g., locations or classes.
"""
function cleanParameterValues(values, p_row, num_type; what="locations")
    counts = countReplacedValues(values, p_row, num_type)
    warnReplacedValues(p_row, counts, what)
    return (; data=Array{num_type}(map(parameterCleaner(p_row, num_type), values)), n_nan=counts.n_nan, n_clamped=counts.n_clamped)
end

"""
    parameterCleaner(p_row, num_type)

Returns the function that makes one value of a parameter file ready to use.

# Notes:
- The value is converted to `num_type` and multiplied by the `unit_factor` of
  `p_row`.
- NaN and missing are replaced by the `default` of `p_row`, and a value outside
  `[lower, upper]` is clamped.
- The settings are taken out of `p_row` as values of `num_type`, so the function is
  type stable inside `map`.
"""
function parameterCleaner(p_row, num_type)
    default, lower, upper, factor = num_type(p_row.default), num_type(p_row.lower), num_type(p_row.upper), num_type(p_row.unit_factor)
    return value -> (ismissing(value) || isnan(value)) ? default : clamp(oftype(factor, value) * factor, lower, upper)
end

"""
    countReplacedValues(values, p_row, num_type)

Returns the `n_nan` and `n_clamped` that `parameterCleaner` replaces in `values`, and
their total `n_values`. A lazy array is read chunk by chunk.
"""
function countReplacedValues(values, p_row, num_type)
    lower, upper, factor = num_type(p_row.lower), num_type(p_row.upper), num_type(p_row.unit_factor)
    n_nan, n_clamped, n_values = 0, 0, 0
    for chunk ∈ YAXArrays.Cubes.eachchunk(values)
        for value ∈ values[chunk...]
            n_values += 1
            if ismissing(value) || isnan(value)
                n_nan += 1
            elseif !(lower <= oftype(factor, value) * factor <= upper)
                n_clamped += 1
            end
        end
    end
    return (; n_nan, n_clamped, n_values)
end

# One warning for each kind of replaced values of a parameter.
function warnReplacedValues(p_row, counts, what)
    if counts.n_nan > 0
        @warn "The parameter `$(p_row.name_full)` is NaN at $(counts.n_nan) of $(counts.n_values) $(what). The default $(p_row.default) is used there."
    end
    if counts.n_clamped > 0
        @warn "The parameter `$(p_row.name_full)` is outside [$(p_row.lower), $(p_row.upper)] at $(counts.n_clamped) of $(counts.n_values) $(what). The values are clamped to the bounds."
    end
    return nothing
end


"""
    saveParameterDataset(params_ds, data_path)

Saves the dataset of a parameter file.

# Arguments:
- `params_ds`: the dataset with the parameter variables
- `data_path`: the path of the file to write, a zarr store for the files Sindbad writes

# Notes:
- `savedataset` cannot copy variables of strings, because it sizes its copy buffer from
  the size of the element type. The file is therefore created as a skeleton and each
  variable is written directly, which is fine for the small arrays of a parameter file.
"""
function saveParameterDataset(params_ds, data_path)
    disk_ds = YAXArrays.savedataset(params_ds, path=data_path, overwrite=true, skeleton=true)
    for (var_name, cube) ∈ params_ds.cubes
        disk_ds.cubes[var_name].data[:] = Array(cube.data)
    end
    return data_path
end
