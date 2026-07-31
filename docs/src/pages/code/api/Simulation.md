```@docs
Sindbad.Simulation
```
## Functions

### TEMYax
```@docs
TEMYax
```

:::details Code

```julia
function TEMYax(map_cubes...;selected_models::Tuple, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data)
    # Make NaN check here instead of AllNaN filters
    

    outputs, inputs = unpackYaxForward(map_cubes; output_vars, forcing_vars)
    # What exactly should the NaN check be? 
    # Do I check per variable, or for all variables together?
    any(ismissing || isnan , inputs)

    # ? apply clean_data fields to input data points
    _data_fill, _forcing_default_info, _num_type, _forcing_vars_info = clean_data

    inputs = map(enumerate(inputs)) do (i, in_forcing)
        _data_info = merge_namedtuple(_forcing_default_info, _forcing_vars_info[i])
        map(data_point -> cleanData(data_point, _data_fill, _data_info, _num_type), in_forcing)
    end
    loc_forcing = (; Pair.(forcing_vars, inputs)...)
    land_out = coreTEMYax(selected_models, loc_forcing, loc_land, tem)
    i = 1
    foreach(output_vars) do var_pair
        data = land_out[first(var_pair)][last(var_pair)]
            fillOutputYax(outputs[i], data)
            i += 1
    end
end
```

:::


----

### coreTEM
```@docs
coreTEM
```

:::details Code

```julia
function coreTEM end

function coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_land, tem_info, spinup_mode)

    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode)

    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return land_time_series
end

function coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_land, tem_info, spinup_mode)

    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode)

    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return land_time_series
end

function coreTEM(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, land_time_series, loc_land, tem_info, spinup_mode)
    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode)

    timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_time_series, land_spin, tem_info, tem_info.run.debug_model)
    return nothing
end
```

:::


----

### coreTEM!
```@docs
coreTEM!
```

:::details Code

```julia
function coreTEM!(selected_models, loc_forcing, loc_spinup_forcing, loc_forcing_t, loc_output, loc_land, tem_info)
    # update the loc_forcing with the actual location
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing_t, 1, tem_info.vals.forcing_types)
    # run precompute
    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers) 
    # run spinup
    land_spin = spinupTEM(selected_models, loc_spinup_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)

    timeLoopTEM!(selected_models, loc_forcing, loc_forcing_t, loc_output, land_spin, tem_info.vals.forcing_types, tem_info.model_helpers, tem_info.vals.output_vars, tem_info.n_timesteps, tem_info.run.debug_model)
    return nothing
end
```

:::


----

### getAllSpinupForcing
```@docs
getAllSpinupForcing
```

:::details Code

```julia
function getAllSpinupForcing(forcing, spin_sequences::Vector{SpinupSequenceWithAggregator}, tem_helpers)
    spinup_forcing = (;)
    for seq ∈ spin_sequences
        forc = getfield(seq, :forcing)
        forc_name = forc
        if forc_name ∉ keys(spinup_forcing)
            seq_forc = getSpinupForcing(forcing, seq, tem_helpers.vals.forcing_types)
            spinup_forcing = set_namedtuple_field(spinup_forcing, (forc_name, seq_forc))
        end
    end
    return spinup_forcing
end
```

:::


----

### getForcingForTimeStep
```@docs
getForcingForTimeStep
```

----

### getLocData
```@docs
getLocData
```

:::details Code

```julia
function getLocData(forcing::NamedTuple, output_array::AbstractArray, loc_ind)
    loc_forcing = getLocData(forcing, loc_ind)
    loc_output = getLocData(output_array, loc_ind)
    return loc_forcing, loc_output
end

function getLocData(output_array::AbstractArray, loc_ind)
    loc_output = map(output_array) do a
        view_at_trailing_indices(a, loc_ind)
    end
    return loc_output
end

function getLocData(forcing::NamedTuple, loc_ind)
    loc_forcing = map(forcing) do a
        view_at_trailing_indices(a, loc_ind) |> Array
    end
    return loc_forcing
end
```

:::


----

### getOutDims
```@docs
getOutDims
```

:::details Code

