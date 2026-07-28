export cFireBurnedArea

abstract type cFireBurnedArea <: LandEcosystem end
purpose(::Type{cFireBurnedArea}) = "Accounts for carbon emissions due to fire"
includeApproaches(cFireBurnedArea, @__DIR__)

@doc """

$(getModelDocString(cFireBurnedArea))

---

# Extended help

*Approaches:*
- none: no fire forcing, no emissions
- forcing: uses fire forcing data to calculate emissions

*Created by*
  - Nuno | nunocarvalhais
"""
cFireBurnedArea
