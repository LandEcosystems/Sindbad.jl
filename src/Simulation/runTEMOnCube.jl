export prepTEMYax
export TEMYax
export runTEMYax
export getMaxCacheYax
export getLoopRangesYax
export removeArraysZarr

const DiskArrays = YAXArrays.Cubes.DiskArrays
const DAE = YAXArrays.Xmap.DAE

"""
    TypeHiddenDiskArray{T,N}

A disk array that wraps another array without its type in the type of the wrapper.

# Notes:
- The type of every cube of an `xmap` holds the types of all its input arrays. With
  the forcing cubes as inputs, which are views of permuted zarr arrays, these types are
  huge and every function that handles the cubes is very slow to compile. Wrapped,
  all inputs with the same element type and number of dimensions share one type.
- Reading a block dispatches on the wrapped array at run time, which is negligible
  next to reading the block from disk.
"""
struct TypeHiddenDiskArray{T,N} <: DiskArrays.AbstractDiskArray{T,N}
    parent::AbstractArray{T,N}
end

Base.parent(a::TypeHiddenDiskArray) = a.parent
Base.size(a::TypeHiddenDiskArray) = size(a.parent)
DiskArrays.haschunks(a::TypeHiddenDiskArray) = DiskArrays.haschunks(a.parent)
DiskArrays.eachchunk(a::TypeHiddenDiskArray) = DiskArrays.eachchunk(a.parent)
DiskArrays.readblock!(a::TypeHiddenDiskArray, aout, r::OrdinalRange...) = DiskArrays.readblock!(a.parent, aout, r...)

"""
    hideCubeType(cube)

Returns `cube` with its data wrapped in a `TypeHiddenDiskArray`, keeping its
dimensions, properties and chunks.
"""
hideCubeType(cube) = YAXArray(DD.dims(cube), TypeHiddenDiskArray(cube.data), cube.properties; chunks=DiskArrays.eachchunk(cube))


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

# Notes:
- Legacy, kept for the old `mapCube` run with a parameter cube, and will be
  removed in the future. New development goes through `coreTEMYax!`, which the
  current run uses for each grid.
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
    # define, precompute and spinup use the parameters of the first time step when
    # they vary in time, and the time loop updates them
    loc_models = initialModels(selected_models)
    land_prec = definePrecomputeTEM(loc_models, loc_forcing_t, loc_land, tem_info.model_helpers)
    land_spin = spinupTEMYax(loc_models, loc_forcing, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
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
- `forcing_sources`: the index of the input cube of each forcing variable, see
  `shareForcingCubesYax`. Variables with the same source share one cube.
- `parameter_to_index`: the index of each parameter per location in the models, or
  `nothing` when there are none. The values of the location then set the parameters of
  `selected_models` before the run.
- `parameter_time`: the `getTimeVaryingInfo` of the parameters, or `nothing` when no
  parameter varies in time. The models of the location are then a
  `TimeVaryingModels`, which the time loop updates.
"""
function TEMYax(map_cubes...;selected_models, forcing_vars, forcing_sources=Tuple(eachindex(forcing_vars)), loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data, restart_vars=(), parameter_to_index=nothing, parameter_time=nothing)
    # Make NaN check here instead of AllNaN filters


    outputs, inputs, restarts, parameter_inputs = unpackYaxForward(map_cubes; output_vars, forcing_vars, restart_vars, n_inputs=maximum(forcing_sources))
    selected_models = setLocationParametersYax(selected_models, parameter_to_index, parameter_inputs)
    selected_models = setTimeVaryingModels(selected_models, parameter_inputs, parameter_time)
    # the same rule as filterNanGrids: a grid with an invalid forcing value at any
    # time step is not run, and its output and restart stay NaN
    if any(in_forcing -> any(is_invalid_number, in_forcing), inputs)
        foreach(xout -> fill!(xout, NaN), outputs)
        foreach(xout -> fill!(xout, NaN), restarts)
        return nothing
    end

    # ? apply clean_data fields to input data points
    _num_type, _forcing_data_info = clean_data

    # each variable is cleaned with its own units and bounds, also when it shares its
    # input cube with another variable
    inputs = map(enumerate(forcing_sources)) do (i, i_source)
        _data_info = _forcing_data_info[i]
        map(data_point -> cleanData(data_point, _data_info, _num_type), inputs[i_source])
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
    TEMYaxFromRef(map_cubes...; tem_kwargs)

Runs `TEMYax` for one location with the keyword arguments held in `tem_kwargs[]`.

# Notes:
- `xmap` makes its function arguments part of the type of every function that runs it.
  The arguments of `TEMYax` hold the models and the land, which makes those types huge
  and slow to compile, so `prepTEMYax` passes them in a `Ref{Any}` instead.
- `TEMYax` is called dynamically once per location and is specialized as before.
"""
function TEMYaxFromRef(map_cubes...; tem_kwargs::Base.RefValue{Any})
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
    shareForcingCubesYax(info, forcing)

Returns the forcing cubes of a lazy run with one cube per source, their core
dimensions, and the index of the cube of each forcing variable.

# Notes:
- Each forcing variable is its own cube, and the run reads and decompresses every
  input cube of a block. Variables that read the same source variable of the same
  file, with the same dimensions and interpolation, e.g., `f_airT` and `f_airT_day`,
  or a placeholder that multiplies a source by zero, then read it more than once.
  Such variables share the cube of the first of them.
- The units and bounds are applied per variable in `TEMYax`, so variables that share a
  cube can differ in them.
- `exe_rules.yax_shared_forcing` set to `false` keeps one cube per variable.
"""
function shareForcingCubesYax(info, forcing)
    cubes = Tuple(values(forcing.data))
    dims = Tuple(forcing.dims)
    all_sources = Tuple(eachindex(cubes))
    get(info.experiment.exe_rules, :yax_shared_forcing, true) || return cubes, dims, all_sources
    forcing_settings = info.experiment.data_settings.forcing
    source_keys = map(Tuple(forcing.variables), cubes) do var_name, cube
        v_info = getForcingVariableInfo(forcing_settings.default_forcing, getproperty(forcing_settings.variables, Symbol(var_name)), forcing_settings)
        (something(v_info.data_path, ""), v_info.source_variable, v_info.space_time_type, v_info.dimension, v_info.interpolation_method, DD.dims(cube))
    end
    first_of_source = map(k -> findfirst(==(k), source_keys), source_keys)
    unique_firsts = unique(first_of_source)
    length(unique_firsts) == length(cubes) && return cubes, dims, all_sources
    sources = map(i -> findfirst(==(i), unique_firsts), first_of_source)
    print_info(shareForcingCubesYax, @__FILE__, @__LINE__, "$(length(cubes)) forcing variables read $(length(unique_firsts)) sources, each source is read once", n_m=4)
    return Tuple(cubes[i] for i ∈ unique_firsts), Tuple(dims[i] for i ∈ unique_firsts), sources
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
    prepTEMYax(selected_models, forcing::NamedTuple, info::NamedTuple)

Builds the lazy run of the TEM over the forcing cubes with `xmap`, without running
it. `runTEMYax` runs it.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `info`: a SINDBAD NT with all information needed for setup and execution of an experiment

# Returns:
- a NamedTuple with the `output` Dataset, the `restart` Dataset with the pools after
  spinup, the `restart_vars` written to it, and the `spinup_mode` of the step that saved
  the restart
"""
function prepTEMYax(selected_models, forcing::NamedTuple, info::NamedTuple)
    # forcing/input information, one cube per source so that no source is read twice
    forcing_cubes, forcing_dims, forcing_sources = shareForcingCubesYax(info, forcing)
    incubes = map(hideCubeType, forcing_cubes);
    indims = forcing_dims;
    n_forcing_cubes = length(incubes)
    # a spatial parameter has no core dimensions, so each location gets one value, and a
    # spatiotemporal one has time, so each location gets its values over time like a
    # forcing. The values set the parameters of the models of the location in TEMYax.
    parameter_cubes, parameter_dims, parameter_to_index, parameter_time = getParameterCubesYax(selected_models, forcing)
    incubes = (incubes..., parameter_cubes...)
    indims = (indims..., parameter_dims...)
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
        forcing_sources=forcing_sources,
        output_vars=run_helpers.output_vars,
        loc_land=loc_land,
        tem=run_helpers.tem_info,
        clean_data=(; _num_type, _forcing_data_info),
        restart_vars=restart_vars,
        parameter_to_index=parameter_to_index,
        parameter_time=parameter_time)
    outcubes = xmap(TEMYaxFromRef,
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
        output_names=varnames, restart_names=restart_names, restart_keys=restart_keys,
        in_cubes=incubes, n_forcing=n_forcing_cubes)
    return (; output=output_ds, restart=restart_ds, restart_vars=restart_vars, spinup_mode=getSaveRestartSpinupMode(info), xmap=xmap_cubes)
