export CarbonPoolConfiguration
export cFlowEdges
export fireCCTable
export TAU_DORMANT
export TAU_HILO_LIT_SPLIT

"""
    CarbonPoolConfiguration

Abstract supertype of the carbon pool configurations: the pool structure a
`cCycleBase` approach is written against, together with any aliases that structure
needs. Each configuration's file also centralizes that structure's own fixed
per-pool defaults an approach reads rather than declares inline -- turnover time
for the pools that are not vegetation-type dependent (`GSI_TAU_DEFAULT`/
`CASA_TAU_NON_VEG_POOLS`/`MGMT_PRODUCTS_TAU`) and vegetation carbon-to-nitrogen ratio
(`GSI_CN_ratio`/`CASA_CN_ratio`) today, alongside the flow-edge topology
(`GSI_FLOW_EDGES`/`CASA_FLOW_EDGES`) that was already here. The vegetation-compartment
pools' turnover (`cVegRoot`/`cVegRootFine`/`cVegRootCoarse`/`cVegWood`/`cVegLeaf`)
is not fixed here: every `cCycleBase` approach looks it up at runtime by
`land.states.veg_type_name`, from the per-vegetation-type tables in
`vegClass/mapSources/ParamsForVegClasses.jl`.

An approach names its configuration with `poolConfiguration`, and the configuration
answers `poolStructure` and `poolAliases`.

# Notes:
- One file per configuration, in this directory, listed at the bottom of this file.
  This file holds only what they share: the supertype, the defaults, and the machinery
  that resolves a declared edge list against a concrete structure. A new structure is a
  new file plus a line in that list.
- `cCycleBase.jl` includes this file explicitly. `includeApproaches` globs
  `cCycleBase_*.jl` in the directory above and does not descend, so it skips the folder.
- Configurations subtype `SindbadTypes`, deliberately not `cCycleBase`. Approach
  enumeration is driven by `subtypes(cCycleBase)` and `subtypes(LandEcosystem)` in
  five places: the generated "# Approaches" docstring list, the variable catalog, the
  approaches list, and approach validation. A configuration has no `define` and no
  parameters, so registering as an approach would surface it as a broken one.
- `subtypes(CarbonPoolConfiguration)` is what enumerates the structures, so a
  configuration file that is written but never included is invisible everywhere,
  including in the pool-name skeleton `setPoolsInfo` builds.
"""
abstract type CarbonPoolConfiguration <: SindbadTypes end
purpose(::Type{CarbonPoolConfiguration}) = "Abstract type for the carbon pool structures that cCycleBase approaches are written against"

"""
    TAU_DORMANT

Shared placeholder turnover *time* (years) for a pool that, by design, effectively
never decays -- a `(0.25, 4.0)`-bounded scalar could never scale a rate derived
from this back up to anything physically meaningful, so it exists purely to make
"this pool is dormant" explicit and consistent wherever it's needed, rather than
each configuration re-choosing its own large number.

Used for the GSI-family vegetation Reserve pool (`GSI_TAU_DEFAULT`, and every
GSI-family `cCycleBase` approach's runtime `cVegReserve` entry, since the Reserve
pool is not vegetation-type dependent).
"""
const TAU_DORMANT = 1.0e11
const TAU_HILO_LIT_SPLIT = 1.0

"""
    poolAliases(configuration)

Extra `zix` names a configuration needs that its nesting cannot produce, `(;)` unless
the configuration declares otherwise.

Only `CASA` declares any: its litter nests by compartment, so the fast/slow
quality split cuts across the hierarchy. Every other structure nests litter by quality
already and generates those names directly.
"""
poolAliases(::Type{<:CarbonPoolConfiguration}) = (;)

