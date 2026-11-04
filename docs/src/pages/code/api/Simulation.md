```@docs
Sindbad.Simulation
```
## Functions

### TEMLazy
```@docs
TEMLazy
```

:::details Code

```julia
function TEMLazy(map_cubes...;selected_models, forcing_vars, forcing_sources=Tuple(eachindex(forcing_vars)), loc_land::NamedTuple, output_vars, tem::NamedTuple, clean_data, restart_vars=(), parameter_to_index=nothing, parameter_time=nothing)
    # Make NaN check here instead of AllNaN filters


    outputs, inputs, restarts, parameter_inputs = unpackGridCubes(map_cubes; output_vars, forcing_vars, restart_vars, n_inputs=maximum(forcing_sources))
    selected_models = setGridParameters(selected_models, parameter_to_index, parameter_inputs)
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
    store_restart = land -> fillGridRestart(restarts, land, restart_vars)
    # every pixel gets its own copy, as the land has mutable arrays and the pixels can
    # run on different threads
    coreTEMLazy!(outputs, selected_models, loc_forcing, deepcopy(loc_land), tem, store_restart)
    return nothing
end

function TEMLazyForGrid(map_cubes...; tem_kwargs::Base.RefValue{Any})
    TEMLazy(map_cubes...; tem_kwargs[]...)
    return nothing
end
```

:::


----

### accumulateSpinupForcing
```@docs
accumulateSpinupForcing
```

:::details Code

```julia
function accumulateSpinupForcing end

accumulateSpinupForcing(::Tuple{}, _, _, spinup_forcing) = spinup_forcing

accumulateSpinupForcing(spin_sequences::Tuple{SpinupStepWithAggregator{:none},Vararg}, forcing, tem_helpers, spinup_forcing) = accumulateSpinupForcing(Base.tail(spin_sequences), forcing, tem_helpers, spinup_forcing)

function accumulateSpinupForcing(spin_sequences::Tuple{SpinupStepWithAggregator{F},Vararg}, forcing, tem_helpers, spinup_forcing) where {F}
    if F ∉ keys(spinup_forcing)
        seq_forc = getSpinupForcing(forcing, first(spin_sequences), tem_helpers.vals.forcing_types)
        spinup_forcing = set_namedtuple_field(spinup_forcing, (F, seq_forc))
    end
    return accumulateSpinupForcing(Base.tail(spin_sequences), forcing, tem_helpers, spinup_forcing)
end

function accumulateSpinupForcing(spin_sequences::Tuple{SpinupStepWithAggregator{F},Vararg}, forcing, tem_helpers, spinup_forcing) where {F}
    if F ∉ keys(spinup_forcing)
        seq_forc = getSpinupForcing(forcing, first(spin_sequences), tem_helpers.vals.forcing_types)
        spinup_forcing = set_namedtuple_field(spinup_forcing, (F, seq_forc))
    end
    return accumulateSpinupForcing(Base.tail(spin_sequences), forcing, tem_helpers, spinup_forcing)
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

function coreTEM(selected_models, loc_forcing, loc_spinup, loc_forcing_t, loc_land, tem_info, spinup_mode)

    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, spinup_mode)

    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return land_time_series
end

function coreTEM(selected_models, loc_forcing, loc_spinup, loc_forcing_t, loc_land, tem_info, spinup_mode)

    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, spinup_mode)

    land_time_series = timeLoopTEM(selected_models, loc_forcing, loc_forcing_t, land_spin, tem_info, tem_info.run.debug_model)
    return land_time_series
end

function coreTEM(selected_models, loc_forcing, loc_spinup, loc_forcing_t, land_time_series, loc_land, tem_info, spinup_mode)
    land_prec = precomputeTEM(selected_models, loc_forcing_t, loc_land, tem_info.model_helpers)

    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, spinup_mode)

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
function coreTEM!(selected_models, loc_forcing, loc_spinup, loc_forcing_t, loc_output, loc_land, tem_info)
    return coreTEM!(selected_models, loc_forcing, loc_spinup, loc_forcing_t, loc_output, nothing, loc_land, tem_info)
end

function coreTEM!(selected_models, loc_forcing, loc_spinup, loc_forcing_t, loc_output, loc_restart, loc_land, tem_info)
    # update the loc_forcing with the actual location
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing_t, 1, tem_info.vals.forcing_types)
    # precompute and spinup use the parameters of the first time step when they vary
    # in time, and the time loop updates them
    loc_models = initialModels(selected_models)
    # run precompute
    land_prec = precomputeTEM(loc_models, loc_forcing_t, loc_land, tem_info.model_helpers)
    # run spinup, which stores the pools for the restart file after the spinup step with
    # `save_restart`
    land_spin = spinupTEM(loc_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, loc_restart)

    timeLoopTEM!(selected_models, loc_forcing, loc_forcing_t, loc_output, land_spin, tem_info.vals.forcing_types, tem_info.model_helpers, tem_info.vals.output_vars, tem_info.n_timesteps, tem_info.run.debug_model)
    return nothing
end
```

