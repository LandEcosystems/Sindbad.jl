export @add_to_elem, @pack_nt, @rep_elem, @rep_vec, @unpack_nt
export addToElem, addToEachElem, addVec
export adjust_pk
export cFlowMatrix
export edgesBetween
export getQP
export getQPEqual
export getVectorOfType
export getZix
export processPackNT, processUnpackNT
export repElem, repElems, repVec
export allocateToPools
export setComponentFromMainPool, setFlowValue, setMainFromComponentPool
export totalS
export totalS_indices
using ..SindbadTEM
import StaticArraysCore: SVector, StaticArray

"""
    @add_to_elem

Macro to add a value to an element of a vector or static vector.

# Arguments
- `outparams::Expr`: Expression in the form `value ⇒ (vector, index)`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> cOther = SVector(100.0f0, 1.0f0)
julia> @add_to_elem 1.0f0 ⇒ (cOther, 1)
julia> cOther
2-element SVector{2, Float32} with indices SOneTo(2):
 101.0f0
   1.0f0
```
"""
macro add_to_elem(outparams::Expr)
    @assert outparams.head == :call || outparams.head == :(=)
    @assert outparams.args[1] == :(⇒)
    @assert length(outparams.args) == 3
    lhs = esc(outparams.args[2])
    rhs = outparams.args[3]
    rhsa = rhs.args
    tar = esc(rhsa[1])
    indx = rhsa[2]
    outCode = [
        Expr(:(=),
            tar,
            Expr(:call,
                addToElem,
                tar,
                lhs,
                esc(indx)))
    ]
    return Expr(:block, outCode...)
end


"""
    addToElem(v::SVector, Δv, ind::Int)
    addToElem(v::AbstractVector, Δv, ind::Int)

Add a value to a specific element of a vector.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`
- `Δv`: The value to be added
- `ind::Int`: The index of the element to modify

# Returns
- The modified vector with `Δv` added to element at index `ind`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> addToElem(v, 5.0, 2)
3-element SVector{3, Float64} with indices SOneTo(3):
 1.0
 7.0
 3.0
```
"""
function addToElem end

function addToElem(v::SVector{N}, Δv, ind::Int) where {N}
    # Same NaN/Inf-safe per-element selection as repElem: pick each position
    # instead of masking v with a zero/one vector, since `0 * Inf` and `0 * NaN`
    # are themselves NaN. N is static, so this unrolls to plain scalar selects
    # with no heap allocation.
    T = eltype(v)
    return SVector{N,T}(ntuple(i -> i == ind ? convert(T, v[i] + Δv) : v[i], Val(N)))
end

function addToElem(v::AbstractVector, Δv, ind::Int)
    v[ind] = v[ind] + Δv
    return v
end

"""
    addToEachElem(v::SVector, Δv::Real)
    addToEachElem(v::AbstractVector, Δv::Real)

Add a value to each element of a vector.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`
- `Δv::Real`: The value to be added to each element

# Returns
- The modified vector with `Δv` added to all elements

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> addToEachElem(v, 5.0)
3-element SVector{3, Float64} with indices SOneTo(3):
 6.0
 7.0
 8.0
```
"""
function addToEachElem end

function addToEachElem(v::SVector, Δv::Real)
    v = v .+ Δv
    return v
end

function addToEachElem(v::AbstractVector, Δv::Real)
    v .= v .+ Δv
    return v
end



"""
    addVec(v::SVector, Δv::SVector)
    addVec(v::AbstractVector, Δv::AbstractVector)

Add one vector to another element-wise.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`
- `Δv`: A `StaticVector` or `AbstractVector` of the same length

# Returns
- The result of adding `Δv` to `v` element-wise

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> Δv = SVector(0.5, 1.0, 1.5)
julia> addVec(v, Δv)
3-element SVector{3, Float64} with indices SOneTo(3):
 1.5
 3.0
 4.5
```
"""
function addVec end

function addVec(v::SVector, Δv::SVector)
    v = v + Δv
    return v
end

function addVec(v::AbstractVector, Δv::AbstractVector)
    v .= v .+ Δv
    return v
end

"""
    getZix(dat::SubArray)
    getZix(dat::SubArray, zixhelpersPool)
    getZix(dat::Array, zixhelpersPool)
    getZix(dat::SVector, zixhelpersPool)

Return the indices of a view for a subarray or return the provided indices.

# Arguments
- `dat`: A `SubArray`, `Array`, or `SVector`
- `zixhelpersPool`: (Optional) Helper indices to return if `dat` is not a `SubArray`

# Returns
- A tuple of indices for the array view

# Examples
```jldoctest
julia> arr = [1, 2, 3, 4, 5]
julia> view_arr = view(arr, 2:4)
julia> getZix(view_arr)
(2:4,)
```
"""
function getZix end

