export cMicrobialEfficiencycLit
export meCASAFlowsLitter

abstract type cMicrobialEfficiencycLit <: LandEcosystem end

purpose(::Type{cMicrobialEfficiencycLit}) = "Microbial carbon-transfer efficiency of the decomposition flows leaving the litter pools."

"""
    meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
        eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
        eff_cLitRootFine_to_cSoilSlow)

The CASA microbial carbon-transfer efficiency of every litter decomposition pathway, as
`edge => value` pairs keyed by giver-to-taker pool-name pair.

The surface microbial pathway retains least, the direct route into slow soil most, and
fine roots sit between the two because they decompose in the soil rather than at the
surface. The last two entries are the aggregated GSI litter pools, which take the
litter-to-soil efficiency; on CASA they are absent and `setMEFlow` skips them, and on GSI
the CASA-only entries are absent instead, so one table serves both.

A function rather than a table written inline, because two approaches declare it:
[`cMicrobialEfficiencycLit_CASA`](@ref) as this group's factor, and
[`cMicrobialEfficiency_CASA`](@ref) as part of the whole self-contained table. This is
the assignment whose `cLitRootCoarse` and `cLitWood` columns were transposed for as long
as it was a dense array indexed by position, so it exists in exactly one place.
"""
function meCASAFlowsLitter(eff_cLit_to_cMicSurf, eff_cLitRootFine_to_cMicSoil,
        eff_cLitRootCoarse_to_cMicSoil, eff_cLit_to_cSoilSlow,
        eff_cLitRootFine_to_cSoilSlow)
    return (
        (:cLitLeafFast_to_cMicSurf, eff_cLit_to_cMicSurf),
        (:cLitLeafSlow_to_cMicSurf, eff_cLit_to_cMicSurf),
        (:cLitWood_to_cMicSurf, eff_cLit_to_cMicSurf),
        (:cLitRootFineFast_to_cMicSoil, eff_cLitRootFine_to_cMicSoil),
        (:cLitRootFineSlow_to_cMicSoil, eff_cLitRootFine_to_cMicSoil),
        (:cLitRootCoarse_to_cMicSoil, eff_cLitRootCoarse_to_cMicSoil),
        (:cLitLeafSlow_to_cSoilSlow, eff_cLit_to_cSoilSlow),
        (:cLitRootCoarse_to_cSoilSlow, eff_cLit_to_cSoilSlow),
        (:cLitWood_to_cSoilSlow, eff_cLit_to_cSoilSlow),
        (:cLitRootFineSlow_to_cSoilSlow, eff_cLitRootFine_to_cSoilSlow),
        (:cLitFast_to_cSoilSlow, eff_cLit_to_cSoilSlow),
        (:cLitSlow_to_cSoilSlow, eff_cLit_to_cSoilSlow),
    )
end

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
`_CASA` names its edges instead, because it is the only one that distinguishes pathways
within the group.
"""
cMicrobialEfficiencycLit
