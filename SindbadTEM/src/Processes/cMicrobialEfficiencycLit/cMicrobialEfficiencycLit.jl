export cMicrobialEfficiencycLit

abstract type cMicrobialEfficiencycLit <: LandEcosystem end

purpose(::Type{cMicrobialEfficiencycLit}) = "Microbial carbon-transfer efficiency of the decomposition flows leaving the litter pools."

includeApproaches(cMicrobialEfficiencycLit, @__DIR__)

@doc """
	$(getModelDocString(cMicrobialEfficiencycLit))

---
# Extended help

`cMicrobialEfficiencycLit` provides `c_flow_ME_f_cLit`, a flow-aligned factor of the microbial
carbon-transfer efficiency with one entry per active carbon transfer, in the same order
as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the transfers leaving the litter pools, and
[`cMicrobialEfficiency_mult`](@ref) combines it with the other two pool-group factors to
form `c_flow_ME_vec`. No other factor touches a `cLit` giver, which is what lets the
three be combined.

Every pool structure has litter pools, so this factor is active on all of them: the
ten CASA litter transfers under `CarbonPoolsCASA`, and the two aggregated
`cLitFast`/`cLitSlow` transfers into slow soil under the GSI structures.

`_none`, `_constant` and `_texture` decide which transfers are theirs from
`helpers.pools.zix.cLit`, so they need no edge list and hold on any pool structure.
CASA's own per-pathway litter table lives in `cCycleBase_CASA` as defaults instead of
a group factor here.
"""
cMicrobialEfficiencycLit