end

"""
    runTEMYax(xmap_cubes, store_path; max_cache=5e8, loop_ranges=nothing,
        run_filter=nothing, variable_properties=nothing,
        global_properties=Dict{String,Any}(), save_kwargs=(;),
        parallelization=ThreadsParallelization())

Runs the lazy run of `prepTEMYax` and writes all its output and restart cubes in one
pass to the zarr store at `store_path`.

# Arguments:
- `xmap_cubes`: the `xmap` field returned by `prepTEMYax`
- `store_path`: the path of the zarr store that holds the computed cubes
- `max_cache`: the cache size for the block that DiskArrayEngine optimizes
- `loop_ranges`: the steps of each loop dimension in a block, from
  `getLoopRangesYax`, or `nothing` to let DiskArrayEngine choose the block
- `run_filter`: a `ValidGridsFilterYax` from `getLoopRangesYax` that skips the blocks
  without a valid grid, or `nothing` to run every block
- `variable_properties`: a `Dict` of the attributes of each output variable by name,
  or `nothing`
- `global_properties`: the global attributes of the store
- `save_kwargs`: the keyword arguments of `savedataset`, e.g., the compressor
- `parallelization`: how the blocks run, see `getRunnerYax`

# Returns:
- a NamedTuple with the `output` and `restart` Datasets, read from the store

# Notes:
- All cubes of `prepTEMYax` come from one `xmap`. Saving them one by one runs the
  model once per cube, while `runXmap` runs it once for all of them.
- The cubes keep their padded dimensions until they are computed, since the run can
  only fuse the direct outputs of the `xmap`. The store has them removed.
- With the attributes, the store can be the final output file. The restart cubes stay
  in it until they are saved to their own file, see `removeArraysZarr`.
"""
function runTEMYax(xmap_cubes, store_path; max_cache=5e8, loop_ranges=nothing, run_filter=nothing, variable_properties=nothing, global_properties=Dict{String,Any}(), save_kwargs=(;), parallelization=ThreadsParallelization())
    dataset = xmap_cubes.dataset
    if !isnothing(variable_properties)
        cubes = Any[withPropertiesYax(cube, get(variable_properties, name, nothing)) for (name, cube) ∈ dataset.cubes]
        dataset = datasetFromCubes(collect(keys(dataset.cubes)), cubes)
    end
    computed = runXmap(dataset, store_path, xmap_cubes.padded_names; max_cache=max_cache, loop_ranges=loop_ranges, run_filter=run_filter, properties=global_properties, save_kwargs=save_kwargs, parallelization=parallelization)
    output_ds = datasetFromCubes(xmap_cubes.output_names, Any[computed.cubes[name] for name ∈ xmap_cubes.output_names])
    restart_ds = datasetFromCubes(xmap_cubes.restart_names, Any[computed.cubes[key] for key ∈ xmap_cubes.restart_keys])
    return (; output=output_ds, restart=restart_ds)
