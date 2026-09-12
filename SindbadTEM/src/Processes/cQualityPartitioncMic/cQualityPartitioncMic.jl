export cQualityPartitioncMic

abstract type cQualityPartitioncMic <: LandEcosystem end

purpose(::Type{cQualityPartitioncMic}) = "Effect of soil texture on the carbon-quality partition: the split of soil-microbial decomposition between stabilization into old soil carbon and the remaining pathway."

includeApproaches(cQualityPartitioncMic, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitioncMic))

---
# Extended help

`cQualityPartitioncMic` provides `c_flow_QP_f_cMic`, a flow-aligned factor of the
carbon-quality partition with one entry per active carbon transfer, in the same
order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving `cMicSoil`, in
`land.cCycleBase.c_flow_qp_groups.cMic`: clay-rich soils stabilize a larger share
of decomposing soil-microbial carbon into the old soil pool.
[`cQualityPartition_mult`](@ref) multiplies this factor with the `cVeg`, `cLit`
and `cSoil` factors to form `c_flow_QP_vec`.

`c_flow_qp_groups.cMic` is derived once, from the resolved flow topology, by
`deriveQPGroups` (`cCycleBase/poolConfigurations/poolConfigurations.jl`): it is
the `(stabilized_positions, other_positions)` pair for the giver named
`cMicSoil`, present only when that giver exists and has more than one outgoing
edge. A structure without an explicit microbial pool, or where `cMicSoil` has
only a single outflow, resolves to an empty group and simply keeps its neutral
partition of one on those flows.

Named after the giver pool group it owns (`cMic`), the way
[`cMicrobialEfficiencycLit`](@ref)/`cMic`/`cSoil` are. This and
[`cQualityPartitioncSoil`](@ref) used to be combined into one process,
`cQualityPartitionSoilProperties`, which mixed the `cSoilSlow` and `cMicSoil`
giver groups; splitting them apart keeps every `cQualityPartition` factor
strictly single-giver-group, as `cMicrobialEfficiency`'s already are.

This is the partition counterpart of [`cTauSoilProperties`](@ref) and
[`cMicrobialEfficiencycMic`](@ref), which carry the texture control of
decomposition rates and of microbial transfer efficiency respectively.
"""
cQualityPartitioncMic