function getZix(dat::SubArray)
    return Tuple(first(parentindices(dat)))
end

function getZix(dat::SubArray, zixhelpersPool)
    return Tuple(first(parentindices(dat)))
end

function getZix(dat::Array, zixhelpersPool)
    return zixhelpersPool
end

function getZix(dat::SVector, zixhelpersPool)
    return zixhelpersPool
end

export MutableLandNamedTuple
export mutable_land

"""
    MutableLandNamedTuple

A type-stable, mutable runtime representation of a `NamedTuple`. Field names
remain type parameters and every value is held in a typed `Ref`, so literal
property access remains inferable while time-step updates avoid rebuilding the
complete immutable land state.

This container is intentionally used only after model definition and
precomputation. Setup and consistency scanning continue to use ordinary
`NamedTuple`s.
"""
struct MutableLandNamedTuple{names,Refs<:Tuple}
    refs::Refs
end

@inline function MutableLandNamedTuple(nt::NamedTuple)
    refs = map(Ref, values(nt))
    return MutableLandNamedTuple{keys(nt),typeof(refs)}(refs)
end

@generated function _land_property_ref(
        land::MutableLandNamedTuple{names},
        ::Val{name},
    ) where {names,name}
    index = findfirst(==(name), names)
    index === nothing && return :(throw(ArgumentError("unknown land field: $name")))
    return :(getfield(getfield(land, :refs), $index))
end

@inline function Base.getproperty(land::MutableLandNamedTuple, name::Symbol)
    return _land_property_ref(land, Val(name))[]
end

@inline function Base.setproperty!(
        land::MutableLandNamedTuple,
        name::Symbol,
        value,
    )
    _land_property_ref(land, Val(name))[] = value
    return value
end

@inline Base.propertynames(::MutableLandNamedTuple{names}) where {names} = names
@inline Base.keys(::MutableLandNamedTuple{names}) where {names} = names
@inline Base.values(land::MutableLandNamedTuple{names}) where {names} =
    ntuple(i -> getfield(getfield(land, :refs), i)[], length(names))

"""
    mutable_land(land::NamedTuple)

Convert the top-level land tuple and each of its first-level NamedTuple
containers to a mutable, type-stable runtime representation. Values below the
first level (including static arrays and metadata NamedTuples) are preserved.
"""
@inline _mutable_land_subfield(value::NamedTuple) = MutableLandNamedTuple(value)
@inline _mutable_land_subfield(value) = value

function mutable_land(land::NamedTuple)
    runtime_values = map(_mutable_land_subfield, values(land))
    runtime_refs = map(Ref, runtime_values)
    return MutableLandNamedTuple{keys(land),typeof(runtime_refs)}(runtime_refs)
end

@inline function _pack_land_fields(
        target::NamedTuple,
        ::Val{names},
        packed_values::Tuple,
    ) where {names}
    return merge(target, NamedTuple{names}(packed_values))
end

@generated function _pack_land_fields(
        target::MutableLandNamedTuple{target_names},
        ::Val{names},
        packed_values::Tuple,
    ) where {target_names,names}
    assignments = Expr[]
    for (value_index, name) in enumerate(names)
        target_index = findfirst(==(name), target_names)
        target_index === nothing &&
            error("cannot pack unknown mutable land field: $name")
        push!(
            assignments,
            :(
                getfield(getfield(target, :refs), $target_index)[] =
                    getfield(packed_values, $value_index)
            ),
        )
    end
    return Expr(:block, assignments..., :(target))
end

@inline function _pack_nested_land_fields(
        land::NamedTuple,
        ::Val{field},
        names::Val,
        packed_values::Tuple,
    ) where {field}
    updated = _pack_land_fields(getproperty(land, field), names, packed_values)
    return merge(land, NamedTuple{(field,)}((updated,)))
end

@generated function _pack_nested_land_fields(
        land::MutableLandNamedTuple{land_names},
        ::Val{field},
        names::Val,
        packed_values::Tuple,
    ) where {land_names,field}
    field_index = findfirst(==(field), land_names)
    field_index === nothing && error("cannot pack unknown land container: $field")
    return quote
        target = getfield(getfield(land, :refs), $field_index)[]
        _pack_land_fields(target, names, packed_values)
        land
    end
end

