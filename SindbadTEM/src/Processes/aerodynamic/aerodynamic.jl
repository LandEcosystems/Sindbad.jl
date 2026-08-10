export aerodynamic

abstract type aerodynamic <: LandEcosystem end

purpose(::Type{aerodynamic}) = "Aerodynamic resistance or condutance of leaf"

includeApproaches(aerodynamic, @__DIR__)

@doc """ 
	$(getModelDocString(aerodynamic))
"""
aerodynamic
