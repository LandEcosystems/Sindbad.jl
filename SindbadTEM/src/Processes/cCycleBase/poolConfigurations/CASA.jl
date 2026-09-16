export CASA
export FIRE_CC_NO_BURN
export FIRE_CC_HIGH_BURN

struct CASA <: CarbonPoolConfiguration end
purpose(::Type{CASA}) = "CASA carbon pools: 14 pools, vegetation split into fine and coarse roots and litter nested by compartment"

"""
    poolStructure(::Type{CASA})

Fourteen pools on a nested layout: roots split into fine and coarse, litter
nested by compartment and then by quality, and an explicit microbial
component. `cEco` is `cVegRootFine`, `cVegRootCoarse`, `cVegWood`, `cVegLeaf`,
`cLitLeafFast`, `cLitLeafSlow`, `cLitRootFineFast`, `cLitRootFineSlow`,
`cLitRootCoarse`, `cLitWood`, `cMicSurf`, `cMicSoil`, `cSoilSlow`, `cSoilOld`.

Fine-root litter carries the quality split and coarse-root litter does not,
so `cLitRoot` nests one level deeper than the other compartments. The
fast/slow quality split on the other compartments cuts across this hierarchy
and is declared as `poolAliases` instead, the only configuration that needs
any. See `poolStructure(::Type{GSI})` for the shape and ordering rules that
apply to every structure.
"""
poolStructure(::Type{CASA}) = (;
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
    poolAliases(::Type{CASA})

The fast/slow litter grouping, which this structure's nesting cannot produce
since litter nests by compartment while the fast/slow axis is quality. An
alias has no backing array in `land.pools`, so models must iterate
`helpers.pools.zix.X` for these names rather than reach into `land.pools.X`.
"""
poolAliases(::Type{CASA}) = (;
    cLitFast = (:cLitLeafFast, :cLitRootFineFast),                            # -> (5, 7)
    cLitSlow = (:cLitLeafSlow, :cLitRootFineSlow, :cLitRootCoarse, :cLitWood), # -> (6, 8, 9, 10)
)

"""
    CASA_FLOW_EDGES

The 22 edges of `cCycleBase_CASA`. See `cFlowEdges` for the ordering
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

cFlowEdges(::Type{CASA}) = CASA_FLOW_EDGES

"""
    CASA_TAU_NON_VEG_POOLS

Turnover time (years) of every CASA carbon pool except the four
vegetation-compartment pools (`cVegRootFine`, `cVegRootCoarse`, `cVegWood`,
`cVegLeaf`), per pool name. `k = 1.0/value` is computed at the point of use;
fixed data, not a parameter, since calibration happens through `k_c_scalar` in
`cCycleBase_CASA` instead.

The four vegetation-compartment pools are looked up instead at runtime from
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_LEAF_AGE_PER_VEGTYPE`/
`CVEG_ROOTCOARSE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`
(`ParamsForVegClasses.jl`) by `land.states.veg_type_name`, in
`cCycleBase_CASA`'s `precompute`.
"""
const CASA_TAU_NON_VEG_POOLS = (;
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

Carbon-to-nitrogen ratio of each CASA carbon pool, per pool name. Fixed data,
not a parameter; calibration happens through `CN_ratio_scalar` in
`cCycleBase_CASA` instead. Only the four vegetation pools have a physically
meaningful ratio; every other pool is `0.0`.
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
"""
    FIRE_CC_NO_BURN, FIRE_CC_HIGH_BURN

Shared `(ccMin, ccMax, weight)` fire combustion-completeness triples: pools
that essentially never burn (`FIRE_CC_NO_BURN`, `ccMin = ccMax = 0`) and
pools that burn almost completely once fire reaches them
(`FIRE_CC_HIGH_BURN`). `weight` is a reserved autoregressive filter weight,
not yet consumed by any approach.
"""
const FIRE_CC_NO_BURN = (0.0f0, 0.0f0, 1.0f0)
const FIRE_CC_HIGH_BURN = (0.9f0, 1.0f0, 0.9f0)

"""
    CASA_FIRE_CC_VANDERWERF

Van der Werf et al. (2006) fire combustion completeness, `(ccMin, ccMax,
weight)` triples (see `FIRE_CC_NO_BURN`/`FIRE_CC_HIGH_BURN`) per CASA pool
name. Fixed data, not a parameter; calibration happens through
`fire_cc_scalar` in `cFireCombustionCompleteness_vanDerWerf2006` instead.

Root pools and every fine litter/soil pool downstream of them do not burn;
leaf and its litter, wood and its litter, and the surface microbial pool do.
"""
const CASA_FIRE_CC_VANDERWERF = (;
    cVegRootFine = FIRE_CC_NO_BURN,
    cVegRootCoarse = FIRE_CC_NO_BURN,
    cVegWood = (0.2f0, 0.3f0, 1.0f0),
    cVegLeaf = (0.8f0, 1.0f0, 1.0f0),
    cLitLeafFast = FIRE_CC_HIGH_BURN,
    cLitLeafSlow = FIRE_CC_HIGH_BURN,
    cLitRootFineFast = FIRE_CC_NO_BURN,
    cLitRootFineSlow = FIRE_CC_NO_BURN,
    cLitRootCoarse = FIRE_CC_NO_BURN,
    cLitWood = (0.5f0, 0.6f0, 0.6f0),
    cMicSurf = FIRE_CC_HIGH_BURN,
    cMicSoil = FIRE_CC_NO_BURN,
    cSoilSlow = FIRE_CC_NO_BURN,
    cSoilOld = FIRE_CC_NO_BURN,   # old soil does not burn
)

fireCCTable(::Type{CASA}) = CASA_FIRE_CC_VANDERWERF