"""
    getVectorOfType(source_vector, output_length)
    getVectorOfType(source_vector, output_length, fill_value)
    getVectorOfType(source_vector::StaticArray, output_length, fill_value)

Return a vector of `output_length` elements shaped like `source_vector`: its element
type and its container kind, filled with `fill_value(eltype(source_vector))`.
`output_length` need not match `length(source_vector)`: at carbon-cycle call sites,
`source_vector` is typically `cEco` (one entry per pool) while the result has one
entry per carbon flow.

# Arguments
- `source_vector`: the vector whose element type and container kind to copy
- `output_length`: length of the returned vector
- `fill_value`: `zero` or `one`, the function rather than a number. Defaults to `zero`

# Returns
- A vector of `output_length` elements, static when `source_vector` is static

# Examples
```jldoctest
julia> getVectorOfType([1.0, 2.0, 3.0], 2)
2-element Vector{Float64}:
 0.0
 0.0

julia> getVectorOfType([1.0, 2.0, 3.0], 2, one)
2-element Vector{Float64}:
 1.0
 1.0
```
"""
function getVectorOfType end

function getVectorOfType(source_vector, output_length)
    return getVectorOfType(source_vector, output_length, zero)
end

function getVectorOfType(source_vector, output_length, fill_value)
    return fill(fill_value(eltype(source_vector)), output_length)
end

function getVectorOfType(source_vector::StaticArray, output_length, fill_value)
    return SVector{output_length}(fill(fill_value(eltype(source_vector)), output_length))
end

function getQPEqual(c_flow_QP_vec, c_flow_order, c_giver, c_taker, zix_of_source)
    for fO ∈ c_flow_order
        c_taker[fO] ∈ zix_of_source && continue
        give_r = c_giver[fO]
        take_r = c_taker[fO]

        n_out = oftype(c_flow_QP_vec[fO],
            count(
                fO_i -> c_giver[fO_i] == give_r && !(c_taker[fO_i] ∈ zix_of_source),
                c_flow_order,
            )
        )
        frac_out = safe_divide(one(n_out), n_out)
        c_flow_QP_vec = repElem(c_flow_QP_vec, frac_out, fO)
    end
    return c_flow_QP_vec
end

function getQPperFlow(turnoverRank, slowPart)
    QP =
        (one(turnoverRank) - abs(turnoverRank)) +
        at_least_zero(turnoverRank) * (one(slowPart) - slowPart) +
        at_least_zero(-turnoverRank) * slowPart
    return QP
end

function getQP(c_flow_QP_vec, c_flow_order, c_giver, c_taker, zix_of_source, 
    c_flow_taker_turnover_rank, slowPart)
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_of_source || continue
        turnoverRank = c_flow_taker_turnover_rank[fO]
        QP = getQPperFlow(turnoverRank, slowPart)
        c_flow_QP_vec = repElem(c_flow_QP_vec, QP, fO)
    end
    return c_flow_QP_vec
end

function getQP(c_flow_QP_vec, c_flow_order, c_giver, c_taker, zix_of_source, 
    c_flow_taker_turnover_rank, slowPartLoK, slowPartHiK, k_hilo_lit_split, c_eco_k_base)
    for fO ∈ c_flow_order
        c_giver[fO] ∈ zix_of_source || continue
        slowPart = c_eco_k_base[c_giver[fO]] < k_hilo_lit_split ? slowPartLoK : slowPartHiK
        turnoverRank = c_flow_taker_turnover_rank[fO]
        QP = getQPperFlow(turnoverRank, slowPart)
        c_flow_QP_vec = repElem(c_flow_QP_vec, QP, fO)
    end

    return c_flow_QP_vec
end

"""
    cFlowMatrix(c_giver, c_taker, n_pools)
    cFlowMatrix(approach, pool_names)

Return the carbon flow topology as a square matrix of flow indices, with
`matrix[taker, giver]` holding the position of that flow in the flow vector and `0`
where the two pools are not connected.

# Arguments
- `c_giver`: the giver index of each flow, in flow-vector order
- `c_taker`: the taker index of each flow, in flow-vector order
- `n_pools`: the number of carbon pools, which is the size of the square matrix
- `approach`: a `cCycleBase` approach, as a type or an instance, whose `cFlowEdges`
  declare the topology
- `pool_names`: the leaf pool names in `cEco` index order, which is
  `helpers.pools.components.cEco` at runtime

# Returns
- A `Matrix{Int}` of size `n_pools` by `n_pools`

# Examples
```jldoctest
julia> cFlowMatrix((1, 1, 2), (2, 3, 3), 3)
3×3 Matrix{Int64}:
 0  0  0
 1  0  0
 2  3  0
```

# Notes:
- Row is the taker, column is the giver, matching every dense flow array in the
  models (`c_flow_A_array`, `c_flow_ME_array`).
- The two methods produce the same matrix. The three-argument form takes indices
  the base already resolved; the two-argument form resolves an approach's
  declared edges directly, repeating `cFlowStructure`'s `(giver, taker)` sort so
  flow `k` here is the flow `k` the model packs.
- `pool_names` is passed in rather than derived from `poolStructure`, since that
  flattening (`getPoolInformation`) lives in `Sindbad.Setup`, which depends on
  `SindbadTEM` rather than the other way round.
"""
function cFlowMatrix end

