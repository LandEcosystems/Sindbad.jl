export cForestryHarvestIntensity

abstract type cForestryHarvestIntensity <: LandEcosystem end

purpose(::Type{cForestryHarvestIntensity}) = "Appropriation of carbon for wood products."

includeApproaches(cForestryHarvestIntensity, @__DIR__)

@doc """ 
	$(getModelDocString(cForestryHarvestIntensity))
"""
cForestryHarvestIntensity

