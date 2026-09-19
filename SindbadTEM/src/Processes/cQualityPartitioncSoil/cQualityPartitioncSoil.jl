export cQualityPartitioncSoil

abstract type cQualityPartitioncSoil <: LandEcosystem end

purpose(::Type{cQualityPartitioncSoil}) = "Effect of soil texture on the carbon-quality partition: the split of slow-soil decomposition between stabilization into old soil carbon and the remaining pathway."

includeApproaches(cQualityPartitioncSoil, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitioncSoil))

---
# Extended help

`cQualityPartitioncSoil` provides `c_flow_QP_f_cSoil`, a flow-aligned factor of
the carbon-quality partition with one entry per active carbon transfer, in the
same order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving `cSoilSlow`, in
`land.cCycleBase.c_flow_qp_groups.cSoil`: clay-rich soils stabilize a larger
share of decomposing slow-soil carbon into the old soil pool.
[`cQualityPartition_mult`](@ref) multiplies this factor with the `cVeg`, `cLit`
and `cMic` factors to form `c_flow_QP_vec`.

`c_flow_qp_groups.cSoil` is derived once, from the resolved flow topology, by
`deriveQPGroups` (`cCycleBase/poolConfigurations/poolConfigurations.jl`): it is
the `(stabilized_positions, other_positions)` pair for the giver named
`cSoilSlow`, present only when that giver has more than one outgoing edge. On a
structure where `cSoilSlow` has only a single outflow -- such as GSI, where
`cSoilSlow` feeds only `cSoilOld` -- this resolves to an empty group and simply
keeps its neutral partition of one on that flow.

Named after the giver pool group it owns (`cSoil`), the way
[`cMicrobialEfficiencycLit`](@ref)/`cMic`/`cSoil` are. This and
[`cQualityPartitioncMic`](@ref) used to be combined into one process,
`cQualityPartitionSoilProperties`, which mixed the `cSoilSlow` and `cMicSoil`
giver groups; splitting them apart keeps every `cQualityPartition` factor
strictly single-giver-group, as `cMicrobialEfficiency`'s already are.

This is the partition counterpart of [`cTauSoilProperties`](@ref), which carries
the texture control of decomposition rates.
"""
cQualityPartitioncSoil
