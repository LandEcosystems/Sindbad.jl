export cQualityPartitionLignin
export QP_LIGNIN_STRUCT_GROUPS, QP_LIGNIN_WOOD_GROUPS

abstract type cQualityPartitionLignin <: LandEcosystem end

purpose(::Type{cQualityPartitionLignin}) = "Effect of litter lignin content on the carbon-quality partition: the split of structural and woody litter decomposition between the slow soil pool and the microbial pools."

"""
    QP_LIGNIN_STRUCT_GROUPS

The structural-litter partition groups this process owns, as
`(stabilized edge, microbial edge)` pairs. The first edge of a pair takes the
lignin fraction of structural litter carbon and the second takes its complement.
"""
const QP_LIGNIN_STRUCT_GROUPS = (
    (:cLitLeafSlow_to_cSoilSlow, :cLitLeafSlow_to_cMicSurf),
    (:cLitRootFineSlow_to_cSoilSlow, :cLitRootFineSlow_to_cMicSoil),
)

"""
    QP_LIGNIN_WOOD_GROUPS

The woody-litter partition groups this process owns, in the same
`(stabilized edge, microbial edge)` shape, split by the lignin fraction of woody
litter rather than of structural litter.
"""
const QP_LIGNIN_WOOD_GROUPS = (
    (:cLitWood_to_cSoilSlow, :cLitWood_to_cMicSurf),
    (:cLitRootCoarse_to_cSoilSlow, :cLitRootCoarse_to_cMicSoil),
)

includeApproaches(cQualityPartitionLignin, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitionLignin))

---
# Extended help

`cQualityPartitionLignin` provides `c_flow_QP_f_lignin`, a flow-aligned factor of
the carbon-quality partition with one entry per active carbon transfer, in the
same order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving the structural and woody
litter pools, listed in `QP_LIGNIN_STRUCT_GROUPS` and `QP_LIGNIN_WOOD_GROUPS`:
the lignin-rich part of decomposing litter is stabilized directly into the slow
soil pool, and the rest passes through the microbial pools.
[`cQualityPartition_mult`](@ref) multiplies this factor with the
metabolic-fraction and soil-property factors to form `c_flow_QP_vec`.

Edges are matched by pool-name pair through `c_flow_named_edges`, so a structure
without the explicit structural-litter and microbial pools simply keeps its
neutral partition of one on those flows.

This is the partitioning counterpart of the [`lignin`](@ref) process, which
publishes `lit_frac_lignin_struct` and the rate effect `lit_k_f_lignin` for the
decomposition-rate side. The two are deliberately independent: the approaches
here declare their own fractions, so the partition can be reparameterised without
touching the litter chemistry that `cTauVegProperties` consumes.
"""
cQualityPartitionLignin
