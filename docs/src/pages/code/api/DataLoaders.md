```@docs
Sindbad.DataLoaders
```
## Functions

### getData
```@docs
getData
```

:::details Code

```julia
function getData end

function getData(model_output::LandWrapper, observations, cost_option)
    obs_ind = cost_option.obs_ind
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷField = getproperty(model_output, mod_field)
    ŷ = getproperty(ŷField, mod_subfield)
    y = observations[obs_ind]
    yσ = observations[obs_ind+1]
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
    obs_ind = cost_option.obs_ind
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷField = getproperty(model_output, mod_field)
    ŷ = getproperty(ŷField, mod_subfield)
    y = observations[obs_ind]
    yσ = observations[obs_ind+1]
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
    obs_ind = cost_option.obs_ind
    mod_field = cost_option.mod_field
    mod_subfield = cost_option.mod_subfield
    ŷ = model_output
    sf_name = mod_subfield
    if !hasproperty(model_output, sf_name)
        sf_name = Symbol(String(mod_field) * "__" * String(mod_subfield))
    end
    ŷ = getproperty(model_output, sf_name)
    y = observations[obs_ind]
    yσ = observations[obs_ind+1]
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
    end
    # ymask = observations[obs_ind + 2]

    y, yσ, ŷ = getHarmonizedData(y, yσ, ŷ, cost_option)
    return (y, yσ, ŷ)
end

function getData(model_output::AbstractArray, observations, cost_option)
    obs_ind = cost_option.obs_ind
    ŷ = model_output[cost_option.mod_ind]
    if size(ŷ, 2) == 1
        ŷ = getModelOutputView(ŷ)
    end
    y = observations[obs_ind]
    yσ = observations[obs_ind+1]
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
function getForcing(info::NamedTuple)
    nc_default = nothing
    forcing_data_settings = info.experiment.data_settings.forcing
    # forcing_data_settings = info.experiment.data_settings.forcing
    data_path = forcing_data_settings.default_forcing.data_path
    if !isnothing(data_path)
        data_path = getAbsDataPath(info, data_path)
        print_info(getForcing, @__FILE__, @__LINE__, "default_data_path: `$(data_path)`")
        nc_default = loadDataFile(data_path)
    end
    data_backend = getfield(Types, to_uppercase_first(info.helpers.run.input_data_backend, "Backend"))()

    forcing_mask = nothing
    if :sel_mask ∈ keys(forcing_data_settings)
        if !isnothing(forcing_data_settings.forcing_mask.data_path)
            mask_path = getAbsDataPath(info, forcing_data_settings.forcing_mask.data_path)
            _, forcing_mask = getYaxFromSource(nothing, mask_path, nothing, forcing_data_settings.forcing_mask.source_variable, info, data_backend)
            forcing_mask = positive_mask(forcing_mask)
        end
    end

    default_info = info.experiment.data_settings.forcing.default_forcing
    forcing_vars = keys(forcing_data_settings.variables)
    tar_dims = getTargetDimensionOrder(info)
    print_info(getForcing, @__FILE__, @__LINE__, "getting forcing variables. Units given in forcing settings are not strictly enforced but shown for reference. Bounds are applied after unit conversion...", n_m=1)
    vinfo = nothing
    f_sizes = nothing
    f_dimension = nothing
    num_type = Val{info.helpers.numbers.num_type}()
    incubes = map(forcing_vars) do k
        nc = nc_default
        vinfo = merge_namedtuple_prefer_nonempty(default_info, forcing_data_settings.variables[k])
        data_path_v = getAbsDataPath(info, getfield(vinfo, :data_path))
        nc, yax = getYaxFromSource(nc, data_path, data_path_v, vinfo.source_variable, info, data_backend)
        incube = subsetAndProcessYax(yax, forcing_mask, tar_dims, vinfo, info, num_type)
        v_op = vinfo.additive_unit_conversion ? " + " : " * "
        v_op = v_op * "$(vinfo.source_to_sindbad_unit)"
        v_string = "`$(k)` ($(vinfo.sindbad_unit), $(vinfo.bounds)) = <$(vinfo.space_time_type)> `$(vinfo.source_variable)` ($(vinfo.source_unit)) $(v_op)"
        print_info(nothing, @__FILE__, @__LINE__, v_string, n_m=4)
        if vinfo.space_time_type == "spatiotemporal" && isnothing(f_sizes)
            f_sizes = collectForcingSizes(info, incube)
            f_dimension = getSindbadDims(incube)
        end
        incube
    end
    return createForcingNamedTuple(incubes, f_sizes, f_dimension, info)
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
    exe_rules_settings = info.experiment.exe_rules
    data_path = observation_data_settings.observations.default_observation.data_path
    data_backend = getfield(Types, to_uppercase_first(exe_rules_settings.input_data_backend, "Backend"))()
    default_info = observation_data_settings.observations.default_observation
    tar_dims = getTargetDimensionOrder(info)

    nc_default = nothing

    if !isnothing(data_path)
        data_path = getAbsDataPath(info, data_path)
        print_info(getObservation, @__FILE__, @__LINE__, "default_observation_data_path: `$(data_path)`")
        nc_default = loadDataFile(data_path)
    end

    varnames = Symbol.(observation_data_settings.observational_constraints)

    yax_mask = nothing
    if :one_sel_mask ∈ keys(observation_data_settings)
        if !isnothing(observation_data_settings.one_sel_mask)
            mask_path = getAbsDataPath(info, observation_data_settings.one_sel_mask)
            _, yax_mask = getYaxFromSource(nothing, mask_path, nothing, "mask", info, data_backend)
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
        nc, yax, vinfo_data, bounds_data = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :data, info)

        # get quality flags data and use it later to mask observations. Set to value of 1 when :qflag field is not given for a data stream or all are turned off by setting optimizatio.optimization.observations.use_quality_flag to false
        nc_qc, yax_qc, vinfo_qc, bounds_qc = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :qflag, info; yax=yax, use_data_sub=observation_data_settings.observations.use_quality_flag)

        # get uncertainty data and add to observations. Set to value of 1 when :unc field is not given for a data stream or all are turned off by setting observation_data_settings.use_uncertainty to false
        nc_unc, yax_unc, vinfo_unc, bounds_unc = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :unc, info; yax=yax, use_data_sub=observation_data_settings.observations.use_uncertainty)

        nc_wgt, yax_wgt, vinfo_wgt, bounds_wgt = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :weight, info; yax=yax, use_data_sub=observation_data_settings.observations.use_spatial_weight)

        _, yax_mask_v, vinfo_mask, bounds_mask = getAllConstraintData(nc, data_backend, data_path, default_info, vinfo, :sel_mask, info; yax=yax)
        yax_mask_v = positive_mask(yax_mask_v)
        if !isnothing(yax_mask)
            yax_mask_v .= yax_mask .* yax_mask_v
        end
        print_info(nothing, @__FILE__, @__LINE__, "harmonize/subset...", n_m=6)
        @debug "      qflag"
        cyax_qc = subsetAndProcessYax(yax_qc, yax_mask_v, tar_dims, vinfo_qc, info, num_type; clean_data=false)
        @debug "      data"
        cyax = subsetAndProcessYax(yax, yax_mask, tar_dims, vinfo_data, info, num_type; fill_nan=true, yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      unc"
        cyax_unc = subsetAndProcessYax(yax_unc, yax_mask, tar_dims, vinfo_unc, info, num_type; fill_nan=true, yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      weight"
        cyax_wgt = subsetAndProcessYax(yax_wgt, yax_mask, tar_dims, vinfo_wgt, info, num_type; fill_nan=true, yax_qc=cyax_qc, bounds_qc=bounds_qc)
        @debug "      mask"
        yax_mask_v = subsetAndProcessYax(yax_mask_v, yax_mask_v, tar_dims, vinfo_mask, info, num_type_bool; clean_data=false)

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
    input_array_type = getfield(Types, to_uppercase_first(exe_rules_settings.input_array_type, "Input"))()
    print_info_separator()

    return (; data=getInputArrayOfType(obscubes, input_array_type), dims=indims, variables=Tuple(varnames_all))
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
            if !isnothing(ss_r)
                ss_range = collect(ss_r)
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
function mapCleanData(_data, _data_qc, _data_fill, bounds_qc, _data_info, ::Val{T}) where {T}
    if !isnothing(bounds_qc) && !isnothing(_data_qc)
        _data = map((da, dq) -> applyQCBound(da, dq, bounds_qc, _data_fill), _data, _data_qc)
    end
    vT = Val{T}()
    _data = map(data_point -> cleanData(data_point, _data_fill, _data_info, vT), _data)
    return _data
end
```

