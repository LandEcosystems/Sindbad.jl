export cQualityPartitioncVeg

abstract type cQualityPartitioncVeg <: LandEcosystem end

purpose(::Type{cQualityPartitioncVeg}) = "Effect of the metabolic litter fraction on the carbon-quality partition: the split of leaf and fine-root litterfall between the metabolic and structural litter pools."

includeApproaches(cQualityPartitioncVeg, @__DIR__)

@doc """
    $(getModelDocString(cQualityPartitioncVeg))

---
# Extended help

`cQualityPartitioncVeg` provides `c_flow_QP_f_cVeg`, a flow-aligned factor of the
carbon-quality partition. The approach operates on flows whose giver belongs to
`cVeg` and uses `land.cCycleBase.c_flow_taker_turnover_rank` to select the fast or
slow share without identifying takers by pool name.

For each flow, `c_flow_taker_turnover_rank` is `1` for the faster of two
non-vegetation takers, `-1` for the slower taker, and `0` when the flow is not a
two-taker quality partition. A rank of zero therefore leaves the flow neutral
(`QP = 1`), including GSI transfers to vegetation and one-taker litterfall.

The individual approaches only determine `fastPart` and `slowPart` (for example,
from the metabolic litter fraction); the same rank-based equation is then applied
to every `cVeg` flow.
"""
cQualityPartitioncVeg