function cFlowMatrix(c_giver, c_taker, n_pools)
    flow_matrix = zeros(Int, n_pools, n_pools)
    for flow ∈ eachindex(c_giver, c_taker)
        flow_matrix[c_taker[flow], c_giver[flow]] = flow
    end
    return flow_matrix
end

function cFlowMatrix(approach, pool_names)
    approach_name = nameof(approach isa Type ? approach : typeof(approach))
    edges = cFlowEdges(approach)
    if isempty(edges)
        error("$(approach_name) declares no carbon flow edges, so it has no flow " *
              "matrix. Use an approach that declares `cFlowEdges`.")
    end
    givers = [cFlowNamePosition(approach_name, pool_names, first(edge), edge) for edge ∈ edges]
    takers = [cFlowNamePosition(approach_name, pool_names, last(edge), edge) for edge ∈ edges]
    flows = collect(zip(givers, takers))
    if length(unique(flows)) < length(flows)
        repeated = unique([edges[i] for i ∈ findall(flow -> count(==(flow), flows) > 1, flows)])
        error("$(approach_name) declares the carbon flow edge(s) $(repeated) more than " *
              "once. Each giver to taker link carries one flow, so list it once.")
    end
    order = sortperm(flows)
    return cFlowMatrix(givers[order], takers[order], length(pool_names))
end

"""
    cFlowNamePosition(approach_name, pool_names, pool_name, edge)

Resolve one end of a flow edge to the single position it holds in `pool_names`,
erroring with the offending name when it is absent or repeated.

Mirrors `cFlowEdgeIndex`, which does the same against `helpers.pools.zix` at run time.
A name spanning more than one position is a group, an alias, or a multi-layer pool, and
an edge naming one would expand into a cross product of links rather than the single
link it reads as.
"""
function cFlowNamePosition(approach_name, pool_names, pool_name, edge)
    positions = findall(==(pool_name), collect(pool_names))
    if isempty(positions)
        error("$(approach_name) declares the carbon flow edge `$(edge)`, but this pool " *
              "structure has no `$(pool_name)`. Known pools: " *
              "$(join(String.(pool_names), ", ")).")
    end
    if length(positions) > 1
        error("$(approach_name) declares the carbon flow edge `$(edge)`, but " *
              "`$(pool_name)` spans $(length(positions)) pools ($(positions)). Flow " *
              "edges must name leaf pools, not groups or aliases, because a group " *
              "would expand into a cross product of links.")
    end
    return only(positions)
end

"""
    edgesBetween(c_giver, c_taker, giver_zix, taker_zix)

Every flow-vector position whose giver is in `giver_zix` and whose taker is in
`taker_zix`, by pool-index membership rather than by matching a literal
`<giver>_to_<taker>` name. This lets a caller work against more than one pool
structure without naming either config's specific pools: e.g. leaf shedding
lands in one pool under `GSI` (`cLitFast`) and two under `CASA`
(`cLitLeafFast`, `cLitLeafSlow`).

An empty `giver_zix` or `taker_zix`, e.g. `CASA`'s absent `cVegReserve`,
returns no edges rather than erroring.
"""
function edgesBetween(c_giver, c_taker, giver_zix, taker_zix)
    # Lazy generator, not Tuple(...): every call site iterates the result once,
    # in the hot per-timestep carbon-flow path, and materializing it would
    # require a heap-allocated Vector first.
    return (flow for flow ∈ eachindex(c_giver, c_taker)
                 if c_giver[flow] ∈ giver_zix && c_taker[flow] ∈ taker_zix)
end

