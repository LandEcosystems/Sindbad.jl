export cMicrobialEfficiency
export meTextureEfficiency, setMEFlow

abstract type cMicrobialEfficiency <: LandEcosystem end

purpose(::Type{cMicrobialEfficiency}) = "Assemble the flow-specific microbial carbon-transfer efficiency of litter and soil decomposition from the per-pool-group factors. The diagnostic c_flow_ME_vec is aligned with c_flow_order/c_giver/c_taker and represents the old CASA p_E efficiency term."

"""
    setMEFlow(me_vec, c_giver, c_taker, giver_zix, taker_zix, value)

Write `value` into every flow-vector position whose giver is in `giver_zix` and
whose taker is in `taker_zix`, and return the vector unchanged when no flow
matches -- e.g. a pool structure that lacks either group entirely.

The efficiency tables are declared once but the values they seed depend only on
which pools are involved, matched by index membership (`edgesBetween` in
`landUtils.jl`, which this calls through) rather than by a literal
`<giver>_to_<taker>` name -- so a table entry naming pools a given structure
lacks simply contributes nothing there, instead of erroring.

The body is `setFlowValue` in `landUtils.jl`. There is no group counterpart
here: an efficiency is a per-flow retention fraction rather than a partition, so a
giver's outgoing efficiencies are under no obligation to sum to one.

Used only by `cCycleBase_CASA`/`cCycleBase_CASA_Legacy`'s own `precompute`, to seed
`c_flow_ME_vec` with CASA's static defaults (`meCASAFlowsLitter`/`meCASAFlowsSoil`,
`cCycleBase_CASA.jl`) -- the per-group `cMicrobialEfficiencyc{Lit,Mic,Soil}`
approaches (`_constant`/`_none`/`_texture`) find their flows through `zix` directly,
without going through this function at all.
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

The efficiency splits by the pool group the carbon leaves, each of which owns a
disjoint set of transfers and is a process of its own:

- [`cMicrobialEfficiencycLit`](@ref): the transfers leaving the litter pools.
- [`cMicrobialEfficiencycMic`](@ref): the transfers leaving the microbial pools.
- [`cMicrobialEfficiencycSoil`](@ref): the transfers leaving the soil carbon pools.

[`cMicrobialEfficiency_mult`](@ref) combines the three, the way
[`cQualityPartition_mult`](@ref) combines the quality-partition factors and
[`cTau_mult`](@ref) the decomposition-rate stressors.

Two approaches bypass the factors instead of combining them, and read none of their
diagnostics, so either can be selected whether or not the groups are:

- [`cMicrobialEfficiency_none`](@ref): every transfer keeps the neutral efficiency of
  one.
- [`cMicrobialEfficiency_constant`](@ref): one constant on every decomposition transfer,
  whichever group it leaves. Set it to zero for the endpoint where all decomposed carbon
  respires.

CASA does not need a third: `cCycleBase_CASA` itself carries the 14 statically-known
CASA transfers as ordinary bounded parameters and writes them into `c_flow_ME_vec` in
`define`, so that table is the default with no `cMicrobialEfficiency` approach
selected at all. Only the soil-microbial pool's texture response, driven by
`st_clay`/`st_silt`, still needs one: select [`cMicrobialEfficiencycMic_texture`](@ref)
(composed with `_texture` for the other two groups through
[`cMicrobialEfficiency_mult`](@ref)), which applies the response to every transfer
leaving a microbial pool rather than singling out the soil one the way CASA's original
table did.

# Notes:
- Split by giver pool group rather than by control. A group is a pool-name prefix, so it
  is well defined on every pool structure and no transfer is ambiguous:
  `cSoilSlow_to_cSoilOld` belongs to `cMicrobialEfficiencycSoil` under GSI and CASA
  alike. A split by control instead strands the texture response on CASA, because GSI
  has no microbial pool for it to act on.
- Within each group, `_none`, `_constant` and `_texture` find their transfers through
  `zix` and so hold on any structure. CASA's exact, per-edge treatment does not have a
  group-factor form; it lives entirely in `cCycleBase_CASA`'s own parameters instead.
"""
cMicrobialEfficiency
