export CarbonPoolsGSI

struct CarbonPoolsGSI <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsGSI}) = "GSI carbon pools: 8 pools with a vegetation reserve and litter split into fast and slow"

"""
    poolStructure(::Type{CarbonPoolsGSI})

Eight pools: vegetation split into root, wood, leaf and reserve, litter split by
quality into fast and slow, and soil into slow and old.

# Notes:
- Shaped exactly like the `pools` block of a model structure JSON, so `setPoolsInfo`
  consumes either source with no reshaping.
- Declaration order is `cEco` index order: `getPoolInformation` flattens depth first,
  in declaration order.
- Each leaf is `(number of layers, initial value)`.
- Every nesting level also becomes a real pool, with its own `zix` entry and backing
  array, so `cVeg`, `cLit` and `cSoil` exist without being declared.
- Litter is nested by quality here, so `cLitFast` and `cLitSlow` are generated
  directly and this configuration needs no `poolAliases`.
"""
poolStructure(::Type{CarbonPoolsGSI}) = (;
    combine = :cEco,
    components = (;
        cVeg  = (; Root = (1, 25.0), Wood = (1, 25.0), Leaf = (1, 25.0), Reserve = (1, 10.0)),
        cLit  = (; Fast = (1, 100.0), Slow = (1, 250.0)),
        cSoil = (; Slow = (1, 500.0), Old = (1, 1000.0)),
    ),
)

"""
    GSI_FLOW_EDGES

The 11 edges shared by every GSI-derived base. Transcribed from the `c_flow_A_array`
those approaches carried, which is identical across `cCycleBase_GSI` and
`_GSI_PlantForm`, and the same 11 under `_GSI_PlantForm_MGMT`, whose products are
decay only and so add no edges.

Lives here rather than with the approaches because every name in it is a pool of this
structure and the list resolves against no other. See `cFlowEdges` for the ordering
convention and why edges must name leaf pools.
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
