export MGMT

struct MGMT <: CarbonPoolConfiguration end
purpose(::Type{MGMT}) = "GSI carbon pools plus wood and crop product pools for land management, 10 pools"

"""
    poolStructure(::Type{MGMT})

The GSI structure plus a `cProducts` component holding harvested wood and
crop carbon, 10 pools in all. Built by splatting `poolStructure(GSI)` in, so
the two structures agree on every `cEco` index they share; this is why
`cCycleBase_MGMT` reuses `GSI_FLOW_EDGES` unchanged. Products are decay only,
with no pool-to-pool transfer, so they add no flow edges.
"""
poolStructure(::Type{MGMT}) = (;
    poolStructure(GSI)...,
    components = (;
        poolStructure(GSI).components...,
        cProducts = (; Wood = (1, 20.0), Crop = (1, 20.0)),
    ),
)

# Products are decay only (see poolStructure's notes), so they add no flow edges:
# MGMT's topology is exactly GSI's.
cFlowEdges(::Type{MGMT}) = GSI_FLOW_EDGES

abovegroundFractionTable(::Type{MGMT}) = abovegroundFractionTable(GSI)

"""
    MGMT_PRODUCTS_TAU

Turnover time (years) of the two harvested-product pools
`poolStructure(MGMT)` adds on top of the GSI structure:
`cProductsWood`/`cProductsCrop`. Fixed data, not a parameter; calibration
happens through `k_c_products_wood_scalar`/`k_c_products_crop_scalar` in
`cCycleBase_MGMT` instead.

Unlike every other pool `cCycleBase_MGMT`'s turnover loop covers, these two
do not vary by vegetation type, so its `precompute` merges this fixed pair
into its runtime, per-vegtype compartment-turnover table rather than looking
them up by `veg_type_name`.
"""
const MGMT_PRODUCTS_TAU = (; cProductsWood = 33.3, cProductsCrop = 1.0)

# MGMT's pool set is GSI's plus cProductsWood/cProductsCrop, which neither
# GSI_FIRE_CC_VANDERWERF nor the old cc_lut-based code ever covered, so they
# stay at the same implicit no-burn-by-omission both already gave them.
fireCCTable(::Type{MGMT}) = fireCCTable(GSI)
