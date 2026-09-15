export GSI

struct GSI <: CarbonPoolConfiguration end
purpose(::Type{GSI}) = "GSI carbon pools: 8 pools with a vegetation reserve and litter split into fast and slow"

"""
    poolStructure(::Type{GSI})

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

The 11 edges shared by every GSI-derived base. Transcribed from the `c_flow_A_array`
those approaches carried, which is identical across `cCycleBase_GSI` and
`_GSI_PlantForm`, and the same 11 under `_MGMT `, whose products are
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

cFlowEdges(::Type{GSI}) = GSI_FLOW_EDGES

"""
    GSI_TAU_DEFAULT

Turnover *time* (years) of each GSI carbon pool. `k = 1.0/turnover_time` is
computed at the point of use; fixed data, not a parameter.

Only `cLitFast`/`cLitSlow`/`cSoilSlow`/`cSoilOld`/`cVegReserve` are read from this
table directly any more -- none of them vary by vegetation type. The three
vegetation-compartment pools that do (`cVegRoot`, `cVegWood`, `cVegLeaf`) are no longer
read from here: every GSI-family `cCycleBase` approach
(`cCycleBase_GSI`/`_GSI_PlantForm`/`_MGMT `) now looks their turnover
up at runtime from `CVEG_ROOTFINE_AGE_PER_VEGTYPE`/`CVEG_WOOD_AGE_PER_VEGTYPE`/
`CVEG_LEAF_AGE_PER_VEGTYPE` (`ParamsForVegClasses.jl`), re-keyed onto the
experiment's active `vegClass` classification and looked up by
`land.states.veg_type_name`, exactly like `vegQualityTraits_vegType.jl` already does
for litter chemistry. This table's own `cVegRoot`/`cVegWood`/`cVegLeaf` entries
are kept only as a historical record of the pre-refactor "tree" defaults.

The four vegetation-compartment values (`cVegRoot`, `cVegWood`, `cVegLeaf`,
`cVegReserve`) are exactly what `cCycleBase_GSI_PlantForm`'s `c_τ_tree` field
defaulted to before this table existed (already time-valued, no conversion
needed); the litter/soil values are converted from the rate these pools were
previously given directly (`14.8, 3.9, 0.2, 0.0045`) to time (`1.0/value`).

**Formatting convention**: an entry is written as a plain decimal, rounded to
one decimal place, when the turnover *time* itself is `>= 1`, and as `1.0/N`
(`N` the exact original rate, unrounded) when it is `< 1`. `cSoilSlow`'s
reciprocal (`1.0/0.2 = 5.0`) rounds to the same value, so it is unaffected, but
`cSoilOld`'s (`1.0/0.0045 = 222.22222222222223`) is rounded to `222.2` for
readability -- a deliberate, if small, change to the resulting rate (`1/222.2
≈ 0.0045005` vs the original `0.0045`, about `0.01%`), not merely a
representation change, since a plain decimal is being chosen over the exact
reciprocal on purpose.
"""
const GSI_TAU_DEFAULT = (;
    cVegRoot = 1.0, cVegWood = 50.0, cVegLeaf = 1.0, cVegReserve = TAU_DORMANT,
    cLitFast = 1.0/14.8, cLitSlow = 1.0/3.9, cSoilSlow = 5.0, cSoilOld = 222.2,
)

"""
    GSI_CN_ratio

Carbon-to-nitrogen ratio of each GSI carbon pool, per pool name. Fixed data, not a
parameter -- calibration happens through `CN_ratio_scalar` in the owning
approach instead. Only the four vegetation pools have a physically meaningful ratio
(the values `cCycleBase_GSI`/`_PlantForm`/`_MGMT`'s `p_CN_ratio_cVeg` field already
defaulted to); every other pool is `0.0`, exactly as that vector field was never
read for any pool other than `cVeg`'s.
"""
const GSI_CN_ratio = (;
    cVegRoot = 25.0, cVegWood = 260.0, cVegLeaf = 25.0, cVegReserve = 50.0,
    cLitFast = 0.0, cLitSlow = 0.0, cSoilSlow = 0.0, cSoilOld = 0.0,
)

const GSI_POOL_NAMES = propertynames(GSI_TAU_DEFAULT)

"""
    fireCCTable(::Type{GSI})

Derived from `CASA_FIRE_CC_VANDERWERF` (`poolConfigurations/CASA.jl`) via
`deriveFireCCTable` rather than hand-duplicated -- see that function's
docstring for the direct-name/`poolAliases` two-tier rule. `cVegRoot` (CASA
generates it from its own `Root.{Fine,Coarse}` nesting, not a declared
`poolAlias`) and `cVegReserve` (no CASA pool at all) are merged in
afterward as the two pools neither tier can resolve.

Computed here in a method body, not as a top-level `const`, so it can live
beside GSI's own pool names even though `GSI.jl` loads before `CASA.jl` in
`poolConfigurations.jl`'s fixed include order -- a method body's global
references resolve at call time, once every configuration file has already
loaded, unlike a top-level `const` initializer.
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
