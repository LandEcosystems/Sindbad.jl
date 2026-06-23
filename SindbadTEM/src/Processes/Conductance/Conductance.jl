export Conductance

abstract type Conductance <: LandEcosystem end

purpose(::Type{Conductance}) = "Canopy conductance"

includeApproaches(Conductance, @__DIR__)

@doc """ 
	$(getModelDocString(Conductance))
"""
Conductance
