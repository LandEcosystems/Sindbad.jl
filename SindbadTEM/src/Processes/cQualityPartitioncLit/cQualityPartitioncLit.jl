export cQualityPartitioncLit

abstract type cQualityPartitioncLit <: LandEcosystem end

purpose(::Type{cQualityPartitioncLit}) = "Effect of litter lignin content on the carbon-quality partition: the split of structural and woody litter decomposition between the slow soil pool and the microbial pools."

includeApproaches(cQualityPartitioncLit, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartitioncLit))

---
# Extended help

`cQualityPartitioncLit` provides `c_flow_QP_f_cLit`, a flow-aligned factor of the
carbon-quality partition with one entry per active carbon transfer, in the same
order as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the flows leaving the structural and woody
litter pools, in `land.cCycleBase.c_flow_qp_groups.cLit.structural` and
`c_flow_qp_groups.cLit.wood`: the lignin-rich part of decomposing litter is
stabilized directly into the slow soil pool, and the rest passes through the
microbial pools. [`cQualityPartition_mult`](@ref) multiplies this factor with
the `cVeg`, `cMic` and `cSoil` factors to form `c_flow_QP_vec`.

`c_flow_qp_groups.cLit` is derived once, from the resolved flow topology, by
`deriveQPGroups` (`cCycleBase/poolConfigurations/poolConfigurations.jl`): a
giver whose name starts with `cLit` and whose outgoing edges include both a
`cSoil`-prefixed taker and a `cMic`-prefixed taker contributes a
`(soil_positions, mic_positions)` pair, filed under `wood` if the giver's name
contains `Wood`/`RootCoarse` and `structural` otherwise. `cLitLeafFast` and
`cLitRootFineFast` are single-outflow (to a `cMic`-prefixed pool only) and so
never match, keeping that neutral partition. A structure without the explicit
structural-litter and microbial pools -- e.g. GSI, whose `cLitFast`/`cLitSlow`
each reach only `cSoilSlow` -- resolves both fields to `()`.

Named after the giver pool group it owns (`cLit`), the way
[`cMicrobialEfficiencycLit`](@ref)/`cMic`/`cSoil` are, rather than after the
control it applies (this used to be `cQualityPartitionLignin`).
[`cQualityPartitioncLit_vegQualityTraits`](@ref) reads the lignin fractions
directly from `land.properties`, published by whichever `vegQualityTraits`
approach is selected, so the partition and the decomposition-rate side can never
disagree about them.
"""
cQualityPartitioncLit
