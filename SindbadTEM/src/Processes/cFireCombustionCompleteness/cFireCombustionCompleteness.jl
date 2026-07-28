export cFireCombustionCompleteness

abstract type cFireCombustionCompleteness <: LandEcosystem end
purpose(::Type{cFireCombustionCompleteness}) = "Accounts for carbon emissions due to fire, combustion completeness."
includeApproaches(cFireCombustionCompleteness, @__DIR__)

@doc """

$(getModelDocString(cFireCombustionCompleteness))

---

# Extended help

*Approaches:*
  - none: no fire forcing, no emissions
  - vanDerWerf2006: uses the van der Werf et al. (2006) method to calculate combustion completeness.

*Created by*
  - Nuno | nunocarvalhais
"""
cFireCombustionCompleteness