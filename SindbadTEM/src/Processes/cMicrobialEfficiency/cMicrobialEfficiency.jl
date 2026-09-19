export cMicrobialEfficiency
export meTextureEfficiency, setMEFlow

abstract type cMicrobialEfficiency <: LandEcosystem end

purpose(::Type{cMicrobialEfficiency}) = "Assemble the flow-specific microbial carbon-transfer efficiency of litter and soil decomposition from the per-pool-group factors. The diagnostic c_flow_ME_vec is aligned with c_flow_order/c_giver/c_taker and represents the old CASA p_E efficiency term."

"""
    setMEFlow(me_vec, c_giver, c_taker, giver_zix, taker_zix, value)

Write `value` into every flow-vector position whose giver is in `giver_zix` and
whose taker is in `taker_zix` (via `setFlowValue`/`edgesBetween` in
`landUtils.jl`), and return the vector unchanged when no flow matches.

There is no group counterpart here: an efficiency is a per-flow retention
fraction rather than a partition, so a giver's outgoing efficiencies are under
no obligation to sum to one.

Used only by `cCycleBase_CASA`'s own `precompute`, to seed `c_flow_ME_vec`
with CASA's static defaults (`meCASAFlowsLitter`/`meCASAFlowsSoil`); the
per-group `cMicrobialEfficiencyc{Lit,Mic,Soil}` approaches find their flows
through `zix` directly, without going through this function.
"""
function setMEFlow(me_vec, c_giver, c_taker, giver_zix, taker_zix, value)
    return setFlowValue(me_vec, c_giver, c_taker, giver_zix, taker_zix, value)
end

"""
    meTextureEfficiency(effA, effB, st_clay, st_silt)

The CASA microbial carbon-transfer efficiency of soil texture,
`clamp_zero_one(effA - effB * (mean(st_silt) + mean(st_clay)))`.

The soil profile collapses to a single mean clay and silt fraction, as in
`cQualityPartitionSoilProperties_clay`. Shared because the same law is the whole of the
three `_texture` approaches.
"""
function meTextureEfficiency(effA, effB, st_clay, st_silt)
    return clamp_zero_one(effA - effB * (mean(st_silt) + mean(st_clay)))
end

includeApproaches(cMicrobialEfficiency, @__DIR__)

@doc """
	$(getModelDocString(cMicrobialEfficiency))

---
# Extended help

`cMicrobialEfficiency` fills in `c_flow_ME_vec`, a flow-aligned diagnostic containing
one efficiency value for each active carbon transfer defined by `c_flow_order`,
`c_giver`, and `c_taker`. The vector itself is allocated neutral, one per flow, by
`cCycleBase`, so `cCycle` reads a valid efficiency even when no
`cMicrobialEfficiency` model is selected.

Vegetation-to-vegetation and vegetation-to-litter transfers are not microbial
decomposition and therefore keep that neutral efficiency of one. In the legacy SINDBAD
CASA implementation, the corresponding quantity was `p_E_vec`.

The efficiency splits by the pool group the carbon leaves, each a process of its own:

- [`cMicrobialEfficiencycLit`](@ref): the transfers leaving the litter pools.
- [`cMicrobialEfficiencycMic`](@ref): the transfers leaving the microbial pools.
- [`cMicrobialEfficiencycSoil`](@ref): the transfers leaving the soil carbon pools.

[`cMicrobialEfficiency_mult`](@ref) combines the three, the way
[`cQualityPartition_mult`](@ref) combines the quality-partition factors and
[`cTau_mult`](@ref) the decomposition-rate stressors.

Two approaches bypass the factors instead of combining them:

- [`cMicrobialEfficiency_none`](@ref): every transfer keeps the neutral efficiency of
  one.
- [`cMicrobialEfficiency_constant`](@ref): one constant on every decomposition transfer,
  whichever group it leaves.

CASA does not need a third: `cCycleBase_CASA` itself carries the 14 statically-known
CASA transfers as ordinary bounded parameters and writes them into `c_flow_ME_vec` in
`define`. Only the soil-microbial pool's texture response, driven by
`st_clay`/`st_silt`, still needs one: select
[`cMicrobialEfficiencycMic_texture`](@ref).

# Notes:
- Split by giver pool group rather than by control, since a group is a pool-name
  prefix and so well defined on every pool structure.
- Within each group, `_none`, `_constant` and `_texture` find their transfers through
  `zix` and so hold on any structure. CASA's exact, per-edge treatment has no
  group-factor form; it lives entirely in `cCycleBase_CASA`'s own parameters instead.
"""
cMicrobialEfficiency
