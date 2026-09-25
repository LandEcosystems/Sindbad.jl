export cQualityPartitioncMic

abstract type cQualityPartitioncMic <: LandEcosystem end

purpose(::Type{cQualityPartitioncMic}) = "Effect of soil texture on the carbon-quality partition: the split of soil-microbial decomposition between stabilization into old soil carbon and the remaining pathway."

includeApproaches(cQualityPartitioncMic, @__DIR__)

@doc """
    $(getModelDocString(cQualityPartitioncMic))

---
# Extended help

`cQualityPartitioncMic` provides `c_flow_QP_f_cMic`, a flow-aligned factor of the
carbon-quality partition. The approach operates on flows whose giver belongs to
`cMic` and uses `land.cCycleBase.c_flow_taker_turnover_rank` to select the fast or
slow share without identifying a particular taker pool by name.

For each flow, `c_flow_taker_turnover_rank` is `1` for the faster of two
non-vegetation takers, `-1` for the slower taker, and `0` when the flow is not a
two-taker quality partition. The soil-stabilization fraction is therefore assigned
as `slowPart`; its complement is `fastPart`.

[`cQualityPartition_mult`](@ref) multiplies this factor with the `cVeg`, `cLit`
and `cSoil` factors to form `c_flow_QP_vec`.
"""
cQualityPartitioncMic
