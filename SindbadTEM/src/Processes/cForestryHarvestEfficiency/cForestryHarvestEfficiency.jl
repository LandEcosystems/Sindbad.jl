export cForestryHarvestEfficiency

abstract type cForestryHarvestEfficiency <: LandEcosystem end

purpose(::Type{cForestryHarvestEfficiency}) = "Appropriation of carbon for wood products."

includeApproaches(cForestryHarvestEfficiency, @__DIR__)

@doc """ 
	$(getModelDocString(cForestryHarvestEfficiency))
"""
cForestryHarvestEfficiency