end

"""
    runXmap(dataset, path, padded_names; max_cache=5e8, loop_ranges=nothing,
        run_filter=nothing, properties=Dict{String,Any}(), save_kwargs=(;),
        parallelization=ThreadsParallelization())

Runs the `xmap` that the cubes of `dataset` come from in one pass, and writes the
cubes to a new zarr store at `path`. Returns the `Dataset` of the store.

# Arguments:
- `padded_names`: the names of the singleton dimensions of each cube that are not
  written, by cube name
- `loop_ranges`: the steps of each loop dimension in a block, or `nothing` for the
  block that DiskArrayEngine optimizes under `max_cache`
- `run_filter`: a run filter of DiskArrayEngine, e.g., `ValidGridsFilterYax`, that
  decides per block whether it runs, or `nothing` to run every block
- `properties`: the global attributes of the store
- `save_kwargs`: the keyword arguments of `savedataset`, e.g., the compressor
- `parallelization`: how the blocks run, see `getRunnerYax`

# Notes:
- The same as `YAXArrays.compute_to_zarr` of YAXArrays 0.7, with these differences:
  - All padded dimensions of a cube are dropped from the store. `compute_to_zarr`
    drops only those that are longer in another cube.
  - The chunks of every array follow the block in all of its dimensions, and are
    split further where a chunk would be larger than `MAX_CHUNK_BYTES_YAX`, see
    `capChunksYax`. `compute_to_zarr` loses them for a cube with dropped
    dimensions, which then gets the default chunks of DiskArrays. Every block then
    writes parts of chunks that other blocks write too.
  - A float array has NaN as its fill value, so the chunks of a block that the run
    filter skips read as NaN, the same as the invalid grids of a block that runs.
  - A block that `run_filter` skips is neither read nor written.
  - The global attributes and `save_kwargs` are passed to `savedataset`.
- It uses the internals of DiskArrayEngine 0.3, and is checked against the
  `compute_to_zarr` of YAXArrays when either is updated.
"""
function runXmap(dataset, path, padded_names; max_cache=5e8, loop_ranges=nothing, run_filter=nothing, properties=Dict{String,Any}(), save_kwargs=(;), parallelization=ThreadsParallelization())
    graph = DAE.MwopGraph()
    out_nodes = Dict{Symbol,Any}()
    for (name, cube) ∈ dataset.cubes
        cube.data isa DAE.GMWOPResult || error("the cube `$(name)` is not a direct output of an xmap")
        out_nodes[name] = DAE.to_graph!(graph, cube.data)
    end
    aliases = DAE.remove_aliases!(graph)
    DAE.fuse_graph!(graph)
    plans = map(graph.connections) do conn
        op = DAE.gmwop_from_conn(conn, graph.nodes)
        lr = isnothing(loop_ranges) ? DAE.optimize_loopranges(op, max_cache) : DAE.custom_loopranges(op, loop_ranges)
        outputs = map(conn.outputids, op.outspecs) do out_id, outspec
            name = findfirst(==(out_id), out_nodes)
            if isnothing(name)
                alias_ids = findall(==(out_id), aliases)
                name = findfirst(in(alias_ids), out_nodes)
            end
            isnothing(name) && return nothing
            # the chunks of the output in each of its dimensions, one per block
            block_ranges = DAE.mysub(outspec.lw, lr.lr.members)
            chunk_sizes = map(block_ranges, outspec.lw.windows.members) do ranges, windows
                DiskArrays.chunktype_from_chunksizes(map(r -> length(DAE.windowmin(windows[first(r)]):DAE.windowmax(windows[last(r)])), ranges))
            end
            cube = dataset.cubes[name]
            padded = filter(d -> DD.name(d) ∈ padded_names[name] && length(d) == 1, collect(DD.dims(cube)))
            keep = findall(d -> !any(p -> DD.name(p) == DD.name(d), padded), collect(DD.dims(cube)))
            stored = withNaNFillYax(dropPaddedDimsYax(cube, DD.name.(padded)))
            element_size = sizeof(Base.nonmissingtype(eltype(stored)))
            stored = YAXArrays.Datasets.setchunks(stored, DiskArrays.GridChunks(capChunksYax(Tuple(chunk_sizes[keep]), element_size)))
            name => (stored, size(cube))
        end
        op, lr, outputs
    end
    stored_cubes = [last(p) for (_, _, outputs) ∈ plans for p ∈ outputs if !isnothing(p)]
    stored_names = [first(p) for (_, _, outputs) ∈ plans for p ∈ outputs if !isnothing(p)]
    new_ds = datasetFromCubes(stored_names, Any[first(c) for c ∈ stored_cubes]; properties=Dict{String,Any}(string(k) => v for (k, v) ∈ properties))
    empty_ds = YAXArrays.savedataset(new_ds; path=path, skeleton=true, overwrite=true, save_kwargs...)
    for (op, lr, outputs) ∈ plans
        out_arrays = map(outputs) do p
            isnothing(p) && return nothing
            name, (_, full_size) = p
            data = empty_ds.cubes[name].data
            # the runner writes the cube with its padded dimensions
            size(data) == full_size ? data : reshape(data, full_size)
        end
        runner = getRunnerYax(parallelization, op, lr, out_arrays)
        runner = withRunFilterYax(runner, run_filter)
        run(runner)
    end
    return empty_ds
end

