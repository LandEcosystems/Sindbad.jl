export @add_to_elem, @pack_nt, @rep_elem, @rep_vec, @unpack_nt
export addToElem, addToEachElem, addVec
export cFlowMatrix
export getVectorOfType
export getZix
export processPackNT, processUnpackNT
export repElem, repVec
export setComponentFromMainPool, setFlowEdgeValue, setMainFromComponentPool
export totalS
export totalS_indices
using ..SindbadTEM
import StaticArraysCore: SVector, StaticArray

"""
    @add_to_elem

Macro to add a value to an element of a vector or static vector.

# Arguments
- `outparams::Expr`: Expression in the form `value ⇒ (vector, index, pool_name)`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> helpers = (; pools = (; zeros = (; cOther = SVector(0.0f0, 0.0f0),),))
julia> cOther = SVector(100.0f0, 1.0f0)
julia> @add_to_elem 1.0f0 ⇒ (cOther, 1, :cOther)
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
    hp_pool = rhsa[3]
    outCode = [
        Expr(:(=),
            tar,
            Expr(:call,
                addToElem,
                tar,
                lhs,
                esc(Expr(:., :(helpers.pools.zeros), hp_pool)),
                esc(indx)))
    ]
    return Expr(:block, outCode...)
end


"""
    addToElem(v::SVector, Δv, v_zero, ind::Int)
    addToElem(v::AbstractVector, Δv, _, ind::Int)

Add a value to a specific element of a vector.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`
- `Δv`: The value to be added
- `v_zero`: A `StaticVector` of zeros (used for `SVector` only)
- `ind::Int`: The index of the element to modify

# Returns
- The modified vector with `Δv` added to element at index `ind`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> v_zero = SVector(0.0, 0.0, 0.0)
julia> addToElem(v, 5.0, v_zero, 2)
3-element SVector{3, Float64} with indices SOneTo(3):
 1.0
 7.0
 3.0
```
"""
function addToElem end

function addToElem(v::SVector, Δv, v_zero, ind::Int)
    n_0 = zero(first(v_zero))
    n_1 = one(first(v_zero))
    v_zero = v_zero .* n_0
    v_zero = Base.setindex(v_zero, n_1, ind)
    v = v .+ v_zero .* Δv
    return v
end

function addToElem(v::AbstractVector, Δv, _, ind::Int)
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

"""
    getVectorOfType(source_vector, output_length)
    getVectorOfType(source_vector, output_length, fill_value)
    getVectorOfType(source_vector::StaticArray, output_length, fill_value)

Return a vector of `output_length` elements shaped like `source_vector`: its element
type and its container kind, filled with `fill_value(eltype(source_vector))`.

# Arguments
- `source_vector`: the vector whose element type and container kind to copy
- `output_length`: length of the returned vector, which need not match
  `length(source_vector)`
- `fill_value`: `zero` or `one`, the function rather than a number, so the element
  type comes from `source_vector` and the caller never repeats it. Defaults to `zero`

# Returns
- A vector of `output_length` elements, static when `source_vector` is static

# Notes:
- "Of type" is about the source's type, not its size: the two lengths differ at every
  carbon-cycle call site, where `source_vector` is `cEco` with one entry per pool and
  the result has one entry per carbon flow.
- Dispatch on `StaticArray` replaces the `if x isa SVector` branch that every one of
  those sites used to carry, which had to be repeated once per constructed vector.

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
- **Row is the taker, column is the giver.** Every dense flow array in every model
  follows this, from the `c_flow_A_array` the topology replaced to the
  `c_flow_ME_array` that outlived it, and so does the flow-vector order itself:
  `cFlowStructure` sorts by `(giver, taker)`, which is column-major over this matrix.
- The two methods produce the same matrix. The three-argument one is the runtime
  form, taking indices the base already resolved, so its flow numbers are
  `c_flow_order` by construction. The two-argument one resolves an approach's
  declared edges without a run, repeating `cFlowStructure`'s sort so that flow `k`
  here is the flow `k` the model packs.
- `pool_names` is an argument rather than something derived from `poolStructure`
  because flattening a structure into ordered names is `getPoolInformation`, which
  lives in `Sindbad.Setup`, and `Sindbad` depends on `SindbadTEM` and not the other
  way round. Passing the names in keeps this inside `SindbadTEM` and avoids a second
  flattener that could drift from the first.
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
    setFlowEdgeValue(flow_vec, c_flow_named_edges, edge, value)

Write `value` into every flow-vector position that carries the named `edge`, and
return the vector unchanged when the configured pool structure has no such edge.

The tables that fill the per-flow vectors are declared over the full CASA pool
topology, while the same approaches are selected against more aggregated structures
that lack the explicit metabolic/structural litter and microbial pools. Skipping
absent edges lets one declaration serve both, instead of erroring on a pool the
structure never had.

