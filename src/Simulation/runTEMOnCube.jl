export runTEMYax
export TEMYax


"""
    coreTEMYax(selected_models, loc_forcing, loc_forcing_t, loc_land, tem_info, tem_spinup, ::DoSpinupTEM)

run the SINBAD CORETEM for a given location

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `loc_forcing`: a forcing NT that contains the forcing time series set for one location
- `loc_land`: initial SINDBAD land with all fields and subfields
- `tem_info`: helper NT with necessary objects for model run and type consistencies
- `tem_spinup`: a NT with information/instruction on spinning up the TEM
- `store_restart`: a function that stores the pools of a land for the restart file, called
  after the spinup step with `save_restart`, or `nothing` to store nothing

# Returns:
- the land time series wrapped in a `LandWrapper`
"""
function coreTEMYax(selected_models, loc_forcing, loc_land, tem_info, store_restart=nothing)

    loc_forcing_t = getForcingForTimeStep(loc_forcing, deepcopy(loc_forcing), 1, tem_info.vals.forcing_types)
    land_prec = definePrecomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)
    # land_prec = precomputeTEM(selected_models, loc_forcing_t, land_prec, tem_info.model_helpers) # ? do I need this step here? 
    land_spin = spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return LandWrapper(land_time_series)
end


"""
    TEMYax(map_cubes; loc_land::NamedTuple, tem::NamedTuple, selected_models::Tuple, forcing_vars::AbstractArray)



# Arguments:
- `map_cubes`: collection/tuple of all input and output cubes from mapCube
- `loc_land`: initial SINDBAD land with all fields and subfields
- `tem`: a nested NT with necessary information of helpers, models, and spinup needed to run SINDBAD TEM and models
- `selected_models`: a tuple of all models selected in the given model structure
- `forcing_vars`: forcing variables
- `parameter_to_index`: the index of each parameter per location in the models, or
  `nothing` when there are none. The values of the location then set the parameters of
  `selected_models` before the run.
"""
function TEMYax(map_cubes...;selected_models::Tuple, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data, restart_vars=(), parameter_to_index=nothing)
    # Make NaN check here instead of AllNaN filters
    

    outputs, inputs, restarts, parameter_inputs = unpackYaxForward(map_cubes; output_vars, forcing_vars, restart_vars)
    selected_models = setLocationParametersYax(selected_models, parameter_to_index, parameter_inputs)
    # What exactly should the NaN check be? 
    # Do I check per variable, or for all variables together?
    any(in_forcing -> any(v -> ismissing(v) || isnan(v), in_forcing), inputs)

    # ? apply clean_data fields to input data points
    _data_fill, _num_type, _forcing_data_info = clean_data

    inputs = map(enumerate(inputs)) do (i, in_forcing)
        _data_info = _forcing_data_info[i]
        map(data_point -> cleanData(data_point, _data_fill, _data_info, _num_type), in_forcing)
    end
    loc_forcing = (; Pair.(forcing_vars, inputs)...)
    # the restart cubes are filled after the spinup step with `save_restart`
    store_restart = land -> fillRestartYax(restarts, land, restart_vars)
    land_out = coreTEMYax(selected_models, loc_forcing, loc_land, tem, store_restart)
    i = 1
    foreach(output_vars) do var_pair
        data = land_out[first(var_pair)][last(var_pair)]
            fillOutputYax(outputs[i], data, var_pair)
            i += 1
    end
end

"""
    getForcingDataInfo(info, forcing_vars)

Returns the cleaning info of every forcing variable, i.e., the settings of the variable
merged into `default_forcing` the same way as in `getForcing`.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an experiment
- `forcing_vars`: the names of the forcing variables, in the order of the forcing cubes

# Notes:
- An empty or null setting of a variable, such as `"bounds": []`, keeps the value of
  `default_forcing`, whose bounds are always typed. The merge is done once here rather
  than for every pixel.
"""
function getForcingDataInfo(info, forcing_vars)
    default_info = info.experiment.data_settings.forcing.default_forcing
    vars_info = info.experiment.data_settings.forcing.variables
    return map(v -> merge_namedtuple_prefer_nonempty(default_info, getproperty(vars_info, Symbol(v))), Tuple(forcing_vars))