"""
    getRunnerYax(parallelization, op, loop_ranges, out_arrays)

Returns the DiskArrayEngine runner of the blocks of a lazy run.

# Arguments:
- `parallelization`: the `exe_rules.parallelization` of the experiment
  - `ThreadsParallelization` or `QbmapParallelization`: a `LocalRunner`, which runs one
    block at a time on all threads of this session
  - `PmapParallelization`: a `PMapRunner`, which runs one block on each Distributed
    worker at a time, on the threads of that worker
- `op`, `loop_ranges`, `out_arrays`: the operation, its blocks and the arrays it writes

# Notes:
- A `LocalRunner` leaves all threads idle while it reads and writes a block. With
  workers, the reading and writing of one worker overlaps the run of the others.
- The workers write their blocks to the store themselves. No two of them write to
  the same chunk, since the chunks follow the blocks.
"""
getRunnerYax(::ParallelizationPackage, op, loop_ranges, out_arrays) = DAE.LocalRunner(op, loop_ranges, out_arrays; showprogress=true)

function getRunnerYax(::PmapParallelization, op, loop_ranges, out_arrays)
    DAE.Distributed.nworkers() > 1 || error("parallelization `pmap` needs Distributed workers, e.g., from `addprocs`, with Sindbad loaded on them, but the session has $(DAE.Distributed.nworkers()) worker")
    return DAE.PMapRunner(op, loop_ranges, out_arrays; showprogress=true)
end

"""
    ValidGridsFilterYax

A run filter of DiskArrayEngine that skips every block of a lazy run without a valid
grid, e.g., one over ocean.

# Fields:
- `valid_sums`: the cumulative counts of the valid grids, see `getValidSumsYax`
- `i_space`: the loop dimension of each spatial dimension of the valid grids

# Notes:
- A grid is valid when the forcing without time has no invalid value at it, the same
  grids as in `getValidGridsYax`. `TEMYax` returns NaN at once for the others, so a
  block without a valid grid only costs the reading of its inputs.
"""
struct ValidGridsFilterYax{S,I}
    valid_sums::S
    i_space::I
end

DAE.need_run(inow, f::ValidGridsFilterYax) = boxSumYax(f.valid_sums, map(i -> inow[i], f.i_space)) > 0

"""
    withRunFilterYax(runner, run_filter)

Returns the `LocalRunner` or `PMapRunner` of DiskArrayEngine with the
`ValidGridsFilterYax` `run_filter` added to its run filters, or `runner` itself when
`run_filter` is `nothing`.

# Notes:
- The runner checks its run filters before it reads the inputs of a block, so a
  skipped block costs nothing. A `PMapRunner` checks them on the worker.
- The progress bar counts every block, and a skipped block is never counted, so the
  bar ends below 100% when blocks are skipped.
"""
withRunFilterYax(runner, _) = runner
withRunFilterYax(runner::DAE.LocalRunner, run_filter::ValidGridsFilterYax) = DAE.LocalRunner(runner.op, runner.loopranges, runner.outars, runner.threaded, runner.inbuffers_pure, runner.outbuffers, runner.cb, (runner.runfilter..., run_filter))
withRunFilterYax(runner::DAE.PMapRunner, run_filter::ValidGridsFilterYax) = DAE.PMapRunner(runner.op, runner.loopranges, runner.outars, runner.threaded, runner.inbuffers_pure, runner.outbuffers, runner.cb, (runner.runfilter..., run_filter))

"""
    withNaNFillYax(cube)

Returns `cube` with NaN as its `_FillValue`, which `savedataset` writes as the fill
value of the zarr array, or `cube` itself when it is not a float array or already has
a fill or missing value.

# Notes:
- The fill value is what a chunk that was never written reads as. With NaN, the
  output of a skipped block is the same as that of an invalid grid.
"""
function withNaNFillYax(cube)
    T = Base.nonmissingtype(eltype(cube))
    T <: AbstractFloat || return cube
    any(k -> haskey(cube.properties, k), ("_FillValue", "missing_value")) && return cube
    properties = merge(Dict{String,Any}(cube.properties), Dict{String,Any}("_FillValue" => T(NaN)))
    return YAXArray(DD.dims(cube), cube.data, properties)
end

"""
    MAX_CHUNK_BYTES_YAX

The largest chunk of an output array of a lazy run, 1 GiB, half the largest buffer
that the Blosc compressor of zarr can take.
"""
const MAX_CHUNK_BYTES_YAX = 2^30

"""
    capChunksYax(chunks, element_size; max_bytes=MAX_CHUNK_BYTES_YAX)

Returns `chunks`, a Tuple of the chunks of each dimension, split until no chunk has
more than `max_bytes` of elements of `element_size` bytes.

# Notes:
- A dimension that is one chunk, e.g., time, is split first, into chunks of near equal
  length. The blocks of the run already split the others, and each of their chunks
  is then split in the same way, so a block still writes whole chunks.
"""
function capChunksYax(chunks, element_size; max_bytes=MAX_CHUNK_BYTES_YAX)
    chunks = collect(Any, chunks)
    while true
        lengths = map(c -> maximum(length, c), chunks)
        n_bytes = prod(lengths; init=1) * element_size
        n_bytes <= max_bytes && return Tuple(chunks)
        splittable = findall(>(1), lengths)
        isempty(splittable) && return Tuple(chunks)
        whole = filter(i -> length(chunks[i]) == 1, splittable)
        candidates = isempty(whole) ? splittable : whole
        i = candidates[argmax(lengths[candidates])]
        piece = cld(lengths[i], min(cld(n_bytes, max_bytes), lengths[i]))
        sizes = reduce(vcat, ([min(piece, length(r) - k) for k ∈ 0:piece:length(r)-1] for r ∈ chunks[i]))
        chunks[i] = DiskArrays.chunktype_from_chunksizes(sizes)
    end
end

"""
    withPropertiesYax(cube, properties)

Returns `cube` with `properties` merged into its attributes, keeping its data, or
`cube` itself when `properties` is `nothing`.
"""
withPropertiesYax(cube, ::Nothing) = cube
withPropertiesYax(cube, properties) = YAXArray(DD.dims(cube), cube.data, merge(Dict{String,Any}(cube.properties), properties))

