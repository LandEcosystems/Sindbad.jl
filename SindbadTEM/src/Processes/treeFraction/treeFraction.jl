export treeFraction

abstract type treeFraction <: LandEcosystem end

purpose(::Type{treeFraction}) = "Tree cover fraction."

# Load the plant-form fallback together with the standard approaches.
includeApproaches(treeFraction, @__DIR__)

@doc """ 
	$(getModelDocString(treeFraction))
"""
treeFraction
