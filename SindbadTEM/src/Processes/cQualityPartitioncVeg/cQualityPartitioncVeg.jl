export cQualityPartitioncVeg

abstract type cQualityPartitioncVeg <: LandEcosystem end

purpose(::Type{cQualityPartitioncVeg}) = "Effect of the metabolic litter fraction on the carbon-quality partition: the split of leaf and fine-root litterfall between the metabolic and structural litter pools."

includeApproaches(cQualityPartitioncVeg, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitioncVeg))

---
# Extended help

`cQualityPartitioncVeg` provides `c_flow_QP_f_cVeg`, a flow-aligned factor of the
carbon-quality partition with one entry per active carbon transfer, in the same
order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving `cVegLeaf` and
`cVegRootFine`, in `land.cCycleBase.c_flow_qp_groups.cVeg`: lignin-rich,
nitrogen-poor litter routes less of its litterfall to the fast-cycling metabolic
pools and more to the structural ones. [`cQualityPartition_mult`](@ref)
multiplies this factor with the `cLit`, `cMic` and `cSoil` factors to form
`c_flow_QP_vec`.

`c_flow_qp_groups.cVeg` is derived once, from the resolved flow topology, by
`deriveQPGroups` (`cCycleBase/poolConfigurations/poolConfigurations.jl`): a
giver whose name starts with `cVeg` and whose outgoing edges include a taker
pair sharing a base name suffixed `Fast`/`Slow` (e.g. `cLitLeafFast`/
`cLitLeafSlow`) contributes a `(fast_positions, slow_positions)` pair. A
structure without the explicit metabolic/structural litter split -- e.g. GSI,
where `cVegLeaf`/`cVegRoot` each reach only a single, unsplit `cLitFast` pool --
resolves to an empty group and simply keeps its neutral partition of one on
those flows.

Named after the giver pool group it owns (`cVeg`), the way
[`cMicrobialEfficiencycLit`](@ref)/`cMic`/`cSoil` are, rather than after the
control it applies (this used to be `cQualityPartitionMetabolicFraction`).
[`cQualityPartitioncVeg_vegQualityTraits`](@ref) reads the metabolic fraction
directly from `land.properties`, published by whichever `vegQualityTraits`
approach is selected, so the partition and the decomposition-rate side can never
disagree about it.
"""
cQualityPartitioncVeg