"""
    removeArraysZarr(store_path, names)

Deletes the variables `names` from the zarr store at `store_path`.

# Notes:
- A zarr store keeps the values of each dimension, e.g., `lat` or `d_cEco`, as an
  array of its own. A dimension that no variable uses after the deletion is deleted
  too, so the store has no leftover dimensions.
- A lazy run uses it to delete the restart variables from `all_variables.zarr` once
  they are saved to the restart file.
"""
function removeArraysZarr(store_path, names)
    foreach(name -> rm(joinpath(store_path, string(name)); recursive=true, force=true), names)
    array_dims = Dict{String,Vector{String}}()
    for name ∈ readdir(store_path)
        zattrs_file = joinpath(store_path, name, ".zattrs")
        isfile(joinpath(store_path, name, ".zarray")) && isfile(zattrs_file) || continue
        array_dims[name] = String.(parsefile(zattrs_file; dicttype=Dict{String,Any})["_ARRAY_DIMENSIONS"])
    end
    is_coordinate(name) = array_dims[name] == [name]
    used = union(String[], (dims for (name, dims) ∈ array_dims if !is_coordinate(name))...)
    for name ∈ keys(array_dims)
        is_coordinate(name) && name ∉ used && rm(joinpath(store_path, name); recursive=true)
    end
    return nothing
end

"""
    getMaxCacheYax(info, in_cubes, out_cubes=(); n_forcing=length(in_cubes),
        grids_per_thread=4, memory_fraction=0.66)
    getMaxCacheYax(info, xmap_cubes)

Returns the cache size of a cube run, `compute_to_zarr` or `mapCube`, from the
`yax_max_cache` setting. A number in the setting is used as it is, and with `null`
the cache is computed.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an
  experiment
- `in_cubes`: the input cubes of the run, starting with the forcing
- `out_cubes`: the output cubes of the run, empty when they are not built yet
- `xmap_cubes`: the `xmap` field returned by `prepTEMYax`, which holds both
- `n_forcing`: the number of forcing cubes at the start of `in_cubes`
- `grids_per_thread`: the number of valid grids per thread in a block
- `memory_fraction`: the largest share of the available memory for the run

# Notes:
- A cube run reads, runs and writes one block of grids at a time, and the
  threads only share the grids of that block. A grid with invalid forcing
  returns at once, so a block with fewer valid grids than threads leaves the
  other threads idle. The computed cache fits `grids_per_thread` valid grids per
  thread.
- The bytes of a grid are summed over the input and output cubes. A cube without
  a spatial dimension is read once for all grids of a block and is not counted.
- The share of valid grids is counted from the forcing without time, since
  reading the forcing with time costs as much as the run.
- The cache only holds the input and output buffers of a block. Reading or writing a
  block can copy each buffer once more, and every thread holds the data of its own
  grid, so the run is taken to need twice the cache and one grid per thread.
  This is kept within `memory_fraction` of the memory that is available when the
  cache is computed, which excludes what the session already holds.
- With `PmapParallelization`, the threads are those of one worker, and every worker
  holds its own block, see `getMemoryLimitYax`.
"""
function getMaxCacheYax(info, in_cubes, out_cubes=(); n_forcing=length(in_cubes), grids_per_thread=4, memory_fraction=0.66)
    max_cache = get(info.experiment.exe_rules, :yax_max_cache, nothing)
    max_cache isa Real && return max_cache
    isnothing(max_cache) || error("experiment.exe_rules.yax_max_cache must be a number of bytes, or null to compute it, got `$(max_cache)`")
    data_dimension = info.experiment.data_settings.forcing.data_dimension
    space_dims = Symbol.(data_dimension.space)
    time_name = Symbol(data_dimension.time)
    bytes_per_grid = sum(cube -> getBytesPerGridYax(cube, space_dims), (in_cubes..., out_cubes...))
    valid_fraction = getValidFractionYax(in_cubes[1:n_forcing], space_dims, time_name)
    parallelization = info.helpers.run.parallelization
    n_threads = getBlockThreadsYax(parallelization)
    n_procs = getBlockProcsYax(parallelization)
    n_grids = ceil(Int, grids_per_thread * n_threads / valid_fraction)
    cache = n_grids * bytes_per_grid
    print_info(getMaxCacheYax, @__FILE__, @__LINE__, "computed cache of $(round(cache / 1e9; digits=2)) GB: $(n_grids) grids per block at $(round(bytes_per_grid / 1e6; digits=2)) MB each, for $(grids_per_thread) valid grids on each of $(n_threads) threads with $(round(100 * valid_fraction; digits=1))% of grids valid", n_m=4)
    memory_limit, available_memory = getMemoryLimitYax(bytes_per_grid, parallelization; memory_fraction=memory_fraction)
    if cache > memory_limit
        @warn "The computed cache of $(round(cache / 1e9; digits=2)) GB needs up to $(round(((n_procs == 1 ? 2 : 2 * n_procs + 1) * cache + n_procs * n_threads * bytes_per_grid) / 1e9; digits=2)) GB for the run, more than $(round(Int, 100 * memory_fraction))% of the $(round(available_memory / 1e9; digits=2)) GB of available memory. It is set to $(round(memory_limit / 1e9; digits=2)) GB, so some threads stay idle."
        cache = memory_limit
    end
    return cache
end

getMaxCacheYax(info, xmap_cubes::NamedTuple; kwargs...) = getMaxCacheYax(info, xmap_cubes.in_cubes, values(xmap_cubes.dataset.cubes); n_forcing=xmap_cubes.n_forcing, kwargs...)

