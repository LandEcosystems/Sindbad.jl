```@docs
Sindbad.DataLoaders
```
## Functions

### applyQCBound
```@docs
applyQCBound
```

:::details Code

```julia
function applyQCBound(_data, data_qc, bounds_qc, _data_fill)
    _data_out = _data
    if data_qc < first(bounds_qc) || data_qc > last(bounds_qc)
        _data_out = _data_fill
    end
    return _data_out
end
```

:::


----

### applyUnitConversion
```@docs
applyUnitConversion
```

:::details Code

```julia
function applyUnitConversion(_data, conversion, isadditive=false)
    if isadditive
        _data_out = _data + conversion
    else
        _data_out = _data * conversion
    end
    return _data_out
end
```

:::


----

### cleanData
```@docs
cleanData
```

:::details Code

```julia
function cleanData(_data, _data_info, ::Val{T}) where {T}
    is_invalid_number(_data) && return T(NaN)::T
    _data = applyUnitConversion(_data, _data_info.source_to_sindbad_unit,
        _data_info.additive_unit_conversion)
    bounds = _data_info.bounds
    # no bounds, given as null or an empty list, means no clamping
    if !isnothing(bounds) && !isempty(bounds)
        _data = clamp(_data, first(bounds), last(bounds))
    end
    # the assertion keeps the cleaned data concretely typed when the bounds are an
    # untyped empty list, for which the type of the clamp cannot be inferred
    return T(_data)::T
end
```

:::


----

### getData
```@docs
getData
```

:::details Code

```julia
function getData end

function getData(model_output::LandWrapper, observations, cost_option)
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷField = getproperty(model_output, mod_field)
    ŷ = getproperty(ŷField, mod_subfield)
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
        y = y[:]
        yσ = yσ[:]
    end
    # ymask = observations[obs_ind + 2]
    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end

function getData(model_output::LandWrapper, observations, cost_option)
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷField = getproperty(model_output, mod_field)
    ŷ = getproperty(ŷField, mod_subfield)
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
        y = y[:]
        yσ = yσ[:]
    end
    # ymask = observations[obs_ind + 2]
    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end

function getData(model_output::NamedTuple, observations, cost_option)
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷ = model_output
    sf_name = mod_subfield
    if !hasproperty(model_output, sf_name)
        sf_name = Symbol(String(mod_field) * "__" * String(mod_subfield))
    end
    ŷ = getproperty(model_output, sf_name)
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
    end
    # ymask = observations[obs_ind + 2]

    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end

function getData(model_output::AbstractArray, observations, cost_option)
    ŷ = model_output[cost_option.mod_ind]
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
    end
    y = cost_option.obs_y
    yσ = cost_option.obs_yσ
    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end
```

:::


----

### getForcing
```@docs
getForcing
```

:::details Code

