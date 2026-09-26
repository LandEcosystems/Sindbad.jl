export APAR

abstract type APAR <: LandEcosystem end

purpose(::Type{APAR}) = "Absorbed Photosynthetically Active Radiation"

includeApproaches(APAR, @__DIR__)

@doc """ 
	$(getModelDocString(APAR))
"""
APAR
