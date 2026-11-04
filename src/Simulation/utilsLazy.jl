export getYaxMaxCache
export getLoopRanges
export dropVariablesFromStore

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
    fillCubeWithNaN(cube)

Returns `cube` with NaN as its `_FillValue`, which `savedataset` writes as the fill
value of the zarr array, or `cube` itself when it is not a float array or already has
a fill or missing value.

# Notes:
- The fill value is what a chunk that was never written reads as. With NaN, the
  output of a skipped block is the same as that of an invalid grid.
"""
function fillCubeWithNaN(cube)
    T = Base.nonmissingtype(eltype(cube))
    T <: AbstractFloat || return cube
    any(k -> haskey(cube.properties, k), ("_FillValue", "missing_value")) && return cube
    properties = merge(Dict{String,Any}(cube.properties), Dict{String,Any}("_FillValue" => T(NaN)))
    return YAXArray(DD.dims(cube), cube.data, properties)
end

"""
    MAX_CHUNK_BYTES

The largest chunk of an output array of a lazy run, 1 GiB, half the largest buffer
that the Blosc compressor of zarr can take.
"""
const MAX_CHUNK_BYTES = 2^30

"""
    getCappedChunks(chunks, element_size; max_bytes=MAX_CHUNK_BYTES)

Returns `chunks`, a Tuple of the chunks of each dimension, split until no chunk has
more than `max_bytes` of elements of `element_size` bytes.

# Notes:
- A dimension that is one chunk, e.g., time, is split first, into chunks of near equal
  length. The blocks of the run already split the others, and each of their chunks
  is then split in the same way, so a block still writes whole chunks.
"""
function getCappedChunks(chunks, element_size; max_bytes=MAX_CHUNK_BYTES)
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
    addPropsToCube(cube, properties)

Returns `cube` with `properties` merged into its attributes, keeping its data, or
`cube` itself when `properties` is `nothing`.
"""
addPropsToCube(cube, ::Nothing) = cube
addPropsToCube(cube, properties) = YAXArray(DD.dims(cube), cube.data, merge(Dict{String,Any}(cube.properties), properties))

"""
    dropVariablesFromStore(store_path, names)

Deletes the variables `names` from the zarr store at `store_path`.

# Notes:
- A zarr store keeps the values of each dimension, e.g., `lat` or `d_cEco`, as an
  array of its own. A dimension that no variable uses after the deletion is deleted
  too, so the store has no leftover dimensions.
- A lazy run uses it to delete the restart variables from `all_variables.zarr` once
  they are saved to the restart file.
"""
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

"""
    getYaxMaxCache(info, in_cubes, out_cubes=(); n_forcing=length(in_cubes),
        grids_per_thread=4, memory_fraction=0.66)
    getYaxMaxCache(info, xmap_cubes)

Returns the cache size of a cube run, `compute_to_zarr` or `mapCube`, from the
`yax_max_cache` setting. A number in the setting is used as it is, and with `null`
the cache is computed.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an
  experiment
- `in_cubes`: the input cubes of the run, starting with the forcing
- `out_cubes`: the output cubes of the run, empty when they are not built yet
- `xmap_cubes`: the `xmap` field returned by `prepTEMLazy`, which holds both
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
  holds its own block, see `getCacheMemoryLimit`.
"""
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

getYaxMaxCache(info, xmap_cubes::NamedTuple; kwargs...) = getYaxMaxCache(info, xmap_cubes.in_cubes, values(xmap_cubes.dataset.cubes); n_forcing=xmap_cubes.n_forcing, kwargs...)

"""
    getCacheMemoryLimit(bytes_per_grid, parallelization=ThreadsParallelization();
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
function getCacheMemoryLimit(bytes_per_grid, parallelization=ThreadsParallelization(); memory_fraction=0.66)
    available_memory = Sys.free_memory()
    n_threads = getThreadsPerBlock(parallelization)
    n_procs = getProcsPerBlock(parallelization)
    n_buffers = n_procs == 1 ? 2 : 2 * n_procs + 1
    memory_limit = (memory_fraction * available_memory - n_procs * n_threads * bytes_per_grid) / n_buffers
    memory_limit > bytes_per_grid || error("$(round(Int, 100 * memory_fraction))% of the $(round(available_memory / 1e9; digits=2)) GB of available memory is too small to run $(n_procs) x $(n_threads) threads at $(round(bytes_per_grid / 1e6; digits=2)) MB per grid. Use fewer threads or more memory.")
    return memory_limit, available_memory
end

"""
    getThreadsPerBlock(parallelization)

Returns the number of threads that run one block of a cube run: those of this session,
or those of the first worker with `PmapParallelization`.
"""
getThreadsPerBlock(::ParallelizationPackage) = Threads.nthreads()
getThreadsPerBlock(::PmapParallelization) = DAE.Distributed.remotecall_fetch(Threads.nthreads, first(DAE.Distributed.workers()))

"""
    getProcsPerBlock(parallelization)

Returns the number of blocks of a cube run that run at once: one, or one per worker
with `PmapParallelization`.
"""
getProcsPerBlock(::ParallelizationPackage) = 1
getProcsPerBlock(::PmapParallelization) = DAE.Distributed.nworkers()

"""
    getMaxGridsPerBlock(info, bytes_per_grid)

