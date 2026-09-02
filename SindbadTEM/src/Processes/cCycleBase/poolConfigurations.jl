# Carbon pool configurations: the pool structure a cCycleBase approach is written against,
# and the pool-to-pool flow topology it uses.
#
# Included explicitly from cCycleBase.jl before includeApproaches, which globs
# `cCycleBase_*.jl` and so ignores this file.
#
# Configurations are `<: SindbadTypes`, deliberately not `<: cCycleBase`. Approach
# enumeration is driven by `subtypes(cCycleBase)` and `subtypes(LandEcosystem)` in five
# places (the generated "# Approaches" docstring list, the variable catalog, the approaches
# list, and approach validation), and a configuration has no `define` and no parameters, so
# registering as an approach would surface it as a broken one.

export CARBON_POOL_NAMES
export CarbonPoolConfiguration
export CarbonPoolsCASA
export CarbonPoolsGSI
export CarbonPoolsMGMT
export cFlowEdges

abstract type CarbonPoolConfiguration <: SindbadTypes end
purpose(::Type{CarbonPoolConfiguration}) = "Abstract type for the carbon pool structures that cCycleBase approaches are written against"

struct CarbonPoolsCASA <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsCASA}) = "CASA carbon pools: 14 pools, vegetation split into fine and coarse roots and litter nested by organ"

struct CarbonPoolsGSI <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsGSI}) = "GSI carbon pools: 8 pools with a vegetation reserve and litter split into fast and slow"

struct CarbonPoolsMGMT <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsMGMT}) = "GSI carbon pools plus wood and crop product pools for land management, 10 pools"

"""
    CARBON_POOL_NAMES

Union of carbon pool names across every configuration.

`setPoolsInfo` emits a `zix` entry for each of these whatever the configuration, so a name a
configuration lacks resolves to `()` rather than a missing field. A loop over an empty entry
runs zero times, statically, which is why models iterate `helpers.pools.zix.X` without an
`isempty` branch and why adding a name here needs no model edit.
"""
const CARBON_POOL_NAMES = (
    :cVeg, :cVegRoot, :cVegRootF, :cVegRootC, :cVegWood, :cVegLeaf, :cVegReserve,
    :cLit, :cLitFast, :cLitSlow, :cLitLeaf, :cLitLeafM, :cLitLeafS,
    :cLitWood, :cLitRoot, :cLitRootFM, :cLitRootFS, :cLitRootC,
    :cMic, :cMicSurf, :cMicSoil, :cSoil, :cSoilSlow, :cSoilOld,
    :cProducts, :cProductsWood, :cProductsCrop,
)

# --------------------------------------------------------------------------------------
# Pool structures. Shaped exactly like the `pools` block of a model structure JSON, so
# setPoolsInfo consumes them with no reshaping. Declaration order is cEco index order:
# getPoolInformation flattens depth first in declaration order.
#
# Each leaf is (number of layers, initial value). Every nesting level also becomes a real
# pool with its own zix entry and backing array, which is where the groupings come from.
# --------------------------------------------------------------------------------------

poolStructure(::Type{CarbonPoolsGSI}) = (;
    combine = :cEco,
    components = (;
        cVeg  = (; Root = (1, 25.0), Wood = (1, 25.0), Leaf = (1, 25.0), Reserve = (1, 10.0)),
        cLit  = (; Fast = (1, 100.0), Slow = (1, 250.0)),
        cSoil = (; Slow = (1, 500.0), Old = (1, 1000.0)),
    ),
)

poolStructure(::Type{CarbonPoolsMGMT}) = (;
    combine = :cEco,
    components = (;
        cVeg      = (; Root = (1, 25.0), Wood = (1, 25.0), Leaf = (1, 25.0), Reserve = (1, 10.0)),
        cLit      = (; Fast = (1, 100.0), Slow = (1, 250.0)),
        cSoil     = (; Slow = (1, 500.0), Old = (1, 1000.0)),
        cProducts = (; Wood = (1, 20.0), Crop = (1, 20.0)),
    ),
)