`setQPFlow` and `setMEFlow` are this function under the names their processes read in.
"""
function setFlowEdgeValue(flow_vec, c_flow_named_edges, edge, value)
    hasproperty(c_flow_named_edges, edge) || return flow_vec
    for flow ∈ getproperty(c_flow_named_edges, edge)
        flow_vec = repElem(flow_vec, value, flow_vec, flow_vec, flow)
    end
    return flow_vec
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
    elseif rename isa Expr && rename.head == :tuple
        rename = rename.args
    end
    lines = broadcast(lhs, rename) do s, rn
        depth_field = length(findall(".", string(esc(rhs)))) + 1
        if depth_field == 1
            expr_l = Expr(:(=),
                esc(rhs),
                Expr(:tuple,
                    Expr(:parameters, Expr(:(...), esc(rhs)),
                        Expr(:kw, esc(s), esc(rn)))))
            expr_l
        elseif depth_field == 2
            top = Symbol(split(string(rhs), '.')[1])
            field = Symbol(split(string(rhs), '.')[2])
            tmp = Expr(:(=),
                esc(top),
                Expr(:tuple,
                    Expr(:(...), esc(top)),
                    Expr(:(=),
                        esc(field),
                        (Expr(:tuple,
                            Expr(:parameters, Expr(:(...), esc(rhs)),
                                Expr(:kw, esc(s), esc(rn))))))))
            tmp
        end
    end
    return Expr(:block, lines...)
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
- `outparams::Expr`: Expression in the form `value ⇒ (vector, index, pool_name)`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> helpers = (; pools = (; zeros = (; cOther = SVector(0.0f0, 0.0f0),), ones = (; cOther = SVector(1.0f0, 1.0f0),)))
julia> cOther = SVector(100.0f0, 1.0f0)
julia> @rep_elem 50.0f0 ⇒ (cOther, 1, :cOther)
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
    hp_pool = rhsa[3]
    outCode = [
        Expr(:(=),
            tar,
            Expr(:call,
                repElem,
                tar,
                lhs,
                esc(Expr(:., :(helpers.pools.zeros), hp_pool)),
                esc(Expr(:., :(helpers.pools.ones), hp_pool)),
                esc(indx)))
    ]
    return Expr(:block, outCode...)
end

"""
    repElem(v::AbstractVector, v_elem, _, _, ind::Int)
    repElem(v::SVector, v_elem, v_zero, v_one, ind::Int)

Replace an element of a vector with a new value.

# Arguments
- `v`: A `StaticVector` or `AbstractVector`
- `v_elem`: The new value to assign
- `v_zero`: A `StaticVector` of zeros (used for `SVector` only)
- `v_one`: A `StaticVector` of ones (used for `SVector` only)
- `ind::Int`: The index of the element to replace

# Returns
- The modified vector with element at index `ind` replaced by `v_elem`

# Examples
```jldoctest
julia> using StaticArraysCore: SVector
julia> v = SVector(1.0, 2.0, 3.0)
julia> v_zero = SVector(0.0, 0.0, 0.0)
julia> v_one = SVector(1.0, 1.0, 1.0)
julia> repElem(v, 5.0, v_zero, v_one, 2)
3-element SVector{3, Float64} with indices SOneTo(3):
 1.0
 5.0
 3.0
```
"""
function repElem end

function repElem(v::AbstractVector, v_elem, _, _, ind::Int)
    v[ind] = v_elem
    return v
end

function repElem(v::SVector, v_elem, v_zero, v_one, ind::Int)
    n_0 = zero(first(v_zero))
    n_1 = one(first(v_zero))
    v_zero = v_zero .* n_0
    v_zero = Base.setindex(v_zero, n_1, ind)
    v_one = v_one .* n_0 .+ n_1
    v_one = Base.setindex(v_one, n_0, ind)
    v = v .* v_one .+ v_zero .* v_elem
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
    n_0 = zero(first(v))
    v = v .* n_0 + v_new
    return v
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
                    Expr(:., :(helpers.pools.zeros), QuoteNode(s_comp)),
                    Expr(:., :(helpers.pools.ones), QuoteNode(s_comp)),
                    c_ix)))

            c_ix += 1
        end
        push!(gen_output.args, Expr(:(=),
            :land,
            Expr(:tuple,
                Expr(:(...), :land),
                Expr(:(=),
                    :pools,
                    (Expr(:tuple,
                        Expr(:parameters, Expr(:(...), :(land.pools)),
                            Expr(:kw, s_comp, s_comp))))))))
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
                    Expr(:., :(helpers.pools.zeros), QuoteNode(s_main)),
                    Expr(:., :(helpers.pools.ones), QuoteNode(s_main)),
                    ix)))
            c_ix += 1
        end
    end
    push!(gen_output.args, Expr(:(=),
        :land,
        Expr(:tuple,
            Expr(:(...), :land),
            Expr(:(=),
                :pools,
                (Expr(:tuple,
                    Expr(:parameters, Expr(:(...), :(land.pools)),
                        Expr(:kw, s_main, s_main))))))))
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