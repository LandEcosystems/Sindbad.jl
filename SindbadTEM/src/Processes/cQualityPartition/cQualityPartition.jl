export cQualityPartition

abstract type cQualityPartition <: LandEcosystem end

purpose(::Type{cQualityPartition}) = "Determine the fraction of carbon flowing between labile and recalcitrant pools."

includeApproaches(cQualityPartition, @__DIR__)

@doc """ 
	$(getModelDocString(cQualityPartition))

---
# Extended help

`cQualityPartition` provides a diagnostic vector, `c_flow_QP_vec`, with one
entry for every active carbon transfer defined by `c_flow_order`, `c_giver`, and
`c_taker` in the selected carbon-cycle structure.

The process separates carbon-quality/routing effects from the transfer-rate
calculation itself. In the legacy SINDBAD CASA implementation, the corresponding
quantity was `p_F_vec`.
"""
cQualityPartition
