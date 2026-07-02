export soilResistance

abstract type soilResistance <: LandEcosystem end

purpose(::Type{soilResistance}) = "Daily Soil Resistance for ET Dual Source Model"

includeApproaches(soilResistance, @__DIR__)

@doc """ 
	$(getModelDocString(soilResistance))
"""
soilResistance
