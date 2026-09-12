export cMicrobialEfficiencycMic

abstract type cMicrobialEfficiencycMic <: LandEcosystem end

purpose(::Type{cMicrobialEfficiencycMic}) = "Microbial carbon-transfer efficiency of the flows leaving the microbial pools."

includeApproaches(cMicrobialEfficiencycMic, @__DIR__)

@doc """
	$(getModelDocString(cMicrobialEfficiencycMic))

---
# Extended help

`cMicrobialEfficiencycMic` provides `c_flow_ME_f_cMic`, a flow-aligned factor of the microbial
carbon-transfer efficiency with one entry per active carbon transfer, in the same order
as `c_flow_order`, `c_giver` and `c_taker`.

The factor is one everywhere except on the transfers leaving the microbial pools, and
[`cMicrobialEfficiency_mult`](@ref) combines it with the other two pool-group factors to
form `c_flow_ME_vec`. No other factor touches a `cMic` giver, which is what lets the
three be combined.

Only `CarbonPoolsCASA` has explicit microbial pools. Under the GSI structures
`zix.cMic` is empty, no flow matches, and this factor stays neutral with no special
case, because microbial mediation there is folded into the litter and soil transfers.

`_none`, `_constant` and `_texture` decide which transfers are theirs from
`helpers.pools.zix.cMic`, so they need no edge list and hold on any pool structure.
CASA's own fixed surface-pathway constant lives in `cCycleBase_CASA` as a default
instead of a group factor here; `_texture` is the group-wide texture response, applied
uniformly to every `cMic` transfer rather than singling out the soil-microbial pool
the way CASA's original table did.
"""
cMicrobialEfficiencycMic
