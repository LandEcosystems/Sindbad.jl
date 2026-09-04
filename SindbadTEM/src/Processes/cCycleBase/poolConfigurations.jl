export CARBON_POOL_NAMES
export CarbonPoolConfiguration
export CarbonPoolsCASA
export CarbonPoolsGSI
export CarbonPoolsMGMT
export cFlowEdges

"""
    CarbonPoolConfiguration

Abstract supertype of the carbon pool configurations: the pool structure a
`cCycleBase` approach is written against, together with any aliases that structure
needs.

An approach names its configuration with `poolConfiguration`, and the configuration
answers `poolStructure` and `poolAliases`. The flow topology is not part of a
configuration; it belongs to the approach and is declared with `cFlowEdges`.

# Notes:
- Defined in `poolConfigurations.jl`, which `cCycleBase.jl` includes explicitly
  before `includeApproaches`. That glob matches `cCycleBase_*.jl` and so skips this
  file.
- Configurations subtype `SindbadTypes`, deliberately not `cCycleBase`. Approach
  enumeration is driven by `subtypes(cCycleBase)` and `subtypes(LandEcosystem)` in
  five places: the generated "# Approaches" docstring list, the variable catalog, the
  approaches list, and approach validation. A configuration has no `define` and no
  parameters, so registering as an approach would surface it as a broken one.
"""
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

`setPoolsInfo` emits a `zix` entry for each of these whatever the configuration, so a
name a configuration lacks resolves to `()` rather than a missing field. A loop over
an empty entry runs zero times, statically, which is why models iterate
`helpers.pools.zix.X` without an `isempty` branch and why adding a name here needs no
model edit.
"""
const CARBON_POOL_NAMES = (
    :cVeg, :cVegRoot, :cVegRootF, :cVegRootC, :cVegWood, :cVegLeaf, :cVegReserve,
    :cLit, :cLitFast, :cLitSlow, :cLitLeaf, :cLitLeafM, :cLitLeafS,
    :cLitWood, :cLitRoot, :cLitRootFM, :cLitRootFS, :cLitRootC,
    :cMic, :cMicSurf, :cMicSoil, :cSoil, :cSoilSlow, :cSoilOld,
    :cProducts, :cProductsWood, :cProductsCrop,
)

"""
    poolStructure(::Type{CarbonPoolsGSI})
    poolStructure(::Type{CarbonPoolsMGMT})
    poolStructure(::Type{CarbonPoolsCASA})

The pool structure each configuration declares.

# Notes:
- Shaped exactly like the `pools` block of a model structure JSON, so `setPoolsInfo`
  consumes either source with no reshaping.
- Declaration order is `cEco` index order: `getPoolInformation` flattens depth first,
  in declaration order.
- Each leaf is `(number of layers, initial value)`.
- Every nesting level also becomes a real pool, with its own `zix` entry and backing
  array. That is where the groupings come from: `CarbonPoolsCASA`'s two-level layout
  yields `cVegRoot`, `cLitLeaf` and `cLitRoot` without declaring them, giving a
  `cEco` of `cVegRootF`, `cVegRootC`, `cVegWood`, `cVegLeaf`, `cLitLeafM`,
  `cLitLeafS`, `cLitWood`, `cLitRootFM`, `cLitRootFS`, `cLitRootC`, `cMicSurf`,
  `cMicSoil`, `cSoilSlow`, `cSoilOld`.
"""
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

"""
    poolAliases(::Type{CarbonPoolsCASA})
    poolAliases(::Type{<:CarbonPoolConfiguration})

Extra `zix` names a configuration needs that its nesting cannot produce.

# Notes:
- CASA litter is nested by organ, while the fast/slow axis is quality, so that split
  cannot be a nesting level. These two entries are the only groupings in any
  configuration that cut across the hierarchy.
- Every other configuration declares none: GSI and MGMT nest litter by quality
  already, so their structures generate `cLitFast` and `cLitSlow` directly.
- An alias has no backing array in `land.pools`, so models must iterate
  `helpers.pools.zix.X` for these names rather than reach into `land.pools.X`.
"""
poolAliases(::Type{CarbonPoolsCASA}) = (;
    cLitFast = (:cLitLeafM, :cLitRootFM),                          # -> (5, 8)
    cLitSlow = (:cLitLeafS, :cLitWood, :cLitRootFS, :cLitRootC),   # -> (6, 7, 9, 10)
)

poolAliases(::Type{<:CarbonPoolConfiguration}) = (;)

"""
    cFlowEdges(T)

