export stomatalConductance

abstract type stomatalConductance <: LandEcosystem end

purpose(::Type{stomatalConductance}) = "Canopy stomatal conductance"

includeApproaches(stomatalConductance, @__DIR__)

@doc """ 
	$(getModelDocString(stomatalConductance))
"""
stomatalConductance
