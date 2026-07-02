export stomatalConductance

abstract type stomatalConductance <: LandEcosystem end

purpose(::Type{stomatalConductance}) = "Daily Stomatal Conductance"

includeApproaches(stomatalConductance, @__DIR__)

@doc """ 
	$(getModelDocString(stomatalConductance))
"""
stomatalConductance