Return the pool-to-pool carbon flow edges of an approach as `giver => taker` pairs,
or `()` if it declares none.

# Notes:
- Topology is an approach property rather than a pool-structure one: a base that adds
  or drops a link is one line here, not a new configuration.
- An edge list rather than a transfer matrix, because the matrix carried no
  information beyond the adjacency. Every `c_flow_A_array` in every `cCycleBase`
  approach held only `{-1, 0, 1}`, and every consumer tested positivity alone, so it
  was a dense encoding of a sparse graph: 64 numbers to say 11 things under GSI, 196
  to say 22 under CASA.
- Listed in flow-vector order: all edges leaving the first giver pool, ordered by
  taker index, then all edges leaving the second, and so on. Nothing depends on it,
  since `cFlowStructure` sorts by `(giver, taker)` whatever the declaration order,
  but reading a declaration against a `d_cFlow` output is far easier when the two
  agree.
- Edges must name leaf pools, never groups. `zix` is keyed by group names as well as
  leaf names, so an edge naming a group would silently expand to a cross product,
  `:cVeg => :cLit` becoming 4x2 entries. CASA is why this matters: `cVegRootF` feeds
  `cLitRootFM` and `cLitRootFS` while `cVegRootC` feeds only `cLitRootC`, so a
  group-level `cVegRoot => cLitFast` would invent links that do not exist.
  `cFlowStructure` rejects both mistakes.
"""
function cFlowEdges end

"""
    GSI_FLOW_EDGES

The 11 edges shared by every GSI-derived base. Transcribed from the `c_flow_A_array`
those approaches carried, which is identical across `cCycleBase_GSI` and
`_GSI_PlantForm`, and the same 11 under `_GSI_PlantForm_MGMT`, whose products are
decay only and so add no edges.
"""
const GSI_FLOW_EDGES = (            # giver => taker, in flow-vector order
    :cVegRoot    => :cVegReserve,   # giver 1: cVegRoot
    :cVegRoot    => :cLitFast,
    :cVegWood    => :cLitSlow,      # giver 2: cVegWood
    :cVegLeaf    => :cVegReserve,   # giver 3: cVegLeaf
    :cVegLeaf    => :cLitFast,
    :cVegReserve => :cVegRoot,      # giver 4: cVegReserve
    :cVegReserve => :cVegLeaf,
    :cVegReserve => :cLitFast,
    :cLitFast    => :cSoilSlow,     # giver 5: cLitFast
    :cLitSlow    => :cSoilSlow,     # giver 6: cLitSlow
    :cSoilSlow   => :cSoilOld,      # giver 7: cSoilSlow
)

"""
    CASA_FLOW_EDGES

The 22 edges of `cCycleBase_CASA`, transcribed from its 14x14 `c_flow_A_array`.
Keeping the `RootFM`/`RootFS` leaf names means every name here matches that matrix;
only the index order shifts under the nested structure (`cLitWood` moves from 9 to
7), which a name-keyed edge list does not care about.
"""
const CASA_FLOW_EDGES = (           # giver => taker, in flow-vector order
    :cVegRootF  => :cLitRootFM,  :cVegRootF  => :cLitRootFS,   # giver 1: cVegRootF
    :cVegRootC  => :cLitRootC,                                 # giver 2: cVegRootC
    :cVegWood   => :cLitWood,                                  # giver 3: cVegWood
    :cVegLeaf   => :cLitLeafM,   :cVegLeaf   => :cLitLeafS,    # giver 4: cVegLeaf
    :cLitLeafM  => :cMicSurf,                                  # giver 5: cLitLeafM
    :cLitLeafS  => :cMicSurf,    :cLitLeafS  => :cSoilSlow,    # giver 6: cLitLeafS
    :cLitWood   => :cMicSurf,    :cLitWood   => :cSoilSlow,    # giver 7: cLitWood
    :cLitRootFM => :cMicSoil,                                  # giver 8: cLitRootFM
    :cLitRootFS => :cMicSoil,    :cLitRootFS => :cSoilSlow,    # giver 9: cLitRootFS
    :cLitRootC  => :cMicSoil,    :cLitRootC  => :cSoilSlow,    # giver 10: cLitRootC
    :cMicSurf   => :cSoilSlow,                                 # giver 11: cMicSurf
    :cMicSoil   => :cSoilSlow,   :cMicSoil   => :cSoilOld,     # giver 12: cMicSoil
    :cSoilSlow  => :cMicSoil,    :cSoilSlow  => :cSoilOld,     # giver 13: cSoilSlow
    :cSoilOld   => :cMicSoil,                                  # giver 14: cSoilOld
)

cFlowEdges(::Type{<:cCycleBase}) = ()
cFlowEdges(T::cCycleBase) = cFlowEdges(typeof(T))

"""
    cFlowStructure(params::cCycleBase, cEco, helpers)