"""
    getMemoryLimitYax(bytes_per_grid, parallelization=ThreadsParallelization();
        memory_fraction=0.66)

Returns the largest cache of a cube run in bytes that keeps the run within
`memory_fraction` of the available memory, and the available memory.

# Notes:
- Reading or writing a block can copy each buffer once more, and every thread holds
  the data of its own grid, so the run is taken to need twice the cache and one grid
  per thread.
- With `PmapParallelization`, each worker holds a block, and this session keeps one
  more copy of the input buffers that it sends to the workers. The run is then taken
  to need twice the cache per worker plus one, and one grid per thread of every
  worker. The workers are started before this is computed, so the memory that they
  hold is not available.
"""
function getMemoryLimitYax(bytes_per_grid, parallelization=ThreadsParallelization(); memory_fraction=0.66)
    available_memory = Sys.free_memory()
    n_threads = getBlockThreadsYax(parallelization)
    n_procs = getBlockProcsYax(parallelization)
    n_buffers = n_procs == 1 ? 2 : 2 * n_procs + 1
    memory_limit = (memory_fraction * available_memory - n_procs * n_threads * bytes_per_grid) / n_buffers
    memory_limit > bytes_per_grid || error("$(round(Int, 100 * memory_fraction))% of the $(round(available_memory / 1e9; digits=2)) GB of available memory is too small to run $(n_procs) x $(n_threads) threads at $(round(bytes_per_grid / 1e6; digits=2)) MB per grid. Use fewer threads or more memory.")
    return memory_limit, available_memory
end

"""
    getBlockThreadsYax(parallelization)

Returns the number of threads that run one block of a cube run: those of this session,
or those of the first worker with `PmapParallelization`.
"""
getBlockThreadsYax(::ParallelizationPackage) = Threads.nthreads()
getBlockThreadsYax(::PmapParallelization) = DAE.Distributed.remotecall_fetch(Threads.nthreads, first(DAE.Distributed.workers()))

"""
    getBlockProcsYax(parallelization)

Returns the number of blocks of a cube run that run at once: one, or one per worker
with `PmapParallelization`.
"""
getBlockProcsYax(::ParallelizationPackage) = 1
getBlockProcsYax(::PmapParallelization) = DAE.Distributed.nworkers()

"""
    getMaxGridsYax(info, bytes_per_grid)

Returns the most grids that a block of a lazy run can have: those that fit the
`yax_max_cache` setting when it is a number, or else the memory limit of
`getMemoryLimitYax`.
"""
function getMaxGridsYax(info, bytes_per_grid)
    max_cache = get(info.experiment.exe_rules, :yax_max_cache, nothing)
    isnothing(max_cache) || max_cache isa Real || error("experiment.exe_rules.yax_max_cache must be a number of bytes, or null to compute it, got `$(max_cache)`")
    cache = isnothing(max_cache) ? first(getMemoryLimitYax(bytes_per_grid, info.helpers.run.parallelization)) : max_cache
    return max(1, floor(Int, cache / bytes_per_grid))
end

