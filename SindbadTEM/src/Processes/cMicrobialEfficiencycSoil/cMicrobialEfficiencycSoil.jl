export cMicrobialEfficiencycSoil

abstract type cMicrobialEfficiencycSoil <: LandEcosystem end

purpose(::Type{cMicrobialEfficiencycSoil}) = "Microbial carbon-transfer efficiency of the decomposition flows leaving the soil carbon pools."

includeApproaches(cMicrobialEfficiencycSoil, @__DIR__)

@doc """
	$(getModelDocString(cMicrobialEfficiencycSoil))

---
# Extended help

`cMicrobialEfficiencycSoil` provides `c_flow_ME_f_cSoil`, a flow-aligned factor of the microbial
carbon-transfer efficiency with one entry per active carbon transfer, in the same order
as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the transfers leaving the soil carbon pools, and
[`cMicrobialEfficiency_mult`](@ref) combines it with the other two pool-group factors to
form `c_flow_ME_vec`. No other factor touches a `cSoil` giver, which is what lets the
three be combined.

Every pool structure has soil pools, so this factor is active on all of them: the
three CASA soil transfers under `CarbonPoolsCASA`, and `cSoilSlow` into `cSoilOld`
alone under the GSI structures.

`_none`, `_constant` and `_texture` decide which transfers are theirs from
`helpers.pools.zix.cSoil`, so they need no edge list and hold on any pool structure.
CASA's own per-pathway soil table lives in `cCycleBase_CASA` as defaults instead of a
group factor here.
"""
cMicrobialEfficiencycSoil