end

"""
    fillRestartYax(restarts, land, restart_vars)

Fills the restart cubes of one location with the pools after the spinup step with
`save_restart`.

# Arguments:
- `restarts`: the restart output arrays of one location
- `land`: the land after the spinup step with `save_restart`
- `restart_vars`: the field and subfield pairs of the restart variables
"""
function fillRestartYax(restarts, land, restart_vars)
    foreach(enumerate(restart_vars)) do (i, var_pair)
        data = getproperty(getproperty(land, first(var_pair)), last(var_pair))
        xout = restarts[i]
        for j ∈ eachindex(data)
            xout[j] = data[j]
        end
    end
    return nothing
end

"""
    runTEMYax(forcing::NamedTuple, output::NamedTuple, tem::NamedTuple, selected_models::Tuple; max_cache = 1.0e9)



# Arguments:
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `output`: an output NT including the data arrays, as well as information of variables and dimensions
- `tem`: a nested NT with necessary information of helpers, models, and spinup needed to run SINDBAD TEM and models
- `selected_models`: a tuple of all models selected in the given model structure
- `max_cache`: cache size to use for mapCube

# Returns:
- a NamedTuple with the `output` Dataset, the `restart` Dataset with the pools after
  spinup, the `restart_vars` written to it, and the `spinup_mode` of the step that saved
  the restart
"""
function runTEMYax(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple)
    # forcing/input information
    incubes = forcing.data;
    indims = forcing.dims;
    # the parameters per location have no core dimensions, so each location gets one
    # value per parameter, which sets the parameters of its models in TEMYax
    parameter_cubes, parameter_to_index = getParameterCubesYax(selected_models, forcing)
    incubes = (incubes..., parameter_cubes...)
    indims = (indims..., map(_ -> (), parameter_cubes)...)
    # information for running model
    run_helpers = prepTEM(forcing, info);
    loc_land = deepcopy(run_helpers.loc_land);
    _data_fill = 0.0f0
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_data_info = getForcingDataInfo(info, forcing.variables)
    #output = XOutput.(getproperty.(run_helpers.output_dims, :axisdesc))
    output = run_helpers.output_dims
    # land_init already has every pool, so no model run is needed to find them
    restart = getRestartDimsArrays(info, forcing.helpers, loc_land)
    restart_vars = restart.variables
    restart_output = getRestartOutDimsYax(info, restart.dims_pairs)
    all_output = (output..., restart_output...)
    # DiskArrayEngine needs all output cubes to have the same dimensions, so every cube
    # is padded with singleton versions of the dimensions of the other cubes.
    alloutdims = union(getproperty.(all_output, :outaxes)...)
    new_output = map(all_output) do out
        singleton_dims = setdiff(alloutdims, out.outaxes)
        newdims = (out.outaxes..., DD.rebuild.(singleton_dims, (1:1,))...) 
        YAXArrays.XOutput(newdims, out.destroyaxes, out.outtype, out.properties)
    end
    outcubes = xmap(TEMYax,
        (incubes .⊘ indims)...;
    function_kwargs = (selected_models=selected_models,
        forcing_vars=forcing.variables,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _data_fill, _num_type, _forcing_data_info),
        restart_vars=restart_vars,
        parameter_to_index=parameter_to_index),
        output = new_output,
        #outdims=run_helpers.output_dims,
        #max_cache=info.experiment.exe_rules.yax_max_cache,
        #ispar=false,
        )
    outcubes = outcubes isa YAXArray ? (outcubes,) : outcubes
    n_out = length(output)
    varnames = getUniqueVarNames(info.output.variables)
    output_ds = Dataset(;zip(varnames, outcubes[1:n_out])...)
    restart_cubes = map(restart_output, outcubes[(n_out+1):end]) do r_out, r_cube
        dropPaddedDimsYax(r_cube, setdiff(DD.name.(alloutdims), DD.name.(r_out.outaxes)))
    end
    restart_ds = Dataset(; zip(last.(restart_vars), restart_cubes)...)
    return (; output=output_ds, restart=restart_ds, restart_vars=restart_vars, spinup_mode=getSaveRestartSpinupMode(info))