:::


----

### dropVariablesFromStore
```@docs
dropVariablesFromStore
```

:::details Code

```julia
function dropVariablesFromStore(store_path, names)
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
```

:::


----

### getAllSpinupForcing
```@docs
getAllSpinupForcing
```

:::details Code

```julia
function getAllSpinupForcing(forcing, spin_sequences::Tuple{Vararg{SpinupStepWithAggregator}}, tem_helpers)
    return accumulateSpinupForcing(spin_sequences, forcing, tem_helpers, (;))
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
        # a variable with fewer dimensions than the domain's spatial index tuple has none of
        # the domain's spatial dimensions at all (e.g. a globally-uniform forcing such as
        # atmospheric CO2 with no lat/lon axis) -- it is constant across the domain, so it is
        # passed through unindexed rather than attempting a spatial view it cannot support
        if ndims(a) < length(loc_ind)
            Array(a)
        else
            view_at_trailing_indices(a, loc_ind) |> Array
        end
    end
    return loc_forcing
end
```

:::


----

### getLoopRanges
```@docs
getLoopRanges
```

:::details Code

```julia
function getLoopRanges(info, xmap_cubes; grids_per_thread=8)
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
    valid_grids = getValidGrids(in_cubes[1:xmap_cubes.n_forcing], space_dims, time_name)
    valid_sums = getValidGridSums(valid_grids)
    run_filter = isnothing(valid_sums) ? nothing : ValidGridsFilter(valid_sums, i_space)
    setting == "optimizer" && return getYaxMaxCache(info, xmap_cubes), nothing, run_filter
    bytes_per_grid = sum(cube -> getBytesPerGrid(cube, space_dims), (in_cubes..., values(xmap_cubes.dataset.cubes)...))
    block = if setting == "auto"
        steps = map(d -> getChunkStep(in_cubes, d, time_name), Tuple(space_dims))
        max_valid = grids_per_thread * getThreadsPerBlock(info.helpers.run.parallelization)
        max_grids = getMaxGridsPerBlock(info, bytes_per_grid)
        fits = b -> prod(b) <= max_grids && maximum(getValidCountsPerBlock(valid_sums, b, space_sizes)) <= max_valid
        growBlock(steps, space_sizes, fits)
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
    valid_counts = getValidCountsPerBlock(valid_sums, block, space_sizes)
    n_skipped = count(iszero, valid_counts)
    parallelization = info.helpers.run.parallelization
    run_threads = "$(getProcsPerBlock(parallelization)) x $(getThreadsPerBlock(parallelization))"
    print_info(getLoopRanges, @__FILE__, @__LINE__, "$(n_blocks) blocks of $(join(block, "x")) grids in $(join(space_dims, "x")), up to $(maximum(valid_counts)) valid grids per block for $(run_threads) threads, $(round(n_grids * bytes_per_grid / 1e9; digits=2)) GB per block. $(n_skipped) blocks without a valid grid are skipped.", n_m=4)
    return n_grids * bytes_per_grid, loop_steps, run_filter
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
        path=joinpath(info.output.dirs.data, "$(vname).$(outformat)"),
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

function getOutDimsPairs(tem_output, forcing_helpers; dthres=1, with_time=true)
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
        with_time && push!(od, axes_dims_pairs[1])
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

### getRestartDimsArrays
```@docs
getRestartDimsArrays
```

:::details Code

```julia
function getRestartDimsArrays(info, forcing_helpers, loc_land)
    restart_vars = getRestartVars(info, loc_land)
    # the dimension names follow the output settings, but the sizes always come from
    # land so that every layer of a variable is stored
    depth_info = map(restart_vars, getLandVarDepthInfo(info, loc_land, restart_vars)) do var_pair, d_info
        length(getproperty(getproperty(loc_land, first(var_pair)), last(var_pair))), last(d_info)
    end
    restart_info = (; variables=restart_vars, depth_info=depth_info)
    dims_pairs = getOutDimsPairs(restart_info, forcing_helpers; with_time=false)
    restart_dims = map(dims_pairs) do dim_pairs
        Tuple(YAXArrays.Dim{first(_dim)}(last(_dim)) for _dim in dim_pairs)
    end
    num_type = info.helpers.numbers.num_type
    space_sizes = Base.tail(values(forcing_helpers.sizes))
    restart_array = map(depth_info) do d_info
        fill(num_type(NaN), 1, first(d_info), space_sizes...)
    end
    return (; variables=restart_vars, dims_pairs=dims_pairs, dims=restart_dims, data=[restart_array...])
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
    loc_space_maps = filterNanGrids(forcing, loc_space_maps, filter_nan_pixels)
    space_ind = Tuple([Tuple(last.(loc_space_map)) for loc_space_map ∈ loc_space_maps])
    return space_ind