Returns the most grids that a block of a lazy run can have: those that fit the
`yax_max_cache` setting when it is a number, or else the memory limit of
`getCacheMemoryLimit`.
"""
function getMaxGridsPerBlock(info, bytes_per_grid)
    max_cache = get(info.experiment.exe_rules, :yax_max_cache, nothing)
    isnothing(max_cache) || max_cache isa Real || error("experiment.exe_rules.yax_max_cache must be a number of bytes, or null to compute it, got `$(max_cache)`")
    cache = isnothing(max_cache) ? first(getCacheMemoryLimit(bytes_per_grid, info.helpers.run.parallelization)) : max_cache
    return max(1, floor(Int, cache / bytes_per_grid))
end

"""
    getLoopRanges(info, xmap_cubes; grids_per_thread=8)

Returns the cache, the block of grids and the run filter of a lazy run, as
`max_cache`, `loop_ranges` and `run_filter` of `runTEMLazy`.

# Arguments:
- `info`: a SINDBAD NT with all information needed for setup and execution of an
  experiment
- `xmap_cubes`: the `xmap` field returned by `prepTEMLazy`
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
    valid grids per thread and it fits the memory, see `getMaxGridsPerBlock`. With
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
    run_filter = isnothing(valid_sums) ? nothing : ValidGridsFilterYax(valid_sums, i_space)
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

"""
    getChunkStep(cubes, dim_name, time_name)

Returns the least common multiple of the chunk sizes in the dimension `dim_name` of
the stored `cubes` with time, or 1 when no such cube has it.

# Notes:
- A block that reads part of a chunk decompresses the whole chunk. That is only
  costly for a chunk with all time steps, so the cubes without time, e.g., a map of
  the vegetation type stored as one chunk, do not set the step. Nor do cubes without
  stored chunks, e.g., forcing resampled on the fly.
"""
function getChunkStep(cubes, dim_name, time_name)
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
    growBlock(steps, sizes, fits)

Returns the block that starts at one step in each dimension and grows by whole steps,
always on its shortest side that can still grow, while `fits(block)` is true. A block
of one step is returned even when it does not fit.
"""
function growBlock(steps, sizes, fits)
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
    getValidGridSums(valid_grids)

Returns the cumulative counts of the valid grids along every dimension, with a zero
before the first grid, so that `countValidGridsInBox` counts the valid grids of any
block at once. Returns `nothing` for `nothing`.
"""
getValidGridSums(::Nothing) = nothing

function getValidGridSums(valid_grids)
    sums = zeros(Int, size(valid_grids) .+ 1)
    sums[map(n -> 2:n+1, size(valid_grids))...] .= valid_grids
    for d ∈ 1:ndims(sums)
        sums = cumsum(sums; dims=d)
    end
    return sums
end

"""
    countValidGridsInBox(sums, ranges)

Returns the number of valid grids in the block of `ranges`, one range per dimension,
from the cumulative counts `sums` of `getValidGridSums`.
"""
function countValidGridsInBox(sums, ranges)
    n_dims = length(ranges)
    total = 0
    for corner ∈ CartesianIndices(ntuple(_ -> 0:1, n_dims))
        index = ntuple(d -> corner[d] == 1 ? last(ranges[d]) + 1 : first(ranges[d]), n_dims)
        total += iseven(n_dims - sum(Tuple(corner))) ? sums[index...] : -sums[index...]
    end
    return total
end

"""
    getValidCountsPerBlock(valid_sums, block, sizes)

Returns the number of valid grids in each block of size `block` that tiles a domain of
`sizes`, from the first grid on. Without valid grids, every grid counts as valid.
"""
function getValidCountsPerBlock(valid_sums, block, sizes)
    starts = map((b, n) -> 1:b:n, Tuple(block), Tuple(sizes))
    return map(Iterators.product(starts...)) do first_indices
        ranges = map((i, b, n) -> i:min(i + b - 1, n), first_indices, Tuple(block), Tuple(sizes))
        isnothing(valid_sums) ? prod(length.(ranges)) : countValidGridsInBox(valid_sums, ranges)
    end
end

"""
    getBytesPerGrid(cube, space_dims)

Returns the bytes of one grid of `cube`, or zero when it has no spatial
dimension.
"""
function getBytesPerGrid(cube, space_dims)
    cube_dims = DD.dims(cube)
    any(d -> DD.name(d) ∈ space_dims, cube_dims) || return 0
    n_values = prod((length(d) for d ∈ cube_dims if DD.name(d) ∉ space_dims); init=1)
    return n_values * sizeof(Base.nonmissingtype(eltype(cube)))
end

"""
    getValidGrids(forcing_cubes, space_dims, time_name)

Returns whether each grid has no invalid value in the forcing cubes that have every
spatial dimension and no time, as an array over `space_dims`, or `nothing` when there
is no such cube.

# Notes:
- The forcing with time is not read, since that costs as much as the run. A grid that
  is valid here can still be invalid in it, and is then left as NaN by `TEMLazy`.
"""
function getValidGrids(forcing_cubes, space_dims, time_name)
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
    getValidGridFraction(forcing_cubes, space_dims, time_name)

Returns the share of the valid grids of `getValidGrids`, or one when no forcing
marks them.
"""
function getValidGridFraction(forcing_cubes, space_dims, time_name)
    is_valid = getValidGrids(forcing_cubes, space_dims, time_name)
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
    dropPaddedDims(cube, padded_names)

Removes the singleton dimensions that were added to an output cube only because
DiskArrayEngine needs all output cubes to have the same dimensions, and those that xmap
adds for the core dimensions of the forcing that the output does not have.

# Arguments:
- `cube`: an output cube of `xmap`
- `padded_names`: the names of the singleton dimensions added to the cube. The spatial
  dimensions are never among them, even when they have a size of 1.
"""
function dropPaddedDims(cube, padded_names)
    padded = filter(d -> DD.name(d) ∈ padded_names, DD.dims(cube))
    isempty(padded) && return cube
    return cube[map(d -> DD.rebuild(d, 1), padded)...]
end
