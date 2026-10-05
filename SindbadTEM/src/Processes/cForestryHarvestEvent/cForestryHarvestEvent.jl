export cForestryHarvestEvent

abstract type cForestryHarvestEvent <: LandEcosystem end

purpose(::Type{cForestryHarvestEvent}) = ""

includeApproaches(cForestryHarvestEvent, @__DIR__)

@doc """ 
	$(getModelDocString(cForestryHarvestEvent))
"""
cForestryHarvestEvent