"""
    cFlowEdges(T)

Return the pool-to-pool carbon flow edges of an approach as `giver => taker` pairs,
or `()` if it declares none.

# Notes:
- Topology is a pool-configuration property: every approach already names its
  configuration via `poolConfiguration`, so `cFlowEdges` on an approach type looks
  that configuration up and asks it directly, rather than every approach repeating
  the same one-line dispatch. The lists themselves sit in the configuration files,
  because an edge list is written in the pool names of one structure and resolves
  against no other: `GSI_FLOW_EDGES` in `GSI.jl`, `CASA_FLOW_EDGES` in `CASA.jl`. A
  configuration that adds no topology of its own -- `MGMT`, whose extra pools are
  decay-only -- declares `cFlowEdges` as reusing another configuration's list
  instead of repeating it.
- An edge list rather than a transfer matrix, because the matrix carried no
  information beyond the adjacency. `cFlowMatrix` rebuilds the matrix view from an
  edge list when one is wanted, in the `[taker, giver]` orientation every dense flow
  array in the models uses. Every `c_flow_A_array` in every `cCycleBase`
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
  `:cVeg => :cLit` becoming 4x2 entries. CASA is why this matters: `cVegRootFine` feeds
  `cLitRootFineFast` and `cLitRootFineSlow` while `cVegRootCoarse` feeds only `cLitRootCoarse`, so a
  group-level `cVegRoot => cLitFast` would invent links that do not exist.
  `cFlowStructure` rejects both mistakes.
"""
function cFlowEdges end

cFlowEdges(::Type{<:CarbonPoolConfiguration}) = ()
function cFlowEdges(A::Type{<:cCycleBase})
    configuration = poolConfiguration(A)
    return isnothing(configuration) ? () : cFlowEdges(configuration)
end
cFlowEdges(T::cCycleBase) = cFlowEdges(typeof(T))

"""
    fireCCTable(configuration)

The fixed, per-pool-name `(ccMin, ccMax, weight)` fire combustion-completeness
table for a `CarbonPoolConfiguration` -- the same kind of "structure's own
fixed per-pool defaults an approach reads rather than declares inline" this
file's `CarbonPoolConfiguration` docstring already describes for turnover and
carbon-to-nitrogen ratio. Named by type, symbol, string, or a `cCycleBase`
type/instance, exactly like `cFlowEdges`, since a single shared approach
(`cFireCombustionCompleteness_vanDerWerf2006`) must resolve the right table at
runtime for whichever pool configuration is actually active.
"""
function fireCCTable end

fireCCTable(::Type{<:CarbonPoolConfiguration}) = error("No fire combustion completeness table is defined for this carbon pool configuration.")
function fireCCTable(A::Type{<:cCycleBase})
    configuration = poolConfiguration(A)
    return isnothing(configuration) ? error("No fire combustion completeness table is defined for this carbon pool configuration.") : fireCCTable(configuration)
end
fireCCTable(T::cCycleBase) = fireCCTable(typeof(T))

"""
    carbonPoolConfiguration(name::Symbol)

Resolve a `CarbonPoolConfiguration` by name. Errors with what was tried rather than
surfacing an `UndefVarError` or silently returning `nothing`.
"""
function carbonPoolConfiguration(name::Symbol)
    if !isdefined(@__MODULE__, name) || !(getfield(@__MODULE__, name) isa Type) ||
       !(getfield(@__MODULE__, name) <: CarbonPoolConfiguration)
        error("`$(name)` does not name a known carbon pool configuration. Use a " *
              "configuration name such as `GSI`, `CASA`, or `MGMT`.")
    end
    return getfield(@__MODULE__, name)
end

"""
    poolStructure(name), poolAliases(name), cFlowEdges(name)
    poolStructure(configuration::CarbonPoolConfiguration), ...

Sister methods so a `CarbonPoolConfiguration` can be named by string (`"GSI"`),
symbol (`:GSI`), or instance (`GSI()`), not only by type (`GSI`). Each method
performs exactly one conversion and calls the next-more-resolved form: string to
symbol, symbol to type via `carbonPoolConfiguration`, instance to its own type.
"""
poolStructure(name::AbstractString) = poolStructure(Symbol(name))
poolStructure(name::Symbol) = poolStructure(carbonPoolConfiguration(name))
poolStructure(configuration::CarbonPoolConfiguration) = poolStructure(typeof(configuration))