"""
    setFlowValue(flow_vec, c_giver, c_taker, giver_zix, taker_zix, value)

Write `value` into every flow-vector position whose giver is in `giver_zix` and
whose taker is in `taker_zix` (via `edgesBetween`), and return the vector unchanged
when no flow matches -- e.g. a pool structure that lacks either group entirely.

`setMEFlow` is this function under the name `cMicrobialEfficiency` reads it in as.
`cQualityPartition` goes through neither this nor named edges: its groups are
resolved to flow-vector positions once, in `cCycleBase`'s `deriveQPGroups`, and its
approaches write directly at those positions.
"""
function setFlowValue(flow_vec, c_giver, c_taker, giver_zix, taker_zix, value)
    for flow ∈ edgesBetween(c_giver, c_taker, giver_zix, taker_zix)
        flow_vec = repElem(flow_vec, value, flow)
    end
    return flow_vec
end

"""
    allocateToPools(v, group_zix, group_n, group_vals)

Spread each group's total value evenly across the pool indices in that group, writing
`group_vals[g] / group_n[g]` into every index in `group_zix[g]`, for every group `g`.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`, e.g. a pool's carbon allocation vector
- `group_zix`: A tuple of pool-index tuples, one per group, e.g. `cVeg_zix`
- `group_n`: The number of pool indices per group, matching `group_zix`, e.g. `cVeg_nzix`
- `group_vals`: An indexable collection of the total value to distribute per group (its
  own length may exceed the number of groups, e.g. a pool-shaped `SVector` of which only
  the first few positions hold real per-group values), e.g. `c_allocation_to_veg`

# Returns
- `v` with every group's share written into its pool indices

# Notes
- `group_zix` is a heterogeneous tuple of differently-sized tuples (groups need
  not all have the same number of pool indices), so it is recursed on via
  `first`/`Base.tail` rather than iterated with `eachindex`, which would make
  each element a non-concrete `Union` and allocate on every call.
- `group_vals` is read by position (`group_vals[group_index]`) rather than
  recursed on the same way, since callers pass it as-is (e.g.
  `c_allocation_to_veg`) without converting it to a tuple first.
"""
function allocateToPools(v, group_zix::Tuple, group_n::Tuple, group_vals)
    return allocateToPools(v, group_zix, group_n, group_vals, 1)
end

function allocateToPools(v, ::Tuple{}, ::Tuple{}, group_vals, group_index)
    return v
end

function allocateToPools(v, group_zix::Tuple, group_n::Tuple, group_vals, group_index)
    group_val = group_vals[group_index] / first(group_n)
    for ix ∈ first(group_zix)
        v = repElem(v, group_val, ix)
    end
    return allocateToPools(v, Base.tail(group_zix), Base.tail(group_n), group_vals, group_index + 1)
end

"""
    @pack_nt

Macro to pack variables into a named tuple.

# Arguments
- `outparams`: Expression or block of expressions in the form `(vars...) ⇒ target` or `var ⇒ target`

# Examples
```jldoctest
julia> land = (; diagnostics = (; a = 1, b = 2), fluxes = (; c = 3, d = 4))
julia> a, b = 10, 20
julia> @pack_nt (a, b) ⇒ land.diagnostics
julia> land.diagnostics
(a = 10, b = 20)
```
"""
macro pack_nt(outparams)
    @assert outparams.head == :block || outparams.head == :call || outparams.head == :(=)
    if outparams.head == :block
        outputs = processPackNT.(filter(i -> isa(i, Expr), outparams.args))
        outCode = Expr(:block, outputs...)
    else
        outCode = processPackNT(outparams)
    end
    return outCode
end

"""
    processPackNT(ex)

Internal helper function to process pack named tuple expressions.

# Arguments
- `ex`: An expression to process

# Returns
- A processed expression for packing into a named tuple

# Notes
- This is an internal function used by the `@pack_nt` macro
"""
function processPackNT(ex)
    rename, ex = if ex.head == :(=)
        ex.args[1], ex.args[2]
    else
        nothing, ex
    end
    @assert ex.head == :call
    @assert ex.args[1] == :(⇒)
    @assert length(ex.args) == 3
    lhs = ex.args[2]
    rhs = ex.args[3]
    if lhs isa Symbol
        lhs = [lhs]
    elseif lhs.head == :tuple
        lhs = lhs.args
    else
        error("processPackNT: could not pack:" * lhs * "=" * rhs)
    end
    if rename === nothing
        rename = lhs
    elseif rename isa Symbol
        rename = [rename]
    elseif rename isa Expr && rename.head == :tuple
        rename = rename.args
    end
    field_names = Tuple(lhs)
    field_names_val = Expr(:call, Expr(:curly, :Val, QuoteNode(field_names)))
    packed_values = Expr(:tuple, map(esc, rename)...)

    depth_field = length(findall(".", string(esc(rhs)))) + 1
    if depth_field == 1
        return Expr(
            :(=),
            esc(rhs),
            Expr(
                :call,
                :_pack_land_fields,
                esc(rhs),
                field_names_val,
                packed_values,
            ),
        )
    elseif depth_field == 2
        top = Symbol(split(string(rhs), '.')[1])
        field = Symbol(split(string(rhs), '.')[2])
        return Expr(
            :(=),
            esc(top),
            Expr(
                :call,
                :_pack_nested_land_fields,
                esc(top),
                Expr(:call, Expr(:curly, :Val, QuoteNode(field))),
                field_names_val,
                packed_values,
            ),
        )
    end
    error("processPackNT supports at most one nested NamedTuple field: $rhs")