"""
    getLoopRangesYax(info, xmap_cubes; grids_per_thread=8)

Returns the cache, the block of grids and the run filter of a lazy run, as
`max_cache`, `loop_ranges` and `run_filter` of `runTEMYax`.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an
  experiment
- `xmap_cubes`: the `xmap` field returned by `prepTEMYax`
- `grids_per_thread`: the number of valid grids per thread that an `"auto"` block
  aims for

# Returns:
- the cache in bytes
- the number of steps of each loop dimension of the `xmap` in a block, or `nothing`
  to let DiskArrayEngine choose the block
- a `ValidGridsFilterYax` that skips the blocks without a valid grid, or `nothing`
  when no forcing without time marks the valid grids

# Notes:
- `exe_rules.yax_block_grids` sets the block, with the sizes in the order of
  `data_dimension.space`:
  - `"auto"` or `null`: whole chunks of the input cubes with time. The step in each
    spatial dimension is the least common multiple of their chunk sizes, so no such
    chunk is read for more than one block. The block grows by whole steps, keeping
    its sides near equal, while its fullest block has at most `grids_per_thread`
    valid grids per thread and it fits the memory, see `getMaxGridsYax`. With
    `PmapParallelization`, these are the threads of one worker. The valid
    grids are counted per block, so a block over land gets the intended work and one
    over ocean has less, instead of every block getting the average.
  - `[n_lat, n_lon]`: a fixed block of grids, e.g. for benchmarks.
  - `"optimizer"`: the block that DiskArrayEngine optimizes from its model of read
    time. That model does not count the invalid grids, nor that a chunk of a forcing
    with all time steps is decompressed whole for every block that reads it.
- With every setting, a block without a valid grid is skipped and not read.
- A block is cut at the end of each dimension. A spatial subset that does not start at
  a chunk boundary shifts the chunks against the blocks, so some chunks are then read
  by two blocks.
- The output chunks follow the block in space.
"""
function getLoopRangesYax(info, xmap_cubes; grids_per_thread=8)
    setting = something(get(info.experiment.exe_rules, :yax_block_grids, "auto"), "auto")
    data_dimension = info.experiment.data_settings.forcing.data_dimension
    space_dims = Symbol.(data_dimension.space)
    time_name = Symbol(data_dimension.time)
    in_cubes = xmap_cubes.in_cubes
    op = first(values(xmap_cubes.dataset.cubes)).data.op
    # the loop dimensions of the xmap are those of all its inputs, in this order,
    # followed by those that only the outputs have
    input_names = DD.name.(DD.combinedims(in_cubes...; val=true, type=false, msg=nothing))
    length(input_names) <= length(op.windowsize) || error("the $(length(input_names)) dimensions of the input cubes are more than the $(length(op.windowsize)) loop dimensions of the lazy run")
    i_space = map(d -> findfirst(==(d), input_names), Tuple(space_dims))
    any(isnothing, i_space) && error("the spatial dimensions $(space_dims) are not all among the dimensions $(input_names) of the input cubes")
    space_sizes = map(i -> op.windowsize[i], i_space)
    expected_sizes = map(d -> length(DD.dims(first(c for c ∈ in_cubes if DD.hasdim(c, d)), d)), Tuple(space_dims))
    space_sizes == expected_sizes || error("the loop sizes $(space_sizes) of the spatial dimensions $(space_dims) do not match their lengths $(expected_sizes)")
    valid_grids = getValidGridsYax(in_cubes[1:xmap_cubes.n_forcing], space_dims, time_name)
    valid_sums = getValidSumsYax(valid_grids)
    run_filter = isnothing(valid_sums) ? nothing : ValidGridsFilterYax(valid_sums, i_space)
    setting == "optimizer" && return getMaxCacheYax(info, xmap_cubes), nothing, run_filter
    bytes_per_grid = sum(cube -> getBytesPerGridYax(cube, space_dims), (in_cubes..., values(xmap_cubes.dataset.cubes)...))
    block = if setting == "auto"
        steps = map(d -> getChunkStepYax(in_cubes, d, time_name), Tuple(space_dims))
        max_valid = grids_per_thread * getBlockThreadsYax(info.helpers.run.parallelization)
        max_grids = getMaxGridsYax(info, bytes_per_grid)
        fits = b -> prod(b) <= max_grids && maximum(getBlockValidCountsYax(valid_sums, b, space_sizes)) <= max_valid
        growBlockYax(steps, space_sizes, fits)
    elseif setting isa AbstractVector && length(setting) == length(space_dims)
        map((n, s) -> clamp(Int(n), 1, s), Tuple(setting), space_sizes)
    else
        error("experiment.exe_rules.yax_block_grids must be \"auto\", \"optimizer\", or the grids of a block in each of $(space_dims), got `$(setting)`")
    end
    loop_steps = ntuple(length(op.windowsize)) do i
        j = findfirst(==(i), i_space)
        isnothing(j) ? op.windowsize[i] : block[j]
    end
    n_grids = prod(block)
    n_blocks = prod(cld.(space_sizes, block))
    valid_counts = getBlockValidCountsYax(valid_sums, block, space_sizes)
    n_skipped = count(iszero, valid_counts)
    parallelization = info.helpers.run.parallelization
    run_threads = "$(getBlockProcsYax(parallelization)) x $(getBlockThreadsYax(parallelization))"
    print_info(getLoopRangesYax, @__FILE__, @__LINE__, "$(n_blocks) blocks of $(join(block, "x")) grids in $(join(space_dims, "x")), up to $(maximum(valid_counts)) valid grids per block for $(run_threads) threads, $(round(n_grids * bytes_per_grid / 1e9; digits=2)) GB per block. $(n_skipped) blocks without a valid grid are skipped.", n_m=4)
    return n_grids * bytes_per_grid, loop_steps, run_filter
end

"""
    getChunkStepYax(cubes, dim_name, time_name)

Returns the least common multiple of the chunk sizes in the dimension `dim_name` of
the stored `cubes` with time, or 1 when no such cube has it.

# Notes:
- A block that reads part of a chunk decompresses the whole chunk. That is only
  costly for a chunk with all time steps, so the cubes without time, e.g., a map of
  the vegetation type stored as one chunk, do not set the step. Nor do cubes without
  stored chunks, e.g., forcing resampled on the fly.
"""
function getChunkStepYax(cubes, dim_name, time_name)
    step = 1
    for cube ∈ cubes
        cube_names = DD.name.(DD.dims(cube))
        time_name ∈ cube_names || continue
        DiskArrays.haschunks(cube.data) isa DiskArrays.Chunked || continue
        i_dim = findfirst(==(dim_name), cube_names)
        isnothing(i_dim) && continue
        step = lcm(step, DiskArrays.approx_chunksize(DiskArrays.eachchunk(cube.data).chunks[i_dim]))
    end
    return step
end

"""
    growBlockYax(steps, sizes, fits)

Returns the block that starts at one step in each dimension and grows by whole steps,
always on its shortest side that can still grow, while `fits(block)` is true. A block
of one step is returned even when it does not fit.
"""
function growBlockYax(steps, sizes, fits)
    block = min.(steps, sizes)
    while true
        growable = filter(i -> block[i] < sizes[i], collect(eachindex(block)))
        sort!(growable; by=i -> block[i])
        i_grow = findfirst(i -> fits(Base.setindex(block, min(block[i] + steps[i], sizes[i]), i)), growable)
        isnothing(i_grow) && return block
        i = growable[i_grow]
        block = Base.setindex(block, min(block[i] + steps[i], sizes[i]), i)
    end
end

"""
    getValidSumsYax(valid_grids)

Returns the cumulative counts of the valid grids along every dimension, with a zero
before the first grid, so that `boxSumYax` counts the valid grids of any block at
once. Returns `nothing` for `nothing`.
"""
getValidSumsYax(::Nothing) = nothing

function getValidSumsYax(valid_grids)
    sums = zeros(Int, size(valid_grids) .+ 1)
    sums[map(n -> 2:n+1, size(valid_grids))...] .= valid_grids
    for d ∈ 1:ndims(sums)
        sums = cumsum(sums; dims=d)
    end
    return sums
end

"""
    boxSumYax(sums, ranges)

Returns the number of valid grids in the block of `ranges`, one range per dimension,
from the cumulative counts `sums` of `getValidSumsYax`.
"""
function boxSumYax(sums, ranges)
    n_dims = length(ranges)
    total = 0
    for corner ∈ CartesianIndices(ntuple(_ -> 0:1, n_dims))
        index = ntuple(d -> corner[d] == 1 ? last(ranges[d]) + 1 : first(ranges[d]), n_dims)
        total += iseven(n_dims - sum(Tuple(corner))) ? sums[index...] : -sums[index...]
    end
    return total
