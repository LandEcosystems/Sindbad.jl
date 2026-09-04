export cQualityPartitionSoilProperties
export QP_SOIL_PROPERTIES_GROUPS

abstract type cQualityPartitionSoilProperties <: LandEcosystem end

purpose(::Type{cQualityPartitionSoilProperties}) = "Effect of soil texture on the carbon-quality partition: the split of slow-soil and soil-microbial decomposition between stabilization into old soil carbon and the remaining pathway."

"""
    QP_SOIL_PROPERTIES_GROUPS

The soil partition groups this process owns, as `(stabilized edge, other edge)`
pairs. The first edge of a pair takes the fraction stabilized into old soil
carbon and the second takes its complement.

Each pair is the complete set of outgoing flows of one giver, and no other
`cQualityPartition` factor process touches `cSoilSlow` or `cMicSoil`, which is
what lets the factors be multiplied into `c_flow_QP_vec`.
"""
const QP_SOIL_PROPERTIES_GROUPS = (
    (:cSoilSlow_to_cSoilOld, :cSoilSlow_to_cMicSoil),
    (:cMicSoil_to_cSoilOld, :cMicSoil_to_cSoilSlow),
)

includeApproaches(cQualityPartitionSoilProperties, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitionSoilProperties))

---
# Extended help

`cQualityPartitionSoilProperties` provides `c_flow_QP_f_soil_props`, a flow-aligned factor
of the carbon-quality partition with one entry per active carbon transfer, in the
same order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving `cSoilSlow` and
`cMicSoil`, listed in `QP_SOIL_PROPERTIES_GROUPS`: clay-rich soils stabilize a larger
share of decomposing slow-soil and soil-microbial carbon into the old soil pool.
[`cQualityPartition_mult`](@ref) multiplies this factor with the
metabolic-fraction and lignin factors to form `c_flow_QP_vec`.

Edges are matched by pool-name pair through `c_flow_named_edges`, so a structure
without an explicit microbial pool simply keeps its neutral partition of one on
those flows.

This is the partition counterpart of [`cTauSoilProperties`](@ref) and
[`cMicrobialEfficiency`](@ref), which carry the texture control of decomposition
rates and of microbial transfer efficiency respectively.
"""
cQualityPartitionSoilProperties