```julia
function getOutDims end

function getOutDims(info, forcing_helpers)
    outdims = getOutDims(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims
end

function getOutDims(info, forcing_helpers)
    outdims = getOutDims(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims
end

function getOutDims(info, forcing_helpers, ::Union{OutputArray, OutputMArray, OutputSizedArray})
    outdims_pairs = getOutDimsPairs(info.output, forcing_helpers)
    outdims = map(outdims_pairs) do dim_pairs
        od = []
        for _dim in dim_pairs
            push!(od, YAXArrays.Dim{first(_dim)}(last(_dim)))
        end
        Tuple(od)
    end
    return outdims
end

function getOutDims(info, forcing_helpers, ::OutputYAXArray)
    outdims_pairs = getOutDimsPairs(info.output, forcing_helpers);
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    var_dims = map(outdims_pairs) do dim_pairs
        od = []
        for _dim in dim_pairs
            if first(_dim) ∉ space_dims
                push!(od, DD.rebuild(DD.Dimensions.name2dim(first(_dim)),(last(_dim))))
            end
        end
        Tuple(od)
    end
    v_index = 1
    outdims = map(info.output.variables) do vname_full
        vname = string(last(vname_full))
        _properties = collectMetadata(info, vname_full)
        vdims = var_dims[v_index]
        # outformat = info.settings.experiment.model_output.format
        outformat = info.output.format # ? test and see if this works, which it should!
        backend = outformat == "nc" ? :netcdf : :zarr
        out_dim = YAXArrays.XOutput(vdims...)#=;
        properties = _properties,
        path=info.output.file_info.file_prefix * "_$(vname).$(outformat)",
        backend=backend,
        overwrite=true)=#
        v_index += 1
        out_dim
    end
    return outdims
end

function getOutDimsArrays end

function getOutDimsArrays(info, forcing_helpers)
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers)
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers, oarr::OutputArray)
    outdims = getOutDims(info, forcing_helpers, oarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers, omarr::OutputMArray)
    outdims = getOutDims(info, forcing_helpers, omarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    marray = MArray{Tuple{size(outarray)...},eltype(outarray)}(undef)
    return outdims, marray
end

function getOutDimsArrays(info, forcing_helpers, osarr::OutputSizedArray)
    outdims = getOutDims(info, forcing_helpers, osarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    sized_array = SizedArray{Tuple{size(outarray)...},eltype(outarray)}(undef)
    return outdims, sized_array
end

function getOutDimsArrays(info, forcing_helpers, oayax::OutputYAXArray)
    outdims = getOutDims(info, forcing_helpers, oayax)
    outarray = nothing
    return outdims, outarray
end

function getOutDimsPairs(tem_output, forcing_helpers; dthres=1)
    forcing_axes = forcing_helpers.axes
    dim_loops = first.(forcing_axes)
    axes_dims_pairs = []
    if !isnothing(forcing_helpers.dimensions.permute)
        dim_perms = Symbol.(forcing_helpers.dimensions.permute)
        if dim_loops !== dim_perms
            for ix in eachindex(dim_perms)
                dp_i = dim_perms[ix]
                dl_ind = findall(x -> x == dp_i, dim_loops)[1]
                f_a = forcing_axes[dl_ind]
                ax_dim = Pair(first(f_a), last(f_a))
                push!(axes_dims_pairs, ax_dim)
            end
        end
    else
        axes_dims_pairs = map(x -> Pair(first(x), last(x)), forcing_axes)
    end
    opInd = 1
    outdims_pairs = map(tem_output.variables) do vname_full
        depth_info = tem_output.depth_info[opInd]
        depth_size = first(depth_info)
        depth_name = last(depth_info)
        od = []
        push!(od, axes_dims_pairs[1])
        if depth_size > dthres
            if depth_size == 1
                depth_name = "idx"
            end
            push!(od, Pair(Symbol(depth_name), (1:depth_size)))
        end
        foreach(axes_dims_pairs[2:end]) do f_d
            push!(od, f_d)
        end
        opInd += 1
        Tuple(od)
    end
    return outdims_pairs
end
```

:::


----

### getOutDimsArrays
```@docs
getOutDimsArrays
```

:::details Code

```julia
function getOutDimsArrays end

function getOutDimsArrays(info, forcing_helpers)
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers)
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers, oarr::OutputArray)
    outdims = getOutDims(info, forcing_helpers, oarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    return outdims, outarray
end

function getOutDimsArrays(info, forcing_helpers, omarr::OutputMArray)
    outdims = getOutDims(info, forcing_helpers, omarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    marray = MArray{Tuple{size(outarray)...},eltype(outarray)}(undef)
    return outdims, marray
end

function getOutDimsArrays(info, forcing_helpers, osarr::OutputSizedArray)
    outdims = getOutDims(info, forcing_helpers, osarr)
    outarray = getNumericArrays(info, forcing_helpers.sizes)
    sized_array = SizedArray{Tuple{size(outarray)...},eltype(outarray)}(undef)
    return outdims, sized_array
end

function getOutDimsArrays(info, forcing_helpers, oayax::OutputYAXArray)
    outdims = getOutDims(info, forcing_helpers, oayax)
    outarray = nothing
    return outdims, outarray
end
```

