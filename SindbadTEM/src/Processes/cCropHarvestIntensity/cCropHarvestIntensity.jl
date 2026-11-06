export cCropHarvestIntensity

abstract type cCropHarvestIntensity <: LandEcosystem end

purpose(::Type{cCropHarvestIntensity}) = "Appropriation of carbon for crop products."

includeApproaches(cCropHarvestIntensity, @__DIR__)

@doc """ 
	$(getModelDocString(cCropHarvestIntensity))
"""
cCropHarvestIntensity