poolAliases(name::AbstractString) = poolAliases(Symbol(name))
poolAliases(name::Symbol) = poolAliases(carbonPoolConfiguration(name))
poolAliases(configuration::CarbonPoolConfiguration) = poolAliases(typeof(configuration))

cFlowEdges(name::AbstractString) = cFlowEdges(Symbol(name))
cFlowEdges(name::Symbol) = cFlowEdges(carbonPoolConfiguration(name))
cFlowEdges(configuration::CarbonPoolConfiguration) = cFlowEdges(typeof(configuration))

fireCCTable(name::AbstractString) = fireCCTable(Symbol(name))
fireCCTable(name::Symbol) = fireCCTable(carbonPoolConfiguration(name))
fireCCTable(configuration::CarbonPoolConfiguration) = fireCCTable(typeof(configuration))

"""
    cFlowStructure(params::cCycleBase, cEco, helpers)

Resolve an approach's `cFlowEdges` against the pool structure the experiment actually
configured, returning the whole flow-vector description as
`(c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_qp_groups,
c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec)`, in the order the approaches pack it.

# Notes:
- A flow is an edge, so the taker and giver of flow `i` are just the two endpoints of
  edge `i` resolved to indices, and `c_flow_order` is `1:number of edges`. There is no
  transfer matrix in between: the old `c_flow_A_array` existed only to be walked back
  out by `findall`, and its one remaining reader, `cCycleConsistency_simple`, asks
  only whether a flow sits above or below the diagonal, which is `c_taker` against
  `c_giver`.
- All eight come from one call so they cannot disagree about how many flows there are
  or what order they sit in, which is what an approach rederiving each of them
  separately from a matrix left open. `pool_names` is `cEco_index => pool_name`
  pairs and `flow_edges` is `flow_order => (giver_name => taker_name)` pairs, one
  per flow -- readable, at-a-glance context for inspecting `land.cCycleBase` (e.g.
  what pool 3 or flow 5 actually is), not something any process matches against:
  every process matches by giver/taker pool-index membership or uses the
  flow-aligned taker turnover rank derived later in `cCycleBase.precompute`.
- `c_flow_A_vec`, `c_flow_QP_vec` and `c_flow_ME_vec` are neutral, one per flow, and
  are built here rather than in a `cFlow`, `cQualityPartition` or
  `cMicrobialEfficiency` approach for the same reason: their length and order are the
  topology's, so an approach building one had to reach for `c_taker` to re-measure
  what the base already knows. Those approaches fill in values; they no longer decide
  the shape. Allocating here also means the neutral value of one exists whenever the
  topology does, so `cCycle` reads a valid `c_flow_QP_vec` and `c_flow_ME_vec` even
  when no `cQualityPartition` or `cMicrobialEfficiency` model is selected at all.
- Sorted by `(giver, taker)`, which is the column-major order `findall` produced from
  the matrix and which `c_flow_A_vec`, `c_flow_QP_vec`, `c_flow_ME_vec` and the
  `d_cFlow` output dimension are all indexed by. Column-major means the giver is the
  column, so a flow matrix rebuilt from this is `[taker, giver]`; see `cFlowMatrix`. Sorting here rather than trusting the
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
    cEco_components = helpers.pools.components.cEco
    pool_names = ntuple(i -> i => cEco_components[i], length(cEco_components))
    flow_edges = ntuple(
        i -> c_flow_order[i] => (cEco_components[c_giver[i]] => cEco_components[c_taker[i]]),
        length(c_taker))
#=
    # TO SIMPLIFY
    c_flow_qp_groups = deriveQPGroups(c_giver, c_taker, cEco_components)
=#
    # Allocated here so the flow-aligned rank exists as soon as the topology does.
    # Its values depend on c_eco_k_base, which this function has no access to and
    # which only holds real turnover rates once an approach's own precompute has
    # run -- so precompute calls getTakerTurnoverRank itself to fill these in,
    # this function only sizes and zero-fills the vector.
    c_flow_taker_turnover_rank = getVectorOfType(cEco, length(c_taker), zero)
    c_flow_A_vec = getVectorOfType(cEco, length(c_taker), one)
    c_flow_QP_vec = getVectorOfType(cEco, length(c_taker), one)
    c_flow_ME_vec = getVectorOfType(cEco, length(c_taker), zero)

    return c_flow_order, c_taker, c_giver, pool_names, flow_edges, c_flow_taker_turnover_rank,
        c_flow_A_vec, c_flow_QP_vec, c_flow_ME_vec
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
              "known carbon pool name: no carbon pool configuration declares it. Correct the " *
              "edge, or declare the pool in a configuration's poolStructure.")
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
    getTakerTurnoverRank(
        c_flow_taker_turnover_rank,
        c_flow_order,
        c_giver,
        c_taker,
        c_eco_k_base,
        cVeg,
    )

Classify each carbon-flow taker by turnover relative to the other non-vegetation
taker of the same giver. The returned flow-aligned rank is:

- `1`: faster of two non-vegetation takers;
- `-1`: slower of two non-vegetation takers;
- `0`: the flow is not a two-taker quality partition (including flows to vegetation
  and givers with one non-vegetation taker).

Only non-vegetation takers participate in the count. For every giver that has a
non-vegetation taker, the number of non-vegetation takers must therefore be one or
two; more than two is an invalid quality-partition topology. Two takers with equal
base turnover rates are also invalid because their rank is undefined.

The destination vector is supplied by the caller and updated with `repElem`, so the
function does not construct per-giver collections or use `findall`, `unique`, or a
`Dict` in the ranking loop.
"""
function getTakerTurnoverRank(
        c_flow_taker_turnover_rank,
        c_flow_order,
        c_giver,
        c_taker,
        c_eco_k_base,
        cVeg,
    )

    # @inbounds # for efficiency over checks
    for fO ∈ c_flow_order
        taker = c_taker[fO]

        # TO SIMPLIFY QP does not rank transfers whose taker is vegetation.
        if taker ∈ cVeg
            c_flow_taker_turnover_rank = repElem(
                c_flow_taker_turnover_rank,
                zero(eltype(c_flow_taker_turnover_rank)),
                fO,
            )
            continue
        end

        # TO SIMPLIFY count # of takers and identify the other flow (to compare tau below)
        giver = c_giver[fO]
        nTakers = 0
        otherFlow = 0
        for j ∈ c_flow_order
            if c_giver[j] == giver && !(c_taker[j] ∈ cVeg)
                nTakers += 1
                j != fO && (otherFlow = j)
            end
        end
        
        # TO SIMPLIFY 
        if nTakers == 1
            turnoverRank = zero(eltype(c_flow_taker_turnover_rank))
        elseif nTakers == 2
            kTaker = c_eco_k_base[taker]
            kOtherTaker = c_eco_k_base[c_taker[otherFlow]]
            # TO SIMPLIFY the fastest?
            if kTaker > kOtherTaker
                turnoverRank = one(eltype(c_flow_taker_turnover_rank))
            elseif kTaker < kOtherTaker
                turnoverRank = -one(eltype(c_flow_taker_turnover_rank))
            else
                # TO SIMPLIFY this can be done more informative
                error("Cannot rank two non-vegetation takers with identical base turnover rates.") 
            end
        else
            # TO SIMPLIFY this can be done more informative
            error(
                "Carbon quality partition requires one or two non-vegetation takers per giver; " *
                "found $(nTakers) for giver index $(giver).",
            )
        end

        c_flow_taker_turnover_rank = repElem(
            c_flow_taker_turnover_rank,
            turnoverRank,
            fO,
        )
    end

    return c_flow_taker_turnover_rank