:::


----

### getSequence
```@docs
getSequence
```

:::details Code

```julia
function getSequence(year_disturbance, info_helpers_dates; nrepeat_base=200, year_start = 1979)
    nrepeat_age = nrepeatYearsAge(year_disturbance; year_start)
    sequence = [
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_base),
        Dict("spinup_mode" => "eta_scale_AH", "forcing" => "day_MSC", "n_repeat" => 1),
    ]
    if nrepeat_age == 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_base),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
        ]
    elseif nrepeat_age > 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_base),
            Dict("spinup_mode" => "eta_scale_A0H", "forcing" => "day_MSC", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_age),
        ]
    end
    new_sequence = getSpinupTemLite(getSpinupSequenceWithTypes(sequence, info_helpers_dates))
    return new_sequence
end
```

:::


----

### getSpatialInfo
```@docs
getSpatialInfo
```

:::details Code

```julia
function getSpatialInfo end

function getSpatialInfo(forcing_helpers)
    @debug "     getting the space locations to run the model loop"
    forcing_sizes = forcing_helpers.sizes
    loopvars = collect(keys(forcing_sizes))
    additionaldims = setdiff(loopvars, [Symbol(forcing_helpers.dimensions.time)])
    spacesize = values(forcing_sizes[additionaldims])
    loc_space_maps = vec(collect(Iterators.product(Base.OneTo.(spacesize)...)))
    loc_space_maps = map(loc_space_maps) do loc_names
        map(zip(loc_names, additionaldims)) do (loc_index, lv)
            lv => loc_index
        end
    end
    loc_space_maps = Tuple(loc_space_maps)
    space_ind = Tuple([Tuple(last.(loc_space_map)) for loc_space_map ∈ loc_space_maps])
    return space_ind, loc_space_maps
end

function getSpatialInfo(forcing_helpers)
    @debug "     getting the space locations to run the model loop"
    forcing_sizes = forcing_helpers.sizes
    loopvars = collect(keys(forcing_sizes))
    additionaldims = setdiff(loopvars, [Symbol(forcing_helpers.dimensions.time)])
    spacesize = values(forcing_sizes[additionaldims])
    loc_space_maps = vec(collect(Iterators.product(Base.OneTo.(spacesize)...)))
    loc_space_maps = map(loc_space_maps) do loc_names
        map(zip(loc_names, additionaldims)) do (loc_index, lv)
            lv => loc_index
        end
    end
    loc_space_maps = Tuple(loc_space_maps)
    space_ind = Tuple([Tuple(last.(loc_space_map)) for loc_space_map ∈ loc_space_maps])
    return space_ind, loc_space_maps
end

function getSpatialInfo(forcing, filter_nan_pixels)
    space_ind, loc_space_maps = getSpatialInfo(forcing.helpers)
    loc_space_maps = filterNanPixels(forcing, loc_space_maps, filter_nan_pixels)
    space_ind = Tuple([Tuple(last.(loc_space_map)) for loc_space_map ∈ loc_space_maps])
    return space_ind
end
```

:::


----

### prepTEM
```@docs
prepTEM
```

:::details Code

```julia
function prepTEM end

function prepTEM(forcing::NamedTuple, info::NamedTuple)
    selected_models = info.models.forward
    return prepTEM(selected_models, forcing, info)
end

function prepTEM(forcing::NamedTuple, info::NamedTuple)
    selected_models = info.models.forward
    return prepTEM(selected_models, forcing, info)
end

function prepTEM(selected_models, forcing::NamedTuple, info::NamedTuple)
    print_info(prepTEM, @__FILE__, @__LINE__, "preparing to run terrestrial ecosystem model (TEM)", n_f=1)
    output = prepTEMOut(info, forcing.helpers)
    print_info(prepTEM, @__FILE__, @__LINE__, "  preparing helpers for running model experiment", n_f=4)
    run_helpers = helpPrepTEM(selected_models, info, forcing, output, info.helpers.run.land_output_type)
    print_info_separator()

    return run_helpers
end

function prepTEM(selected_models, forcing::NamedTuple, observations::NamedTuple, info::NamedTuple)
    print_info(prepTEM, @__FILE__, @__LINE__, "preparing to run terrestrial ecosystem model (TEM)", n_f=1)
    output = prepTEMOut(info, forcing.helpers)
    run_helpers = helpPrepTEM(selected_models, info, forcing, observations, output, info.helpers.run.land_output_type)
    print_info_separator()

    return run_helpers
end
```

