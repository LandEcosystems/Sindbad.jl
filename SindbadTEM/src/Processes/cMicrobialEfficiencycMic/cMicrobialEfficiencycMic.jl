export cMicrobialEfficiencycMic
export meCASAFlowsMicrobial

abstract type cMicrobialEfficiencycMic <: LandEcosystem end

purpose(::Type{cMicrobialEfficiencycMic}) = "Microbial carbon-transfer efficiency of the flows leaving the microbial pools."

"""
    meCASAFlowsMicrobial(eff_cMicSurf_to_cSoilSlow, microbial_efficiency)

The CASA microbial carbon-transfer efficiency of the microbial turnover pathways, as
`edge => value` pairs keyed by giver-to-taker pool-name pair.

Only the soil microbial pool sees the soil texture, so `microbial_efficiency` is passed
in already computed by `meTextureEfficiency`. The surface pool decomposes above the
mineral soil and takes a fixed value instead. This is the one group whose CASA table
mixes a driver with a constant.

A function rather than a table written inline, because two approaches declare it:
[`cMicrobialEfficiencycMic_CASA`](@ref) as this group's factor, and
[`cMicrobialEfficiency_CASA`](@ref) as part of the whole self-contained table.
"""
function meCASAFlowsMicrobial(eff_cMicSurf_to_cSoilSlow, microbial_efficiency)
    return (
        (:cMicSurf_to_cSoilSlow, eff_cMicSurf_to_cSoilSlow),
        (:cMicSoil_to_cSoilSlow, microbial_efficiency),
        (:cMicSoil_to_cSoilOld, microbial_efficiency),
    )
end

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
`_CASA` names its edges instead, because it is the only one that distinguishes pathways
within the group.
"""
cMicrobialEfficiencycMic
