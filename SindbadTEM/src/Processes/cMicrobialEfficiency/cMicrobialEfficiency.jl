export cMicrobialEfficiency
export meTextureEfficiency, setMEFlow

abstract type cMicrobialEfficiency <: LandEcosystem end

purpose(::Type{cMicrobialEfficiency}) = "Assemble the flow-specific microbial carbon-transfer efficiency of litter and soil decomposition from the per-pool-group factors. The diagnostic c_flow_ME_vec is aligned with c_flow_order/c_giver/c_taker and represents the old CASA p_E efficiency term."

"""
    setMEFlow(me_vec, c_flow_named_edges, edge, value)

Write `value` into every flow-vector position that carries the named `edge`, and
return the vector unchanged when the configured pool structure has no such edge.

The efficiency tables are declared over the full CASA pool topology, but the same
approaches are selected against more aggregated structures that lack the explicit
metabolic/structural litter and microbial pools. Skipping absent edges lets one
declaration serve both, instead of erroring on a pool the structure never had.

The body is `setFlowEdgeValue` in `landUtils.jl`, shared with `setQPFlow`. There is no
group counterpart here: an efficiency is a per-flow retention fraction rather than a
partition, so a giver's outgoing efficiencies are under no obligation to sum to one.

Only the `_CASA` approaches use this. The others find their flows through `zix`, which
needs no edge list and holds on any pool structure.
"""
function setMEFlow(me_vec, c_flow_named_edges, edge, value)
    return setFlowEdgeValue(me_vec, c_flow_named_edges, edge, value)
end

"""
    meTextureEfficiency(effA, effB, st_clay, st_silt)

The CASA microbial carbon-transfer efficiency of soil texture,
`clamp_zero_one(effA - effB * (mean(st_silt) + mean(st_clay)))`.

The soil profile collapses to a single mean clay and silt fraction, as in
`cQualityPartitionSoilProperties_clay`. Shared because the same law is the whole of the
three `_texture` approaches and the soil-microbial half of
[`cMicrobialEfficiencycMic_CASA`](@ref).
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

Three approaches bypass the factors instead of combining them, and read none of their
diagnostics, so any of them can be selected whether or not the groups are:

- [`cMicrobialEfficiency_CASA`](@ref): the whole CASA table in one selection, equal to
  composing the three `_CASA` factors. It shares their declarations rather than repeating
  them, so the two paths cannot drift apart.
- [`cMicrobialEfficiency_none`](@ref): every transfer keeps the neutral efficiency of
  one.
- [`cMicrobialEfficiency_constant`](@ref): one constant on every decomposition transfer,
  whichever group it leaves. Set it to zero for the endpoint where all decomposed carbon
  respires.

# Notes:
- Split by giver pool group rather than by control. A group is a pool-name prefix, so it
  is well defined on every pool structure and no transfer is ambiguous:
  `cSoilSlow_to_cSoilOld` belongs to `cMicrobialEfficiencycSoil` under GSI and CASA
  alike. A split by control instead strands the texture response on CASA, because GSI
  has no microbial pool for it to act on.
- Within each group, `_none`, `_constant` and `_texture` find their transfers through
  `zix` and so hold on any structure, while `_CASA` names its edges because it is the
  only one that distinguishes pathways within a group.
"""
cMicrobialEfficiency
