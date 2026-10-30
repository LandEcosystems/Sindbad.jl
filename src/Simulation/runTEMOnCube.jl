export runTEMYax
export TEMYax
export computeTEMYax

const DiskArrays = YAXArrays.Cubes.DiskArrays

"""
    ErasedDiskArray{T,N}

A disk array that wraps another array without its type in the type of the wrapper.

# Notes:
- The type of every cube of an `xmap` holds the types of all its input arrays. With
  the forcing cubes as inputs, which are views of permuted zarr arrays, these types are
  huge and every function that handles the cubes is very slow to compile. Wrapped,
  all inputs with the same element type and number of dimensions share one type.
- Reading a block dispatches on the wrapped array at run time, which is negligible
  next to reading the block from disk.
"""
struct ErasedDiskArray{T,N} <: DiskArrays.AbstractDiskArray{T,N}
    parent::AbstractArray{T,N}
end

Base.parent(a::ErasedDiskArray) = a.parent
Base.size(a::ErasedDiskArray) = size(a.parent)
DiskArrays.haschunks(a::ErasedDiskArray) = DiskArrays.haschunks(a.parent)
DiskArrays.eachchunk(a::ErasedDiskArray) = DiskArrays.eachchunk(a.parent)
DiskArrays.readblock!(a::ErasedDiskArray, aout, r::OrdinalRange...) = DiskArrays.readblock!(a.parent, aout, r...)

"""
    eraseCubeType(cube)

Returns `cube` with its data wrapped in an `ErasedDiskArray`, keeping its dimensions,
properties and chunks.
"""
eraseCubeType(cube) = YAXArray(DD.dims(cube), ErasedDiskArray(cube.data), cube.properties; chunks=DiskArrays.eachchunk(cube))


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
    coreTEMYax!(loc_output, selected_models, loc_forcing, loc_land, tem_info, store_restart=nothing)

Runs the TEM for one location and writes the output variables of every time step into
`loc_output`, the same way as `coreTEM!` of an eager run.

# Arguments:
- `loc_output`: the output arrays of the location, in the order of
  `tem_info.vals.output_vars`, with time as the first dimension
- the other arguments are the same as for `coreTEMYax`

# Notes:
- Only the output variables are kept at each time step, whereas `coreTEMYax` keeps the
  whole land of every time step and allocates far more memory.
"""
function coreTEMYax!(loc_output, selected_models, loc_forcing, loc_land, tem_info, store_restart=nothing)
    loc_forcing_t = getForcingForTimeStep(loc_forcing, deepcopy(loc_forcing), 1, tem_info.vals.forcing_types)
    land_prec = definePrecomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)
    land_spin = spinupTEMYax(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    timeLoopTEM!(selected_models, loc_forcing, loc_forcing_t, loc_output, land_spin, tem_info.vals.forcing_types, tem_info.model_helpers, tem_info.vals.output_vars, tem_info.n_timesteps, tem_info.run.debug_model)
    return nothing
end


"""
    TEMYax(map_cubes; loc_land::NamedTuple, tem::NamedTuple, selected_models, forcing_vars::AbstractArray)



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
function TEMYax(map_cubes...;selected_models, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data, restart_vars=(), parameter_to_index=nothing)
    # Make NaN check here instead of AllNaN filters
    

    outputs, inputs, restarts, parameter_inputs = unpackYaxForward(map_cubes; output_vars, forcing_vars, restart_vars)
    selected_models = setLocationParametersYax(selected_models, parameter_to_index, parameter_inputs)
    # the same rule as filterNanPixels: a pixel with an invalid forcing value at any
    # time step is not run, and its output and restart stay NaN
    if any(in_forcing -> any(is_invalid_number, in_forcing), inputs)
        foreach(xout -> fill!(xout, NaN), outputs)
        foreach(xout -> fill!(xout, NaN), restarts)
        return nothing
    end

    # ? apply clean_data fields to input data points
    _num_type, _forcing_data_info = clean_data

    inputs = map(enumerate(inputs)) do (i, in_forcing)
        _data_info = _forcing_data_info[i]
        map(data_point -> cleanData(data_point, _data_info, _num_type), in_forcing)
    end
    loc_forcing = (; Pair.(forcing_vars, inputs)...)
    # the restart cubes are filled after the spinup step with `save_restart`
    store_restart = land -> fillRestartYax(restarts, land, restart_vars)
    # every pixel gets its own copy, as the land has mutable arrays and the pixels can
    # run on different threads
    coreTEMYax!(outputs, selected_models, loc_forcing, deepcopy(loc_land), tem, store_restart)
    return nothing