end

#= TO SIMPLIFY OLD name-derived QP grouping retained for reference; turnover rank is now used.
"""
    deriveQPGroups(c_giver, c_taker, cEco_components)

Derive the `cQualityPartition` giver/taker split groups directly from the resolved
flow topology, by pool-naming convention, rather than from a per-configuration table
of edge names. Returns `(; cVeg, cLit = (; structural, wood), cMic, cSoil)`, each a tuple
of `(fraction_positions, complement_positions)` pairs (one pair per giver that
actually has a matching split in this structure's topology).

# Rules
- `cVeg`: a giver whose own name starts with `cVeg` and whose outgoing edges include a
  taker pair sharing a base name suffixed `Fast`/`Slow` (e.g. `cLitLeafFast`/
  `cLitLeafSlow`, both reached from `cVegLeaf`) is a metabolic/structural litterfall
  split. The `Fast` taker's positions are `fraction_positions`, the `Slow` taker's are
  `complement_positions`.
- `cLit`: a giver whose own name starts with `cLit` and whose outgoing edges include
  both a `cSoil`-prefixed taker and a `cMic`-prefixed taker is a lignin-controlled
  stabilization split. The `cSoil`-prefixed positions are `fraction_positions`, the
  `cMic`-prefixed positions are `complement_positions`. Filed under `wood` if the
  giver's name contains `Wood` or `RootCoarse`, `struct` otherwise.
- `cMic`/`cSoil`: the giver named exactly `cMicSoil`/`cSoilSlow`, only when it has more
  than one outgoing edge and one of them reaches `cSoilOld`. The `cSoilOld` positions
  are `fraction_positions`, every other outgoing edge's positions are
  `complement_positions`.

The `cVeg`/`cLit` name-prefix restrictions and the `cMic`/`cSoil` more-than-one-edge
requirement are not cosmetic: without them, a giver like `cSoilSlow` (taker set
`cMicSoil`/`cSoilOld`, i.e. one `cMic`-prefixed and one `cSoil`-prefixed taker) would
also match the `cLit` rule, and a single-outflow `cSoilSlow` (as in `GSI`,
which has no `cMicSoil` pool) would match the `cSoil` rule on its lone edge to
`cSoilOld` with no complementary edge to divide against -- silently replacing that
edge's neutral partition of one with a fraction meant for an actual two-way split.

A structure with no matching pattern for a given field (e.g. `GSI`, whose
litter and soil pools aren't split by quality) resolves that field to `()`; no
per-configuration declaration is needed for that to happen correctly.
"""
function deriveQPGroups(c_giver, c_taker, cEco_components)
    by_giver = Dict{Symbol,Dict{Symbol,Vector{Int}}}()
    for flow ∈ eachindex(c_giver, c_taker)
        giver_name = cEco_components[c_giver[flow]]
        taker_name = cEco_components[c_taker[flow]]
        takers = get!(by_giver, giver_name, Dict{Symbol,Vector{Int}}())
        push!(get!(takers, taker_name, Int[]), flow)
    end

    QPGroup = Tuple{Tuple{Vararg{Int}},Tuple{Vararg{Int}}}
    cVeg = QPGroup[]
    cLit_struct = QPGroup[]
    cLit_wood = QPGroup[]
    cMic = QPGroup[]
    cSoil = QPGroup[]

    for (giver_name, takers) ∈ by_giver
        giver_str = String(giver_name)
        if startswith(giver_str, "cVeg")
            for taker_name ∈ keys(takers)
                taker_str = String(taker_name)
                endswith(taker_str, "Fast") || continue
                slow_name = Symbol(taker_str[1:(end - 4)] * "Slow")
                haskey(takers, slow_name) || continue
                push!(cVeg, (Tuple(takers[taker_name]), Tuple(takers[slow_name])))
            end
        elseif startswith(giver_str, "cLit")
            soil_positions = Int[]
            mic_positions = Int[]
            for (taker_name, positions) ∈ takers
                taker_str = String(taker_name)
                if startswith(taker_str, "cSoil")
                    append!(soil_positions, positions)
                elseif startswith(taker_str, "cMic")
                    append!(mic_positions, positions)
                end
            end
            if !isempty(soil_positions) && !isempty(mic_positions)
                target = (occursin("Wood", giver_str) || occursin("RootCoarse", giver_str)) ?
                          cLit_wood : cLit_struct
                push!(target, (Tuple(soil_positions), Tuple(mic_positions)))
            end
        elseif giver_name === :cMicSoil || giver_name === :cSoilSlow
            n_out = sum(length, values(takers))
            if n_out > 1 && haskey(takers, :cSoilOld)
                fraction_positions = Tuple(takers[:cSoilOld])
                complement_positions = Tuple(
                    position for (taker_name, positions) ∈ takers if taker_name !== :cSoilOld
                    for position ∈ positions
                )
                target = giver_name === :cMicSoil ? cMic : cSoil
                push!(target, (fraction_positions, complement_positions))
            end
        end
    end

    return (;
        cVeg = Tuple(cVeg),
        cLit = (; structural = Tuple(cLit_struct), wood = Tuple(cLit_wood)),
        cMic = Tuple(cMic),
        cSoil = Tuple(cSoil),
    )
