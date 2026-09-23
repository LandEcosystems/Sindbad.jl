export cCropHarvestEvent

abstract type cCropHarvestEvent <: LandEcosystem end

purpose(::Type{cCropHarvestEvent}) = ""

includeApproaches(cCropHarvestEvent, @__DIR__)

@doc """ 
	$(getModelDocString(cCropHarvestEvent))
"""
cCropHarvestEvent