end

"""
    processUnpackNT(ex)

Internal helper function to process unpack named tuple expressions.

# Arguments
- `ex`: An expression to process

# Returns
- A processed expression for unpacking from a named tuple

# Notes
- This is an internal function used by the `@unpack_nt` macro
"""
function processUnpackNT(ex)
    rename, ex = if ex.head == :(=)
        ex.args[1], ex.args[2]
    else
        nothing, ex
    end
    @assert ex.head == :call
    @assert ex.args[1] == :(⇐)
    @assert length(ex.args) == 3
    lhs = ex.args[2]
    rhs = ex.args[3]
    if lhs isa Symbol
        lhs = [lhs]
    elseif lhs.head == :tuple
        lhs = lhs.args
    else
        error("processUnpackNT: could not unpack:" * lhs * "=" * rhs)
    end
    if rename === nothing
        rename = lhs
    elseif rename isa Expr && rename.head == :tuple
        rename = rename.args
    end
    lines = broadcast(lhs, rename) do s, rn
        return Expr(:(=), esc(rn), Expr(:(.), esc(rhs), QuoteNode(s)))
    end
    return Expr(:block, lines...)
end


"""
    @rep_elem

Macro to replace an element of a vector or static vector.

# Arguments
- `outparams::Expr`: Expression in the form `value ⇒ (vector, index)`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> cOther = SVector(100.0f0, 1.0f0)
julia> @rep_elem 50.0f0 ⇒ (cOther, 1)
julia> cOther
2-element SVector{2, Float32} with indices SOneTo(2):
  50.0f0
   1.0f0
```
"""
macro rep_elem(outparams::Expr)
    @assert outparams.head == :call || outparams.head == :(=)
    @assert outparams.args[1] == :(⇒)
    @assert length(outparams.args) == 3
    lhs = esc(outparams.args[2])
    rhs = outparams.args[3]
    rhsa = rhs.args
    tar = esc(rhsa[1])
    indx = rhsa[2]
    outCode = [
        Expr(:(=),
            tar,
            Expr(:call,
                repElem,
                tar,
                lhs,
                esc(indx)))
    ]
    return Expr(:block, outCode...)
end

"""
    repElem(v::AbstractVector, v_elem, ind::Int)
    repElem(v::SVector, v_elem, ind::Int)

Replace an element of a vector with a new value.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`
- `v_elem`: The new value to assign
- `ind::Int`: The index of the element to replace

# Returns
- The modified vector with element at index `ind` replaced by `v_elem`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> repElem(v, 5.0, 2)
3-element SVector{3, Float64} with indices SOneTo(3):
 1.0
 5.0
 3.0
```
"""
function repElem end

function repElem(v::AbstractVector, v_elem, ind::Int)
    v[ind] = v_elem
    return v
end

@inline function repElem(v::SVector{N,T}, v_elem, ind::Int) where {N,T}
    # The element is converted to the element type of the container (the land field type). The
    # result is stored back into the land with this type in any case, and keeping it here avoids
    # promoting e.g. a Float32 SVector to Float64 on the first replacement, which makes the
    # container type unstable in the loops of the models and allocates in the daily model loop.
    # Written as a tuple `setindex` (rather than a zero/one mask multiplied into v) because that
    # arithmetic is not exact when v holds NaN or Inf: `0 * Inf` and `0 * NaN` are themselves NaN.
    return SVector{N,T}(Base.setindex(Tuple(v), convert(T, v_elem), ind))
end

"""
    repElems(f, v)

Replace every element `i` of `v` with `f(i)`.

For an `SVector` the new vector is built in one unrolled pass (converted to the element type of `v`), instead of rebuilding the whole vector once per element as repeated `@rep_elem` calls in a loop do. For other vectors, the elements are replaced in place.

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> repElems(i -> 2.0 * i, SVector(0.0, 0.0, 0.0))
3-element SVector{3, Float64} with indices SOneTo(3):
 2.0
 4.0
 6.0
```
"""
function repElems end

