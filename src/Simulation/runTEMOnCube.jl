export runTEMOnCube
export runTEMYax
export TEMYax


"""
    runTEMOnCube(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple)
    runTEMOnCube(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple, parameter_cube, parameter_table)

run the SINDBAD TEM on `YAXArrays` cubes, one pixel at a time through `xmap`. The run is lazy: the TEM is
run for a pixel when the corresponding part of the output cubes is read or saved.

With `parameter_cube` and `parameter_table`, the model parameters are set for every pixel from the
`parameter` axis of `parameter_cube`, in the order of the rows of `parameter_table`. Otherwise the parameters
in `selected_models` are used for all pixels.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `forcing`: a forcing NT that contains the forcing cubes (`data`), their per pixel dimensions (`dims`) and `variables` for ALL locations
- `info`: a SINDBAD NT that includes all information needed for setup and execution of an experiment
- `parameter_cube`: a cube with the spatial dimensions of the forcing and a `parameter` dimension
- `parameter_table`: the parameter table that defines the order of the values along the `parameter` dimension

# Returns:
- a `Dataset` with one lazy output cube per output variable
"""
function runTEMOnCube end

function runTEMOnCube(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple)
    return mapTEMOnCube(selected_models, forcing, info, (), nothing)
end

function runTEMOnCube(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple, parameter_cube, parameter_table)
    parameter_to_index = getParameterIndices(selected_models, parameter_table)
    return mapTEMOnCube(selected_models, forcing, info, (parameter_cube ⊘ :parameter,), parameter_to_index)
end


"""
    mapTEMOnCube(selected_models, forcing, info, parameter_input::Tuple, parameter_to_index)

map `runTEMOnPixel!` over the forcing cubes and the cubes in `parameter_input`, which is empty when no parameter
cube is used, in which case `parameter_to_index` is `nothing`.
"""
function mapTEMOnCube(selected_models, forcing, info, parameter_input::Tuple, parameter_to_index)
    cube_helpers = prepTEMOnCube(forcing, info)
    outcubes = xmap(runTEMOnPixel!,
        (forcing.data .⊘ forcing.dims)...,
        parameter_input...;
        function_kwargs=(; selected_models, parameter_to_index, cube_helpers.pixel_kwargs...),
        output=cube_helpers.output,
        )
    # xmap returns the cube itself instead of a tuple when there is a single output variable
    outcubes = outcubes isa Tuple ? outcubes : (outcubes,)
    # xmap keeps the consumed parameter axis as a singleton axis of every output, drop it (lazily)
    outcubes = map(c -> DD.hasdim(c, :parameter) ? dropdims(c; dims=:parameter) : c, outcubes)
    varnames = getUniqueVarNames(info.output.variables)
    return Dataset(; zip(varnames, outcubes)...)
end


