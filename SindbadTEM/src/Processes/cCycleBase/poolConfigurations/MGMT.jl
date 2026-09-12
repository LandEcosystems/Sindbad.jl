export CarbonPoolsMGMT

struct CarbonPoolsMGMT <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsMGMT}) = "GSI carbon pools plus wood and crop product pools for land management, 10 pools"

"""
    poolStructure(::Type{CarbonPoolsMGMT})

The GSI structure plus a `cProducts` component holding harvested wood and crop
carbon, 10 pools in all.

# Notes:
- Built directly on `poolStructure(CarbonPoolsGSI)` (splatted in, both at the top
  level for `combine` and inside `components` for the eight shared pools) rather than
  repeating its leaf entries, so the two structures cannot drift apart on the eight
  pools they share. Declaration order is preserved by the splat, so the two structures
  still agree on every `cEco` index they share -- that is why
  `cCycleBase_GSI_PlantForm_MGMT` reuses `GSI_FLOW_EDGES` unchanged.
- Products are decay only: carbon enters them from management and leaves by turnover,
  with no pool-to-pool transfer, so they add no flow edges.
- See `poolStructure(::Type{CarbonPoolsGSI})` for the shape and ordering rules that
  apply to every structure.
"""
poolStructure(::Type{CarbonPoolsMGMT}) = (;
    poolStructure(CarbonPoolsGSI)...,
    components = (;
        poolStructure(CarbonPoolsGSI).components...,
        cProducts = (; Wood = (1, 20.0), Crop = (1, 20.0)),
    ),
)

"""
    MGMT_PRODUCTS_TAU

Turnover *time* (years) of the two harvested-product pools
`poolStructure(CarbonPoolsMGMT)` adds on top of the GSI structure:
`cProductsWood`/`cProductsCrop`. Fixed data, not a parameter -- calibration
happens through `k_c_products_wood_scalar`/`k_c_products_crop_scalar` in
`cCycleBase_GSI_PlantForm_MGMT` instead.

Unlike every other pool that approach's turnover loop covers, these two do not
vary by vegetation type: harvested-product decay does not depend on the pixel's
vegetation-type classification, so `cCycleBase_GSI_PlantForm_MGMT`'s `precompute`
merges this fixed pair into its runtime, per-vegtype organ-turnover table (built
from `ParamsForVegClasses.jl`'s `CVEG_*_AGE_PER_VEGTYPE` tables) rather than
looking them up by `veg_type_name` at all.

The old `c_τ_cProductsWood`/`c_τ_cProductsCrop` rate defaults (`0.03`, `1.0`
yr⁻¹) invert to `33.333333333333336` and `1.0`; following `GSI_TAU_DEFAULT`'s
magnitude-based formatting convention (`poolConfigurations/GSI.jl`, both entries
here are `>= 1`, rounded to one decimal place), `cProductsWood` is stored as
`33.3` -- a deliberate, if small, change to the resulting rate for readability
(about `0.1%` off `0.03`), not merely a representation change; `cProductsCrop`'s
`1.0` is unaffected by rounding.
"""
const MGMT_PRODUCTS_TAU = (; cProductsWood = 33.3, cProductsCrop = 1.0)
