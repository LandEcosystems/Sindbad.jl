export aerodynamics

abstract type aerodynamics <: LandEcosystem end

purpose(::Type{aerodynamics}) = "Aerodynamic resistance or condutance of leaf"

includeApproaches(aerodynamics, @__DIR__)

@doc """ 
	$(getModelDocString(aerodynamics))
"""
aerodynamics