"""
    prepTEMOnCube(forcing::NamedTuple, info::NamedTuple)

prepare the shared objects for running the TEM on cubes.

# Returns:
- `pixel_kwargs`: keyword arguments passed to `runTEMOnPixel!` for every pixel
- `output`: the `XOutput` of every output variable. Time is put first, followed by the variable's own
  dimensions, e.g., soil layers, and singleton versions of the dimensions that only other output variables have.
"""
function prepTEMOnCube(forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(forcing, info)
    forcing_settings = info.experiment.data_settings.forcing
    clean_data = (;
        data_fill=0.0f0,
        default_info=forcing_settings.default_forcing,
        num_type=Val{info.helpers.numbers.num_type}(),
        vars_info=forcing_settings.variables)

    time_name = Symbol(forcing_settings.data_dimension.time)
    time_first(axes) = (filter(ax -> DD.name(ax) == time_name, axes)..., filter(ax -> DD.name(ax) != time_name, axes)...)
    all_out_axes = union(getproperty.(run_helpers.output_dims, :outaxes)...)
    output = map(run_helpers.output_dims) do out
        singleton_axes = setdiff(all_out_axes, out.outaxes)
        out_axes = (time_first(out.outaxes)..., DD.rebuild.(singleton_axes, (1:1,))...)
        YAXArrays.XOutput(out_axes, out.destroyaxes, out.outtype, out.properties)
    end

    pixel_kwargs = (;
        forcing_vars=forcing.variables,
        output_vars=run_helpers.output_vars,
        loc_land=deepcopy(run_helpers.loc_land),
        tem_info=run_helpers.tem_info,
        clean_data)
    return (; pixel_kwargs, output)
end


"""
    runTEMOnPixel!(xs...; selected_models, parameter_to_index, forcing_vars, output_vars, loc_land, tem_info, clean_data)

run the TEM for one pixel and write the output variables to the output arrays. This is the function mapped by `xmap` in `runTEMOnCube`.

# Arguments:
- `xs`: the output arrays, followed by the forcing arrays and, optionally, the parameter vector of the pixel
- `selected_models`: a tuple of all models selected in the given model structure
- `parameter_to_index`: indices of the model parameters in the parameter vector, or `nothing` to keep the parameters of `selected_models`
- `forcing_vars`: forcing variables
- `output_vars`: output variables as (field, variable) pairs
- `loc_land`: initial SINDBAD land with all fields and subfields
- `tem_info`: helper NT with necessary objects for model run and type consistencies
- `clean_data`: fill value, variable information and number type used to clean the forcing
"""
function runTEMOnPixel!(xs...; selected_models, parameter_to_index, forcing_vars, output_vars, loc_land, tem_info, clean_data)
    outputs, inputs, pixel_parameters = splitPixelArgs(xs, length(output_vars), length(forcing_vars))
    loc_forcing = cleanPixelForcing(inputs, forcing_vars, clean_data)
    pixel_models = updatePixelModels(selected_models, parameter_to_index, pixel_parameters)
    land_out = coreTEMOnPixel(pixel_models, loc_forcing, loc_land, tem_info)
    fillPixelOutputs!(outputs, land_out, output_vars)
    return nothing
end


"""
    splitPixelArgs(xs, n_out, n_in)

split the arrays passed by `xmap` into the output arrays, the forcing arrays and the parameter vector, which
is `nothing` when no parameter cube is mapped.
"""
function splitPixelArgs(xs, n_out, n_in)
    outputs = xs[1:n_out]
    inputs = xs[(n_out+1):(n_out+n_in)]
    pixel_parameters = length(xs) > n_out + n_in ? last(xs) : nothing
    return outputs, inputs, pixel_parameters
end


"""
    cleanPixelForcing(inputs, forcing_vars, clean_data)

fill invalid values, convert units, apply bounds and number type to the forcing of one pixel, and return it as a forcing NT.
"""
function cleanPixelForcing(inputs, forcing_vars, clean_data)
    cleaned = map(enumerate(inputs)) do (i, in_forcing)
        data_info = merge_namedtuple(clean_data.default_info, clean_data.vars_info[i])
        map(data_point -> cleanData(data_point, clean_data.data_fill, data_info, clean_data.num_type), in_forcing)
    end
    return (; Pair.(forcing_vars, cleaned)...)
end


"""
    updatePixelModels(selected_models, parameter_to_index, pixel_parameters)

set the parameters of the models to the parameters of the pixel. With `parameter_to_index` set to `nothing` the models are returned unchanged.
"""
function updatePixelModels end

updatePixelModels(selected_models, ::Nothing, _) = selected_models

function updatePixelModels(selected_models, parameter_to_index::NamedTuple, pixel_parameters)
    return updateModelParameters(parameter_to_index, selected_models, pixel_parameters)
end


"""
    fillPixelOutputs!(outputs, land_out, output_vars)

write every output variable of the land time series to its output array. The first dimension of an output array is time.
"""
function fillPixelOutputs!(outputs, land_out, output_vars)
    foreach(outputs, output_vars) do xout, (field, var)
        xin = land_out[field][var]
        for t ∈ eachindex(xin)
            selectdim(xout, 1, t) .= xin[t]
        end
    end
    return nothing
end


"""
    coreTEMOnPixel(selected_models, loc_forcing, loc_land, tem_info)

run the SINDBAD core TEM for a given location: precompute, optional spinup and the time loop.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `loc_forcing`: a forcing NT that contains the forcing time series set for one location
- `loc_land`: initial SINDBAD land with all fields and subfields
- `tem_info`: helper NT with necessary objects for model run and type consistencies, including the spinup settings

# Returns:
- the land time series wrapped in a `LandWrapper`
"""
function coreTEMOnPixel(selected_models, loc_forcing, loc_land, tem_info)
    loc_forcing_t = getForcingForTimeStep(loc_forcing, deepcopy(loc_forcing), 1, tem_info.vals.forcing_types)
    land_prec = definePrecomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)
    land_spin = spinupTEMOnPixel(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)
    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return LandWrapper(land_time_series)
