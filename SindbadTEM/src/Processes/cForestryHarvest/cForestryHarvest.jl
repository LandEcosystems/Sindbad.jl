export cForestryHarvest

abstract type cForestryHarvest <: LandEcosystem end

purpose(::Type{cForestryHarvest}) = "Carbon loss due to harvest events."

includeApproaches(cForestryHarvest, @__DIR__)

@doc """ 
	$(getModelDocString(cForestryHarvest))
"""
cForestryHarvest