```julia
function getForcingVariableInfo(default_info, var_settings, forcing_data_settings)
    vinfo = merge_namedtuple_prefer_nonempty(default_info, var_settings)
    dims_fallback = (; space=forcing_data_settings.data_dimension.space, time=forcing_data_settings.data_dimension.time)
    var_dims = mergeForcingGroup(dims_fallback, :dimension, default_info, var_settings)
    method_fallback = (; space="None", time="None")
    var_methods = mergeForcingGroup(method_fallback, :interpolation_method, default_info, var_settings)
    vinfo = set_namedtuple_field(vinfo, (:dimension, var_dims))
    vinfo = set_namedtuple_field(vinfo, (:interpolation_method, var_methods))
    return vinfo
end

function getForcing(info::NamedTuple)
    nc_default = nothing
    forcing_data_settings = info.experiment.data_settings.forcing
    # forcing_data_settings = info.experiment.data_settings.forcing
    data_path = forcing_data_settings.default_forcing.data_path
    if !isnothing(data_path)
        data_path = getAbsDataPath(info, data_path)
        print_info(getForcing, @__FILE__, @__LINE__, "default_data_path: `$(data_path)`")
        nc_default = YAXArrays.open_dataset(data_path)
    end

    forcing_mask = nothing
    if :sel_mask ∈ keys(forcing_data_settings)
        if !isnothing(forcing_data_settings.forcing_mask.data_path)
            mask_path = getAbsDataPath(info, forcing_data_settings.forcing_mask.data_path)
            _, forcing_mask = getYaxFromSource(nothing, mask_path, nothing, forcing_data_settings.forcing_mask.source_variable)
            forcing_mask = positive_mask(forcing_mask)
        end
    end

    default_info = info.experiment.data_settings.forcing.default_forcing
    forcing_vars = keys(forcing_data_settings.variables)
    tar_dims = getTargetDimensionOrder(info)
    print_info(getForcing, @__FILE__, @__LINE__, "getting forcing variables. Units given in forcing settings are not strictly enforced but shown for reference. Bounds are applied after unit conversion...", n_m=1)
    num_type = Val{info.helpers.numbers.num_type}()
    loaded_vars = map(forcing_vars) do k
        nc = nc_default
        vinfo = getForcingVariableInfo(default_info, forcing_data_settings.variables[k], forcing_data_settings)
        data_path_v = getAbsDataPath(info, getfield(vinfo, :data_path))
        nc, yax = getYaxFromSource(nc, data_path, data_path_v, vinfo.source_variable)
        yax = renameToCanonicalDims(yax, vinfo.dimension, forcing_data_settings)
        incube = subsetAndProcessCube(yax, forcing_mask, tar_dims, vinfo, info, num_type)
        v_op = vinfo.additive_unit_conversion ? " + " : " * "
        v_op = v_op * "$(vinfo.source_to_sindbad_unit)"
        v_string = "`$(k)` ($(vinfo.sindbad_unit), $(vinfo.bounds)) = <$(vinfo.space_time_type)> `$(vinfo.source_variable)` ($(vinfo.source_unit)) $(v_op)"
        print_info(nothing, @__FILE__, @__LINE__, v_string, n_m=4)
        (k => incube, vinfo)
    end
    incubes = first.(loaded_vars)
    vinfos = last.(loaded_vars)
    interpincubes = resampleForcingCubes(incubes, vinfos, forcing_data_settings, num_type)
    # The sizes are taken after resampling so that they match the target resolution.
    f_sizes = nothing
    f_dimension = nothing
    i_spatiotemporal = findfirst(vinfo -> vinfo.space_time_type == "spatiotemporal", vinfos)
    if !isnothing(i_spatiotemporal)
        f_sizes = collectForcingSizes(info, interpincubes[i_spatiotemporal])
        f_dimension = getSindbadDims(interpincubes[i_spatiotemporal])
    end
    parameters = getParameters(info, f_dimension, NamedTuple{Tuple(forcing_vars)}(Tuple(interpincubes)))
    return createForcingNamedTuple(interpincubes, f_sizes, f_dimension, info; parameters=parameters)
end
```

:::


----

### getInterpolationMethod
```@docs
getInterpolationMethod
```

:::details Code

```julia
function getInterpolationMethod end

function getInterpolationMethod(method::InterpolationMethod, axis::Symbol)
    method isa getInterpolationAxis(axis).method_type || error("`$(nameof(typeof(method)))` is not a $(axis) interpolation method")
    return method
end

function getInterpolationMethod(method::InterpolationMethod, axis::Symbol)
    method isa getInterpolationAxis(axis).method_type || error("`$(nameof(typeof(method)))` is not a $(axis) interpolation method")
    return method
end

function getInterpolationMethod(setting::NamedTuple, axis::Symbol)
    hasproperty(setting, :method) || error("an interpolation_method group needs the name of the method in `method`, got $(setting)")
    method_name = string(setting.method)
    method_type = getInterpolationType(method_name, axis)
    if isnothing(method_type)
        other_axis = axis == :space ? :time : :space
        other_note = isnothing(getInterpolationType(method_name, other_axis)) ? "" : " It is a $(other_axis) method."
        error("unknown $(axis) interpolation_method `$(method_name)`.$(other_note) Valid $(axis) methods are: $(join(getInterpolationMethodNames(axis), ", ")).")
    end
    options = Base.structdiff(setting, NamedTuple{(:method,)})
    unknown = setdiff(keys(options), fieldnames(method_type))
    if !isempty(unknown)
        valid_options = isempty(fieldnames(method_type)) ? "none" : join(fieldnames(method_type), ", ")
        error("$(axis) interpolation_method `$(method_name)` has no option $(join(unknown, ", ")). Its options are: $(valid_options).")
    end
    method = method_type(; options...)
    checkInterpolationMethod(method)
    return method
end

function getInterpolationMethodNames(axis::Symbol)
    axis_info = getInterpolationAxis(axis)
    concreteSubtypes(T) = isconcretetype(T) ? [T] : reduce(vcat, map(concreteSubtypes, subtypes(T)); init=Type[])
    type_names = map(T -> replace(string(nameof(T)), Regex("^" * axis_info.prefix) => ""), concreteSubtypes(axis_info.method_type))
    return sort(map(n -> lowercase(replace(n, r"(?<=[a-z0-9])(?=[A-Z])" => "_")), type_names))
end
```