end

"""
    TEMYaxErased(map_cubes...; tem_kwargs)

Runs `TEMYax` for one location with the keyword arguments held in `tem_kwargs[]`.

# Notes:
- `xmap` makes its function arguments part of the type of every function that runs it.
  The arguments of `TEMYax` hold the models and the land, which makes those types huge
  and slow to compile, so `runTEMYax` passes them in a `Ref{Any}` instead.
- `TEMYax` is called dynamically once per location and is specialized as before.
"""
function TEMYaxErased(map_cubes...; tem_kwargs::Base.RefValue{Any})
    TEMYax(map_cubes...; tem_kwargs[]...)
    return nothing
end

"""
    getTemplateLandYax(selected_models, forcing, info, tem_info, land_init, forcing_data_info)

Builds the land that every location of a lazy run starts from, with every field of the
selected models in its final type, as `runTEMOne` does for an eager run.

# Notes:
- The land is built from a placeholder forcing, see `getPlaceholderForcingYax`, so no
  forcing is read and no location has to be valid.
- The model errors are not caught in this step, since the placeholder values of
  different variables are not consistent with each other. The values of the land are
  set again for every location by define and precompute.
"""
function getTemplateLandYax(selected_models, forcing, info, tem_info, land_init, forcing_data_info)
    loc_forcing = getPlaceholderForcingYax(forcing, info, forcing_data_info, getTestForcing())
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing, 1, tem_info.vals.forcing_types)
    model_helpers = (; tem_info.model_helpers..., run=(; tem_info.model_helpers.run..., catch_model_errors=DoNotCatchModelErrors()))
    return buildFullLand(selected_models, loc_forcing_t, deepcopy(land_init), model_helpers)
end

"""
    getPlaceholderForcingYax(forcing, info, forcing_data_info, test_forcing)

Returns a forcing NT of one location with the same types as the forcing that `TEMYax`
builds from the cubes.

# Arguments:
- `test_forcing`: the forcing of one location from `getTestForcing`, whose values are
  used for the variables it has

# Notes:
- An array has the core dimensions of its cube, i.e., all dimensions but the spatial
  ones. The time dimension has a length of 1, and the other dimensions, e.g., soil
  layers, keep their length.
- A test value with another number of layers than the cube is replaced by its mean.
- A variable that is not in `test_forcing` is filled with the middle of its bounds, or
  with one when it has no bounds. The middle of the bounds is not valid for every
  variable, e.g., soil texture, whose bounds are in percent while the values are
  fractions, so the test values are preferred.
"""
function getPlaceholderForcingYax(forcing, info, forcing_data_info, test_forcing)
    num_type = info.helpers.numbers.num_type
    time_name = Symbol(info.experiment.data_settings.forcing.data_dimension.time)
    arrays = map(Tuple(forcing.variables), Tuple(values(forcing.data)), Tuple(forcing.dims), forcing_data_info) do var_name, cube, core_dims, data_info
        sizes = map(d -> d == time_name ? 1 : length(DD.dims(cube, d)), core_dims)
        test_value = get(test_forcing, Symbol(var_name), nothing)
        if isnothing(test_value)
            bounds = data_info.bounds
            value = isnothing(bounds) || isempty(bounds) ? one(num_type) : num_type((first(bounds) + last(bounds)) / 2)
            fill(value, sizes...)
        elseif test_value isa Number
            fill(num_type(test_value), sizes...)
        elseif length(test_value) == prod(sizes)
            reshape(num_type.(vec(test_value)), sizes...)
        else
            fill(num_type(sum(test_value) / length(test_value)), sizes...)
        end
    end
    return (; Pair.(forcing.variables, arrays)...)
end

