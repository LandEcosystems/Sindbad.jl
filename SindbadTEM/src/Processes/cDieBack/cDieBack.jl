export cDieBack

abstract type cDieBack <: LandEcosystem end

purpose(::Type{cDieBack}) = "Disturbance of the carbon cycle pools."

includeApproaches(cDieBack, @__DIR__)

@doc """ 
	$(getModelDocString(cDieBack))
"""
cDieBack
