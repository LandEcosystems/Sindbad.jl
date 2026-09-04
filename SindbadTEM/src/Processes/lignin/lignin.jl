export lignin

abstract type lignin <: LandEcosystem end

purpose(::Type{lignin}) = "Determine the effect of litter lignin content on carbon-flow partitioning and decomposition rates."

includeApproaches(lignin, @__DIR__)

@doc """
	$(getModelDocString(lignin))

---
# Extended help

`lignin` publishes the lignin-effect properties:

- `lit_frac_lignin_struct`: lignin as a fraction of structural litter carbon.
  This controls how structural litter decomposition is split between the slow
  soil pool and the microbial pools.
- `lit_k_f_lignin`: multiplicative effect of lignin content on the decomposition
  rate of the structural litter pools. One means no effect.
- `lit_frac_C_lignin`: carbon fraction of lignin.
- `lit_frac_lignin_wood`: lignin fraction of woody litter, which controls the
  partitioning of woody and coarse-root litter decomposition.

The process runs directly after [`metabolicFraction`](@ref) and reads
`lit_frac_lignin`, `lit_frac_metabolic` and `lit_nonsol_to_sol_lignin` back from
`land.properties`, because lignin as a fraction of *structural* litter depends on
how much litter is structural in the first place. That ordering is what lets the
per-PFT litter chemistry be declared once, in `metabolicFraction`.

In the legacy SINDBAD CASA implementation these quantities were `SCLIGNIN`,
`LIGEFF`, `C2LIGNIN` and `frac_lignin_wood`, spread across
`cTauVegProperties_CASA`, `cQualityPartition_CASA` and `cFlowVegProperties_CASA`.
"""
lignin
