
export LandTypes
abstract type LandTypes <: SindbadTypes end
purpose(::Type{LandTypes}) = "Abstract type for land related types that are typically used in preparing objects for model runs in SINDBAD"

# ------------------------- land related helper types ------------------------------------------------------------
export PreAlloc
export PreAllocArray
export PreAllocArrayAll
export PreAllocArrayFD
export PreAllocArrayMT
export PreAllocArrayReactant
export PreAllocStacked
export PreAllocTimeseries
export PreAllocYAXArray

abstract type PreAlloc <: LandTypes end
purpose(::Type{PreAlloc}) = "Abstract type for preallocated land helpers types in prepTEM of SINDBAD"

struct PreAllocArray <: PreAlloc end
purpose(::Type{PreAllocArray}) = "use a preallocated array for model output"

struct PreAllocArrayAll <: PreAlloc end
purpose(::Type{PreAllocArrayAll}) = "use a preallocated array to output all land variables"

struct PreAllocArrayFD <: PreAlloc end
purpose(::Type{PreAllocArrayFD}) = "use a preallocated array for finite difference (FD) hybrid experiments"

struct PreAllocArrayMT <: PreAlloc end
purpose(::Type{PreAllocArrayMT}) = "use arrays of nThreads size for land model output for replicates of multiple threads"

struct PreAllocArrayReactant <: PreAlloc end
purpose(::Type{PreAllocArrayReactant}) = "use a Reactant-traced preallocated array for model output, for hybrid experiments differentiated via Reactant+Enzyme"

struct PreAllocStacked <: PreAlloc end
purpose(::Type{PreAllocStacked}) = "save output as a stacked vector of land using map over temporal dimension"

struct PreAllocTimeseries <: PreAlloc end
purpose(::Type{PreAllocTimeseries}) = "save land output as a preallocated vector for time series of land"

struct PreAllocYAXArray <: PreAlloc end
purpose(::Type{PreAllocYAXArray}) = "use YAX arrays for model output"

# ------------------------- land wrapper and group view types ------------------------------------------------------------
export LandWrapper
export GroupView
export ArrayView
abstract type LandWrapperType <: LandTypes end
purpose(::Type{LandWrapperType}) = "Abstract type for land wrapper types in SINDBAD"

"""
    LandWrapper{S}

# Fields:
- `s::S`: The underlying NamedTuple or data structure being wrapped.
"""
struct LandWrapper{S} <: LandWrapperType
    s::S
end

purpose(::Type{LandWrapper}) = "Wraps the nested fields of a NamedTuple output of SINDBAD land into a nested structure of views that can be easily accessed with dot notation."

"""
    GroupView{S}

# Fields:
- `groupname::Symbol`: The name of the group being accessed.
- `s::S`: The underlying data structure containing the group.
"""
struct GroupView{S} <: LandWrapperType
    groupname::Symbol
    s::S
end

purpose(::Type{GroupView}) = "Represents a group of data within a `LandWrapper`, allowing access to specific groups of variables."

"""
    ArrayView{T,N,S<:AbstractArray{<:Any,N}}

# Fields:
- `s::S`: The underlying array being viewed.
- `groupname::Symbol`: The name of the group containing the array.
- `arrayname::Symbol`: The name of the array being accessed.
"""
struct ArrayView{T,N,S<:AbstractArray{<:Any,N}} <: AbstractArray{T,N}
    s::S
    groupname::Symbol
    arrayname::Symbol
end

purpose(::Type{ArrayView}) = "A view into a specific array within a group of data, enabling efficient access and manipulation."


Base.getproperty(s::LandWrapper, aggr_func::Symbol) = GroupView(aggr_func, getfield(s, :s))

# Define the setindex! method
function Base.setindex!(obj::LandWrapper{Vector{Any}}, value::LandWrapper, index::Int)
    obj.data[index] = value
end

# Define the setindex method
function Base.setindex(obj::LandWrapper{Vector{Any}}, value::LandWrapper, index::Int)
    obj.data[index] = value
end

# Define the getindex method
function Base.getindex(obj::LandWrapper{Vector{Any}}, value::LandWrapper, index::Int)
    return obj.data[index]
end

"""
    Base.getproperty(g::GroupView, aggr_func::Symbol)

Accesses a specific array within a group of data in a `GroupView`.

# Returns:
An `ArrayView` object for the specified array.
"""
function Base.getproperty(g::GroupView, aggr_func::Symbol)
    allarrays = getfield(g, :s)
    groupname = getfield(g, :groupname)
    T = typeof(first(allarrays)[groupname][aggr_func])
    return ArrayView{T,ndims(allarrays),typeof(allarrays)}(allarrays, groupname, aggr_func)
end

Base.size(a::ArrayView) = size(a.s)
Base.IndexStyle(a::Type{<:ArrayView}) = IndexLinear()
Base.getindex(a::ArrayView, i::Int) = a.s[i][a.groupname][a.arrayname]
Base.propertynames(o::LandWrapper) = propertynames(first(getfield(o, :s)))
Base.keys(o::LandWrapper) = propertynames(o)
Base.getindex(o::LandWrapper, s::Symbol) = getproperty(o, s)

"""
    Base.propertynames(o::GroupView)

Returns the property names of a group in a `GroupView`.
"""
function Base.propertynames(o::GroupView)
    return propertynames(first(getfield(o, :s))[getfield(o, :groupname)])
end

Base.keys(o::GroupView) = propertynames(o)
Base.getindex(o::GroupView, i::Symbol) = getproperty(o, i)
Base.size(g::GroupView) = size(getfield(g, :s))
Base.length(g::GroupView) = prod(size(g))

"""
    Base.show(io::IO, gv::GroupView)

Displays a summary of the contents of a `GroupView`.
"""
function Base.show(io::IO, gv::GroupView)
    print(io, "GroupView with")
    printstyled(io, ":"; color=:red)
    println(io)
    print(io, "  Vector Arrays of size $(size(getfield(gv, :s)))")
    printstyled(io, ":"; color=:blue)
    println(io)
    g_name = getfield(gv, :groupname)
    for name in propertynames(gv)
        g_data = getproperty(getproperty(first(getfield(gv, :s)), g_name), name)
        printstyled(io, "     $name"; color=6)
        printstyled(io, ": "; color=:yellow)
        if isa(g_data, Tuple)
            printstyled(io, "Tuple of length $(length(g_data))\n"; color=:light_black)
        elseif isa(g_data, AbstractArray)
            printstyled(io, "Vector Arrays of size $(size(g_data))\n"; color=:light_black)
        else
            printstyled(io, "$(typeof(g_data))\n"; color=:light_black)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", lw::LandWrapper)
    print(io, "LandWrapper")
    printstyled(io, ":"; color=:red)
    println(io)
    for (i, groupname) in enumerate(propertynames(lw))
        if groupname in (:fluxes, :states, :diagnostics, :properties, :models, :pools, :constants)
            printstyled(io, "  $(groupname)"; color=12)
            printstyled(io, " ➘")
        else
            printstyled(io, "  $(groupname)"; color=:light_black)
            printstyled(io, ":"; color=:blue)
            group_data = first(getfield(lw, :s))[groupname]
            if length(propertynames(group_data))>1
                printstyled(io, " ➘")
            end
        end
        if i>20
            printstyled(io, "\n    ⋮ ")
            return
        end
        println(io)
    end
end