end

=#

"""
    getKfromTau(c_eco, table, scalar, helpers)

Multiply each pool in `table` (a per-pool-name `NamedTuple` mapping to a turnover
*time*, e.g. `GSI_TAU_DEFAULT`/`CASA_TAU_NON_VEG_POOLS`) by `one(T) / T(value) * scalar`, `T` being
`eltype(c_eco)`, writing the result into `c_eco` at that pool's `cEco` index via
`repElem`, and return the updated `c_eco`. `scalar` is either one value applied to
every pool (`cCycleBase_CASA`'s single `k_c_scalar`) or a per-pool-name `NamedTuple`
with the same keys as `table` (`cCycleBase_GSI`'s `k_c_scalars`, one shared scalar
per compartment/pool group), dispatched on `scalar`'s type.

# Notes:
- The explicit `T(value)` conversion is not cosmetic: `table`'s entries are `Float64`
  literals (`GSI_TAU_DEFAULT`/`CASA_TAU_NON_VEG_POOLS` are defined once, independent of any
  approach's working precision), but `c_eco` and `scalar` are typically `Float32` in
  a model configured that way. Without converting, `one(turnover_time) /
  turnover_time` (an untouched `Float64`) times a `Float32` `scalar` promotes to
  `Float64`, and writing that into an `SVector{N,Float32}` via `repElem` silently
  upgrades the *whole array* to `Float64` on the very first loop iteration -- so the
  loop's accumulator has one type on iteration 1 and another from iteration 2 on,
  which Julia's inference reports as this function returning
  `Union{SVector{N,Float32}, SVector{N,Float64}}`, not a concrete type. Converting
  `table`'s value to `eltype(c_eco)` up front keeps every iteration in the same
  precision as the array being built, closing that union.
- Exists as its own function, not inlined into each approach's `precompute`, so a
  type instability in this loop (present or future) cannot silently widen the whole
  `land` structure `precompute` returns -- inference failing here fails loudly on
  this function's own, much smaller signature instead. This also keeps the
  table-driven loop itself out of `precompute`'s already substantial body (unpacking
  a dozen struct fields, unpacking and repacking several `land` namespaces), rather
  than adding to it.
- Used identically by `cCycleBase_GSI`, `cCycleBase_GSI_PlantForm`,
  `cCycleBase_MGMT ` (`c_eco_τ`, per-pool `k_c_scalars`) and
  `cCycleBase_CASA` (`c_eco_k_base`, the single `k_c_scalar`) -- the target array's
  name and whether the scalar varies by pool differ by approach, the loop does not.
"""
function getKfromTau(c_eco, table, scalar::Real, helpers)
    T = eltype(c_eco)
    for (pool_name, turnover_time) in pairs(table)
        for ix in getproperty(helpers.pools.zix, pool_name)
            tmp = (one(T) / T(turnover_time)) * scalar
            c_eco = repElem(c_eco, tmp, ix)
        end
    end
    return c_eco