end
```

:::


----

### getSpinupSequence
```@docs
getSpinupSequence
```

:::details Code

```julia
function getSpinupSequenceSteps(sequence)
    steps = [0]
    for (seq_index, spin_seq) ∈ enumerate(sequence)
        append!(steps, fill(seq_index, spin_seq.n_repeat * spinupStoreSteps(spin_seq)))
    end
    return steps
end
```

:::


----

### getYaxMaxCache
```@docs
getYaxMaxCache
```

:::details Code

```julia
function getYaxMaxCache(info, in_cubes, out_cubes=(); n_forcing=length(in_cubes), grids_per_thread=4, memory_fraction=0.66)
    max_cache = get(info.experiment.exe_rules, :yax_max_cache, nothing)
    max_cache isa Real && return max_cache
    isnothing(max_cache) || error("experiment.exe_rules.yax_max_cache must be a number of bytes, or null to compute it, got `$(max_cache)`")
    data_dimension = info.experiment.data_settings.forcing.data_dimension
    space_dims = Symbol.(data_dimension.space)
    time_name = Symbol(data_dimension.time)
    bytes_per_grid = sum(cube -> getBytesPerGrid(cube, space_dims), (in_cubes..., out_cubes...))
    valid_fraction = getValidGridFraction(in_cubes[1:n_forcing], space_dims, time_name)
    parallelization = info.helpers.run.parallelization
    n_threads = getThreadsPerBlock(parallelization)
    n_procs = getProcsPerBlock(parallelization)
    n_grids = ceil(Int, grids_per_thread * n_threads / valid_fraction)
    cache = n_grids * bytes_per_grid
    print_info(getYaxMaxCache, @__FILE__, @__LINE__, "computed cache of $(round(cache / 1e9; digits=2)) GB: $(n_grids) grids per block at $(round(bytes_per_grid / 1e6; digits=2)) MB each, for $(grids_per_thread) valid grids on each of $(n_threads) threads with $(round(100 * valid_fraction; digits=1))% of grids valid", n_m=4)
    memory_limit, available_memory = getCacheMemoryLimit(bytes_per_grid, parallelization; memory_fraction=memory_fraction)
    if cache > memory_limit
        @warn "The computed cache of $(round(cache / 1e9; digits=2)) GB needs up to $(round(((n_procs == 1 ? 2 : 2 * n_procs + 1) * cache + n_procs * n_threads * bytes_per_grid) / 1e9; digits=2)) GB for the run, more than $(round(Int, 100 * memory_fraction))% of the $(round(available_memory / 1e9; digits=2)) GB of available memory. It is set to $(round(memory_limit / 1e9; digits=2)) GB, so some threads stay idle."
        cache = memory_limit
    end
    return cache