end

"""
    getRestartOutDimsYax(info, restart_dims_pairs)

Builds one `XOutput` per restart variable from its dimension pairs, leaving out the
spatial dimensions that `xmap` loops over.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an experiment
- `restart_dims_pairs`: the dimension pairs of each restart variable without time
"""
function getRestartOutDimsYax(info, restart_dims_pairs)
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    return map(Tuple(restart_dims_pairs)) do dim_pairs
        vdims = []
        for _dim in dim_pairs
            if first(_dim) ∉ space_dims
                push!(vdims, DD.rebuild(DD.Dimensions.name2dim(first(_dim)), last(_dim)))
            end
        end
        YAXArrays.XOutput(vdims...)
    end
end

"""
    dropPaddedDimsYax(cube, padded_names)

Removes the singleton dimensions that were added to an output cube only because
DiskArrayEngine needs all output cubes to have the same dimensions.

# Arguments:
- `cube`: an output cube of `xmap`
- `padded_names`: the names of the singleton dimensions added to the cube. The spatial
  dimensions are never among them, even when they have a size of 1.
"""
function dropPaddedDimsYax(cube, padded_names)
    padded = filter(d -> DD.name(d) ∈ padded_names, DD.dims(cube))
    isempty(padded) && return cube
    return cube[map(d -> DD.rebuild(d, 1), padded)...]
end

"""
    psTEMYax(in_pixel_cube...; selected_models::Tuple, param_to_index, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data)
"""
function psTEMYax(in_pixel_cube...; selected_models::Tuple, param_to_index, forcing_vars, loc_land::NamedTuple,
    output_vars, tem::NamedTuple, clean_data)

    outputs, inputs = unpackYaxForward(in_pixel_cube[1:end-1]; output_vars, forcing_vars)
    in_new_params = last(in_pixel_cube)
    # ? apply clean_data fields to input data points
    _data_fill, _num_type, _forcing_data_info = clean_data

    inputs = map(enumerate(inputs)) do (i, in_forcing)
        _data_info = _forcing_data_info[i]
        map(data_point -> cleanData(data_point, _data_fill, _data_info, _num_type), in_forcing)
    end
    loc_forcing = (; Pair.(forcing_vars, inputs)...)
    updated_models = updateModelParameters(param_to_index, selected_models, in_new_params)
    land_out = coreTEMYax(updated_models, loc_forcing, loc_land, tem)
    i = 1
    foreach(output_vars) do var_pair
        data = land_out[first(var_pair)][last(var_pair)]
            fillOutputYax(outputs[i], data, var_pair)
            i += 1
    end
end


"""
    runTEMYaxParameters(selected_models::Tuple, forcing::NamedTuple, in_cube_params, tbl_params, info::NamedTuple)

"""
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
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_data_info = getForcingDataInfo(info, forcing.variables)

    outcubes = mapCube(psTEMYax,
        (in_cubes_all...,);
        selected_models=selected_models,
        param_to_index=param_to_index,
        forcing_vars=forcing.variables,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _data_fill, _num_type, _forcing_data_info),
        indims=indims,
        outdims=run_helpers.output_dims,
        max_cache=info.experiment.exe_rules.yax_max_cache,
        ispar=true,
        )
    return outcubes
end



"""
    spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode, store_restart=nothing)

Handle TEM spinup according to `spinup_mode`. If spinup is requested, the forcing needed for the Spinup is derived and a normal spinup is performed. If spinup is skipped, the provided precomputed land is returned unchanged.

# Arguments
- `selected_models`: Tuple of models selected in the model structure.
- `loc_forcing`: Forcing NamedTuple containing time series for the location (all timesteps).
- `loc_forcing_t`: Forcing NamedTuple for a single timestep (used for precompute structures).
- `land_prec`: Precomputed/initial land NamedTuple that may be modified during spinup.
- `tem_info`: NamedTuple with helper objects and run settings (including `spinup`,
  `spinup_dates` and `run.spinup_TEM`).
- `spinup_mode`: Dispatch type controlling behavior: use `DoSpinupTEM()` to run/load spinup,
  or `DoNotSpinupTEM()` to skip spinup.
- `store_restart`: a function that stores the pools for the restart file after the spinup
  step with `save_restart`, or `nothing`. Without spinup, it stores the pools of
  `land_prec`.

# Returns
- Updated land NamedTuple to be used for the main TEM time loop.

# Notes
- When `DoSpinupTEM` is used the function builds the sequence of the location and the forcing
  it needs via `getLocSpinup`, and calls `spinupTEM` with `tem_info.run.spinup_TEM`.
- When `DoNotSpinupTEM` is used the input `land_prec` is returned unchanged.
"""
function spinupTEMYax end

function spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM, store_restart=nothing)
    loc_spinup = getLocSpinup(loc_forcing, tem_info)
    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    return land_spin
end

function spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoNotSpinupTEM, store_restart=nothing)
    setRestart!(store_restart, land_prec, tem_info)
    return land_prec
end


"""
    unpackYaxForward(args; tem::NamedTuple, forcing_vars::AbstractArray)

unpack the input and output cubes from all cubes thrown by mapCube

# Arguments:
- `all_cubes`: collection/tuple of all input and output cubes
- `forcing_vars`: forcing variables
- `output_vars`: output variables
- `restart_vars`: restart variables, whose cubes follow the output cubes

# Notes:
- The cubes of the parameters per location, if any, follow the forcing cubes and are
  returned last.
"""
function unpackYaxForward(all_cubes; output_vars, forcing_vars, restart_vars=())
    nin = length(forcing_vars)
    nout = length(output_vars)
    nres = length(restart_vars)
    outputs = all_cubes[1:nout]
    restarts = all_cubes[(nout+1):(nout+nres)]
    inputs = all_cubes[(nout+nres+1):(nout+nres+nin)]
    parameter_inputs = all_cubes[(nout+nres+nin+1):end]
    return outputs, inputs, restarts, parameter_inputs
end


"""
    getParameterCubesYax(selected_models, forcing)

Returns the cubes of the parameters per location and the index of each parameter in
the models, for the input cubes of `xmap`.

# Returns:
- `()` and `nothing` when `forcing.parameters` is `nothing`, so the input cubes of
  `xmap` are only the forcing.
- Otherwise the cubes of `forcing.parameters.data`, which hold values that are already
  in run units and within bounds, and the `parameter_to_index` from
  `getParameterIndices`.
"""
function getParameterCubesYax(selected_models, forcing)
    forcing_parameters = get(forcing, :parameters, nothing)
    isnothing(forcing_parameters) && return (), nothing
    parameter_to_index = getParameterIndices(selected_models, forcing_parameters.parameter_table)
    return Tuple(forcing_parameters.data), parameter_to_index
end


"""
    setLocationParametersYax(selected_models, parameter_to_index, parameter_inputs)

Returns the models of one location with the parameters set from the values of the
parameters per location, or `selected_models` when there are none.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `parameter_to_index`: the index of each parameter in the models, or `nothing`
- `parameter_inputs`: the value of each parameter at the location, as arrays without
  dimensions from `xmap`
"""
setLocationParametersYax(selected_models, ::Nothing, _) = selected_models

function setLocationParametersYax(selected_models, parameter_to_index, parameter_inputs)
    return setParametersKeepTypes(selected_models, parameter_to_index, map(first, parameter_inputs))
end



"""
    fillOutputYax(xout, xin, var_pair)

fills the output array position with the input data/vector

# Arguments:
- `xout`: output array location
- `xin`: input data/vector
- `var_pair`: the field and subfield pair of the output variable, used in the error

# Notes:
- The number of layers of the output must equal the number of layers of the variable in
  land, the same check as `checkOutputLayers` in a run that is not lazy. It is done once
  per location and variable, not per time step.
"""
function fillOutputYax(xout, xin, var_pair)
    n_land = length(first(xin))
    n_out = length(xout) ÷ length(xin)
    n_land == n_out || throwOutputLayerError(var_pair, n_out, n_land)
    if ndims(xout) == ndims(xin) && length(xin[1]) == 1
        for i ∈ eachindex(xin)
            xout[i] = xin[i][1]
        end
    else
        for i ∈ CartesianIndices(xin)
            xout[i,:] .= xin[i]
        end
    end
end