end
function getKfromTau(c_eco, table, scalar_for::NamedTuple, helpers)
    T = eltype(c_eco)
    for (pool_name, turnover_time) in pairs(table)
        scalar = getproperty(scalar_for, pool_name)
        for ix in getproperty(helpers.pools.zix, pool_name)
            tmp = (one(T) / T(turnover_time)) * scalar
            c_eco = repElem(c_eco, tmp, ix)
        end
    end
    return c_eco
end

"""
    getCNfromParams(CN_ratio_cVeg, table, cn_scalar, helpers)

Same idea as `getKfromTau`, for the vegetation carbon-to-nitrogen ratio: multiplies
each `table` (`GSI_CN_ratio`/`CASA_CN_ratio`) entry by `cn_scalar` directly, no
turnover-time inversion, writing into `CN_ratio_cVeg`. Every `cCycleBase` approach
applies one shared `CN_ratio_scalar` across all pools, so unlike `getKfromTau` this
has only the single-scalar form. Kept as its own function, separate from
`getKfromTau`, since the two write different target arrays for a different
physical quantity even though the loop shape matches -- but for the same
type-stability reason (see `getKfromTau`'s notes), it must remain its own function
barrier rather than get inlined into `precompute`.
"""
function getCNfromParams(CN_ratio_cVeg, table, cn_scalar, helpers)
    T = eltype(CN_ratio_cVeg)
    for (pool_name, CN_ratio) in pairs(table)
        for ix in getproperty(helpers.pools.zix, pool_name)
            tmp = T(CN_ratio) * cn_scalar
            CN_ratio_cVeg = repElem(CN_ratio_cVeg, tmp, ix)
        end
    end
    return CN_ratio_cVeg