end
```

:::


----

### prepSequenceDefault
```@docs
prepSequenceDefault
```

:::details Code

```julia
function prepSequenceDefault(; nrepeat_base=200, forcing_msc="day_MSC")
    return [
        Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => forcing_msc, "n_repeat" => nrepeat_base),
        Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => "all_years", "n_repeat" => 1),
    ]
end
```

:::


----

### prepSequenceWithAge
```@docs
prepSequenceWithAge
```

:::details Code

```julia
function prepSequenceWithAge(year_disturbance; nrepeat_base=200, year_start = 1979, forcing_msc = "day_MSC")
    nrepeat_age = nrepeatYearsAge(year_disturbance; year_start)
    sequence = [
        Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => "all_years", "n_repeat" => 1),
        Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => forcing_msc, "n_repeat" => nrepeat_base),
        Dict("spinup_mode" => "eta_scale_H", "forcing" => nothing, "models" => nothing, "n_repeat" => 1, "save_restart" => true),
    ]
    if nrepeat_age >= 0
        sequence = [
            Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => forcing_msc, "n_repeat" => nrepeat_base),
            Dict("spinup_mode" => "clearance_A0", "forcing" => nothing, "models" => nothing, "n_repeat" => 1),
            Dict("spinup_mode" => "eta_scale_H", "forcing" => nothing, "models" => nothing, "n_repeat" => 1, "save_restart" => true),
            Dict("spinup_mode" => "loop_TEM", "models" => "spinup", "forcing" => forcing_msc, "n_repeat" => nrepeat_age),
        ]
    end
    return sequence
end
```

:::


----

### prepSpinupOut
```@docs
prepSpinupOut
```

:::details Code

```julia
function prepSpinupOut end

prepSpinupOut(info, run_helpers) = prepSpinupOut(info, run_helpers, info.helpers.run.store_spinup)

prepSpinupOut(_, _, ::DoNotStoreSpinup) = nothing

function prepSpinupOut(info, run_helpers, ::DoStoreSpinup)
    restart = run_helpers.restart
    space_land = run_helpers.space_land
    space_ind = run_helpers.space_ind
    sequences = [loc_spinup.sequence for loc_spinup ∈ run_helpers.space_spinup]
    sequence_steps = map(getSpinupSequenceSteps, sequences)
    n_max = maximum(length, sequence_steps)
    step_dim = YAXArrays.Dim{:spinup_step}(1:n_max)
    num_type = info.helpers.numbers.num_type
    variables = []
    names = Symbol[]
    dims = []
    data = []
    space_dims = ()
    for pool_name ∈ (:cEco, :TWS)
        store_name = Symbol("spinup_", pool_name)
        loc_store = getproperty(first(space_land).states, store_name)
        isnothing(loc_store) && continue
        var_index = findfirst(==((:pools, pool_name)), restart.variables)
        isnothing(var_index) && continue
        n_layers = size(loc_store, 2)
        space_sizes = size(restart.data[var_index])[3:end]
        pool_data = fill(num_type(NaN), n_max, n_layers, space_sizes...)
        for (loc_land, loc_ind) ∈ zip(space_land, space_ind)
            loc_store = getproperty(loc_land.states, store_name)
            view_at_trailing_indices(pool_data, loc_ind)[1:size(loc_store, 1), :] .= loc_store
        end
        pool_dims = restart.dims[var_index]
        if n_layers == 1
            pool_data = dropdims(pool_data; dims=2)
        end
        space_dims = Tuple(pool_dims)[end-length(space_sizes)+1:end]
        push!(variables, (:pools, pool_name))
        push!(names, pool_name)
        push!(dims, (step_dim, pool_dims...))
        push!(data, pool_data)
    end
    isempty(data) && return nothing
    space_sizes = size(last(data))[end-length(space_dims)+1:end]
    step_data = fill(-1, n_max, space_sizes...)
    for (loc_steps, loc_ind) ∈ zip(sequence_steps, space_ind)
        view_at_trailing_indices(step_data, loc_ind)[1:length(loc_steps)] .= loc_steps
    end
    push!(variables, nothing)
    push!(names, :spinup_sequence_step)
    push!(dims, (step_dim, space_dims...))
    push!(data, step_data)
    return (; variables, names, dims, data, sequences, space_ind)
