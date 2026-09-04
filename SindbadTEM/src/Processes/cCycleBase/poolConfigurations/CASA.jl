export CarbonPoolsCASA

struct CarbonPoolsCASA <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsCASA}) = "CASA carbon pools: 14 pools, vegetation split into fine and coarse roots and litter nested by organ"

"""
    poolStructure(::Type{CarbonPoolsCASA})

Fourteen pools on a two-level layout: roots split into fine and coarse, litter nested
by organ and then by quality, and an explicit microbial component.

# Notes:
- The nesting generates `cVegRoot`, `cLitLeaf` and `cLitRoot` without declaring them,
  giving a `cEco` of `cVegRootF`, `cVegRootC`, `cVegWood`, `cVegLeaf`, `cLitLeafM`,
  `cLitLeafS`, `cLitWood`, `cLitRootFM`, `cLitRootFS`, `cLitRootC`, `cMicSurf`,
  `cMicSoil`, `cSoilSlow`, `cSoilOld`.
- Litter nests by organ, so the fast/slow quality split cuts across the hierarchy and
  cannot be a nesting level. It is declared as `poolAliases` instead, the only
  configuration that needs any.
- See `poolStructure(::Type{CarbonPoolsGSI})` for the shape and ordering rules that
  apply to every structure.
"""
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

The fast/slow litter grouping, which this structure's nesting cannot produce.

# Notes:
- CASA litter is nested by organ, while the fast/slow axis is quality, so that split
  cannot be a nesting level. These two entries are the only groupings in any
  configuration that cut across the hierarchy.
- An alias has no backing array in `land.pools`, so models must iterate
  `helpers.pools.zix.X` for these names rather than reach into `land.pools.X`.
"""
poolAliases(::Type{CarbonPoolsCASA}) = (;
    cLitFast = (:cLitLeafM, :cLitRootFM),                          # -> (5, 8)
    cLitSlow = (:cLitLeafS, :cLitWood, :cLitRootFS, :cLitRootC),   # -> (6, 7, 9, 10)
)

"""
    CASA_FLOW_EDGES

The 22 edges of `cCycleBase_CASA`, transcribed from its 14x14 `c_flow_A_array`.
Keeping the `RootFM`/`RootFS` leaf names means every name here matches that matrix;
only the index order shifts under the nested structure (`cLitWood` moves from 9 to
7), which a name-keyed edge list does not care about.

Lives here rather than with the approaches because every name in it is a pool of this
structure and the list resolves against no other. See `cFlowEdges` for the ordering
convention and why edges must name leaf pools.
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
