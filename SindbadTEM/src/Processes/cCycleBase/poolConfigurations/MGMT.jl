export CarbonPoolsMGMT

struct CarbonPoolsMGMT <: CarbonPoolConfiguration end
purpose(::Type{CarbonPoolsMGMT}) = "GSI carbon pools plus wood and crop product pools for land management, 10 pools"

"""
    poolStructure(::Type{CarbonPoolsMGMT})

The GSI structure plus a `cProducts` component holding harvested wood and crop
carbon, 10 pools in all.

# Notes:
- The first eight pools are declared exactly as `CarbonPoolsGSI` declares them, in the
  same order, so the two structures agree on every `cEco` index they share. That is
  why `cCycleBase_GSI_PlantForm_MGMT` reuses `GSI_FLOW_EDGES` unchanged.
- Products are decay only: carbon enters them from management and leaves by turnover,
  with no pool-to-pool transfer, so they add no flow edges.
- See `poolStructure(::Type{CarbonPoolsGSI})` for the shape and ordering rules that
  apply to every structure.
"""
poolStructure(::Type{CarbonPoolsMGMT}) = (;
    combine = :cEco,
    components = (;
        cVeg      = (; Root = (1, 25.0), Wood = (1, 25.0), Leaf = (1, 25.0), Reserve = (1, 10.0)),
        cLit      = (; Fast = (1, 100.0), Slow = (1, 250.0)),
        cSoil     = (; Slow = (1, 500.0), Old = (1, 1000.0)),
        cProducts = (; Wood = (1, 20.0), Crop = (1, 20.0)),
    ),
)