"""
    getTestForcing()

Returns the forcing of one location in the test data of SindbadTEM, `tmp_forcing` in
`test/test_data/forcing.jl`, or an empty NT when the file is not found.

# Notes:
- Only the `tmp_forcing` expression of the file is evaluated, in a new module, so the
  packages that the file loads do not have to be available.
"""
function getTestForcing()
    path = joinpath(pkgdir(SindbadTEM), "test", "test_data", "forcing.jl")
    isfile(path) || return (;)
    for ex ∈ Meta.parseall(read(path, String)).args
        if ex isa Expr && ex.head == :(=) && ex.args[1] == :tmp_forcing
            return Core.eval(Module(), ex.args[2])
        end
    end
    return (;)
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
- Only the fields that `cleanData` reads are kept. The info is part of the argument
  types of `TEMYax`, and the full settings, e.g., with the `dimension` and
  `interpolation_method` groups, make it slow to compile.
"""
function getForcingDataInfo(info, forcing_vars)
    default_info = info.experiment.data_settings.forcing.default_forcing
    vars_info = info.experiment.data_settings.forcing.variables
    return map(Tuple(forcing_vars)) do v
        v_info = merge_namedtuple_prefer_nonempty(default_info, getproperty(vars_info, Symbol(v)))
        (; source_to_sindbad_unit=v_info.source_to_sindbad_unit, additive_unit_conversion=v_info.additive_unit_conversion, bounds=v_info.bounds)
    end
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
    runTEMYax(forcing::NamedTuple, output::NamedTuple, tem::NamedTuple, selected_models; max_cache = 1.0e9)



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
function runTEMYax(selected_models, forcing::NamedTuple, info::NamedTuple)
    # forcing/input information
    incubes = map(eraseCubeType, values(forcing.data));
    indims = forcing.dims;
    # the parameters per location have no core dimensions, so each location gets one
    # value per parameter, which sets the parameters of its models in TEMYax
    parameter_cubes, parameter_to_index = getParameterCubesYax(selected_models, forcing)
    incubes = (incubes..., parameter_cubes...)
    indims = (indims..., map(_ -> (), parameter_cubes)...)
    # information for running model
    run_helpers = prepTEM(forcing, info);
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_data_info = getForcingDataInfo(info, forcing.variables)
    # every location starts from this land, so the land keeps one type in all models
    loc_land = getTemplateLandYax(selected_models, forcing, info, run_helpers.tem_info, run_helpers.loc_land, _forcing_data_info)
    checkOutputLayers(info.output.variables, info.output.depth_info, loc_land)
    #output = XOutput.(getproperty.(run_helpers.output_dims, :axisdesc))
    output = run_helpers.output_dims
    # the template land has every pool
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
    tem_kwargs = (selected_models=selected_models,
        forcing_vars=forcing.variables,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _num_type, _forcing_data_info),
        restart_vars=restart_vars,
        parameter_to_index=parameter_to_index)
    outcubes = xmap(TEMYaxErased,
        (incubes .⊘ indims)...;
    # the arguments become part of the type of every function of the xmap run, so they
    # are passed behind a Ref{Any} to keep those types small and fast to compile
    function_kwargs = (tem_kwargs=Ref{Any}(tem_kwargs),),
        output = new_output,
        # xmap runs the pixels of a block on one thread unless this is set. The number of
        # threads of the Julia session decides how many are used.
        allow_threads = true,
        #outdims=run_helpers.output_dims,
        #max_cache=info.experiment.exe_rules.yax_max_cache,
        #ispar=false,
        )
    # the cubes are kept in a Vector{Any}, as code for the tuple of all their types is
    # slow to compile
    outcubes = outcubes isa YAXArray ? Any[outcubes] : collect(Any, outcubes)
    n_out = length(output)
    varnames = Tuple(getUniqueVarNames(info.output.variables))
    restart_names = Tuple(last.(restart_vars))
    # besides the padding, xmap adds a singleton for every core dimension of the forcing
    # that the output does not have, e.g. the soil layers of the texture forcing
    space_dims = Symbol.(info.experiment.data_settings.forcing.data_dimension.space)
    padded_names = Vector{Symbol}[setdiff(DD.name.(DD.dims(o_cube)), (DD.name.(out.outaxes)..., space_dims...)) for (out, o_cube) ∈ zip(collect(Any, all_output), outcubes)]
    dropped_cubes = Any[dropPaddedDimsYax(o_cube, padded) for (o_cube, padded) ∈ zip(outcubes, padded_names)]
    output_ds = datasetFromCubes(varnames, dropped_cubes[1:n_out])
    restart_ds = datasetFromCubes(restart_names, dropped_cubes[(n_out+1):end])
    # a pool can also be an output variable, so the restart cubes get their own keys
    restart_keys = map(r -> Symbol("restart_", r), restart_names)
    xmap_keys = (varnames..., restart_keys...)
    xmap_cubes = (; dataset=datasetFromCubes(xmap_keys, outcubes),
        padded_names=Dict(zip(xmap_keys, padded_names)),
        output_names=varnames, restart_names=restart_names, restart_keys=restart_keys)
    return (; output=output_ds, restart=restart_ds, restart_vars=restart_vars, spinup_mode=getSaveRestartSpinupMode(info), xmap=xmap_cubes)
end

"""
    computeTEMYax(xmap_cubes, store_path; max_cache=5e8)

