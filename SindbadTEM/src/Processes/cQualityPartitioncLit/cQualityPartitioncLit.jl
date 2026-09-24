export cQualityPartitioncLit

abstract type cQualityPartitioncLit <: LandEcosystem end

purpose(::Type{cQualityPartitioncLit}) = "Effect of litter lignin content on the carbon-quality partition: the split of structural and woody litter decomposition between the slow soil pool and the microbial pools."

includeApproaches(cQualityPartitioncLit, @__DIR__)

@doc """
    $(getModelDocString(cQualityPartitioncLit))

---
# Extended help

`cQualityPartitioncLit` provides `c_flow_QP_f_cLit`, a flow-aligned factor of the
carbon-quality partition. The approach operates on flows whose giver belongs to
`cLit` and uses `land.cCycleBase.c_flow_taker_turnover_rank` to select the fast or
slow taker without identifying takers by pool name.

For each flow, `c_flow_taker_turnover_rank` is `1` for the faster of two
non-vegetation takers, `-1` for the slower taker, and `0` when the flow is not a
two-taker quality partition. Lignin controls the slow share, while its complement
is the fast share. The existing structural-versus-woody litter distinction remains
a giver-side ecological distinction because those two litter classes use different
lignin fractions; it is independent of identifying the taker.

[`cQualityPartition_mult`](@ref) multiplies this factor with the `cVeg`, `cMic`
and `cSoil` factors to form `c_flow_QP_vec`.
"""
cQualityPartitioncLit
