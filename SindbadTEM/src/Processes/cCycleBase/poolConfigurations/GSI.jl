export GSI

struct GSI <: CarbonPoolConfiguration end
purpose(::Type{GSI}) = "GSI carbon pools: 8 pools with a vegetation reserve and litter split into fast and slow"

"""
    poolStructure(::Type{GSI})

Eight pools: vegetation split into root, wood, leaf and reserve, litter split by
quality into fast and slow, and soil into slow and old. Shaped like the `pools`
block of a model structure JSON; each leaf is `(number of layers, initial
value)`. Litter is already nested by quality, so `cLitFast`/`cLitSlow` are
generated directly and this configuration needs no `poolAliases`.
"""
poolStructure(::Type{GSI}) = (;
    combine = :cEco,
    components = (;
        cVeg  = (; Root = (1, 25.0), Wood = (1, 25.0), Leaf = (1, 25.0), Reserve = (1, 10.0)),
        cLit  = (; Fast = (1, 100.0), Slow = (1, 250.0)),
        cSoil = (; Slow = (1, 500.0), Old = (1, 1000.0)),
    ),
)

"""
    GSI_FLOW_EDGES

The 11 edges shared by `cCycleBase_GSI`, `_GSI_PlantForm`, and `_MGMT` (whose
products are decay-only and add no edges). See `cFlowEdges` for the ordering
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

cFlowEdges(::Type{GSI}) = GSI_FLOW_EDGES

"""
    GSI_TAU_DEFAULT

Turnover time (years) of each GSI carbon pool. `k = 1.0/turnover_time` is
computed at the point of use; fixed data, not a parameter.

Only `cLitFast`/`cLitSlow`/`cSoilSlow`/`cSoilOld`/`cVegReserve` are read from
this table directly, since none vary by vegetation type. `cVegRoot`,
`cVegWood`, and `cVegLeaf` are looked up instead at runtime from
`CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`/
`CVEG_LEAF_AGE_PER_VEGTYPE` (`ParamsForVegClasses.jl`) by
`land.states.veg_type_name`; this table's entries for those three pools are
kept only as a historical record of the pre-refactor defaults.
"""
const GSI_TAU_DEFAULT = (;
    cVegRoot = 1.0, cVegWood = 50.0, cVegLeaf = 1.0, cVegReserve = TAU_DORMANT,
    cLitFast = 1.0/14.8, cLitSlow = 1.0/3.9, cSoilSlow = 5.0, cSoilOld = 222.2,
)

"""
    GSI_CN_ratio

Carbon-to-nitrogen ratio of each GSI carbon pool, per pool name. Fixed data,
not a parameter; calibration happens through `CN_ratio_scalar` in the owning
approach instead. Only the four vegetation pools have a physically meaningful
ratio; every other pool is `0.0`.
"""
const GSI_CN_ratio = (;
    cVegRoot = 25.0, cVegWood = 260.0, cVegLeaf = 25.0, cVegReserve = 50.0,
    cLitFast = 0.0, cLitSlow = 0.0, cSoilSlow = 0.0, cSoilOld = 0.0,
)

const GSI_POOL_NAMES = propertynames(GSI_TAU_DEFAULT)

"""
    fireCCTable(::Type{GSI})

Derived from `CASA_FIRE_CC_VANDERWERF` (`poolConfigurations/CASA.jl`) via
`deriveFireCCTable`. `cVegRoot` and `cVegReserve`, which `deriveFireCCTable`
cannot resolve from CASA's names or aliases, are merged in afterward.

Defined as a method body rather than a top-level `const` since `GSI.jl` loads
before `CASA.jl`, and a method body's global references resolve at call time.
"""
function fireCCTable(::Type{GSI})
    return merge(
        deriveFireCCTable(CASA_FIRE_CC_VANDERWERF, GSI_POOL_NAMES, CASA),
        (;
            cVegRoot = FIRE_CC_NO_BURN,           # CASA generates cVegRoot from Root.{Fine,Coarse} nesting, not a poolAlias
            cVegReserve = (0.2f0, 0.3f0, 1.0f0),  # no CASA counterpart at all; matches cVegWood's value, same as the old cc_lut's cVegReserve => fcc_stem mapping
        ),
    )
end
