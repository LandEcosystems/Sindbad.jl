export @add_to_elem, @pack_nt, @rep_elem, @rep_vec, @unpack_nt
export addToElem, addToEachElem, addVec
export getZix
export processPackNT, processUnpackNT
export repElem, repVec
export setComponentFromMainPool, setComponents, setMainFromComponentPool
export totalS
export totalS_indices
using ..SindbadTEM
import StaticArraysCore: SVector

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
                    rep_elem,
                    s_comp,
                    Expr(:ref, s_main, ix),
                    Expr(:., :(helpers.pools.zeros), QuoteNode(s_comp)),
                    Expr(:., :(helpers.pools.ones), QuoteNode(s_comp)),
                    :(land.constants.z_zero),
                    :(land.constants.o_one),
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
    setComponents(land, helpers, Val{s_main}, Val{s_comps}, Val{zix})

Set component pools from main pool values.

# Arguments
- `land`: A core SINDBAD NamedTuple containing all variables for a given time step
- `helpers`: Helper NamedTuple with necessary objects for model run and type consistencies
- `::Val{s_main}`: A NamedTuple with names of the main pools
- `::Val{s_comps}`: A NamedTuple with names of the component pools
- `::Val{zix}`: A NamedTuple with zix (indices) of each pool

# Returns
- Generated code expression to set components

# Notes
- This function generates code at runtime to set component pools
"""
function setComponents(
    land,
    helpers,
    ::Val{s_main},
    ::Val{s_comps},
    ::Val{zix}) where {s_main, s_comps, zix}
    output = quote end
    push!(output.args, Expr(:(=), s_main, Expr(:., :(land.pools), QuoteNode(s_main))))
    foreach(s_comps) do s_comp
        push!(output.args, Expr(:(=), s_comp, Expr(:., :(land.pools), QuoteNode(s_comp))))
        zix_pool = getfield(zix, s_comp)
        c_ix = 1
        foreach(zix_pool) do ix
            push!(output.args, Expr(:(=),
                s_comp,
                Expr(:call,
                    rep_elem,
                    s_comp,
                    Expr(:ref, s_main, ix),
                    Expr(:., :(helpers.pools.zeros), QuoteNode(s_comp)),
                    Expr(:., :(helpers.pools.ones), QuoteNode(s_comp)),
                    :(land.constants.z_zero),
                    :(land.constants.o_one),
                    c_ix)))

            c_ix += 1
        end
        push!(output.args, Expr(:(=),
            :land,
            Expr(:tuple,
                Expr(:(...), :land),
                Expr(:(=),
                    :pools,
                    (Expr(:tuple,
                        Expr(:parameters, Expr(:(...), :(land.pools)),
                            Expr(:kw, s_comp, s_comp))))))))
    end
    return output
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
                    rep_elem,
                    s_main,
                    Expr(:ref, s_comp, c_ix),
                    Expr(:., :(helpers.pools.zeros), QuoteNode(s_main)),
                    Expr(:., :(helpers.pools.ones), QuoteNode(s_main)),
                    :(land.constants.z_zero),
                    :(land.constants.o_one),
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