@inline function repElems(f::F, v::SVector{N,T}) where {F,N,T}
    return SVector{N,T}(ntuple(i -> convert(T, f(i)), Val(N)))
end

function repElems(f::F, v::AbstractVector) where {F}
    for i ∈ eachindex(v)
        v[i] = f(i)
    end
    return v
end

"""
    @rep_vec

Macro to replace a vector or static vector with a new value.

# Arguments
- `outparams::Expr`: Expression in the form `vector ⇒ new_value`

# Examples
```jldoctest
julia> _vec = [100.0f0, 2.0f0]
julia> @rep_vec _vec ⇒ 1.0f0
julia> _vec
2-element Vector{Float32}:
 1.0f0
 1.0f0
```
"""
macro rep_vec(outparams::Expr)
    @assert outparams.head == :call || outparams.head == :(=)
    @assert outparams.args[1] == :(⇒)
    @assert length(outparams.args) == 3
    lhs = esc(outparams.args[2])
    rhs = esc(outparams.args[3])
    outCode = [Expr(:(=), lhs, Expr(:call, repVec, lhs, rhs))]
    return Expr(:block, outCode...)
end

"""
    repVec(v::AbstractVector, v_new)
    repVec(v::SVector, v_new)

Replace the values of a vector with a new value or vector.

# Arguments
- `v`: An `AbstractVector` or `StaticVector`
- `v_new`: A new value or vector to replace the old values

# Returns
- The modified vector with values replaced

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> repVec(v, 5.0)
3-element SVector{3, Float64} with indices SOneTo(3):
 5.0
 5.0
 5.0
```
"""
function repVec end

function repVec(v::AbstractVector, v_new)
    v .= v_new
    return v
end

function repVec(v::SVector, v_new)
    # `zero(v)` depends only on v's type, not its runtime values, so this is exact
    # even when v holds NaN or Inf -- unlike the `v .* zero(...)` mask this replaced,
    # where `0 * Inf` and `0 * NaN` are themselves NaN. `v_new` is broadcast in via
    # `.+`, matching both a scalar and a same-size vector.
    return zero(v) .+ v_new
end

"""
    setComponentFromMainPool(land, helpers, Val{s_main}, Val{s_comps}, Val{zix})

Set component pool values using values from the main pool.

# Arguments
- `land`: A core SINDBAD NamedTuple containing all variables for a given time step
- `helpers`: Helper NamedTuple with necessary objects for model run and type consistencies
- `::Val{s_main}`: A NamedTuple with names of the main pools
- `::Val{s_comps}`: A NamedTuple with names of the component pools
- `::Val{zix}`: A NamedTuple with zix (indices) of each pool

# Returns
- Generated code expression to set component pools from main pool

# Notes
- Names are generated using components in helpers so model formulations are not specific for pool names
- This is a generated function that creates code at compile time
"""
@generated function setComponentFromMainPool(
    land,
    helpers,
    ::Val{s_main},
    ::Val{s_comps},
    ::Val{zix}) where {s_main, s_comps, zix}
    gen_output = quote end
    push!(gen_output.args, Expr(:(=), s_main, Expr(:., :(land.pools), QuoteNode(s_main))))
    foreach(s_comps) do s_comp
        push!(gen_output.args, Expr(:(=), s_comp, Expr(:., :(land.pools), QuoteNode(s_comp))))
        zix_pool = getfield(zix, s_comp)
        c_ix = 1
        foreach(zix_pool) do ix
            push!(gen_output.args, Expr(:(=),
                s_comp,
                Expr(:call,
                    repElem,
                    s_comp,
                    Expr(:ref, s_main, ix),
                    c_ix)))

            c_ix += 1
        end
        # Use the shared packing path so this works for both the setup-time
        # immutable NamedTuple and the inline-update MutableLandNamedTuple.
        push!(gen_output.args, Expr(:(=),
            :land,
            Expr(:call,
                _pack_nested_land_fields,
                :land,
                Expr(:call, Val, QuoteNode(:pools)),
                Expr(:call, Val, QuoteNode((s_comp,))),
                Expr(:tuple, s_comp))))
    end
    return gen_output
end