:::


----

### getModelOutputView
```@docs
getModelOutputView
```

:::details Code

```julia
function getModelOutputView(_dat::AbstractArray{<:Any,N}) where N
    dim = 1
    inds = map(size(_dat)) do _
        ind = dim == 2 ? 1 : Colon()
        dim += 1
        ind
    end
    @view _dat[inds...]
end
```

:::


----

### getNumberOfTimeSteps
```@docs
getNumberOfTimeSteps
```

:::details Code

```julia
function getNumberOfTimeSteps(incubes, time_name)
    i1 = findfirst(c -> YAXArrays.Axes.findAxis(time_name, c) !== nothing, incubes)
    return length(getAxis(time_name, incubes[i1]).values)
end
```

:::


----

### getObservation
```@docs
getObservation
```

:::details Code

```julia
function getObservation(info::NamedTuple, forcing_helpers::NamedTuple)
    observation_data_settings = info.experiment.data_settings.optimization
    forcing_data_settings = info.experiment.data_settings.forcing
    data_path = observation_data_settings.observations.default_observation.data_path
    default_info = observation_data_settings.observations.default_observation
    tar_dims = getTargetDimensionOrder(info)

    nc_default = nothing

    if !isnothing(data_path)
        data_path = getAbsDataPath(info, data_path)
        print_info(getObservation, @__FILE__, @__LINE__, "default_observation_data_path: `$(data_path)`")
        nc_default = YAXArrays.open_dataset(data_path)
    end

    varnames = Symbol.(observation_data_settings.observational_constraints)

    yax_mask = nothing
    if :one_sel_mask ∈ keys(observation_data_settings)
        if !isnothing(observation_data_settings.one_sel_mask)
            mask_path = getAbsDataPath(info, observation_data_settings.one_sel_mask)
            _, yax_mask = getYaxFromSource(nothing, mask_path, nothing, "mask")
            yax_mask = positive_mask(yax_mask)
        end
    end
    obscubes = []
    num_type = Val{info.helpers.numbers.num_type}()
    num_type_bool = Val{Bool}()

    print_info(getObservation, @__FILE__, @__LINE__, "getting observation variables. Units given in optimization settings are not strictly enforced but shown for reference. Bounds are applied after unit conversion...")
    map(varnames) do k

        vinfo = getproperty(observation_data_settings.observations.variables, k)
        print_info(nothing, @__FILE__, @__LINE__, "constraint: `$k`", n_m=4)

        src_var = vinfo.data.source_variable
        nc = nc_default
        nc, yax, vinfo_data, bounds_data = getAllConstraintData(nc, data_path, default_info, vinfo, :data, info)

        # get quality flags data and use it later to mask observations. Set to value of 1 when :qflag field is not given for a data stream or all are turned off by setting optimizatio.optimization.observations.use_quality_flag to false
        nc_qc, yax_qc, vinfo_qc, bounds_qc = getAllConstraintData(nc, data_path, default_info, vinfo, :qflag, info; yax=yax, use_data_sub=observation_data_settings.observations.use_quality_flag)

        # get uncertainty data and add to observations. Set to value of 1 when :unc field is not given for a data stream or all are turned off by setting observation_data_settings.use_uncertainty to false
        nc_unc, yax_unc, vinfo_unc, bounds_unc = getAllConstraintData(nc, data_path, default_info, vinfo, :unc, info; yax=yax, use_data_sub=observation_data_settings.observations.use_uncertainty)

        nc_wgt, yax_wgt, vinfo_wgt, bounds_wgt = getAllConstraintData(nc, data_path, default_info, vinfo, :weight, info; yax=yax, use_data_sub=observation_data_settings.observations.use_spatial_weight)

        _, yax_mask_v, vinfo_mask, bounds_mask = getAllConstraintData(nc, data_path, default_info, vinfo, :sel_mask, info; yax=yax)
        yax_mask_v = positive_mask(yax_mask_v)
        if !isnothing(yax_mask)
            yax_mask_v .= yax_mask .* yax_mask_v
        end
        print_info(nothing, @__FILE__, @__LINE__, "harmonize/subset...", n_m=6)
        @debug "      qflag"
        cyax_qc = subsetAndProcessCube(yax_qc, yax_mask_v, tar_dims, vinfo_qc, info, num_type; clean_data=false)
        @debug "      data"
        cyax = subsetAndProcessCube(yax, yax_mask, tar_dims, vinfo_data, info, num_type; yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      unc"
        cyax_unc = subsetAndProcessCube(yax_unc, yax_mask, tar_dims, vinfo_unc, info, num_type; yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      weight"
        cyax_wgt = subsetAndProcessCube(yax_wgt, yax_mask, tar_dims, vinfo_wgt, info, num_type; yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      mask"
        yax_mask_v = subsetAndProcessCube(yax_mask_v, yax_mask_v, tar_dims, vinfo_mask, info, num_type_bool; clean_data=false)

        push!(obscubes, cyax)
        push!(obscubes, cyax_unc)
        push!(obscubes, yax_mask_v)
        push!(obscubes, cyax_wgt)
    end
    print_info(getObservation, @__FILE__, @__LINE__, "getting observation helpers...", n_m=2)
    @debug "getObservation: getting observation dimensions..."
    indims = getDataDims.(obscubes, Ref(forcing_data_settings.data_dimension.space))
    @debug "getObservation: getting number of time steps..."
    nts = forcing_helpers.sizes
    @debug "getObservation: getting variable name..."
    varnames_all = []
    for v ∈ varnames
        push!(varnames_all, v)
        push!(varnames_all, Symbol(string(v) * "_σ"))
        push!(varnames_all, Symbol(string(v) * "_mask"))
        push!(varnames_all, Symbol(string(v) * "_weight"))
    end
    print_info_separator()

    return (; data=getInputArrayOfType(obscubes, info.helpers.run.input_array_type), dims=indims, variables=Tuple(varnames_all))
end
```