end


"""
    spinupTEMOnPixel(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, spinup_mode)

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

# Returns
- Updated land NamedTuple to be used for the main TEM time loop.

# Notes
- When `DoSpinupTEM` is used the function builds the sequence of the location and the forcing
  it needs via `getLocSpinup`, and calls `spinupTEM` with `tem_info.run.spinup_TEM`.
- When `DoNotSpinupTEM` is used the input `land_prec` is returned unchanged.
"""
function spinupTEMOnPixel end

function spinupTEMOnPixel(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM)
    loc_spinup = getLocSpinup(loc_forcing, tem_info)
    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM)
    return land_spin
end

function spinupTEMOnPixel(_, _, _, land_prec, _, ::DoNotSpinupTEM)
    return land_prec
end


"""
    runTEMYaxParameters(selected_models::Tuple, forcing::NamedTuple, in_cube_params, tbl_params, info::NamedTuple)

deprecated, use `runTEMOnCube(selected_models, forcing, info, in_cube_params, tbl_params)`.
"""
function runTEMYaxParameters(selected_models::Tuple, forcing::NamedTuple, in_cube_params, tbl_params, info::NamedTuple)
    return runTEMOnCube(selected_models, forcing, info, in_cube_params, tbl_params)
end


# ! Previous implementation, kept as a reference for runTEMOnCube while the latter is tested. To be removed.

"""
    TEMYax(map_cubes...; selected_models::Tuple, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data)

previous per pixel function of `runTEMYax`, replaced by `runTEMOnPixel!`.
"""
function TEMYax(map_cubes...;selected_models::Tuple, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data)
    # Make NaN check here instead of AllNaN filters


    outputs, inputs = unpackYaxForward(map_cubes; output_vars, forcing_vars)
    # What exactly should the NaN check be?
    # Do I check per variable, or for all variables together?
    any(in_forcing -> any(v -> ismissing(v) || isnan(v), in_forcing), inputs)

    # ? apply clean_data fields to input data points
    _data_fill, _forcing_default_info, _num_type, _forcing_vars_info = clean_data

    inputs = map(enumerate(inputs)) do (i, in_forcing)
        _data_info = merge_namedtuple(_forcing_default_info, _forcing_vars_info[i])
        map(data_point -> cleanData(data_point, _data_fill, _data_info, _num_type), in_forcing)
    end
    loc_forcing = (; Pair.(forcing_vars, inputs)...)
    land_out = coreTEMOnPixel(selected_models, loc_forcing, loc_land, tem)
    i = 1
    foreach(output_vars) do var_pair
        data = land_out[first(var_pair)][last(var_pair)]
            fillOutputYax(outputs[i], data)
            i += 1
    end
end

"""
    runTEMYax(selected_models::Tuple, forcing::NamedTuple, info::NamedTuple)

previous implementation of `runTEMOnCube(selected_models, forcing, info)`.
"""
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
    alloutdims = union(getproperty.(output, :outaxes)...)
    new_output = map(output) do out
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
        clean_data=(; _data_fill, _forcing_default_info, _num_type, _forcing_vars_info)),
        output = new_output,
        #outdims=run_helpers.output_dims,
        #max_cache=info.experiment.exe_rules.yax_max_cache,
        #ispar=false,
        )
    varnames = getUniqueVarNames(info.output.variables)
    return Dataset(;zip(varnames, outcubes)...)
end

"""
    unpackYaxForward(all_cubes; output_vars, forcing_vars)

unpack the input and output cubes from all cubes thrown by xmap, replaced by `splitPixelArgs`.
"""
function unpackYaxForward(all_cubes; output_vars, forcing_vars)
    nin = length(forcing_vars)
    nout = length(output_vars)
    outputs = all_cubes[1:nout]
    inputs = all_cubes[(nout+1):(nout+nin)]
    return outputs, inputs
end

"""
    fillOutputYax(xout, xin)

fills the output array position with the input data/vector, replaced by `fillPixelOutputs!`.
"""
function fillOutputYax(xout, xin)
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
