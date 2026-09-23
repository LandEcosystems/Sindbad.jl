export vegQualityTraits

abstract type vegQualityTraits <: LandEcosystem end

purpose(::Type{vegQualityTraits}) = "Determine litter chemistry, the metabolic litter fraction, and the lignin effects on carbon-flow partitioning and decomposition rates."

includeApproaches(vegQualityTraits, @__DIR__)

@doc """
	$(getModelDocString(vegQualityTraits))

---
# Extended help

`vegQualityTraits` publishes the litter-quality properties that the carbon-flow
partitioning and decomposition-rate processes need:

- `lit_frac_metabolic`: fraction of leaf and fine-root litterfall routed to the
  metabolic litter pools. The complement, `1 - lit_frac_metabolic`, goes to the
  structural pools.
- `lit_CN_ratio`: carbon-to-nitrogen ratio of litter.
- `lit_frac_lignin`: fraction of litter that is lignin.
- `lit_nonsol_to_sol_lignin`: scalar converting nonsoluble to soluble lignin.
- `lit_frac_lignin_struct`: lignin as a fraction of structural litter carbon, which
  controls how structural litter decomposition is split between the slow soil pool
  and the microbial pools.
- `lit_k_f_lignin`: multiplicative effect of lignin content on the decomposition
  rate of the structural litter pools. One means no effect.
- `lit_frac_C_lignin`: carbon fraction of lignin.
- `lit_frac_lignin_wood`: lignin fraction of woody litter, which controls the
  partitioning of woody and coarse-root litter decomposition.

This was previously two separately-selected processes, `metabolicFraction` and
`lignin`. They were never really independent: lignin as a fraction of *structural*
litter depends on how much litter is structural in the first place, so `lignin`'s CASA
approach read `metabolicFraction`'s output back from `land.properties`, and a
mismatched pair of selections (`lignin: CASA` with `metabolicFraction: none`, say)
silently produced wrong numbers rather than an error. One approach now computes both
together, so a valid combination is the only combination there is.

In the legacy SINDBAD CASA implementation these quantities were `MTF`, `LITC2N`,
`LIGNIN`, `NONSOL2SOLLIGNIN`, `SCLIGNIN`, `LIGEFF`, `C2LIGNIN` and `frac_lignin_wood`,
all computed inside `cTauVegProperties_CASA` (and `cQualityPartition_CASA`,
`cFlowVegProperties_CASA` for two of them).
"""
vegQualityTraits