:::


----

### getParameters
```@docs
Sindbad.DataLoaders.getParameters
```

:::details Code

```julia
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
```

:::


----

### getSpatialSubset
```@docs
getSpatialSubset
```

:::details Code

```julia
function getSpatialSubset(ss, v)
    if isa(ss, Dict)
        ss = dict_to_namedtuple(ss)
    end
    if !isnothing(ss)
        ssname = propertynames(ss)
        for ssn ∈ ssname
            ss_r = getproperty(ss, ssn)
            # a variable without the dimension, e.g., a purely temporal one, is kept
            # as it is
            if !isnothing(ss_r) && hasdim(v, ssn)
                ss_range = collect(ss_r)
                checkSubsetValues(v, ssn, ss_range)
                ss_typeName = Symbol("Space" * string(ssn))
                v = spatialSubset(v, ss_range, getfield(Types, ss_typeName)())
            end
        end
    end
    return v
end
```

:::


----

### mapCleanData
```@docs
mapCleanData
```

:::details Code

```julia
function mapCleanData(_data, _data_qc, bounds_qc, _data_info, ::Val{T}) where {T}
    if !isnothing(bounds_qc) && !isnothing(_data_qc)
        _data = map((da, dq) -> applyQCBound(da, dq, bounds_qc, NaN), _data, _data_qc)
    end
    vT = Val{T}()
    _data = map(data_point -> cleanData(data_point, _data_info, vT), _data)
    return _data
end
```

:::


----

### prepCostOptions
```@docs
prepCostOptions
```

:::details Code

