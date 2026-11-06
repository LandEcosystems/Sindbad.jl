export cCropHarvestEfficiency

abstract type cCropHarvestEfficiency <: LandEcosystem end

purpose(::Type{cCropHarvestEfficiency}) = "Appropriation of carbon for crop products."

includeApproaches(cCropHarvestEfficiency, @__DIR__)

@doc """ 
	$(getModelDocString(cCropHarvestEfficiency))
"""
cCropHarvestEfficiency

