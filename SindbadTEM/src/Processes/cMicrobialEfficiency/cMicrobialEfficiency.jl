export cMicrobialEfficiency

abstract type cMicrobialEfficiency <: LandEcosystem end

purpose(::Type{cMicrobialEfficiency}) = "Determine flow-specific microbial carbon-transfer efficiency during litter and soil decomposition. The diagnostic c_ME_vec is aligned with c_flow_order/c_giver/c_taker and represents the old CASA p_E efficiency term."

includeApproaches(cMicrobialEfficiency, @__DIR__)

@doc """ 
	$(getModelDocString(cMicrobialEfficiency))

---
# Extended help

`cMicrobialEfficiency` provides `c_ME_vec`, a flow-aligned diagnostic containing
one efficiency value for each active carbon transfer defined by
`c_flow_order`, `c_giver`, and `c_taker`.

Vegetation-to-vegetation and vegetation-to-litter transfers are not microbial
decomposition and therefore use the neutral efficiency of one. Approaches apply
microbial efficiency to transfers whose giver is a litter or soil carbon pool.
In the legacy SINDBAD CASA implementation, the corresponding quantity was
`p_E_vec`.
"""
cMicrobialEfficiency