```julia
function prepCostOptions end


function prepCostOptions(observations, cost_options)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObsPriors)
    return prepCostOptions(observations, cost_options, CostModelObs())
end

function prepCostOptions(observations, cost_options, ::CostModelObs)
    obs_masks = []
    obs_ys = []
    obs_yσs = []
    valids = []
    is_valid = []
    for cost_option in Table(cost_options)
        y = observations[cost_option.obs_ind]
        yσ = observations[cost_option.obs_ind+1]
        obs_mask = Array(.!is_invalid_number.(y .* yσ))
        y, yσ = aggregateObsData(y, yσ, obs_mask, cost_option, cost_option.aggr_obs)
        idxs = Array(.!is_invalid_number.(y .* yσ))
        push!(is_valid, sum(idxs) >= cost_option.min_data_points)
        push!(obs_masks, obs_mask)
        push!(obs_ys, y)
        push!(obs_yσs, yσ)
        push!(valids, idxs)
    end
    cost_options = set_namedtuple_field(cost_options, (:obs_mask, obs_masks))
    cost_options = set_namedtuple_field(cost_options, (:obs_y, obs_ys))
    cost_options = set_namedtuple_field(cost_options, (:obs_yσ, obs_yσs))
    cost_options = set_namedtuple_field(cost_options, (:valids, valids))
    cost_options = set_namedtuple_field(cost_options, (:is_valid, is_valid))
    cost_options = drop_namedtuple_fields(cost_options, (:min_data_points, :temporal_data_aggr, :aggr_func,))
    cost_option_table = Table(cost_options)
    cost_options_table_filtered = filter(row -> row.is_valid === true , cost_option_table)
    return cost_options_table_filtered
end
```

:::


----

### resampleCube
```@docs
resampleCube
```

:::details Code

```julia
function resampleCube(incube, target_dims, method::InterpolationMethod, num_type)
    radius = resampleRadius(method)
    isnothing(radius) || return getResampleBlock(incube, target_dims, method, num_type, radius)
    core_names, out_dims, source_axes, target_axes = getResampleAxes(incube, target_dims, method)
    plan = resamplePlan(method, source_axes, target_axes)
    out = xmap(resampleSlice!, incube ⊘ core_names;
        output=XOutput(out_dims...; outtype=num_type, properties=incube.properties),
        inplace=true,
        allow_threads=true,
        function_kwargs=(; source_axes, target_axes, method, num_type, plan))
    # xmap puts the core dimensions first
    in_order = DD.name.(DD.dims(incube))
    return DD.name.(DD.dims(out)) == in_order ? out : permutedims(out, in_order)
end

function resampleCubeToTarget(incube, target_dims, method_setting, axis, num_type, var_name)
    isnothing(target_dims) && return incube
    cube_target_dims = filter(target_dim -> hasdim(incube, DD.name(target_dim)), target_dims)
    needs_resample = any(cube_target_dims) do target_dim
        !isSameDim(DD.lookup(incube, DD.name(target_dim)), DD.lookup(target_dim))
    end
    needs_resample || return incube
    method = getInterpolationMethod(method_setting, axis)
    if method isa Union{SpaceInterpNone,TimeInterpNone}
        target_names = join(string.(DD.name.(cube_target_dims)), ", ")
        print_info(nothing, @__FILE__, @__LINE__, "`$(var_name)` keeps its own $(target_names) because its interpolation_method is None", n_m=4)
        return incube
    end
    return resampleCube(incube, cube_target_dims, method, num_type)
end
```

:::


----

### resampleValues!
```@docs
resampleValues!
```

:::details Code

