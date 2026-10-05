export frozenFraction

abstract type frozenFraction <: LandEcosystem end

purpose(::Type{frozenFraction}) = "Frozen fraction of the soil"

includeApproaches(frozenFraction, @__DIR__)

@doc """ 
	$(getModelDocString(frozenFraction))
"""
frozenFraction

