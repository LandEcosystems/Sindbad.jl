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

"""
    CASA_TAU

Turnover *time* (years) of every CASA carbon pool except the four vegetation-organ
pools (`cVegRootFine`, `cVegRootCoarse`, `cVegWood`, `cVegLeaf`), per pool name.
`k = 1.0/value` is computed at the point of use; fixed data, not a parameter --
calibration happens through `k_c_scalar` in `cCycleBase_CASA` instead, since
array-valued struct fields cannot be optimized.

The four vegetation-organ pools are not here: their turnover now varies by
`land.states.veg_type_name` at runtime, looked up from
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE`/
`CVEG_ROOTCOARSE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`
(`ParamsForVegClasses.jl`) in `cCycleBase_CASA`'s `precompute`, rather than from one
fixed value shared by every vegetation type. See that file's docstrings and
`cCycleBase_CASA.jl`'s own extended help for the mechanics.

Formerly `CASA_ANNK`, which stored the rate `k` directly (values `[1, 0.03, 0.03, 1,
14.8, 3.9, 18.5, 4.8, 0.2424, 0.2424, 6, 7.3, 0.2, 0.0045]`, in the pool order
`poolStructure(CarbonPoolsCASA)` declares). Renamed and re-expressed as time
(`1.0/k`) since turnover time in years is the more legible representation, and
matches what the `c_τ_`-prefixed GSI fields already secretly stored (a time,
immediately inverted) before this session's centralization.

**Formatting convention** (matches `GSI_TAU_DEFAULT`, `poolConfigurations/GSI.jl`):
a plain decimal, rounded to one decimal place, when the turnover time is `>= 1`;
`1.0/N` (`N` the exact original rate, unrounded) when it is `< 1`.
`cLitRootCoarse`/`cLitWood` (`1.0/0.2424 = 4.125412541254125`, rounded to `4.1`)
and `cSoilOld` (`1.0/0.0045 = 222.22222222222223`, rounded to `222.2`) are each a
deliberate, if small, change to the resulting rate for readability (respectively
about `0.6%` and `0.01%` off the original), not merely a representation change.
`cSoilSlow`'s reciprocal (`1.0/0.2 = 5.0`) already rounds to the same value, so it
is unaffected.
"""
const CASA_TAU = (;
    cLitLeafFast = 1.0/14.8,
    cLitLeafSlow = 1.0/3.9,
    cLitRootFineFast = 1.0/18.5,
    cLitRootFineSlow = 1.0/4.8,
    cLitRootCoarse = 4.1,
    cLitWood = 4.1,
    cMicSurf = 1.0/6.0,
    cMicSoil = 1.0/7.3,
    cSoilSlow = 5.0,
    cSoilOld = 222.2,
)

"""
    CASA_CN_ratio

Carbon-to-nitrogen ratio of each CASA carbon pool, per pool name. Fixed data, not a
parameter -- calibration happens through `CN_ratio_scalar` in `cCycleBase_CASA`
instead. Only the four vegetation pools have a physically meaningful ratio; every
other pool is `0.0`, exactly as `p_C_to_N_cVeg` (the vector field this replaces) was
never read for any pool other than `cVeg`'s.
"""
const CASA_CN_ratio = (;
    cVegRootFine = 25.0,
    cVegRootCoarse = 260.0,
    cVegWood = 260.0,
    cVegLeaf = 25.0,
    cLitLeafFast = 0.0,
    cLitLeafSlow = 0.0,
    cLitRootFineFast = 0.0,
    cLitRootFineSlow = 0.0,
    cLitRootCoarse = 0.0,
    cLitWood = 0.0,
    cMicSurf = 0.0,
    cMicSoil = 0.0,
    cSoilSlow = 0.0,
    cSoilOld = 0.0,
)