```julia
function resampleValues!(_, _, _, _, method::InterpolationMethod, _)
    error("interpolation method `$(nameof(typeof(method)))` has no resampleValues! method. Add one in src/DataLoaders/resampleCube.jl, see the docstring of resampleValues!.")
end

function resampleValues!(yout, yin, _, _, method::GridInterpolationMethod, plan)
    itp = Interpolations.extrapolate(Interpolations.interpolate(yin, interpolationType(method)), getExtrapolation(method.extrapolation))
    for (I, idx) ∈ zip(CartesianIndices(yout), Iterators.product(plan...))
        yout[I] = itp(idx...)
    end
    return nothing
end

function resampleValues!(yout, yin, source_axes, target_axes, method::TimeMonotonicInterpolationMethod, _)
    x = only(source_axes).points
    y = vec(yin)
    if x[end] < x[1]
        x, y = reverse(x), reverse(y)
    end
    itp = Interpolations.extrapolate(Interpolations.interpolate(x, y, interpolationType(method)), getExtrapolation(method.extrapolation))
    for (i, x_target) ∈ enumerate(only(target_axes).points)
        yout[i] = itp(x_target)
    end
    return nothing
end

function resampleValues!(yout, yin, _, _, ::SpaceInterpZhao2004, plan)
    for I ∈ CartesianIndices(yout)
        weighted_sum, weight_sum = 0.0, 0.0
        for (source_index, weight) ∈ zip(plan.corners[I], plan.weights[I])
            value = yin[source_index]
            # an invalid grid is left out and the weights of the others are
            # normalized among themselves, which the paper does not cover
            isnan(value) && continue
            weighted_sum += weight * value
            weight_sum += weight
        end
        yout[I] = weight_sum > 0 ? weighted_sum / weight_sum : NaN
    end
    return nothing
end
```

:::


----

### saveParameterDataset
```@docs
saveParameterDataset
```

:::details Code

```julia
function saveParameterDataset(params_ds, data_path)
    disk_ds = YAXArrays.savedataset(params_ds, path=data_path, overwrite=true, skeleton=true)
    for (var_name, cube) ∈ params_ds.cubes
        disk_ds.cubes[var_name].data[:] = Array(cube.data)
    end
    return data_path
end
```

:::


----

### subsetAndProcessCube
```@docs
subsetAndProcessCube
```

:::details Code

```julia
function subsetAndProcessCube(yax, forcing_mask, tar_dims, _data_info, info, ::Val{num_type}; clean_data=true, yax_qc=nothing, bounds_qc=nothing) where {num_type}
    forcing_data_settings = info.experiment.data_settings.forcing
    if !isnothing(forcing_mask)
        yax = yax #todo: mask the forcing variables here depending on the mask of 1 and 0
    end

    if !isnothing(tar_dims)
        permutes = getDimPermutation(YAXArrayBase.dimnames(yax), tar_dims)
        @debug "         -> permuting dimensions to $(tar_dims)..."
        yax = permutedims(yax, permutes)
    end
    time_name = Symbol(forcing_data_settings.data_dimension.time)
    if hasproperty(yax, time_name)
        init_date = DateTime(info.helpers.dates.date_begin)
        # date_end covers its whole timestep, so data stamped within the last period
        # such as a daily value at 11:00 UTC is kept and matches the dates range.
        last_date = DateTime(info.helpers.dates.date_end) + info.helpers.dates.timestep - Millisecond(1)
        yax = getindex(yax; (time_name => init_date .. last_date,)...)
    end

    if hasproperty(forcing_data_settings, :subset)
        yax = getSpatialSubset(forcing_data_settings.subset, yax)
    end

    # do a proper check on input type for forcing and if is not lazy do the cleanup
    if info.helpers.run.run_lazy isa DoNotRunLazy
        vNT = Val{num_type}()
        if clean_data
            yax = mapCleanData(yax, yax_qc, bounds_qc, _data_info, vNT)
        else
            # masks and QC flags: an invalid point is zero, i.e., false for a mask
            yax = map(yax_point -> replace_invalid_number(yax_point, 0.0), yax)
            yax = map(num_type, yax)
        end
    end
    return yax
end
```

:::


----

### toDimStackArray
```@docs
toDimStackArray
```

:::details Code

```julia
function toDimStackArray(stackArr, time_interval, p_names; name=:pools)
    return DimArray(stackArr,  (p_names=p_names, Ti=time_interval,); name=name,)
end
```

:::


----

### yaxCubeToKeyedArray
```@docs
yaxCubeToKeyedArray
```

:::details Code

```julia
function yaxCubeToKeyedArray(c)
    t_dims = getSindbadDims(c);
    return KeyedArray(Array(c.data); t_dims...)
end
```

:::


----

## Types

### AllNaN
```@docs
AllNaN
```

----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.DataLoaders
end
```
