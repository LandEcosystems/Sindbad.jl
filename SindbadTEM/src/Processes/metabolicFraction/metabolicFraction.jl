export metabolicFraction

abstract type metabolicFraction <: LandEcosystem end

purpose(::Type{metabolicFraction}) = "Determine the fraction of litterfall that is metabolic rather than structural, together with the litter chemistry it is derived from."

includeApproaches(metabolicFraction, @__DIR__)

@doc """
	$(getModelDocString(metabolicFraction))

---
# Extended help

`metabolicFraction` publishes the litter-quality properties that the carbon-flow
partitioning and decomposition-rate processes need:

- `lit_frac_metabolic`: fraction of leaf and fine-root litterfall routed to the
  metabolic litter pools. The complement, `1 - lit_frac_metabolic`, goes to the
  structural pools.
- `lit_C_to_N`: carbon-to-nitrogen ratio of litter.
- `lit_frac_lignin`: fraction of litter that is lignin.
- `lit_nonsol_to_sol_lignin`: scalar converting nonsoluble to soluble lignin.

The last three are inputs to the metabolic-fraction calculation itself, so they
are owned here and consumed by the [`lignin`](@ref) process, which runs directly
after and derives the lignin effects from them. That keeps the per-PFT litter
chemistry declared exactly once.

In the legacy SINDBAD CASA implementation these quantities were `MTF`, `LITC2N`,
`LIGNIN` and `NONSOL2SOLLIGNIN`, all computed inside `cTauVegProperties_CASA`.
"""
metabolicFraction
