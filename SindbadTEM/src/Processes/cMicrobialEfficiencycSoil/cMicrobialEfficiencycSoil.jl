export cMicrobialEfficiencycSoil
export meCASAFlowsSoil

abstract type cMicrobialEfficiencycSoil <: LandEcosystem end

purpose(::Type{cMicrobialEfficiencycSoil}) = "Microbial carbon-transfer efficiency of the decomposition flows leaving the soil carbon pools."

"""
    meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld)

The CASA microbial carbon-transfer efficiency of the soil decomposition pathways, as
`edge => value` pairs keyed by giver-to-taker pool-name pair.

The two routes carry the same CASA value but are separate parameters so that
stabilization into old soil carbon and the return to the microbial pool can be calibrated
apart. On the GSI structures only `cSoilSlow_to_cSoilOld` exists and the other two are
skipped.

A function rather than a table written inline, because two approaches declare it:
[`cMicrobialEfficiencycSoil_CASA`](@ref) as this group's factor, and
[`cMicrobialEfficiency_CASA`](@ref) as part of the whole self-contained table.
"""
function meCASAFlowsSoil(eff_cSoil_to_cMicSoil, eff_cSoilSlow_to_cSoilOld)
    return (
        (:cSoilSlow_to_cMicSoil, eff_cSoil_to_cMicSoil),
        (:cSoilOld_to_cMicSoil, eff_cSoil_to_cMicSoil),
        (:cSoilSlow_to_cSoilOld, eff_cSoilSlow_to_cSoilOld),
    )
end

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
`_CASA` names its edges instead, because it is the only one that distinguishes pathways
within the group.
"""
cMicrobialEfficiencycSoil