end

function prepSpinupOut(info, run_helpers, ::DoStoreSpinup)
    restart = run_helpers.restart
    space_land = run_helpers.space_land
    space_ind = run_helpers.space_ind
    sequences = [loc_spinup.sequence for loc_spinup ∈ run_helpers.space_spinup]
    sequence_steps = map(getSpinupSequenceSteps, sequences)
    n_max = maximum(length, sequence_steps)
    step_dim = YAXArrays.Dim{:spinup_step}(1:n_max)
    num_type = info.helpers.numbers.num_type
    variables = []
    names = Symbol[]
    dims = []
    data = []
    space_dims = ()
    for pool_name ∈ (:cEco, :TWS)
        store_name = Symbol("spinup_", pool_name)
        loc_store = getproperty(first(space_land).states, store_name)
        isnothing(loc_store) && continue
        var_index = findfirst(==((:pools, pool_name)), restart.variables)
        isnothing(var_index) && continue
        n_layers = size(loc_store, 2)
        space_sizes = size(restart.data[var_index])[3:end]
        pool_data = fill(num_type(NaN), n_max, n_layers, space_sizes...)
        for (loc_land, loc_ind) ∈ zip(space_land, space_ind)
            loc_store = getproperty(loc_land.states, store_name)
            view_at_trailing_indices(pool_data, loc_ind)[1:size(loc_store, 1), :] .= loc_store
        end
        pool_dims = restart.dims[var_index]
        if n_layers == 1
            pool_data = dropdims(pool_data; dims=2)
        end
        space_dims = Tuple(pool_dims)[end-length(space_sizes)+1:end]
        push!(variables, (:pools, pool_name))
        push!(names, pool_name)
        push!(dims, (step_dim, pool_dims...))
        push!(data, pool_data)
    end
    isempty(data) && return nothing
    space_sizes = size(last(data))[end-length(space_dims)+1:end]
    step_data = fill(-1, n_max, space_sizes...)
    for (loc_steps, loc_ind) ∈ zip(sequence_steps, space_ind)
        view_at_trailing_indices(step_data, loc_ind)[1:length(loc_steps)] .= loc_steps
    end
    push!(variables, nothing)
    push!(names, :spinup_sequence_step)
    push!(dims, (step_dim, space_dims...))
    push!(data, step_data)
    return (; variables, names, dims, data, sequences, space_ind)
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

### prepTEMLazy
```@docs
prepTEMLazy
```

:::details Code

