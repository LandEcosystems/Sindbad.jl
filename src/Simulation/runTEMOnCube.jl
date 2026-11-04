export TEMYax
export runTEMYax

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