Computes all output and restart cubes of a lazy run in one pass and writes them to the
zarr store at `store_path`.

# Arguments:
- `xmap_cubes`: the `xmap` field returned by `runTEMYax`
- `store_path`: the path of the zarr store that holds the computed cubes
- `max_cache`: the cache size of `compute_to_zarr`

# Returns:
- a NamedTuple with the `output` and `restart` Datasets, read from the store and
  without the padded dimensions

# Notes:
- All cubes of `runTEMYax` come from one `xmap`. Saving them one by one runs the model
  once per cube, while `compute_to_zarr` runs it once for all of them.
- The cubes keep their padded dimensions until they are computed, since
  `compute_to_zarr` can only fuse the direct outputs of the `xmap`.
"""
function computeTEMYax(xmap_cubes, store_path; max_cache=5e8)
    computed = YAXArrays.compute_to_zarr(xmap_cubes.dataset, store_path; max_cache=max_cache, overwrite=true)
    stored(key) = dropPaddedDimsYax(computed.cubes[key], xmap_cubes.padded_names[key])
    output_ds = datasetFromCubes(xmap_cubes.output_names, Any[stored(name) for name ∈ xmap_cubes.output_names])
    restart_ds = datasetFromCubes(xmap_cubes.restart_names, Any[stored(key) for key ∈ xmap_cubes.restart_keys])
    return (; output=output_ds, restart=restart_ds)
end

"""
    datasetFromCubes(names, cubes; properties=Dict{String,Any}())

Builds a `Dataset` of `cubes` named by `names`, the same as `Dataset(; cubes...)`.

# Notes:
- The keyword constructor of `Dataset` is compiled for the types of all its cubes
  together, which is slow for the cubes of a lazy run. Here the cubes are added one by
  one to the dictionary of the `Dataset`.
"""
function datasetFromCubes(names, cubes; properties=Dict{String,Any}())
    cube_dict = YAXArrays.Datasets.OrderedDict{Symbol,YAXArray}()
    axes = Dict{Symbol,DD.Dimension}()
    for (name, cube) ∈ zip(names, cubes)
        cube_dict[Symbol(name)] = cube
        for ax ∈ DD.dims(cube)
            axes[DD.name(ax)] = ax
        end
    end
    return Dataset(cube_dict, axes, properties)
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
DiskArrayEngine needs all output cubes to have the same dimensions, and those that xmap
adds for the core dimensions of the forcing that the output does not have.

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
    psTEMYax(in_pixel_cube...; selected_models, param_to_index, forcing_vars, loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data)
"""
function psTEMYax(in_pixel_cube...; selected_models, param_to_index, forcing_vars, loc_land::NamedTuple,
    output_vars, tem::NamedTuple, clean_data)

    outputs, inputs = unpackYaxForward(in_pixel_cube[1:end-1]; output_vars, forcing_vars)
    in_new_params = last(in_pixel_cube)
    # ? apply clean_data fields to input data points
    _num_type, _forcing_data_info = clean_data

    inputs = map(enumerate(inputs)) do (i, in_forcing)
        _data_info = _forcing_data_info[i]
        map(data_point -> cleanData(data_point, _data_info, _num_type), in_forcing)
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
    runTEMYaxParameters(selected_models, forcing::NamedTuple, in_cube_params, tbl_params, info::NamedTuple)

"""
function runTEMYaxParameters(selected_models, forcing::NamedTuple, in_cube_params, tbl_params, info::NamedTuple)

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
        clean_data=(; _num_type, _forcing_data_info),
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
    return setTypedParameters(selected_models, parameter_to_index, map(first, parameter_inputs))
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