"""
    setMainFromComponentPool(land, helpers, Val{s_main}, Val{s_comps}, Val{zix})

Set main pool values from component pool values.

# Arguments
- `land`: A core SINDBAD NamedTuple containing all variables for a given time step
- `helpers`: Helper NamedTuple with necessary objects for model run and type consistencies
- `::Val{s_main}`: A NamedTuple with names of the main pools
- `::Val{s_comps}`: A NamedTuple with names of the component pools
- `::Val{zix}`: A NamedTuple with zix (indices) of each pool

# Returns
- Generated code expression to set main pool from component pools

# Notes
- Names are generated using components in helpers so model formulations are not specific for pool names
- This is a generated function that creates code at compile time
"""
@generated function setMainFromComponentPool(
    land,
    helpers,
    ::Val{s_main},
    ::Val{s_comps},
    ::Val{zix}) where {s_main, s_comps, zix}
    gen_output = quote end
    push!(gen_output.args, Expr(:(=), s_main, Expr(:., :(land.pools), QuoteNode(s_main))))
    foreach(s_comps) do s_comp
        push!(gen_output.args, Expr(:(=), s_comp, Expr(:., :(land.pools), QuoteNode(s_comp))))
        zix_pool = getfield(zix, s_comp)
        c_ix = 1
        foreach(zix_pool) do ix
            push!(gen_output.args, Expr(:(=),
                s_main,
                Expr(:call,
                    repElem,
                    s_main,
                    Expr(:ref, s_comp, c_ix),
                    ix)))
            c_ix += 1
        end
    end
    # Keep the immutable and inline-update land representations on the same
    # packing API; splatting MutableLandNamedTuple is intentionally unsupported.
    push!(gen_output.args, Expr(:(=),
        :land,
        Expr(:call,
            _pack_nested_land_fields,
            :land,
            Expr(:call, Val, QuoteNode(:pools)),
            Expr(:call, Val, QuoteNode((s_main,))),
            Expr(:tuple, s_main))))
    return gen_output
end

"""
    totalS(s, sΔ)
    totalS(s)

Return the total storage amount given storage and delta storage without creating temporary arrays.

# Arguments
- `s`: Storage array
- `sΔ`: (Optional) Delta storage array

# Returns
- Total storage amount (sum of `s` and `sΔ` if provided, or just `s`)

# Examples
```jldoctest
julia> s = [1.0, 2.0, 3.0]
julia> sΔ = [0.1, 0.2, 0.3]
julia> totalS(s, sΔ)
6.6
julia> totalS(s)
6.0
```
"""
function totalS(s, sΔ)
    sm = zero(eltype(s))
    for si ∈ eachindex(s)
        sm = sm + s[si] + sΔ[si]
    end
    return sm
end

function totalS(s)
    sm = zero(eltype(s))
    for si ∈ eachindex(s)
        sm = sm + s[si]
    end
    return sm
end

"""
    totalS_indices(s, s_indices)

Return the total storage amount for specific indices of a storage array.
"""
function totalS_indices(s, s_indices)
    sm = zero(eltype(s))
    for si ∈ s_indices
        sm = sm + s[si]
    end
    return sm
end

"""
    @unpack_nt

Macro to unpack variables from a named tuple.

# Arguments
- `inparams`: Expression or block of expressions in the form `(vars...) ⇐ source` or `var ⇐ source`

# Examples
```jldoctest
julia> forcing = (; f1 = 1.0, f2 = 2.0)
julia> @unpack_nt (f1, f2) ⇐ forcing
julia> f1, f2
(1.0, 2.0)
```
"""
macro unpack_nt(inparams)
    @assert inparams.head == :block || inparams.head == :call || inparams.head == :(=)
    if inparams.head == :block
        outputs = processUnpackNT.(filter(i -> isa(i, Expr), inparams.args))
        outCode = Expr(:block, outputs...)
    else
        outCode = processUnpackNT(inparams)
    end
    return outCode
end


"""
    adjust_pk(c_eco_k, kValue, flowValue, maxValue, zix, helpers)
"""
function adjust_pk(c_eco_k, kValue, flowValue, maxValue, zix, helpers)
    c_eco_k_f_sum = zero(eltype(c_eco_k))
    c_eco_k_sum = zero(eltype(c_eco_k))
    for ix ∈ zix
        # get max possible loss and total loss per pool
        tmp = min(c_eco_k[ix] + kValue + flowValue, maxValue)
        @rep_elem tmp ⇒ (c_eco_k, ix)
        c_eco_k_f_sum = c_eco_k_f_sum + tmp
        # get max possible loss to litter and total loss to litter per pool
        tmp_k = at_least_zero(tmp - flowValue)
        c_eco_k_sum = c_eco_k_sum + tmp_k
    end
    return c_eco_k, c_eco_k_f_sum, c_eco_k_sum
end
