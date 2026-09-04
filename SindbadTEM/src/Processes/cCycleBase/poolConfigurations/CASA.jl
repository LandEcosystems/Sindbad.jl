export CarbonPoolsCASA

struct CarbonPoolsCASA <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsCASA}) = "CASA carbon pools: 14 pools, vegetation split into fine and coarse roots and litter nested by organ"

"""
    poolStructure(::Type{CarbonPoolsCASA})

Fourteen pools on a nested layout: roots split into fine and coarse, litter nested by
organ and then by quality, and an explicit microbial component.

# Notes:
- The nesting generates `cVegRoot`, `cLitLeaf`, `cLitRoot` and `cLitRootFine` without
  declaring them, giving a `cEco` of `cVegRootFine`, `cVegRootCoarse`, `cVegWood`,
  `cVegLeaf`, `cLitLeafFast`, `cLitLeafSlow`, `cLitRootFineFast`,
  `cLitRootFineSlow`, `cLitRootCoarse`, `cLitWood`, `cMicSurf`, `cMicSoil`,
  `cSoilSlow`, `cSoilOld`.
- Fine-root litter carries the quality split and coarse-root litter does not, so
  `cLitRoot` nests one level deeper than the other organs.
- Litter nests by organ, so the fast/slow quality split cuts across the hierarchy and
  cannot be a nesting level. It is declared as `poolAliases` instead, the only
  configuration that needs any.
- See `poolStructure(::Type{CarbonPoolsGSI})` for the shape and ordering rules that
  apply to every structure.
"""
poolStructure(::Type{CarbonPoolsCASA}) = (;
    combine = :cEco,
    components = (;
        cVeg  = (; Root = (; Fine = (1, 25.0), Coarse = (1, 25.0)),
                   Wood = (1, 25.0), Leaf = (1, 25.0)),
        cLit  = (; Leaf = (; Fast = (1, 25.0), Slow = (1, 25.0)),
                   Root = (; Fine = 
                                (; Fast = (1, 25.0), Slow = (1, 25.0)),
                             Coarse = (1, 25.0)),
                   Wood = (1, 100.0)),
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
    cLitFast = (:cLitLeafFast, :cLitRootFineFast),                            # -> (5, 7)
    cLitSlow = (:cLitLeafSlow, :cLitRootFineSlow, :cLitRootCoarse, :cLitWood), # -> (6, 8, 9, 10)
)

"""
    CASA_FLOW_EDGES

The 22 edges of `cCycleBase_CASA`, transcribed from its 14x14 `c_flow_A_array`.
The pool names differ from the ones that matrix was written in, and so does the index
order, which a name-keyed edge list does not care about: the edges are the same 22
links.

Lives here rather than with the approaches because every name in it is a pool of this
structure and the list resolves against no other. See `cFlowEdges` for the ordering
convention and why edges must name leaf pools.
"""
const CASA_FLOW_EDGES = (                    # giver => taker, in flow-vector order
    :cVegRootFine     => :cLitRootFineFast,                                  # giver 1
    :cVegRootFine     => :cLitRootFineSlow,
    :cVegRootCoarse   => :cLitRootCoarse,                                    # giver 2
    :cVegWood         => :cLitWood,                                          # giver 3
    :cVegLeaf         => :cLitLeafFast,     :cVegLeaf         => :cLitLeafSlow,   # giver 4
    :cLitLeafFast     => :cMicSurf,                                          # giver 5
    :cLitLeafSlow     => :cMicSurf,         :cLitLeafSlow     => :cSoilSlow,  # giver 6
    :cLitRootFineFast => :cMicSoil,                                          # giver 7
    :cLitRootFineSlow => :cMicSoil,         :cLitRootFineSlow => :cSoilSlow,  # giver 8
    :cLitRootCoarse   => :cMicSoil,         :cLitRootCoarse   => :cSoilSlow,  # giver 9
    :cLitWood         => :cMicSurf,         :cLitWood         => :cSoilSlow,  # giver 10
    :cMicSurf         => :cSoilSlow,                                         # giver 11
    :cMicSoil         => :cSoilSlow,        :cMicSoil         => :cSoilOld,   # giver 12
    :cSoilSlow        => :cMicSoil,         :cSoilSlow        => :cSoilOld,   # giver 13
    :cSoilOld         => :cMicSoil,                                          # giver 14
)
