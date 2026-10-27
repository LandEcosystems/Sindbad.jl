export vegFraction

abstract type vegFraction <: LandEcosystem end

purpose(::Type{vegFraction}) = "Vegetation cover fraction."

# Load the forcing-independent fallback together with the standard approaches.
includeApproaches(vegFraction, @__DIR__)

@doc """ 
	$(getModelDocString(vegFraction))
"""
vegFraction