```julia
function prepTEMLazy(selected_models, forcing::NamedTuple, info::NamedTuple)
    # forcing/input information, one cube per source so that no source is read twice
    forcing_cubes, forcing_dims, forcing_sources = shareForcingCubes(info, forcing)
    incubes = map(hideCubeType, forcing_cubes);
    indims = forcing_dims;
    n_forcing_cubes = length(incubes)
    # a spatial parameter has no core dimensions, so each location gets one value, and a
    # spatiotemporal one has time, so each location gets its values over time like a
    # forcing. The values set the parameters of the models of the location in
    # TEMLazy.
    parameter_cubes, parameter_dims, parameter_to_index, parameter_time = getParameterCubes(selected_models, forcing)
    incubes = (incubes..., parameter_cubes...)
    indims = (indims..., parameter_dims...)
    # information for running model
    run_helpers = prepTEM(forcing, info);
    _num_type = Val{info.helpers.numbers.num_type}()
    _forcing_data_info = getForcingDataInfo(info, forcing.variables)
    # every location starts from this land, so the land keeps one type in all models
    loc_land = getLandTemplate(selected_models, forcing, info, run_helpers.tem_info, run_helpers.loc_land, _forcing_data_info)
    checkOutputLayers(info.output.variables, info.output.depth_info, loc_land)
    #output = XOutput.(getproperty.(run_helpers.output_dims, :axisdesc))
    output = run_helpers.output_dims
    # the template land has every pool
    restart = getRestartDimsArrays(info, forcing.helpers, loc_land)
    restart_vars = restart.variables
    restart_output = getRestartOutDims(info, restart.dims_pairs)
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
    outcubes = xmap(TEMLazyForGrid,
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
    dropped_cubes = Any[dropPaddedDims(o_cube, padded) for (o_cube, padded) ∈ zip(outcubes, padded_names)]
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

### runSpinupSequences
```@docs
runSpinupSequences
```

:::details Code

```julia
function runSpinupSequences end

runSpinupSequences(::Tuple{}, selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart=nothing) = land

function runSpinupSequences(spin_seqs::Tuple, selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart=nothing)
    spin_seq = first(spin_seqs)
    n_repeat = spin_seq.n_repeat
    sel_forcing = sequenceForcing(spinup_forcings, spin_seq)
    spinup_models = getSpinupModels(selected_models, spin_seq.model_indices)
    land = spinupSequence(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, spin_seq.n_timesteps, n_repeat, spin_seq.spinup_mode)
    spin_seq.save_restart && setRestart!(loc_restart, land, tem_info)
    return runSpinupSequences(Base.tail(spin_seqs), selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart)
end

function runSpinupSequences(spin_seqs::Tuple, selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart=nothing)
    spin_seq = first(spin_seqs)
    n_repeat = spin_seq.n_repeat
    sel_forcing = sequenceForcing(spinup_forcings, spin_seq)
    spinup_models = getSpinupModels(selected_models, spin_seq.model_indices)
    land = spinupSequence(spinup_models, sel_forcing, loc_forcing_t, land, tem_info, spin_seq.n_timesteps, n_repeat, spin_seq.spinup_mode)
    spin_seq.save_restart && setRestart!(loc_restart, land, tem_info)
    return runSpinupSequences(Base.tail(spin_seqs), selected_models, spinup_forcings, loc_forcing_t, land, tem_info, loc_restart)
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
function runTEMOne(selected_models, loc_forcing, land_init, tem, spinup_sequence)
    loc_forcing_t = getForcingForTimeStep(loc_forcing, loc_forcing, 1, tem.vals.forcing_types)
    loc_land = buildFullLand(selected_models, loc_forcing_t, land_init, tem.model_helpers)
    loc_land = addSpinupStore(loc_land, spinup_sequence, tem.run.store_spinup)
    checkSpinupInput(loc_land, loc_forcing_t, spinup_sequence)
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
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    return run_helpers.output_array
end

