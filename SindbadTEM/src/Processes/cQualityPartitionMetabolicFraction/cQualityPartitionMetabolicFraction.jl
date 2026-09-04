export cQualityPartitionMetabolicFraction
export QP_METABOLIC_FRACTION_GROUPS

abstract type cQualityPartitionMetabolicFraction <: LandEcosystem end

purpose(::Type{cQualityPartitionMetabolicFraction}) = "Effect of the metabolic litter fraction on the carbon-quality partition: the split of leaf and fine-root litterfall between the metabolic and structural litter pools."

"""
    QP_METABOLIC_FRACTION_GROUPS

The partition groups this process owns, as `(metabolic edge, structural edge)`
pairs. The first edge of a pair takes the metabolic fraction and the second takes
its complement.

Each pair is the complete set of outgoing flows of one giver, and no other
`cQualityPartition` factor process touches `cVegLeaf` or `cVegRootF`, which is
what lets the factors be multiplied into `c_flow_QP_vec`.
"""
const QP_METABOLIC_FRACTION_GROUPS = (
    (:cVegLeaf_to_cLitLeafM, :cVegLeaf_to_cLitLeafS),
    (:cVegRootF_to_cLitRootFM, :cVegRootF_to_cLitRootFS),
)

includeApproaches(cQualityPartitionMetabolicFraction, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitionMetabolicFraction))

---
# Extended help

`cQualityPartitionMetabolicFraction` provides `c_flow_QP_f_metabolic_fraction`, a
flow-aligned factor of the carbon-quality partition with one entry per active
carbon transfer, in the same order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving `cVegLeaf` and
`cVegRootF`, listed in `QP_METABOLIC_FRACTION_GROUPS`: lignin-rich, nitrogen-poor
litter routes less of its litterfall to the fast-cycling metabolic pools and more
to the structural ones. [`cQualityPartition_mult`](@ref) multiplies this factor
with the lignin and soil-property factors to form `c_flow_QP_vec`.

Edges are matched by pool-name pair through `c_flow_named_edges`, so a structure
without the explicit metabolic/structural litter split simply keeps its neutral
partition of one on those flows.

This is the partitioning counterpart of the [`metabolicFraction`](@ref) process,
which publishes `lit_frac_metabolic` and the litter chemistry behind it for the
decomposition-rate side. The two are deliberately independent: the approaches
here declare their own fractions, so the partition can be reparameterised without
touching the litter chemistry that `lignin` and `cTauVegProperties` consume.
"""
cQualityPartitionMetabolicFraction
