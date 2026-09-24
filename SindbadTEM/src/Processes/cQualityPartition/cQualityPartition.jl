export cQualityPartition

abstract type cQualityPartition <: LandEcosystem end

purpose(::Type{cQualityPartition}) = "Determine the fraction of carbon flowing between labile and recalcitrant pools."

includeApproaches(cQualityPartition, @__DIR__)

@doc """
	$(getModelDocString(cQualityPartition))

---
# Extended help

`cQualityPartition` fills in `c_flow_QP_vec`, a diagnostic vector with one entry
for every active carbon transfer defined by `c_flow_order`, `c_giver`, and
`c_taker` in the selected carbon-cycle structure. The vector itself is allocated
neutral, one per flow, by `cCycleBase`, so `cCycle` reads a valid partition even
when no `cQualityPartition` model is selected.

The process separates carbon-quality/routing effects from the transfer-rate
calculation itself. In the legacy SINDBAD CASA implementation, the corresponding
quantity was `p_F_vec`.

The partition splits along four independent controls, each of which owns a
disjoint giver pool group and is a process of its own, named after that group the
way `cMicrobialEfficiency`'s factors are:

- [`cQualityPartitioncVeg`](@ref): the metabolic/structural split of leaf and
  fine-root litterfall.
- [`cQualityPartitioncLit`](@ref): the lignin control of structural and woody
  litter decomposition.
- [`cQualityPartitioncMic`](@ref): the clay control of soil-microbial
  stabilization.
- [`cQualityPartitioncSoil`](@ref): the clay control of slow-soil stabilization.

[`cQualityPartition_mult`](@ref) multiplies the four factors, the way
[`cTau_mult`](@ref) multiplies the decomposition-rate stressors. There is no
self-contained single-table alternative: composing
`cQualityPartitioncVeg_vegQualityTraits`, `cQualityPartitioncLit_vegQualityTraits`,
`cQualityPartitioncMic_texture` and `cQualityPartitioncSoil_texture` through
`cQualityPartition_mult` reproduces the old CASA table exactly, so the separate
`cQualityPartition_CASA` approach that used to declare it in one table was removed.
"""
cQualityPartition