function runTEM!(selected_models, forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(selected_models, forcing, info)
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    return run_helpers.output_array
end

function runTEM!(forcing::NamedTuple, info::NamedTuple)
    run_helpers = prepTEM(forcing, info)
    runTEM!(run_helpers.space_selected_models, run_helpers.space_forcing, run_helpers.space_spinup, run_helpers.loc_forcing_t, run_helpers.space_output, run_helpers.space_land, run_helpers.tem_info)
    return run_helpers.output_array
end

function runTEM!(space_selected_models, space_forcing, space_spinup, loc_forcing_t, space_output, space_land, tem_info::NamedTuple; show_progress=false)
    # one `nothing` per location, so no pools are stored for the restart file
    no_restart = Fill(nothing, length(space_forcing))
    return runTEM!(space_selected_models, space_forcing, space_spinup, loc_forcing_t, space_output, no_restart, space_land, tem_info; show_progress=show_progress)
end

function runTEM!(space_selected_models, space_forcing, space_spinup, loc_forcing_t, space_output, space_restart, space_land, tem_info::NamedTuple; show_progress=false)
    parallelizeTEM!(space_selected_models, space_forcing, space_spinup, loc_forcing_t, space_output, space_restart, space_land, tem_info, tem_info.run.parallelization; show_progress=show_progress)
    return nothing
end
```

:::


----

### runTEMLazy
```@docs
runTEMLazy
```

:::details Code

```julia
function runTEMLazy(xmap_cubes, store_path; max_cache=5e8, loop_ranges=nothing, run_filter=nothing, variable_properties=nothing, global_properties=Dict{String,Any}(), save_kwargs=(;), parallelization=ThreadsParallelization())
    dataset = xmap_cubes.dataset
    if !isnothing(variable_properties)
        cubes = Any[addPropsToCube(cube, get(variable_properties, name, nothing)) for (name, cube) ∈ dataset.cubes]
        dataset = datasetFromCubes(collect(keys(dataset.cubes)), cubes)
    end
    computed = runXmap(dataset, store_path, xmap_cubes.padded_names; max_cache=max_cache, loop_ranges=loop_ranges, run_filter=run_filter, properties=global_properties, save_kwargs=save_kwargs, parallelization=parallelization)
    output_ds = datasetFromCubes(xmap_cubes.output_names, Any[computed.cubes[name] for name ∈ xmap_cubes.output_names])
    restart_ds = datasetFromCubes(xmap_cubes.restart_names, Any[computed.cubes[key] for key ∈ xmap_cubes.restart_keys])
    return (; output=output_ds, restart=restart_ds)
end
```

:::


----

### setOutputForTimeStep!
```@docs
setOutputForTimeStep!
```

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
function spinupTEMLazy end

function spinupTEMLazy(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM, store_restart=nothing)
    loc_spinup = getLocSpinup(loc_forcing, tem_info)
    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    return land_spin
end

function spinupTEMLazy(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM, store_restart=nothing)
    loc_spinup = getLocSpinup(loc_forcing, tem_info)
    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    return land_spin
end

function spinupTEMLazy(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoNotSpinupTEM, store_restart=nothing)
    setRestart!(store_restart, land_prec, tem_info)
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
function spinupTEMLazy end

function spinupTEMLazy(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM, store_restart=nothing)
    loc_spinup = getLocSpinup(loc_forcing, tem_info)
    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    return land_spin
end

function spinupTEMLazy(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoSpinupTEM, store_restart=nothing)
    loc_spinup = getLocSpinup(loc_forcing, tem_info)
    land_spin = spinupTEM(selected_models, loc_spinup, loc_forcing_t, land_prec, tem_info, tem_info.run.spinup_TEM, store_restart)
    return land_spin
end

function spinupTEMLazy(selected_models, loc_forcing, loc_forcing_t, land_prec, tem_info, ::DoNotSpinupTEM, store_restart=nothing)
    setRestart!(store_restart, land_prec, tem_info)
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

function timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, ::DoNotStoreSpinup)
    return timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps)
end

function timeLoopTEMSpinup(spinup_models, spinup_forcing, loc_forcing_t, land, tem_info, n_timesteps, store_spinup_mode::DoStoreSpinup)
    for ts ∈ 1:n_timesteps
        f_ts = getForcingForTimeStep(spinup_forcing, loc_forcing_t, ts, tem_info.vals.forcing_types)
        land = computeTEM(spinup_models, f_ts, land, tem_info.model_helpers)
        storeSpinupStep!(land, store_spinup_mode)
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