:::


----

### prepTEMOut
```@docs
prepTEMOut
```

:::details Code

```julia
function prepTEMOut(info::NamedTuple, forcing_helpers::NamedTuple)
    print_info(prepTEMOut, @__FILE__, @__LINE__, "preparing output helpers for Terrestrial Ecosystem Model (TEM)", n_f=4)
    land = info.helpers.land_init
    output_tuple = (;)
    output_tuple = set_namedtuple_field(output_tuple, (:land_init, land))
    @debug "     prepTEMOut: getting out variables, dimension and arrays..."
    outdims, outarray = getOutDimsArrays(info, forcing_helpers, info.helpers.run.output_array_type)
    output_tuple = set_namedtuple_field(output_tuple, (:dims, outdims))
    output_tuple = set_namedtuple_field(output_tuple, (:data, outarray))
    output_tuple = set_namedtuple_field(output_tuple, (:variables, info.output.variables))

    output_tuple = setupOptiOutput(info, output_tuple, info.helpers.run.run_optimization)
    @debug "\n----------------------------------------------\n"
    return output_tuple
end
```

:::


----

### runTEM
```@docs
runTEM
```

:::details Code

```julia
function runTEMOne(selected_models, loc_forcing, land_init, tem)
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing, 1, tem.vals.forcing_types)
    loc_land = definePrecomputeTEM(selected_models, loc_forcing_t, land_init,
        tem.model_helpers)
    loc_land = computeTEM(selected_models, loc_forcing_t, loc_land, tem.model_helpers)
    # loc_land = drop_empty_namedtuple_fields(loc_land)
    loc_land = addSpinupLog(loc_land, tem.spinup_sequence, tem.run.store_spinup)
    # loc_land = definePrecomputeTEM(selected_models, loc_forcing_t, loc_land,
        # tem.model_helpers)
    # loc_land = precomputeTEM(selected_models, loc_forcing_t, loc_land,
        # tem.model_helpers)
    # loc_land = computeTEM(selected_models, loc_forcing_t, loc_land, tem.model_helpers)
    return loc_forcing_t, loc_land
end
```

:::


----

### runTEM!
```@docs
runTEM!
```

:::details Code

```julia
function runTEM! end

function runTEM!(selected_models, forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(selected_models, forcing, info)
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    return run_helpers.output_array
end

function runTEM!(selected_models, forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(selected_models, forcing, info)
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    return run_helpers.output_array
end

function runTEM!(forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(forcing, info)
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup_forcing, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    return run_helpers.output_array
end

function runTEM!(space_selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, space_output, space_land, tem_info::NamedTuple)
    parallelizeTEM!(space_selected_models, space_forcing, space_spinup_forcing, loc_forcing_t, space_output, space_land, tem_info, tem_info.run.parallelization)
    return nothing
end
```

:::


----

### runTEMYax
```@docs
runTEMYax
```

:::details Code

```julia
function runTEMYax(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple)

    # forcing/input information
    incubes = forcing.data;
    indims = forcing.dims;
    # information for running model
    run_helpers = prepTEM(forcing, info);
    loc_land = deepcopy(run_helpers.loc_land);
    _data_fill = 0.0f0
    _forcing_default_info = info.experiment.data_settings.forcing.default_forcing
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_vars_info = info.experiment.data_settings.forcing.variables
    #output = XOutput.(getproperty.(run_helpers.output_dims, :axisdesc))
    output = run_helpers.output_dims
    outcubes = xmap(TEMYax,
        (incubes .⊘ indims)...;
    function_kwargs = (selected_models=selected_models,
        forcing_vars=forcing.variables,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _data_fill, _forcing_default_info, _num_type, _forcing_vars_info)),
        output = output,
        #outdims=run_helpers.output_dims,
        #max_cache=info.experiment.exe_rules.yax_max_cache,
        #ispar=false,
        )
    varnames = getUniqueVarNames(info.output.variables)
    return Dataset(;zip(varnames, outcubes)...)
end

function runTEMYaxParameters(selected_models::Tuple, forcing::NamedTuple, in_cube_params, tbl_params, info::NamedTuple)

    # forcing/input information
    in_cubes_forcing = forcing.data
    in_cubes_all = (in_cubes_forcing..., in_cube_params)
    indims = forcing.dims
    indims = (indims..., InDims((YAXArrays.ByName("parameter"),), Array, (AllNaN(),), missing))
    param_to_index = getParameterIndices(selected_models, tbl_params)
    # information for running model
    run_helpers = prepTEM(forcing, info)
    loc_land = deepcopy(run_helpers.loc_land)
    _data_fill = 0.0f0
    _forcing_default_info = info.experiment.data_settings.forcing.default_forcing
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_vars_info = info.experiment.data_settings.forcing.variables

    outcubes = mapCube(psTEMYax,
        (in_cubes_all...,);
        selected_models=selected_models,
        param_to_index=param_to_index,
        forcing_vars=forcing.variables,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _data_fill, _forcing_default_info, _num_type, _forcing_vars_info),
        indims=indims,
        outdims=run_helpers.output_dims,
        max_cache=info.experiment.exe_rules.yax_max_cache,
        ispar=true,
        )
    return outcubes
end
```

