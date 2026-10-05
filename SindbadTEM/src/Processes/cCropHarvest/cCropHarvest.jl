export cCropHarvest

abstract type cCropHarvest <: LandEcosystem end

purpose(::Type{cCropHarvest}) = "Carbon loss due to harvest events."

includeApproaches(cCropHarvest, @__DIR__)

@doc """ 
	$(getModelDocString(cCropHarvest))
"""
cCropHarvest