end

"""
    getFireCCFromParams(c_fire_ccMin, c_fire_ccMax, table, scalar, helpers)

Same idea as `getKfromTau`/`getCNfromParams`, but scattering a two-component
`(ccMin, ccMax)` pair per pool instead of a single scalar -- `table`'s
entries are `(ccMin, ccMax, weight)` triples (`CASA_FIRE_CC_VANDERWERF`/
`GSI_FIRE_CC_VANDERWERF`, resolved for the active configuration via
`fireCCTable`); `weight`, a reserved autoregressive filter weight, is
intentionally not read here. Both components are scaled by the same shared
`scalar` and written into `c_fire_ccMin`/`c_fire_ccMax` via `repElem`.
"""
function getFireCCFromParams(c_fire_ccMin, c_fire_ccMax, table, scalar, helpers)
    Tmin = eltype(c_fire_ccMin)
    Tmax = eltype(c_fire_ccMax)
    for (pool_name, cc) in pairs(table)
        cc_min, cc_max, _ = cc
        for ix in getproperty(helpers.pools.zix, pool_name)
            c_fire_ccMin = repElem(c_fire_ccMin, Tmin(cc_min) * scalar, ix)
            c_fire_ccMax = repElem(c_fire_ccMax, Tmax(cc_max) * scalar, ix)
        end
    end
    return c_fire_ccMin, c_fire_ccMax
end

"""
    deriveFireCCTable(fine_table, coarse_pool_names, fine_configuration)

Build a coarser pool-name-keyed fire combustion completeness table from a
finer one. For each name in `coarse_pool_names`: a name `fine_table` already
has directly is passed through unchanged; a name declared in
`poolAliases(fine_configuration)` is averaged over its constituent pools --
the same "average over however many targets this entry names" rule
`getParamsPerVegType` uses for vegetation classifications, applied along the
pool-name axis instead. A name that is neither is left out of the result and
must be supplied independently afterward.
"""
function deriveFireCCTable(fine_table, coarse_pool_names, fine_configuration)
    aliases = poolAliases(fine_configuration)
    names = Symbol[]
    vals = []
    for coarse_name in coarse_pool_names
        if hasproperty(fine_table, coarse_name)
            push!(names, coarse_name)
            push!(vals, getproperty(fine_table, coarse_name))
        elseif hasproperty(aliases, coarse_name)
            components = [getproperty(fine_table, n) for n in getproperty(aliases, coarse_name)]
            push!(names, coarse_name)
            push!(vals, ntuple(i -> sum(c[i] for c in components) / length(components), length(first(components))))
        end
    end
    return NamedTuple{Tuple(names)}(Tuple(vals))
end

# One file per pool structure, listed rather than globbed so only files meant to load
# do. New structure: add the file, add it here. Included last, so the supertype and the
# defaults above are already defined.
include("GSI.jl")
include("MGMT.jl")
include("CASA.jl")