:::


----

### subsetAndProcessYax
```@docs
subsetAndProcessYax
```

:::details Code

```julia
function subsetAndProcessYax(yax, forcing_mask, tar_dims, _data_info, info, ::Val{num_type}; clean_data=true, fill_nan=false, yax_qc=nothing, bounds_qc=nothing) where {num_type}
    forcing_data_settings = info.experiment.data_settings.forcing
    if !isnothing(forcing_mask)
        yax = yax #todo: mask the forcing variables here depending on the mask of 1 and 0
    end

    if !isnothing(tar_dims)
        permutes = getDimPermutation(YAXArrayBase.dimnames(yax), tar_dims)
        @debug "         -> permuting dimensions to $(tar_dims)..."
        yax = permutedims(yax, permutes)
    end
    if hasproperty(yax, Symbol(forcing_data_settings.data_dimension.time))
        init_date = DateTime(info.helpers.dates.date_begin)
        last_date = DateTime(info.helpers.dates.date_end)
        yax = yax[time=(init_date .. last_date)]
    end

    if hasproperty(forcing_data_settings, :subset)
        yax = getSpatialSubset(forcing_data_settings.subset, yax)
    end

    #todo mean of the data instead of zero or nan
    vfill = 0.0
    if fill_nan
        vfill = NaN
    end
    vNT = Val{num_type}()
    if clean_data
        yax = mapCleanData(yax, yax_qc, vfill, bounds_qc, _data_info, vNT)
    else
        yax = map(yax_point -> replace_invalid_number(yax_point, vfill), yax)
        # yax = num_type.(yax)
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