Resolve an approach's `cFlowEdges` against the pool structure the experiment actually
configured, returning the whole flow-vector description as
`(c_flow_order, c_taker, c_giver, c_flow_named_edges)`, in the order the approaches pack
it.

# Notes:
- A flow is an edge, so the taker and giver of flow `i` are just the two endpoints of
  edge `i` resolved to indices, and `c_flow_order` is `1:number of edges`. There is no
  transfer matrix in between: the old `c_flow_A_array` existed only to be walked back
  out by `findall`, and its one remaining reader, `cCycleConsistency_simple`, asks
  only whether a flow sits above or below the diagonal, which is `c_taker` against
  `c_giver`.
- All four come from one call so they cannot disagree about how many flows there are
  or what order they sit in, which is what an approach rederiving each of them
  separately from a matrix left open. `c_flow_named_edges` is the same topology keyed
  by pool-name pair rather than by position, built by `cFlowNamedEdges`.
- Sorted by `(giver, taker)`, which is the column-major order `findall` produced from
  the matrix and which `c_flow_A_vec`, `c_flow_QP_vec`, `c_flow_ME_vec` and the
  `d_cFlow` output dimension are all indexed by. Sorting here rather than trusting the
  declaration means an edge list written out of order still yields the same flow
  vector; the lists are kept in that order anyway so a declaration reads in the same
  order as the flows it produces.
- This is where an edge list first meets a concrete structure, so the checks live
  here: an edge naming a pool the structure lacks, an edge naming a group or alias
  rather than a leaf pool, which would otherwise expand silently into a cross
  product, and a duplicated edge, which the matrix used to swallow into one flow.
"""
function cFlowStructure(params::cCycleBase, cEco, helpers)
    edges = cFlowEdges(typeof(params))
    givers = [cFlowEdgeIndex(params, helpers, first(edge), edge) for edge ∈ edges]
    takers = [cFlowEdgeIndex(params, helpers, last(edge), edge) for edge ∈ edges]
    flows = collect(zip(givers, takers))
    if length(unique(flows)) < length(flows)
        repeated = unique([edges[i] for i ∈ findall(flow -> count(==(flow), flows) > 1, flows)])
        error("$(nameof(typeof(params))) declares the carbon flow edge(s) " *
              "$(repeated) more than once. Each giver to taker link carries one flow, " *
              "so list it once.")
    end
    order = sortperm(flows)
    c_taker = Tuple(takers[order])
    c_giver = Tuple(givers[order])
    c_flow_order = ntuple(identity, length(order))
    c_flow_named_edges = cFlowNamedEdges(c_taker, c_giver, helpers.pools.components.cEco)
    return c_flow_order, c_taker, c_giver, c_flow_named_edges
end

"""
    cFlowEdgeIndex(params, helpers, pool_name, edge)

Resolve one end of a flow edge to the single `cEco` index it names, erroring with the
offending name when it resolves to no pool or to more than one.
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

Bucket the flow-vector positions by the `(giver, taker)` pool-name pair they connect,
as `<giver>_to_<taker> => (positions...)`.

`cFlow` approaches need to find "the entry that carries leaf shedding" without
knowing which index that is. They used to rederive it themselves by matching
component names and taking `findall(...)[1]`, which silently kept only the first
match wherever a name spans more than one `cEco` slot. Resolving it once here, as a
tuple of every match, removes the duplication and the truncation together: the caller
loops over the tuple instead of writing a single element.

A pair the topology does not contain is simply absent, so reading it fails at
`define` naming the missing edge rather than at a `BoundsError` on an empty
`findall`.
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