# Nested two levels deep, so cVegRoot, cLitLeaf and cLitRoot come out as pools without being
# declared. cEco is then cVegRootF, cVegRootC, cVegWood, cVegLeaf, cLitLeafM, cLitLeafS,
# cLitWood, cLitRootFM, cLitRootFS, cLitRootC, cMicSurf, cMicSoil, cSoilSlow, cSoilOld.
poolStructure(::Type{CarbonPoolsCASA}) = (;
    combine = :cEco,
    components = (;
        cVeg  = (; Root = (; F = (1, 25.0), C = (1, 25.0)),
                   Wood = (1, 25.0), Leaf = (1, 25.0)),
        cLit  = (; Leaf = (; M = (1, 25.0), S = (1, 25.0)),
                   Wood = (1, 100.0),
                   Root = (; FM = (1, 25.0), FS = (1, 25.0), C = (1, 25.0))),
        cMic  = (; Surf = (1, 20.0), Soil = (1, 20.0)),
        cSoil = (; Slow = (1, 500.0), Old = (1, 1000.0)),
    ),
)

# CASA litter is nested by organ, but the fast/slow axis is quality, so it cannot be a nesting
# level. These two are the only groupings in any configuration that cut across the hierarchy.
poolAliases(::Type{CarbonPoolsCASA}) = (;
    cLitFast = (:cLitLeafM, :cLitRootFM),                          # -> (5, 8)
    cLitSlow = (:cLitLeafS, :cLitWood, :cLitRootFS, :cLitRootC),   # -> (6, 7, 9, 10)
)

# GSI and MGMT: their nesting already produces cLitFast and cLitSlow directly.
poolAliases(::Type{<:CarbonPoolConfiguration}) = (;)

# --------------------------------------------------------------------------------------
# Flow topology, as an edge list rather than a transfer matrix.
#
# Every c_flow_A_array in every cCycleBase approach holds only {-1, 0, 1} and every consumer
# tests positivity alone, so the matrix is a dense encoding of a sparse adjacency: 64 numbers
# to say 11 things under GSI, 196 to say 22 under CASA.
#
# Edges name leaf pools, never groups. `zix` is keyed by group names as well as leaf names, so
# an edge naming a group would silently expand to a cross product (`:cVeg => :cLit` becoming
# 4x2 entries). CASA is the reason this matters: cVegRootF feeds cLitRootFM/FS while cVegRootC
# feeds only cLitRootC, so a group-level `cVegRoot => cLitFast` would invent links.
# --------------------------------------------------------------------------------------

"""
    cFlowEdges(T)

Return the pool-to-pool carbon flow edges of an approach as `giver => taker` pairs, or `()`
if it declares none.

Topology is an approach property rather than a pool-structure one: a base that adds or drops
a link is one line here, not a new configuration.
"""
function cFlowEdges end

"""
    GSI_FLOW_EDGES

The 11 edges shared by every GSI-derived base. Transcribed from the `c_flow_A_array` those
approaches carried, which is identical across `cCycleBase_GSI` and `_GSI_PlantForm`, and the
same 11 under `_GSI_PlantForm_MGMT`, whose products are decay only and so add no edges.
"""
const GSI_FLOW_EDGES = (            # giver => taker
    :cVegReserve => :cVegRoot,
    :cVegReserve => :cVegLeaf,
    :cVegRoot    => :cVegReserve,
    :cVegLeaf    => :cVegReserve,
    :cVegRoot    => :cLitFast,
    :cVegLeaf    => :cLitFast,
    :cVegReserve => :cLitFast,
    :cVegWood    => :cLitSlow,
    :cLitFast    => :cSoilSlow,
    :cLitSlow    => :cSoilSlow,
    :cSoilSlow   => :cSoilOld,
)

"""
    CASA_FLOW_EDGES

The 22 edges of `cCycleBase_CASA`, transcribed from its 14x14 `c_flow_A_array`. Keeping the
`RootFM`/`RootFS` leaf names means every name here matches that matrix; only the index order
shifts under the nested structure (`cLitWood` moves from 9 to 7), which a name-keyed edge
list does not care about.
"""
const CASA_FLOW_EDGES = (           # giver => taker
    :cVegRootF  => :cLitRootFM,  :cVegRootF  => :cLitRootFS,
    :cVegRootC  => :cLitRootC,   :cVegWood   => :cLitWood,
    :cVegLeaf   => :cLitLeafM,   :cVegLeaf   => :cLitLeafS,
    :cLitLeafM  => :cMicSurf,    :cLitLeafS  => :cMicSurf,   :cLitLeafS  => :cSoilSlow,
    :cLitRootFM => :cMicSoil,    :cLitRootFS => :cMicSoil,   :cLitRootFS => :cSoilSlow,
    :cLitWood   => :cMicSurf,    :cLitWood   => :cSoilSlow,
    :cLitRootC  => :cMicSoil,    :cLitRootC  => :cSoilSlow,
    :cMicSurf   => :cSoilSlow,   :cMicSoil   => :cSoilSlow,  :cMicSoil   => :cSoilOld,
    :cSoilSlow  => :cMicSoil,    :cSoilSlow  => :cSoilOld,   :cSoilOld   => :cMicSoil,
)