:::


----

### setOutputForTimeStep!
```@docs
setOutputForTimeStep!
```

----

### setSequence
```@docs
setSequence
```

:::details Code

```julia
function setSequence(tem_info, new_sequence)
    return @set tem_info.spinup_sequence = new_sequence
end
```

:::


----

### setupOptiOutput
```@docs
setupOptiOutput
```

:::details Code

```julia
function setupOptiOutput end

function setupOptiOutput(info::NamedTuple, output::NamedTuple, ::DoRunOptimization)
    @debug "     setupOptiOutput: getting parameter output for optimization..."
    params = info.optimization.parameter_table.name_full    
    paramaxis = YAXArrays.Dim{:parameter}(params)
    outformat = info.output.format
    backend = outformat == "nc" ? :netcdf : :zarr
    od = YAXArrays.XOutput(paramaxis)
        #path=joinpath(info.output.dirs.optimization,
        #    "optimized_parameters.$(outformat)"),
        #backend=backend,
        #overwrite=true)
    # list of parameter
    output = set_namedtuple_field(output, (:parameter_dim, od))
    return output
end

function setupOptiOutput(info::NamedTuple, output::NamedTuple, ::DoRunOptimization)
    @debug "     setupOptiOutput: getting parameter output for optimization..."
    params = info.optimization.parameter_table.name_full    
    paramaxis = YAXArrays.Dim{:parameter}(params)
    outformat = info.output.format
    backend = outformat == "nc" ? :netcdf : :zarr
    od = YAXArrays.XOutput(paramaxis)
        #path=joinpath(info.output.dirs.optimization,
        #    "optimized_parameters.$(outformat)"),
        #backend=backend,
        #overwrite=true)
    # list of parameter
    output = set_namedtuple_field(output, (:parameter_dim, od))
    return output
end

function setupOptiOutput(info::NamedTuple, output::NamedTuple, ::DoNotRunOptimization)
    return output
end
```

:::


----

### spinup
```@docs
spinup
```

:::details Code

```julia
function spinupTEMYax end

function spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM)
    spinup_forcing = getAllSpinupForcing(loc_forcing, tem_info.spinup_sequence, tem_info);
    land_spin = spinupTEM(selected_models, spinup_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)
    return land_spin
end

function spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM)
    spinup_forcing = getAllSpinupForcing(loc_forcing, tem_info.spinup_sequence, tem_info);
    land_spin = spinupTEM(selected_models, spinup_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)
    return land_spin
end

function spinupTEMYax(_, _, _, land_prec, _, ::DoNotSpinupTEM)
    return land_prec
end
```

:::


----

### spinupTEM
```@docs
spinupTEM
```

:::details Code

```julia
function spinupTEMYax end

function spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM)
    spinup_forcing = getAllSpinupForcing(loc_forcing, tem_info.spinup_sequence, tem_info);
    land_spin = spinupTEM(selected_models, spinup_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)
    return land_spin
end

function spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM)
    spinup_forcing = getAllSpinupForcing(loc_forcing, tem_info.spinup_sequence, tem_info);
    land_spin = spinupTEM(selected_models, spinup_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)
    return land_spin
end

function spinupTEMYax(_, _, _, land_prec, _, ::DoNotSpinupTEM)
    return land_prec
end
```

:::


----

### timeLoopTEMSpinup
```@docs
timeLoopTEMSpinup
```

:::details Code

```julia
function timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps)
    for ts ∈ 1:n_timesteps
        f_ts = getForcingForTimeStep(spinup_forcing, loc_forcing_t, ts, tem_info.vals.forcing_types)
        land = computeTEM(spinup_models, f_ts, land, tem_info.model_helpers)
    end
    return land
end
```

:::


----

```@meta
CollapsedDocStrings = false
DocTestSetup= quote
using Sindbad.Simulation
end
```