end

"""
    getBlockValidCountsYax(valid_sums, block, sizes)

Returns the number of valid grids in each block of size `block` that tiles a domain of
`sizes`, from the first grid on. Without valid grids, every grid counts as valid.
"""
function getBlockValidCountsYax(valid_sums, block, sizes)
    starts = map((b, n) -> 1:b:n, Tuple(block), Tuple(sizes))
    return map(Iterators.product(starts...)) do first_indices
        ranges = map((i, b, n) -> i:min(i + b - 1, n), first_indices, Tuple(block), Tuple(sizes))
        isnothing(valid_sums) ? prod(length.(ranges)) : boxSumYax(valid_sums, ranges)
    end
end

"""
    getBytesPerGridYax(cube, space_dims)

Returns the bytes of one grid of `cube`, or zero when it has no spatial
dimension.
"""
function getBytesPerGridYax(cube, space_dims)
    cube_dims = DD.dims(cube)
    any(d -> DD.name(d) ∈ space_dims, cube_dims) || return 0
    n_values = prod((length(d) for d ∈ cube_dims if DD.name(d) ∉ space_dims); init=1)
    return n_values * sizeof(Base.nonmissingtype(eltype(cube)))
end

"""
    getValidGridsYax(forcing_cubes, space_dims, time_name)

Returns whether each grid has no invalid value in the forcing cubes that have every
spatial dimension and no time, as an array over `space_dims`, or `nothing` when there
is no such cube.

# Notes:
- The forcing with time is not read, since that costs as much as the run. A grid that
  is valid here can still be invalid in it, and is then left as NaN by `TEMYax`.
"""
function getValidGridsYax(forcing_cubes, space_dims, time_name)
    is_valid = nothing
    for cube ∈ forcing_cubes
        cube_names = DD.name.(DD.dims(cube))
        (time_name ∈ cube_names || !all(∈(cube_names), space_dims)) && continue
        other_names = filter(∉(space_dims), cube_names)
        perm = DD.dimnum(cube, (space_dims..., other_names...))
        data = permutedims(Array(cube.data), perm)
        space_size = size(data)[1:length(space_dims)]
        cube_valid = reshape(all(!is_invalid_number, reshape(data, prod(space_size), :); dims=2), space_size)
        is_valid = isnothing(is_valid) ? cube_valid : is_valid .& cube_valid
    end
    return is_valid
end

"""
    getValidFractionYax(forcing_cubes, space_dims, time_name)

Returns the share of the valid grids of `getValidGridsYax`, or one when no forcing
marks them.
"""
function getValidFractionYax(forcing_cubes, space_dims, time_name)
    is_valid = getValidGridsYax(forcing_cubes, space_dims, time_name)
    isnothing(is_valid) && return 1.0
    return max(count(is_valid), 1) / length(is_valid)
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

# Notes:
- Legacy, kept for the old `mapCube` run with a parameter cube, and will be
  removed in the future. New development goes through `prepTEMYax` and
  `runTEMYax`, where the parameters per grid come from `forcing.parameters`.
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

# Notes:
- Legacy, kept for the old `mapCube` run with a parameter cube, and will be
  removed in the future. New development goes through `prepTEMYax` and
  `runTEMYax`, where the parameters per grid come from `forcing.parameters`.
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
        max_cache=getMaxCacheYax(info, in_cubes_all; n_forcing=length(in_cubes_forcing)),
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
- `n_inputs`: the number of forcing input cubes, fewer than `forcing_vars` when
  variables share a cube

# Notes:
- The cubes of the parameters per location, if any, follow the forcing cubes and are
  returned last.
"""
function unpackYaxForward(all_cubes; output_vars, forcing_vars, restart_vars=(), n_inputs=length(forcing_vars))
    nin = n_inputs
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

Returns the cubes of the parameters per location, their core dimensions, and the index
of each parameter in the models, for the input cubes of `xmap`.

# Returns:
- `()`, `()`, `nothing` and `nothing` when `forcing.parameters` is `nothing`, so the
  input cubes of `xmap` are only the forcing.
- Otherwise:
  - the cubes of `forcing.parameters.data`, which hold values that are already in run
    units and within bounds, with their types hidden like the forcing cubes
  - the core dimensions of each cube, `(time,)` for a parameter with time, else `()`
  - the `parameter_to_index` from `getParameterIndices`
  - the `getTimeVaryingInfo` of the parameters, `nothing` when none varies in time
"""
function getParameterCubesYax(selected_models, forcing)
    forcing_parameters = get(forcing, :parameters, nothing)
    isnothing(forcing_parameters) && return (), (), nothing, nothing
    parameter_to_index = getParameterIndices(selected_models, forcing_parameters.parameter_table)
    parameter_time = getTimeVaryingInfo(selected_models, parameter_to_index, forcing_parameters)
    parameter_cubes = map(hideCubeType, Tuple(forcing_parameters.data))
    return parameter_cubes, Tuple(forcing_parameters.dims), parameter_to_index, parameter_time
end


"""
    setLocationParametersYax(selected_models, parameter_to_index, parameter_inputs)

Returns the models of one location with the parameters set from the values of the
parameters per location, or `selected_models` when there are none.

# Arguments:
- `selected_models`: a tuple of all models selected in the given model structure
- `parameter_to_index`: the index of each parameter in the models, or `nothing`
- `parameter_inputs`: the values of each parameter at the location from `xmap`, an
  array without dimensions, or with time for a parameter that varies in time, in which
  case the value of the first time step is set
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
- Legacy, kept for the old `mapCube` run with a parameter cube, and will be
  removed in the future. New development goes through `prepTEMYax` and
  `runTEMYax`, where the parameters per grid come from `forcing.parameters`.
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