cFlowEdges(::Type{<:cCycleBase}) = ()
cFlowEdges(T::cCycleBase) = cFlowEdges(typeof(T))

"""
    cFlowMatrix(params::cCycleBase, cEco, helpers)

Build the carbon transfer matrix for an approach from its `cFlowEdges`, resolved against the
pool structure the experiment actually configured.

Row is taker, column is giver, `-1` on the diagonal and `+1` at each edge, which is the layout
the hand-written `c_flow_A_array` used. `c_taker`/`c_giver`/`c_flow_order` are still derived
from the matrix by the existing `findall`, so the flow-vector order stays column major and the
edge declaration order cannot affect it.

This is where an edge list first meets a concrete structure, so both checks live here: an edge
naming a pool the structure lacks, and an edge naming a group or alias rather than a leaf pool,
which would otherwise expand silently into a cross product.
"""
function cFlowMatrix(params::cCycleBase, cEco, helpers)
    edges = cFlowEdges(typeof(params))
    n_pools = length(cEco)
    num_type = eltype(cEco)
    c_flow_A_array = zeros(num_type, n_pools, n_pools)
    for pool ∈ 1:n_pools
        c_flow_A_array[pool, pool] = -one(num_type)
    end
    for edge ∈ edges
        giver = cFlowEdgeIndex(params, helpers, first(edge), edge)
        taker = cFlowEdgeIndex(params, helpers, last(edge), edge)
        c_flow_A_array[taker, giver] = one(num_type)
    end
    return c_flow_A_array
end

"""
    cFlowEdgeIndex(params, helpers, pool_name, edge)

Resolve one end of a flow edge to the single `cEco` index it names, erroring with the offending
name when it resolves to no pool or to more than one.
"""
function cFlowEdgeIndex(params, helpers, pool_name, edge)
    approach = nameof(typeof(params))
    if !hasproperty(helpers.pools.zix, pool_name)
        error("$(approach) declares the carbon flow edge `$(edge)`, but `$(pool_name)` is not a " *
              "known carbon pool name. Add it to CARBON_POOL_NAMES, or correct the edge.")
    end
    zix = getproperty(helpers.pools.zix, pool_name)
    if isempty(zix)
        error("$(approach) declares the carbon flow edge `$(edge)`, but the configured pool " *
              "structure has no `$(pool_name)`. Use a pool structure that has it, or an approach " *
              "whose edges match this structure.")
    end
    if length(zix) > 1
        error("$(approach) declares the carbon flow edge `$(edge)`, but `$(pool_name)` spans " *
              "$(length(zix)) pools ($(zix)). Flow edges must name leaf pools, not groups or " *
              "aliases, because a group would expand into a cross product of links. List the " *
              "individual edges instead.")
    end
    return only(zix)
end

"""
    cFlowNamedEdges(c_taker, c_giver, cEco_components)

Bucket the flow-vector positions by the `(giver, taker)` pool-name pair they connect, as
`<giver>_to_<taker> => (positions...)`.

`cFlow` approaches need to find "the entry that carries leaf shedding" without knowing which
index that is. They used to rederive it themselves by matching component names and taking
`findall(...)[1]`, which silently kept only the first match wherever a name spans more than one
`cEco` slot. Resolving it once here, as a tuple of every match, removes the duplication and the
truncation together: the caller loops over the tuple instead of writing a single element.

A pair the topology does not contain is simply absent, so reading it fails at `define` naming
the missing edge rather than at a `BoundsError` on an empty `findall`.
"""
function cFlowNamedEdges(c_taker, c_giver, cEco_components)
    edge_names = Symbol[]
    edge_positions = Vector{Int}[]
    for flow ∈ eachindex(c_taker, c_giver)
        edge = Symbol(String(cEco_components[c_giver[flow]]) * "_to_" *
                      String(cEco_components[c_taker[flow]]))
        known = findfirst(==(edge), edge_names)
        if isnothing(known)
            push!(edge_names, edge)
            push!(edge_positions, [flow])
        else
            push!(edge_positions[known], flow)
        end
    end
    return NamedTuple{Tuple(edge_names)}(Tuple(Tuple.(edge_positions)))
end
